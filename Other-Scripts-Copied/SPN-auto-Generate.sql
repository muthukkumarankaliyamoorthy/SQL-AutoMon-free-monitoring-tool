/*
== Description == 
This script will check SPN and generate script like below if missed
   SETSPN –S MSSQLSvc/YOURSERVERNAME:1604 mydomain\svcAcct 
   SETSPN –S MSSQLSvc/YOURSERVERNAME.mydomain.com:1433 mydomain\svcAcct
== LIMITATION == 
- Make sure your sql server is not using DynamicPort
- If the server is part of AG group, this script won't check AG Listner 
*/

SET NOCOUNT ON
 
-- service account
DECLARE @DBEngineLogin VARCHAR(100)
 
EXECUTE master.dbo.xp_instance_regread
   @rootkey = N'HKEY_LOCAL_MACHINE',
   @key = N'SYSTEM\CurrentControlSet\Services\MSSQLServer',
   @value_name = N'ObjectName',
   @value = @DBEngineLogin OUTPUT
 
-- SELECT [DBEngineLogin] = @DBEngineLogin
 
DECLARE @physicalServerName varchar(128) = '%' + cast(serverproperty('ComputerNamePhysicalNetBIOS') as varchar(64))+ '%'
DECLARE @ServerName varchar(128) = '%' + cast(SERVERPROPERTY('MachineName') as varchar(64)) + '%'
DECLARE @spnCmd varchar(265)
 
SET @spnCmd = 'setspn -L ' + @DBEngineLogin
CREATE TABLE #spnResult (output varchar(1024) null)
INSERT #spnResult exec xp_cmdshell @spnCmd
 
CREATE TABLE #spnLIst (output varchar(1024) null)
 
INSERT #spnLIst
SELECT output as 'SPN List for Service Account' FROM #spnResult
WHERE output like @physicalServerName or output like @ServerName
 
Declare @NodeName VARCHAR(128)
DECLARE db_cursor CURSOR FOR  
SELECT '%' + NodeName + '%' AS NodeName FROM fn_virtualservernodes()
 
OPEN db_cursor 
FETCH NEXT FROM db_cursor INTO @NodeName 
 
WHILE @@FETCH_STATUS = 0 
BEGIN 
   INSERT #spnLIst
   SELECT output as 'SPN List for Service Account' FROM #spnResult
   WHERE output like @NodeName  
 
   FETCH NEXT FROM db_cursor INTO @NodeName 
END  
 
CLOSE db_cursor 
DEALLOCATE db_cursor
 
SELECT DISTINCT output as CurrentSPNRegisterStatus INTO #spnListCurrent FROM #spnLIst
 
TRUNCATE TABLE #spnLIst
 
-- GET Port Number 
DECLARE @PortNumber varchar(10) 
SELECT @PortNumber = cast(local_tcp_port as varchar(10))
FROM sys.dm_exec_connections WHERE session_id = @@SPID
 
-- GET FQDN
DECLARE @Domain NVARCHAR(100)
EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE', 'SYSTEM\CurrentControlSet\services\Tcpip\Parameters', N'Domain',@Domain OUTPUT
 
INSERT #spnLIst
SELECT 'MSSQLSvc/' + cast(serverproperty('ComputerNamePhysicalNetBIOS') as varchar(64)) + ':' + @PortNumber
UNION ALL
SELECT 'MSSQLSvc/' + cast(serverproperty('ComputerNamePhysicalNetBIOS') as varchar(64)) + '.' + @Domain  + ':' + @PortNumber
UNION ALL
SELECT 'MSSQLSvc/' + cast(SERVERPROPERTY('MachineName') as varchar(64)) + ':' + @PortNumber
UNION ALL
SELECT 'MSSQLSvc/' + cast(SERVERPROPERTY('MachineName') as varchar(64)) + '.' + @Domain + ':' + @PortNumber
 
-- If this serve is clusterd, need to check for all Physical nodes
IF SERVERPROPERTY('IsClustered') = 1
BEGIN
 
   INSERT #spnLIst
   SELECT 'MSSQLSvc/' + NodeName + ':' + @PortNumber
   FROM fn_virtualservernodes()
 
   INSERT #spnLIst
   SELECT 'MSSQLSvc/' + NodeName + '.' + @Domain  + ':' + @PortNumber
   FROM fn_virtualservernodes() 
 
END
 
IF NOT EXISTS(SELECT CurrentSPNRegisterStatus FROM #spnListCurrent)
   SELECT 'NO SPN has been registered' as CurrentSPNRegisterStatus
ELSE
   SELECT CurrentSPNRegisterStatus FROM #spnListCurrent
 
SELECT 
   CASE 
      WHEN A.CurrentSPNRegisterStatus is NULL THEN '*Missing SPN - See SPNGenerateCommandLine'
      ELSE A.CurrentSPNRegisterStatus END AS 'CurrentSPNRegisterStatus', 
   CASE 
      WHEN B.output IS NULL THEN '*** Review for Remove or you have multiple instance ***'
   ELSE B.output end as SuggestSPNList,
   CASE 
      WHEN B.output is null THEN
          'SETSPN -D ' + A.CurrentSPNRegisterStatus + ' ' + @DBEngineLogin
   ELSE 'SETSPN –S ' + output + ' ' + @DBEngineLogin END as SPNGenerateCommandLine
FROM #spnListCurrent A 
FULL OUTER JOIN #spnLIst B on REPLACE(A.CurrentSPNRegisterStatus,CHAR(9),'') = B.output
WHERE CurrentSPNRegisterStatus is NULL OR B.output IS NULL
 
IF @@ROWCOUNT = 0
 SELECT 'All SPN has been registered correctly. If you are running for AG Group, this script does not check so please check manually' as SPNStatus
 
DROP TABLE #spnResult
DROP TABLE #spnLIst
DROP TABLE #spnListCurrent
GO
