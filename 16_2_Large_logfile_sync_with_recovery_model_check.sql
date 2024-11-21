USE [DBAdata]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*

USE [DBAdata]
GO
--drop table tbl_Large_logfile_sync_with_recovery_model_check
CREATE TABLE [dbo].[tbl_Large_logfile_sync_with_recovery_model_check](
	[servername] [sysname] NULL,
	[dbname] [sysname] NOT NULL,
	[filename] [sysname] NOT NULL,
	[recovery_model] [sysname] NOT NULL,
	[log_size] [int] NULL,
	[freespace] [varchar](50) NULL,
	[Drive_letter] [sysname] NULL,
	[log_reuse_wait_desc] [sysname] NOT NULL
	
)

USE [DBAdata_archive]
GO
--drop table tbl_Large_logfile_sync_with_recovery_model_check
CREATE TABLE [dbo].[tbl_Large_logfile_sync_with_recovery_model_check](
	[servername] [sysname] NULL,
	[dbname] [sysname] NOT NULL,
	[filename] [sysname] NOT NULL,
	[recovery_model] [sysname] NOT NULL,
	[log_size] [int] NULL,
	[freespace] [varchar](50) NULL,
	[Drive_letter] [sysname] NULL,
	[log_reuse_wait_desc] [sysname] NOT NULL,
	upload_date datetime
)

select * from tbl_Error_handling order by Upload_Date  desc
select * from tbl_recovery_model
and name not in (''''''''ReportServer'''''''',''''''''ReportServerTempDB'''''''')
*/


--exec dbadata.[dbo].[USP_Large_logfile_sync_with_recovery_model_check] @P_log_size = 50000, @P_freespace =50000 -- alert where log file is big not sync with recovery model

create  proc [dbo].[USP_Large_logfile_sync_with_recovery_model_check]
/*
Summary:        Send the log file size bot matching with recovery model to DBA Team
Contact:        Muthukkumaran Kaliyamoorthy SQL DBA
Description:	Send the log file size bot matching with recovery model to DBA Team

ChangeLog:
Date                          Coder                                                    Description
2012-06-04                 Muthukkumaran Kaliyamoorthy               created	Large log file than drive space
 
*******************All the SQL keywords should be written in upper case********************
*/
--with Encryption
(@P_log_size bigint, @P_freespace bigint)
as
begin

	  DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @sql varchar(max)
      DECLARE @minrow int
      DECLARE @maxrow int
-- select * from tbl_Large_logfile_sync_with_recovery_model_check
TRUNCATE TABLE tbl_Large_logfile_sync_with_recovery_model_check

 BEGIN TRY
 
insert into tbl_Large_logfile_sync_with_recovery_model_check
select servername,dbname,filename,recovery_model,log_size,freespace,Drive_letter,log_reuse_wait_desc--,[log_usedsize%] 
from [dbo].[tbl_get_logfiles_Huge] LH join [tbl_recovery_model_non_Prod] RM
on (LH.SERVERNAME=RM.SERVER_NAME)
where lh.dbname=rm.db_name
--and log_size >20000 and freespace <50000

insert into tbl_Large_logfile_sync_with_recovery_model_check
select servername,dbname,filename,recovery_model,log_size,freespace,Drive_letter,log_reuse_wait_desc--,[log_usedsize%]
--into tbl_Large_logfile_sync_with_recovery_model_check
from [dbo].[tbl_get_logfiles_Huge] LH join tbl_recovery_model RM
on (LH.SERVERNAME=RM.SERVER_NAME)
where lh.dbname=rm.db_name
--and log_size >20000 and freespace <50000


end try

BEGIN CATCH
SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'Largerlog_sysn_RM',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()


END CATCH



----------------------------------------------------------------
--Send an email to DBA team
-----------------------------------------------------------------
      
