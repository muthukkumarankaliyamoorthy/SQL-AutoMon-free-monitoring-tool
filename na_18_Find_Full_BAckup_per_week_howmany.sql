USE [DBAdata]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*


use dbadata
drop table  tbl_find_fullbackup_per_week
go
CREATE TABLE [dbo].[tbl_find_fullbackup_per_week](
	[Servername] [nvarchar](128) NULL,
	[SQL_Version] [varchar] (50) NULL,
	[database_name] [nvarchar](128) NULL,
	[location] [nvarchar](260) NULL,
	[backup_finish_date] [datetime] NULL,
	[size_MB] [numeric](31, 11) NULL
)

use dbadata_archive
drop table  tbl_find_fullbackup_per_week
go
CREATE TABLE [dbo].[tbl_find_fullbackup_per_week](
	[Servername] [nvarchar](128) NULL,
	[SQL_Version] [varchar] (50) NULL,
	[database_name] [nvarchar](128) NULL,
	[location] [nvarchar](260) NULL,
	[backup_finish_date] [datetime] NULL,
	[size_MB] [numeric](31, 11) NULL,
	upload_date datetime
)


*/

-- SELECT * from dbadata_archive.dbo.tbl_find_fullbackup_per_week

alter PROCEDURE [dbo].[USP_DBA_find_full_bak_per_week]
AS BEGIN

SET NOCOUNT ON
TRUNCATE TABLE DBADATA.DBO.tbl_find_fullbackup_per_week

DECLARE @SERVERNAME VARCHAR(200)
DECLARE @DESC VARCHAR(200)
DECLARE @text VARCHAR(1000)


-- Load last 7 Days full backup 

insert into  tbl_find_fullbackup_per_week 

SELECT @@servername as Servername ,  cast (serverproperty('ProductVersion') as varchar(100))
,b.database_name, f.physical_device_name as location,
b.backup_finish_date,b.backup_size /1024/1024 AS size_MB -- into tbl_find_fullbackup_per_week
FROM MSDB.DBO.BACKUPMEDIAFAMILY F
JOIN MSDB.DBO.BACKUPSET B
ON (f.media_set_id=b.media_set_id)
where (b.type ='D'  or  b.type is null)
and b.backup_finish_date >= dateadd (dd,-7,getdate())
AND B.type='d'
and b.database_name not in ('master','msdb','model','ReportServer' ,'ReportServerTempDB' )
ORDER BY b.backup_finish_date DESC


PRINT @@SERVERNAME +' COMPLETED.'


DECLARE c_F_BAckup_find CURSOR
FOR

SELECT SERVERNAME,[DESCRIPTION] FROM DBADATA.DBO.DBA_ALL_SERVERS
where [DESCRIPTION] not like '%kil%'
--and [DESCRIPTION] not like '%express%'
and [DESCRIPTION] not in ('CVPSQLIP12','CVPSQLIP13','SACSQLIP16\INFOSECADRMS')
and svr_status ='running'

OPEN c_F_BAckup_find
FETCH NEXT FROM c_F_BAckup_find INTO @SERVERNAME,@DESC

WHILE @@FETCH_STATUS=0  
BEGIN
BEGIN TRY

set @text = 'EXEC(''SELECT * from OPENQUERY(['+@servername+'],
''''
SELECT @@servername as Servername ,  cast (serverproperty(''''''''ProductVersion'''''''') as varchar(100))
,b.database_name, f.physical_device_name as location,
b.backup_finish_date,b.backup_size /1024/1024 AS size_MB 
FROM MSDB.DBO.BACKUPMEDIAFAMILY F
JOIN MSDB.DBO.BACKUPSET B
ON (f.media_set_id=b.media_set_id)
where (b.type =''''''''D''''''''  or  b.type is null)
and b.backup_finish_date >= dateadd (dd,-7,getdate())
AND B.type=''''''''d''''''''
and b.database_name not in (''''''''master'''''''',''''''''msdb'''''''',
''''''''model'''''''',''''''''ReportServer'''''''' ,''''''''ReportServerTempDB'''''''' )
ORDER BY b.backup_finish_date DESC
'''')'')
'
/*
if exists(
select servername,database_name,sum(size_mb),count(database_name) as conut_of_backup --,location
from [dbo].tbl_find_fullbackup_per_week 
group by database_name,servername --,location
having count(database_name)>3
)
*/
--begin
--print @text
insert into tbl_find_fullbackup_per_week
exec (@text)
--end

