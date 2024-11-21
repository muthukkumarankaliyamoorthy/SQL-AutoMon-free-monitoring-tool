USE [DBAdata]

GO
/*
USE [DBAdata]
GO
select * from DBAdata.dbo.tbl_find_fullBak_per_week_sync_with_drive
drop table tbl_find_fullBak_per_week_sync_with_drive
CREATE TABLE [dbo].[tbl_find_fullBak_per_week_sync_with_drive](
	[servername] [nvarchar](128) NULL,
	[database_name] [nvarchar](128) NULL,
	[sum_of_Bak_size] [numeric](38, 11) NULL,
	[conut_of_backup] [int] NULL,
	[SQL_Version] [varchar](50) NULL,
	[location] [char](1) NULL,
	[FREE_SPACE_IN_MB] [int] NULL,
	[Total_SPACE_IN_MB] [int] NULL,
	[Precentage_free] [numeric](9, 0) NULL
)

USE [DBAdata_archive]
GO
select * from DBAdata_archive.dbo.tbl_find_fullBak_per_week_sync_with_drive
drop table tbl_find_fullBak_per_week_sync_with_drive
CREATE TABLE [dbo].[tbl_find_fullBak_per_week_sync_with_drive](
	[servername] [nvarchar](128) NULL,
	[database_name] [nvarchar](128) NULL,
	[sum_of_Bak_size] [numeric](38, 11) NULL,
	[conut_of_backup] [int] NULL,
	[SQL_Version] [varchar](50) NULL,
	[location] [char](1) NULL,
	[FREE_SPACE_IN_MB] [int] NULL,
	[Total_SPACE_IN_MB] [int] NULL,
	[Precentage_free] [numeric](9, 0) NULL,
	upload_date datetime
)

*/


alter  proc [dbo].[USP_Get_full_backup_per_week_sync_with_Drive]
with Encryption
as

begin
SET NOCOUNT ON
TRUNCATE TABLE DBADATA.DBO.tbl_find_fullBak_per_week_sync_with_drive


--loading all server details with condition , u can use having () optional
-- select * from tbl_find_fullBak_per_week_sync_with_drive

insert into  tbl_find_fullBak_per_week_sync_with_drive 
---- select * from [dbo].tbl_find_fullbackup_per_week  where servername ='KCH1P515'
select  servername,database_name,sum(ff.size_mb) as sum_of_Bak_size,count(database_name) as conut_of_backup,--ff.backup_finish_date,
ff.SQL_Version,sp.drive as location,sp.FREE_SPACE_IN_MB,sp.Total_SPACE_IN_MB,sp.Precentage_free  --into tbl_find_fullBak_per_week_sync_with_drive
 from  [dbo].tbl_find_fullbackup_per_week FF 
join [DBA_All_Server_Space_percentage] SP
--on FF.servername =SP.SERVER_NAME
on left(ff.location,1) =SP.DRIVE
where  FF.servername =SP.SERVER_NAME
and ff.size_mb > 10000 and Precentage_free <70
group by 
database_name,servername,ff.SQL_Version,--ff.backup_finish_date,
sp.drive,sp.FREE_SPACE_IN_MB,sp.Total_SPACE_IN_MB,sp.Precentage_free
having count(ff.database_name)>1
order by Precentage_free 

PRINT @@SERVERNAME +' COMPLETED.'

----------------------------------------------------------------
--Send an email to DBA team
-----------------------------------------------------------------
      
DECLARE @servername varchar(100),@database_name varchar(100),@Bak_size_MB varchar(100),@count varchar(100),@SQL_Version varchar(100)
,@Bak_Drive varchar(100),@FREE_SPACE_IN_MB varchar(100),@Total_SPACE_IN_MB varchar(100),@Precentage_free varchar(100)
  
      
IF EXISTS (

select  1
 from  [dbo].tbl_find_fullbackup_per_week FF 
join [DBA_All_Server_Space_percentage] SP
--on FF.servername =SP.SERVER_NAME
on left(ff.location,1) =SP.DRIVE
where  FF.servername =SP.SERVER_NAME
and ff.size_mb > 10000 and Precentage_free <75
group by 
database_name,servername,ff.SQL_Version,--ff.backup_finish_date,
sp.drive,sp.FREE_SPACE_IN_MB,sp.Total_SPACE_IN_MB,sp.Precentage_free
--having count(ff.database_name)>1

) 
begin

