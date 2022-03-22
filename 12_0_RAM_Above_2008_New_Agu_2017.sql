/*
--drop table tbl_memory_usgae_2012_New

select * from tbl_memory_usgae_2012_New

use dbadata
go
drop table tbl_memory_usgae_2012_New
go
CREATE TABLE [dbo].[tbl_memory_usgae_2012_New](
	[servername] [varchar](100) NULL,
	[Physical_RAM_mB][bigint] NULL,
	[Physical_RAM_Use_mB] [bigint] NULL,
	[Physical_RAM_Available_mB] [bigint] NULL,
	[Percentage use] [numeric](23, 10) NULL,
	[Locked_page_RAM_mB]  [bigint] NULL,
	[Max_RAM]   sql_variant NULL,
	[Min_RAM]  sql_variant NULL,
	[PLE] [bigint] NULL,
	[Version] [varchar](10) NULL,
	[cntr_type] [int] NULL
	
)

use dbadata_archive
go
drop table tbl_memory_usgae_2012_New
go
CREATE TABLE [dbo].[tbl_memory_usgae_2012_New](
	[servername] [varchar](100) NULL,
	[Physical_RAM_mB][bigint] NULL,
	[Physical_RAM_Use_mB] [bigint] NULL,
	[Physical_RAM_Available_mB] [bigint] NULL,
	[Percentage use] [numeric](23, 10) NULL,
	[Locked_page_RAM_mB]  [bigint] NULL,
	[Max_RAM]   sql_variant NULL,
	[Min_RAM]  sql_variant NULL,
	[PLE] [bigint] NULL,
	[Version] [varchar](10) NULL,
	[cntr_type] [int] NULL,
	[Upload_date] [datetime] NULL
)


*/
-- Exec DBAdata.[dbo].[Usp_Memory_alert_2012_New] @P_PLE = 300 -- alert low PLE
use DBAData
go
--DROP PROC [[Usp_Memory_alert_2012_New]]
alter proc [dbo].[Usp_Memory_alert_2012_New]
/*
Summary:     Memory Utilization findings
Contact:     Muthukkumaran Kaliyamoorhty SQL DBA
Description: Memory Utilization findings

ChangeLog:
Date         Coder							Description
2017-Aug-21	 Muthukkumaran Kaliyamoorhty     Updated the 2012 functionality                   
Add version

*/

--with Encryption
(@P_PLE int)
as
begin

 DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @sql varchar(8000)
      DECLARE @sql1 varchar(8000)
      DECLARE @sql2 varchar(8000)
      DECLARE @sql3 varchar(8000)
      DECLARE @VER SYSNAME
      DECLARE @minrow int
      DECLARE @maxrow int

create table #tbl (servername varchar(100),cntr_value bigint,cntr_type bigint)
-- select * from tbl_memory_usgae_2012_New
TRUNCATE TABLE tbl_memory_usgae_2012_New
--select @@SERVERNAME 

INSERT INTO dbadata.dbo.tbl_memory_usgae_2012_New
SELECT @@servername as Servername,
    [physical_memory_kb]/1024AS [PhysMemmB],
    [physical_memory_in_use_kb]/1024 AS [PhysMemInUsemB],
    [available_physical_memory_kb]/1024 AS [PhysMemAvailmB],
	((CONVERT(NUMERIC(9,0),[physical_memory_in_use_kb]/1024) / CONVERT(NUMERIC(9,0),[Total_physical_memory_kb]/1024)) * 100) AS [Percentage use],
    [locked_page_allocations_kb]/1024 AS [LPAllocmB],
    [max_server_memory] AS [MaxSvrMem],
    [min_server_memory] AS [MinSvrMem], 
	500,'SQL2012',65792-- into tbl_memory_usgae_2012_New_T
FROM
    sys.dm_os_sys_info
CROSS JOIN
    sys.dm_os_process_memory
CROSS JOIN
    sys.dm_os_sys_memory
CROSS JOIN (
    SELECT
        [value_in_use] AS [max_server_memory]
    FROM
        sys.configurations
    WHERE
        [name] = 'max server memory (MB)') AS c
CROSS JOIN (
    SELECT
        [value_in_use] AS [min_server_memory]
    FROM
        sys.configurations
    WHERE
        [name] = 'min server memory (MB)') AS c2

update t set ple= cntr_value
from tbl_memory_usgae_2012_New t join sys.dm_os_performance_counters a 
on t.cntr_type=a.cntr_type 
where a.counter_name  like '%page life%'
and a.object_name like '%manager%'


declare @Memory_info table (id int  primary key identity, 
servername varchar(100),Description varchar(100),VERSION varchar(20) ) 


insert into @Memory_info
select Servername , Description,Version  from dbadata.dbo.dba_all_servers 
WHERE Version >='SQL2012'
and Description not in ('sss')
AND svr_status ='running'
 --select *  from dbadata.dbo.dba_all_servers
SELECT @minrow = MIN(id)FROM   @Memory_info
SELECT @maxrow  = MAX(id) FROM   @Memory_info
--SELECT * FROM @Memory_info

 
 while (@minrow <=@maxrow)
 begin
 BEGIN TRY
 TRUNCATE TABLE #tbl
 select @Server_name=Servername ,@Desc=Description,
 @VER=VERSION from @Memory_info where ID = @minrow 