end try
BEGIN CATCH
--SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @DESC,'Find_full_BAckup',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

PRINT 'SERVER ['+@SERVERNAME+']is not COMPLETED.'
END CATCH

FETCH NEXT FROM c_F_BAckup_find INTO @SERVERNAME,@DESC
END
CLOSE c_F_BAckup_find
DEALLOCATE c_F_BAckup_find

-- select * from tbl_find_fullbackup_per_week --where sql_version like '0%'

/*
SELECT *
FROM DBADATA.DBO.tbl_find_fullbackup_per_week


*/

/*
----------------------------------------------------
-- May be its time to send the report to my DBA
IF EXISTS(

select 1 from [dbo].tbl_find_fullbackup_per_week 
group by database_name,servername
having count(database_name)>3

)
BEGIN
DECLARE @SERVER_NAME VARCHAR(100)
DECLARE @database_name VARCHAR(100)
DECLARE @backup_type VARCHAR(10)
DECLARE @count VARCHAR(50)


begin


DECLARE c_find_Full_bak CURSOR FOR


select servername,database_name,count(database_name) as conut_of_backup from [dbo].tbl_find_fullbackup_per_week 
group by database_name,servername
having count(database_name)>3
order by conut_of_backup desc


OPEN c_find_Full_bak

FETCH NEXT FROM c_find_Full_bak
INTO @SERVER_NAME,@database_name,@count

DECLARE @BODY1 VARCHAR(max)
--#ECE5B6

SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>Followings are frequent Full backup per week:</b> </font>

<P> 
 <font size=1 color=#FF00FF  face=''verdana''>
<Table border=5 width=1000 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">  
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold"> 
 <td width=600 color=white>SERVER NAME</td> 
 <td width=600 color=white>DB Name</td> 
 <td width=100 color=white>Type</td>
 <td width=600 color=white>Count</td>
 </b> 
 </tr>'


WHILE @@FETCH_STATUS=0
BEGIN
SET @BODY1= @BODY1 +'<tr>
<td>'+ISNULL(@SERVER_NAME,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@database_name,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@count,'&nbsp')+'</td>'

FETCH NEXT FROM c_find_Full_bak
INTO @SERVER_NAME,@database_name,@count

END
SET @BODY1=@BODY1+'</Table> </p>
<p>
<font style="color:#7E2217;font-face:verdana;font-size:9px;"> Generated on '
+convert(varchar(30),getdate(),100)+'. </BR>
This is an auto generated mail by CNA DBA Team. If you receive this email by mistake please contact us. 
 </br>
© Property of DBA Team.
 </font>'

CLOSE c_find_Full_bak
DEALLOCATE c_find_Full_bak
DECLARE @EMAILIDS VARCHAR(500)

SELECT @EMAILIDS=
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS  
FROM DBADATA.dbo.DBA_ALL_OPERATORS WHERE name ='muthu' and STATUS =1



DECLARE @EMAILIDS1 VARCHAR(500)
SELECT @EMAILIDS1=
COALESCE(@EMAILIDS1+';','')+EMAIL_ADDRESS  FROM DBAdata.DBO.DBA_ALL_OPERATORS
WHERE STATUS =1 and Mail_copy='CC'


EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@SUBJECT = 'DBA: Find Full backup per week',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,
@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';
--select @BODY1
-------------------------------------------------------
END
end

*/
insert into DBADATA_Archive.DBO.tbl_find_fullbackup_per_week
select *,getdate() from DBADATA.DBO.tbl_find_fullbackup_per_week



END