DECLARE Getper_week_CuR CURSOR FOR

select  servername,database_name,sum(ff.size_mb) as sum_of_Bak_size,count(database_name) as conut_of_backup,--ff.backup_finish_date,
ff.SQL_Version,sp.drive as location,sp.FREE_SPACE_IN_MB,sp.Total_SPACE_IN_MB,sp.Precentage_free
 from  [dbo].tbl_find_fullbackup_per_week FF 
join [DBA_All_Server_Space_percentage] SP
--on FF.servername =SP.SERVER_NAME
on left(ff.location,1) =SP.DRIVE
where  FF.servername =SP.SERVER_NAME
and ff.size_mb > 10000 and Precentage_free <75
group by 
database_name,servername,ff.SQL_Version,--ff.backup_finish_date,
sp.drive,sp.FREE_SPACE_IN_MB,sp.Total_SPACE_IN_MB,sp.Precentage_free
--having count(ff.database_name)>1
order by Precentage_free


OPEN Getper_week_CuR
FETCH NEXT FROM Getper_week_CuR
INTO @servername,@database_name,@Bak_size_MB,@count,@SQL_Version,@Bak_Drive,@FREE_SPACE_IN_MB,@Total_SPACE_IN_MB,@Precentage_free

DECLARE @BODY1 VARCHAR(max)
SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>Followings are full backup stored in the drive:</b> </font>
<P> 
<font size=1 color=#FF00FF  face=''verdana''>
<Table border=5 width=1000 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">  
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold"> 
 <td width=600 color=white>Server Name</td>
 <td width=200 color=white>Database Name</td> 
 <td width=200 color=white>Count Size MB</td> 
 <td width=200 color=white>Taken Count</td> 
 <td width=200 color=white>Version</td> 
 <td width=200 color=white>Drive</td> 
  <td width=200 color=white>FreeSpace MB</td> 
 <td width=200 color=white>TotalSpace MB</td> 
  <td width=600 color=white>% Free</td> 
 </b>  

 </tr>'
WHILE @@FETCH_STATUS=0
BEGIN
SET @BODY1= @BODY1 +'<tr>
<td>'+ISNULL(@servername,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@database_name,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@Bak_size_MB,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@count,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@SQL_Version,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@Bak_Drive,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@FREE_SPACE_IN_MB,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@Total_SPACE_IN_MB,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@Precentage_free,'&nbsp')+'</td>'

FETCH NEXT FROM Getper_week_CuR
INTO @servername,@database_name,@Bak_size_MB,@count,@SQL_Version,@Bak_Drive,@FREE_SPACE_IN_MB,@Total_SPACE_IN_MB,@Precentage_free

END
SET @BODY1=@BODY1+'</Table> </p>
<p>
<font style="color:#7E2217;font-face:verdana;font-size:9px;"> Generated on '
+convert(varchar(30),getdate(),100)+'. </BR>
This is an auto generated mail by CNA DBA Team. If you receive this email by mistake please contact us. 
 </br>
© Property of DBA Team.
 </font>'

CLOSE Getper_week_CuR
DEALLOCATE Getper_week_CuR
DECLARE @EMAILIDS VARCHAR(500)

SELECT @EMAILIDS=
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS 
FROM DBADATA.dbo.DBA_ALL_OPERATORS WHERE name ='muthu' and STATUS =1


DECLARE @EMAILIDS1 VARCHAR(500)
SELECT @EMAILIDS1=
COALESCE(@EMAILIDS1+';','')+EMAIL_ADDRESS  FROM DBAdata.DBO.DBA_ALL_OPERATORS
WHERE STATUS =1 and Mail_copy='CC'

-- select * FROM DBAdata.DBO.DBA_ALL_OPERATORS
EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@SUBJECT = 'DBA: Get full backup stored in drive Report',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,
@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';
--select @BODY1

-------------------------------------------------------

end  

insert into DBAdata_Archive.dbo.tbl_find_fullBak_per_week_sync_with_drive
select *,getdate() from tbl_find_fullBak_per_week_sync_with_drive
--select * from  DBAdata_Archive.dbo.tbl_find_fullBak_per_week_sync_with_drive

END
-- [USP_Get_full_backup_per_week_sync_with_Drive]

