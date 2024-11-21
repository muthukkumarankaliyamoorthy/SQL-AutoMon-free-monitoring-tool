USE [DBAdata]
go
/*
-- drop table  tbl_ALL_DB_full_backup

use dbadata
go
drop table tbl_ALL_DB_full_backup

CREATE TABLE [dbo].[tbl_ALL_DB_full_backup](
	[SERVER] [nvarchar](128) NULL,
	[DATABASE] [nvarchar](128) NULL,
	[BAKUPTYPE] [varchar](20) NULL,
	[Backup_size_In_GB] bigint,
	[RECENT BACKUP] [datetime] NULL,
	[LOCATION] [nvarchar](260) NULL
) 

use dbadata_archive
go
drop table tbl_ALL_DB_full_backup

CREATE TABLE [dbo].[tbl_ALL_DB_full_backup](
	[SERVER] [nvarchar](128) NULL,
	[DATABASE] [nvarchar](128) NULL,
	[BAKUPTYPE] [varchar](20) NULL,
	[Backup_size_In_GB] bigint,
	[RECENT BACKUP] [datetime] NULL,
	[LOCATION] [nvarchar](260) NULL,
	uploaddate datetime
)


*/ 

-- This is not scheduled in the job, but it's good get the latest backup of each DB all types

alter PROCEDURE [dbo].[USP_DBA_All_DB_Full_Backup_Last_Taken]
AS BEGIN

SET NOCOUNT ON
TRUNCATE TABLE DBADATA.DBO.tbl_ALL_DB_full_backup

DECLARE @SERVERNAME VARCHAR(200)
DECLARE @DESC VARCHAR(200)
DECLARE @text nVARCHAR(MAX)


/* Find last full backup test script, this will have a (a.type ='D' or  a.type is null)

insert into  tbl_ALL_DB_full_backup 

 
		EXEC USP_DBA_RECENTBACKUPS '<DBNAME>','R'
		
PRINT @@SERVERNAME +' COMPLETED.'
*/

DECLARE c_F_BAckup_last_Date CURSOR
FOR

SELECT SERVERNAME,[DESCRIPTION] FROM DBADATA.DBO.DBA_ALL_SERVERS
where [DESCRIPTION] not like '%kil%'
--and [DESCRIPTION] not like '%express%'
and [DESCRIPTION] not in ('CVPSQLIP12','CVPSQLIP13','SACSQLIP16\INFOSECADRMS')
and svr_status ='running'
and Version <>'sql2000'

OPEN c_F_BAckup_last_Date
FETCH NEXT FROM c_F_BAckup_last_Date INTO @SERVERNAME,@DESC

WHILE @@FETCH_STATUS=0  
BEGIN
BEGIN TRY