/* 
IF (@VER='SQL2005')
 BEGIN
 set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''SELECT '''''''''+@Desc+''''''''',CEILING(physical_memory_in_bytes/1073741824.0) as [Physical Memory_mB],
CEILING((bpool_committed*8)/1024.0/1024.0) as BPool_Committed_mB,00,
500,'''''''''+@VER+''''''''',65792,getdate()
FROM sys.dm_os_sys_info
'''')'')
'
insert into dbadata.dbo.tbl_memory_usgae
exec(@sql)


set @sql1=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''SELECT '''''''''+@Desc+''''''''',cntr_value,cntr_type from
sys.dm_os_performance_counters where counter_name  like ''''''''%page life%''''''''
and object_name like ''''''''%manager%''''''''
'''')'')
'

insert into #tbl
exec(@sql1)

update t set ple= cntr_value
from tbl_memory_usgae t join #tbl a 
on t.cntr_type=a.cntr_type where t.servername =a.servername

--print @sql1
 
END

ELSE
*/
BEGIN

set @sql2=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''SELECT '''''''''+@Desc+''''''''',[physical_memory_kb]/1024 AS [PhysMemmB],
    [physical_memory_in_use_kb]/1024 AS [PhysMemInUsemB],
	((CONVERT(NUMERIC(9,0),[physical_memory_in_use_kb]/1024) / CONVERT(NUMERIC(9,0),[Total_physical_memory_kb]/1024)) * 100) AS [Percentage use],
    [available_physical_memory_kb]/1024 AS [PhysMemAvailmB],
    [locked_page_allocations_kb]/1024 AS [LPAllocmB],
    [max_server_memory] AS [MaxSvrMem],
    [min_server_memory] AS [MinSvrMem],
500,'''''''''+@VER+''''''''',65792
FROM
    sys.dm_os_sys_info
CROSS JOIN
    sys.dm_os_process_memory
CROSS JOIN
    sys.dm_os_sys_memory
CROSS JOIN (
    SELECT
        [value_in_use] AS [max_server_memory]
    FROM
        sys.configurations
    WHERE
        [name] = ''''''''max server memory (MB)'''''''') AS c
CROSS JOIN (
    SELECT
        [value_in_use] AS [min_server_memory]
    FROM
        sys.configurations
    WHERE
        [name] = ''''''''min server memory (MB)'''''''') AS c2
'''')'')
'
insert into dbadata.dbo.tbl_memory_usgae_2012_New
exec(@sql2)

set @sql3=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''SELECT '''''''''+@Desc+''''''''',cntr_value,cntr_type from
sys.dm_os_performance_counters where counter_name  like ''''''''%page life%''''''''
and object_name like ''''''''%manager%''''''''
'''')'')
'

insert into #tbl
exec(@sql3)

update t set ple= cntr_value
from tbl_memory_usgae_2012_New t join #tbl a 
on t.cntr_type=a.cntr_type where t.servername =a.servername 
--print @sql1
END

end try
BEGIN CATCH
SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'Memory',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()


--PRINT 'SERVER ['+@SERVER_NAME+']is not COMPLETED.'
END CATCH
 
set @minrow =@minrow +1 
end
DROP TABLE #tbl

--/*
----------------------------------------------------------------
--Send an email to DBA team
-----------------------------------------------------------------
      
      DECLARE @servername varchar(100)
      DECLARE @Physical_Ram_Use varchar(100)
      --DECLARE @AVAILABLE_MEMORY_MB varchar(100)
      DECLARE @Physical_ram_Available varchar(100)
      DECLARE @PLE varchar(100)         
      
      
--SELECT * FROM dbadata.dbo.tbl_memory_usgae
IF EXISTS (
SELECT * FROM dbadata.dbo.tbl_memory_usgae_2012_New
where PLE<=@P_PLE
) 
begin

DECLARE SPACECUR CURSOR FOR

SELECT servername,Physical_Ram_Use_mB,Physical_ram_Available_mB,PLE
FROM dbadata.dbo.tbl_memory_usgae_2012_New 
where PLE<=@P_PLE

OPEN SPACECUR
FETCH NEXT FROM SPACECUR
INTO @servername,@Physical_Ram_Use, @Physical_ram_Available,@PLE

DECLARE @BODY1 VARCHAR(max)
SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>Followings are MEMORY usage :</b> </font>
<P> 
<font size=1 color=#FF00FF  face=''verdana''>
<Table border=5 width=1000 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">  
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold"> 
 <td width=600 color=white>SERVER</td> 
 <td width=600 color=white>SQL used RAM MB</td> 
 <td width=600 color=white>Available RAM MB</td> 
 <td width=150 color=white>PLE</td>  
 </b>  

 </tr>'
WHILE @@FETCH_STATUS=0
BEGIN
SET @BODY1= @BODY1 +'<tr>
<td>'+ISNULL(@SERVERNAME,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@Physical_Ram_Use,'&nbsp')+'</td>'+

'<td align=center>'+ISNULL(@Physical_ram_Available,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@PLE,'&nbsp')+'</td>'


FETCH NEXT FROM SPACECUR
INTO @servername,@Physical_Ram_Use, @Physical_ram_Available,@PLE


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
@SUBJECT = 'DBA: RAM Usage SQL 2012 and Onwards',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,
@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';
--select @BODY1

-------------------------------------------------------

end  
--*/
insert into DBAdata_Archive.dbo.tbl_memory_usgae_2012_New
select *,getdate() from tbl_memory_usgae_2012_New


END


