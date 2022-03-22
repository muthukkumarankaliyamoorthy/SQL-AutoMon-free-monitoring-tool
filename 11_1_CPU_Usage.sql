/*

use dbadata
go
DROP TABLE tbl_CPU_usgae

--select * from tbl_CPU_usgae

CREATE TABLE [dbo].[tbl_CPU_usgae](
	[servername] [varchar](100) NULL,
	[SQL_CPU_utilization] [int] NULL,
	[Idel] [int] NULL,
	[other_process] [int] NULL,
	[rundate] [datetime] NULL
	--,[Upload_date] [datetime] NULL
)

use dbadata_archive
go
DROP TABLE tbl_CPU_usgae


CREATE TABLE [dbo].[tbl_CPU_usgae](
	[servername] [varchar](100) NULL,
	[SQL_CPU_utilization] [int] NULL,
	[Idel] [int] NULL,
	[other_process] [int] NULL,
	[rundate] [datetime] NULL,
	[Upload_date] [datetime] NULL
)

*/

--DROP PROC [Usp_CPU_alert]
-- Exec DBAdata.[dbo].[Usp_CPU_alert] @SQL_CPU_utilization = 90, @other_process = 90
use dbadata
go
create proc [dbo].[Usp_CPU_alert]
/*
Summary:     CPU Utilization findings
Contact:     Muthukkumaran Kaliyamoorthy SQL DBA
Description: CPU Utilization findings

ChangeLog:
Date         Coder							Description
2013-jan-21	 Muthukkumaran Kaliyamoorhty     Updated the 2012 functionality                   


*/
--with Encryption
(@SQL_CPU_utilization int,@other_process int)
as

begin
-- select * from tbl_CPU_usgae
TRUNCATE TABLE tbl_CPU_usgae

	  DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @VER SYSNAME
      DECLARE @sql varchar(8000)
      DECLARE @sql1 varchar(8000)
      DECLARE @minrow int
      DECLARE @maxrow int

--select @@servername
DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks)FROM sys.dm_os_sys_info); 
insert into DBAdata.DBO.tbl_CPU_usgae

SELECT TOP(1) @@servername,SQLProcessUtilization AS [SQL Server Process CPU Utilization], 
               SystemIdle AS [System Idle Process], 
               100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization], 
               DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time] 
FROM ( 
      SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, 
            record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
            AS [SystemIdle], 
            record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 
            'int') 
            AS [SQLProcessUtilization], [timestamp] 
      FROM ( 
            SELECT [timestamp], CONVERT(xml, record) AS [record] 
            FROM sys.dm_os_ring_buffers 
            WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
            AND record LIKE '%<SystemHealth>%') AS x 
      ) AS y 
ORDER BY SQLProcessUtilization DESC;

declare @spaceinfo table (id int  primary key identity, 
servername varchar(100),Description varchar(100),VERSION varchar(20) ) 


insert into @spaceinfo
select Servername , Description,Version  from dbadata.dbo.dba_all_servers 
WHERE Version not in ('SQL2000') -- and edition  not in ('Express')
and Description not in ('ssss') AND svr_status ='running'
 --select *  from dbadata.dbo.dba_all_servers
SELECT @minrow = MIN(id)FROM   @spaceinfo
SELECT @maxrow  = MAX(id) FROM   @spaceinfo
--SELECT * FROM @spaceinfo

while (@minrow <=@maxrow)
 begin
 BEGIN TRY
select @Server_name=Servername ,@Desc=Description,@VER=VERSION from @spaceinfo where ID = @minrow 


 IF (@VER='SQL2005')
 BEGIN
 set @sql1=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''DECLARE @ts_now bigint;
SET @ts_now = (SELECT cpu_ticks / CONVERT(float, cpu_ticks_in_ms) FROM sys.dm_os_sys_info); SELECT TOP 1 '''''''''+@Desc+''''''''',
SQLProcessUtilization AS [SQL Server Process CPU Utilization], 
               SystemIdle AS [System Idle Process], 
               100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization], 
               DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time] 
FROM ( 
      SELECT record.value(''''''''(./Record/@id)[1]'''''''', ''''''''int'''''''') AS record_id, 
            record.value(''''''''(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]'''''''', ''''''''int'''''''') 
            AS [SystemIdle], 
            record.value(''''''''(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]'''''''', 
            ''''''''int'''''''') 
            AS [SQLProcessUtilization], [timestamp] 
      FROM ( 
            SELECT [timestamp], CONVERT(xml, record) AS [record] 
            FROM sys.dm_os_ring_buffers 
            WHERE ring_buffer_type = N''''''''RING_BUFFER_SCHEDULER_MONITOR''''''''
            AND record LIKE ''''''''%<SystemHealth>%'''''''') AS x 
       ) AS y