DECLARE @servername varchar(100),@dbname varchar(100),@filename varchar(100),@recovery_model varchar(100),
 @log_size varchar(100),@freespace varchar(100),@Drive_letter varchar(100),@log_reuse_wait_desc varchar(100),
 @log_usedsize varchar(100)

         
     
      
      
--SELECT * FROM dbadata.dbo.tbl_recovery_model
IF EXISTS (

select 1
from [dbo].[tbl_get_logfiles_Huge] LH join tbl_recovery_model RM
on (LH.SERVERNAME=RM.SERVER_NAME)
where lh.dbname=rm.db_name
and log_size >@P_log_size and freespace <@P_freespace
) 
begin

DECLARE Largelog_RM_CuR CURSOR FOR

select servername,dbname,filename,recovery_model,log_size,freespace,Drive_letter,log_reuse_wait_desc--,[log_usedsize%]
--into tbl_Large_logfile_sync_with_recovery_model_check
from [dbo].[tbl_get_logfiles_Huge] LH join tbl_recovery_model RM
on (LH.SERVERNAME=RM.SERVER_NAME)
where lh.dbname=rm.db_name
and log_size >@P_log_size and freespace <@P_freespace

OPEN Largelog_RM_CuR
FETCH NEXT FROM Largelog_RM_CuR
INTO @servername,@dbname,@filename,@recovery_model,@log_size,@freespace,@Drive_letter,@log_reuse_wait_desc--,@log_usedsize

DECLARE @BODY1 VARCHAR(max)
SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>Followings are Big log Sync with recover model:</b> </font>
<P> 
<font size=1 color=#FF00FF  face=''verdana''>
<Table border=5 width=1000 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">  
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold"> 
 <td width=600 color=white>Server Name</td>
 <td width=200 color=white>Database Name</td> 
 <td width=200 color=white>File Name</td> 
 <td width=200 color=white>Recovery</td> 
 <td width=200 color=white>Log Size</td> 
 <td width=200 color=white>Drive Free</td> 
 <td width=200 color=white>Drive</td> 
 <td width=200 color=white>Log Wait</td> 
  
 </b>  

 </tr>'
WHILE @@FETCH_STATUS=0
BEGIN
SET @BODY1= @BODY1 +'<tr>
<td>'+ISNULL(@servername,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@DBname,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@filename,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@recovery_model,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@log_size,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@freespace,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@Drive_letter,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@log_reuse_wait_desc,'&nbsp')+'</td>'


FETCH NEXT FROM Largelog_RM_CuR
INTO @servername,@dbname,@filename,@recovery_model,@log_size,@freespace,@Drive_letter,@log_reuse_wait_desc--,@log_usedsize

END
SET @BODY1=@BODY1+'</Table> </p>
<p>
<font style="color:#7E2217;font-face:verdana;font-size:9px;"> Generated on '
+convert(varchar(30),getdate(),100)+'. </BR>
This is an auto generated mail by DBA Team. If you receive this email by mistake please contact us. 
 </br>
© Property of DBA Team.
 </font>'

CLOSE Largelog_RM_CuR
DEALLOCATE Largelog_RM_CuR
DECLARE @EMAILIDS VARCHAR(500)

SELECT @EMAILIDS=
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS 
FROM DBADATA.dbo.DBA_ALL_OPERATORS WHERE name ='muthu' and STATUS =1


DECLARE @EMAILIDS1 VARCHAR(500)
SELECT @EMAILIDS1=
COALESCE(@EMAILIDS1+';','')+EMAIL_ADDRESS  FROM DBAdata.DBO.DBA_ALL_OPERATORS
WHERE STATUS =1 and Mail_copy='CC'


EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@SUBJECT = 'DBA: Big log Sync with recover model Report',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,
@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';
--select @BODY1

-------------------------------------------------------

end  

insert into DBAdata_Archive.dbo.tbl_Large_logfile_sync_with_recovery_model_check
select *,getdate() from tbl_Large_logfile_sync_with_recovery_model_check


END


