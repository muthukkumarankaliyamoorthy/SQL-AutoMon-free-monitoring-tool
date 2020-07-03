
-- drop table tbl_OS_version
-- select * from master.sys.sysdatabases

-- select * from tbl_OS_version

USE [DBAdata]

GO
/*

drop TABLE [dbo].[tbl_OS_version]

USE [DBAData]
GO
create table tbl_OS_version
(Servername varchar(100) primary key,Value varchar(100), OS_Version varchar(100))

exec master..xp_regread
      'HKEY_LOCAL_MACHINE'
    , 'SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    , 'ProductName'

select * from tbl_OS_version

*/
use DBAdata
go


create PROCEDURE [dbo].[Usp_load_OS_Info]
/*
Summary:       [Usp_load_OS_Info]
Contact:        Muthukkumaran Kaliyamoorhty SQL DBA

ChangeLog:
Date                          Coder                                                    Description
2012-06-04                 Muthukkumaran Kaliyamoorhty               created
 
*******************All the SQL keywords should be written in upper case********************
*/

AS
BEGIN
SET nocount ON

--inserting the drive space
Truncate table dbadata.dbo.[tbl_OS_version]


      DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @sql varchar(8000)
	  DECLARE @sql1 varchar(8000)
      DECLARE @minrow int
      DECLARE @maxrow int

---------------------------------------------------
--Put the local server first
---------------------------------------------------
 

CREATE TABLE #tbl_OS_version
(
value VARCHAR(50),
OS VARCHAR(100))

/*

create proc [dbo].[Usp_OS_version]
AS
BEGIN
TRUNCATE TABLE tbl_OS_version
INSERT INTO tbl_OS_version
exec master..xp_regread
      'HKEY_LOCAL_MACHINE'
    , 'SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    , 'ProductName'
end


INSERT INTO #tbl_OS_version
exec master..xp_regread
      'HKEY_LOCAL_MACHINE'
    , 'SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    , 'ProductName'

INSERT INTO tbl_OS_version
SELECT 'server'  AS SERVERNAME,* FROM #tbl_OS_version
*/

DECLARE Load_OS_version CURSOR
FOR

SELECT SERVERNAME,	[DESCRIPTION] FROM DBADATA.DBO.DBA_ALL_SERVERS
WHERE  svr_status ='running' 

OPEN Load_OS_version
FETCH NEXT FROM Load_OS_version INTO @SERVER_NAME,@DESC

WHILE @@FETCH_STATUS=0  
BEGIN
BEGIN TRY

TRUNCATE TABLE #tbl_OS_version


EXEC ('EXEC [' + @SERVER_NAME+'].MASTER.DBO.Usp_OS_version')
EXEC ('INSERT INTO  #tbl_OS_version SELECT * FROM [' + @SERVER_NAME+'].MASTER.DBO.tbl_OS_version')

INSERT INTO tbl_OS_version
SELECT @DESC AS SERVERNAME ,*  FROM #tbl_OS_version

--PRINT 'SERVER ' +@SERVER_NAME+' COMPLETED.'
END TRY

BEGIN CATCH
--SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
--select * from tbl_Error_handling

insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'Load OS version',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

--PRINT 'SERVER ['+@SERVER_NAME+']is not COMPLETED.'
END CATCH

FETCH NEXT FROM Load_OS_version INTO @SERVER_NAME,@DESC
END
CLOSE Load_OS_version
DEALLOCATE Load_OS_version
DROP TABLE #tbl_OS_version
END