set @text = 'EXEC(''SELECT * from OPENQUERY(['+@servername+'],
''''

WITH 
		BACKUP_RECENT AS
		(
		
		SELECT MAX(BACKUP_DATE) BACKUP_DATE,MAX(ID) ID,[TYPE], @@servername as SERVER_NAME,name
		FROM
		(
		SELECT  ROW_NUMBER() OVER (ORDER BY d.name,[TYPE],BACKUP_FINISH_DATE) ID,
				BACKUP_FINISH_DATE BACKUP_DATE, PHYSICAL_DEVICE_NAME,A.MEDIA_SET_ID,
				@@servername as SERVER_NAME, d.name,[TYPE],backup_size

				
				FROM master.dbo.sysdatabases D left outer join MSDB.DBO.BACKUPSET A 
				on D.name= a.database_name				

				left outer join MSDB.DBO.BACKUPMEDIAFAMILY B ON(A.MEDIA_SET_ID=B.MEDIA_SET_ID)

				where D.name not in (''''''''tempdb'''''''')
				and  (b.PHYSICAL_DEVICE_NAME not like ''''''''vn%''''''''or  b.PHYSICAL_DEVICE_NAME  is null)
				and  (b.PHYSICAL_DEVICE_NAME not like ''''''''{%''''''''or  b.PHYSICAL_DEVICE_NAME  is null)

		) BACKUPS 		GROUP BY [TYPE],SERVER_NAME,name

		),

		BACKUP_ALL AS
		(
		
SELECT  ROW_NUMBER() OVER (ORDER BY D.name,[TYPE],BACKUP_FINISH_DATE) ID,PHYSICAL_DEVICE_NAME,backup_size

				FROM master.dbo.sysdatabases D left outer join MSDB.DBO.BACKUPSET A 
				on D.name= a.database_name				

				left outer join MSDB.DBO.BACKUPMEDIAFAMILY B ON(A.MEDIA_SET_ID=B.MEDIA_SET_ID)

				where D.name not in (''''''''tempdb'''''''')
				and  (b.PHYSICAL_DEVICE_NAME not like ''''''''vn%''''''''or  b.PHYSICAL_DEVICE_NAME  is null)
				and  (b.PHYSICAL_DEVICE_NAME not like ''''''''{%''''''''or  b.PHYSICAL_DEVICE_NAME  is null)
		)

SELECT  SERVER_NAME [SERVER],name [DATABASE],BAKUPTYPE=
				CASE WHEN [TYPE]=''''''''D'''''''' THEN ''''''''FULL''''''''  
				WHEN [TYPE]=''''''''I'''''''' THEN ''''''''DIFFERENTIAL'''''''' 
				WHEN [TYPE]=''''''''L'''''''' THEN ''''''''LOG''''''''
				WHEN [TYPE]=''''''''F'''''''' THEN ''''''''FILE / FILEGROUP''''''''
				WHEN [TYPE]=''''''''G''''''''  THEN ''''''''DIFFERENTIAL FILE''''''''
				WHEN [TYPE]=''''''''P'''''''' THEN ''''''''PARTIAL''''''''
				WHEN [TYPE]=''''''''Q'''''''' THEN ''''''''DIFFERENTIAL PARTIAL''''''''
				END,backup_size/1024/1024/1024 [Backup size In GB],BACKUP_DATE [RECENT BACKUP], PHYSICAL_DEVICE_NAME [LOCATION] 
FROM BACKUP_RECENT,BACKUP_ALL 
WHERE BACKUP_RECENT.ID=BACKUP_ALL.ID 
and (backup_size/1024/1024/1024) >10
ORDER BY SERVER_NAME,name,BACKUP_DATE



'''')'')
'
/*
if exists(
select servername,database_name,sum(size_mb),count(database_name) as conut_of_backup --,location
from [dbo].tbl_ALL_DB_full_backup 
group by database_name,servername --,location
having count(database_name)>3
)
*/
--begin
--print @text
insert into tbl_ALL_DB_full_backup
exec (@text)
--end

end try
BEGIN CATCH
--SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @DESC,'Full_BAckup_per_DB_Joe',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

PRINT 'SERVER ['+@SERVERNAME+']is not COMPLETED.'
END CATCH

FETCH NEXT FROM c_F_BAckup_last_Date INTO @SERVERNAME,@DESC
END
CLOSE c_F_BAckup_last_Date
DEALLOCATE c_F_BAckup_last_Date

-- select * from tbl_ALL_DB_full_backup --where sql_version like '0%'

/*
SELECT *
FROM DBADATA.DBO.tbl_ALL_DB_full_backup


*/

/*
----------------------------------------------------
-- May be its time to send the report to my DBA
IF EXISTS(

select 1 from [dbo].tbl_ALL_DB_full_backup 
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


select servername,database_name,count(database_name) as conut_of_backup from [dbo].tbl_ALL_DB_full_backup 
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


insert into DBADATA_Archive.DBO.tbl_ALL_DB_full_backup
select *,getdate() from DBADATA.DBO.tbl_ALL_DB_full_backup

*/

END