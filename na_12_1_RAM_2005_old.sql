/*
--drop table tbl_memory_usgae

select * from tbl_memory_usgae

use dbadata
go

CREATE TABLE [dbo].[tbl_memory_usgae](
	[servername] [varchar](100) NULL,
	[Physical_Memory_GB] [bigint] NULL,
	[BPool_Committed_GB] [bigint] NULL,
	[PLE] [bigint] NULL,
	[cntr_type] [int] NULL
	
)


use dbadata_archive
go
CREATE TABLE [dbo].[tbl_memory_usgae](
	[servername] [varchar](100) NULL,
	[Physical_Memory_GB] [bigint] NULL,
	[BPool_Committed_GB] [bigint] NULL,
	[PLE] [bigint] NULL,
	[cntr_type] [int] NULL,
	[Upload_date] [datetime] NULL
)

*/

--DROP PROC [Usp_Memory_alert]
alter proc [dbo].[Usp_Memory_alert]
with Encryption
as
begin

 DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @sql varchar(8000)
      DECLARE @sql1 varchar(8000)
      DECLARE @minrow int
      DECLARE @maxrow int

create table #tbl (servername varchar(100),cntr_value bigint,cntr_type bigint)


TRUNCATE TABLE tbl_memory_usgae


declare @spaceinfo table (id int  primary key identity, 
servername varchar(100),Description varchar(100)) 
 
insert into @spaceinfo
select Servername , Description   from dbadata.dbo.dba_all_servers 
WHERE Version in ('SQL2005') -- and edition  not in ('Express')
AND svr_status ='running'
 --select *  from dbadata.dbo.dba_all_servers
SELECT @minrow = MIN(id)FROM   @spaceinfo
SELECT @maxrow  = MAX(id) FROM   @spaceinfo
 
 while (@minrow <=@maxrow)
 begin
 BEGIN TRY
 TRUNCATE TABLE #tbl
 select @Server_name=Servername ,
 @Desc=Description   from @spaceinfo where ID = @minrow 

set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''SELECT '''''''''+@Desc+''''''''',CEILING(physical_memory_in_bytes/1073741824.0) as [Physical Memory_GB],
CEILING((bpool_committed*8)/1024.0/1024.0) as BPool_Committed_GB,500,65792
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
--print @sql1
insert into #tbl
exec(@sql1)

update t set ple= cntr_value
from tbl_memory_usgae t join #tbl a 
on t.cntr_type=a.cntr_type where t.servername =a.servername 

end try
BEGIN CATCH
SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'Memory2005',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()


PRINT 'SERVER ['+@SERVER_NAME+']is not COMPLETED.'
END CATCH
 
set @minrow =@minrow +1 
end
DROP TABLE #tbl
/*
----------------------------------------------------------------
--Send an email to DBA team
-----------------------------------------------------------------
      
      DECLARE @servername varchar(100)
      DECLARE @PHYSICAL_MEMORY_GB varchar(100)
      DECLARE @BPool_Committed_GB varchar(100)
      DECLARE @PLE varchar(100)         
      
      
--SELECT * FROM dbadata.dbo.tbl_memory_usgae
IF EXISTS (
SELECT * FROM dbadata.dbo.tbl_memory_usgae
where PLE <300
) 
begin

DECLARE SPACECUR CURSOR FOR

SELECT servername,PHYSICAL_MEMORY_GB, BPool_Committed_GB,
PLE FROM dbadata.dbo.tbl_memory_usgae 
where PLE <300

OPEN SPACECUR
FETCH NEXT FROM SPACECUR
INTO @servername,@PHYSICAL_MEMORY_GB, @BPool_Committed_GB,@PLE

DECLARE @BODY1 VARCHAR(max)
SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>Followings are MEMORY usage :</b> </font>
<P> 
<font size=1 color=#FF00FF  face=''verdana''>
<Table border=5 width=1000 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">  
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold"> 
 <td width=600 color=white>SERVER</td> 
 <td width=600 color=white>OS Memory GB</td> 
 <td width=600 color=white>SQL Memory GB</td> 
 <td width=150 color=white>PLE</td>  
 </b>  

 </tr>'
WHILE @@FETCH_STATUS=0
BEGIN
SET @BODY1= @BODY1 +'<tr>
<td>'+ISNULL(@SERVERNAME,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@PHYSICAL_MEMORY_GB,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@BPool_Committed_GB,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@PLE,'&nbsp')+'</td>'


FETCH NEXT FROM SPACECUR
INTO @servername,@PHYSICAL_MEMORY_GB, @BPool_Committed_GB,
@PLE

END
SET @BODY1=@BODY1+'</Table> </p>
<p>
<font style="color:#7E2217;font-face:verdana;font-size:9px;"> Generated on '
+convert(varchar(30),getdate(),100)+'. </BR>
This is an auto generated mail by CNA DBA Team. If you receive this email by mistake please contact us. 
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
@SUBJECT = 'DBA: RAM Usage ',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,
@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';
--select @BODY1

-------------------------------------------------------

end  
*/
insert into DBAdata_Archive.dbo.tbl_memory_usgae
select *,getdate() from tbl_memory_usgae
END