ORDER BY SQLProcessUtilization DESC OPTION (RECOMPILE);
'''')'')
'
insert into dbadata.dbo.tbl_CPU_usgae
EXEC (@sql1)

--PRINT @sql1
END

ELSE

BEGIN
set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks)FROM sys.dm_os_sys_info); SELECT TOP 1 '''''''''+@Desc+''''''''',
SQLProcessUtilization AS [SQL Server Process CPU Utilization], 
               SystemIdle AS [System Idle Process], 
               100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization], 
               DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time] 
FROM ( 
      SELECT record.value(''''''''(./Record/@id)[1]'''''''', ''''''''int'''''''') AS record_id, 
            record.value(''''''''(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]'''''''', ''''''''int'''''''') 
            AS [SystemIdle], 
            record.value(''''''''(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]'''''''', 
            ''''''''int'''''''') 
            AS [SQLProcessUtilization], [timestamp] 
      FROM ( 
            SELECT [timestamp], CONVERT(xml, record) AS [record] 
            FROM sys.dm_os_ring_buffers 
            WHERE ring_buffer_type = N''''''''RING_BUFFER_SCHEDULER_MONITOR''''''''
            AND record LIKE ''''''''%<SystemHealth>%'''''''') AS x 
       ) AS y 
ORDER BY SQLProcessUtilization DESC;
'''')'')
'
     
insert into dbadata.dbo.tbl_CPU_usgae
EXEC (@sql)

--PRINT @sql
END

end try
BEGIN CATCH
--SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'CPU',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

PRINT 'SERVER ['+@SERVER_NAME+']is not COMPLETED.'
END CATCH

set @minrow =@minrow +1 
end

--/*
----------------------------------------------------------------
--Send an email to DBA team
-----------------------------------------------------------------
      
      DECLARE @servername varchar(100)
      DECLARE @CUP_sql_Utilization varchar(100)
      DECLARE @IDEL varchar(100)
      DECLARE @CUP_other_process_Utilization varchar(100)
      
      
      
--SELECT * FROM dbadata.dbo.tbl_memory_usgae
IF EXISTS (
SELECT * FROM dbadata.dbo.tbl_CPU_usgae
where (SQL_CPU_utilization>@SQL_CPU_utilization) OR (other_process>@other_process)
) 
begin

DECLARE SPACECUR CURSOR FOR

SELECT servername,SQL_CPU_utilization,Idel,other_process FROM dbadata.dbo.tbl_CPU_usgae
where (SQL_CPU_utilization>@SQL_CPU_utilization) OR (other_process>@other_process)

OPEN SPACECUR
FETCH NEXT FROM SPACECUR
INTO @servername,@CUP_sql_Utilization,@IDEL,@CUP_other_process_Utilization

DECLARE @BODY1 VARCHAR(max)
SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>Followings are CPU usage :</b> </font>
<P> 
<font size=1 color=#FF00FF  face=''verdana''>
<Table border=5 width=1000 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">  
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold"> 
 <td width=600 color=white>Server</td> 
 <td width=600 color=white>% SQL Usage</td> 
 <td width=600 color=white>% Idel</td> 
 <td width=150 color=white>% Other Process</td>  
 </b>  

 </tr>'
WHILE @@FETCH_STATUS=0
BEGIN
SET @BODY1= @BODY1 +'<tr>
<td>'+ISNULL(@SERVERNAME,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@CUP_sql_Utilization,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@IDEL,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@CUP_other_process_Utilization,'&nbsp')+'</td>'


FETCH NEXT FROM SPACECUR
INTO @servername,@CUP_sql_Utilization,@IDEL,@CUP_other_process_Utilization

END
SET @BODY1=@BODY1+'</Table> </p>
<p>
<font style="color:#7E2217;font-face:verdana;font-size:9px;"> Generated on '
+convert(varchar(30),getdate(),100)+'. </BR>
This is an auto generated mail by DBA Team. If you receive this email by mistake please contact us. 
 </br>
© Property of DBA Team.
 </font>'

CLOSE SPACECUR
DEALLOCATE SPACECUR
DECLARE @EMAILIDS VARCHAR(500)

SELECT @EMAILIDS=
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS  
FROM DBADATA.dbo.DBA_ALL_OPERATORS WHERE name ='muthu' and STATUS =1



DECLARE @EMAILIDS1 VARCHAR(500)
SELECT @EMAILIDS1=
COALESCE(@EMAILIDS1+';','')+EMAIL_ADDRESS  FROM DBAdata.DBO.DBA_ALL_OPERATORS
WHERE STATUS =1 and Mail_copy='CC'


EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@SUBJECT = 'DBA: CPU Status',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,
@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';
--select @BODY1

-------------------------------------------------------

end
--*/
insert into DBAdata_Archive.dbo.tbl_CPU_usgae
select *,GETDATE() from tbl_CPU_usgae

END


-- select * From DBAdata_Archive.dbo.tbl_CPU_usgae where servername='kw3l1p41'