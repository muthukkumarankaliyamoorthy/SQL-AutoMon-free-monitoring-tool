USE [DBAdata]
GO
/****** Object:  StoredProcedure [dbo].[USP_DBA_No_full_backup]    Script Date: 7/6/2015 3:32:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
-- drop table  tbl_no_full_backup_7days
use dbadata
--drop table tbl_no_full_backup_7days
CREATE TABLE [dbo].[tbl_no_full_backup_7days](
serverName varchar(50),databaseName Varchar(100),type varchar(1),last_backup_date datetime,
DB_Status sql_variant
)

use dbadata_archive
go
--drop table tbl_no_full_backup_7days
CREATE TABLE [dbo].[tbl_no_full_backup_7days](
serverName varchar(50),databaseName Varchar(100),type varchar(1),last_backup_date datetime,
DB_Status sql_variant,upload_date datetime
)


*/

-- SELECT * from DBADATA.DBO.tbl_no_full_backup_7days 

create PROCEDURE [dbo].[USP_DBA_No_full_backup]
/*
Summary:     Find DB with no full backup
Contact:     Muthukkumaran Kaliyamoorthy SQL DBA
Description: Find DB with no full backup last 7 or 10 days

ChangeLog:
Date         Coder							Description
2013-jan-21	 Muthukkumaran Kaliyamoorhty     Updated the 2012 functionality                   


*/
AS BEGIN
--SET NOCOUNT ON
TRUNCATE TABLE DBADATA.DBO.tbl_no_full_backup_7days

DECLARE @SERVERNAME VARCHAR(200)
DECLARE @DESC VARCHAR(200)
DECLARE @text VARCHAR(1000)

-- select * from DBADATA.DBO.DBA_Backup_Non_Location order by backup_date desc
--** PUT LOCAL SERVER FIRST.


insert into  tbl_no_full_backup_7days 

select @@SERVERNAME,d.name,b.type,max(b.backup_finish_date),DATABASEPROPERTYEX(d.name, 'Status') AS DBStatus
from  master.dbo.sysdatabases D left outer join msdb.dbo.backupset b
on d.name = b.database_name
where (b.type ='D' or  b.type is null)
and d.name not in ('ReportServer','ReportServerTempDB','tempdb')
group by d.name,b.type

PRINT @@SERVERNAME +' COMPLETED.'


DECLARE c_F_BAckup_Location CURSOR
FOR
-- select ha FROM DBADATA.DBO.DBA_ALL_SERVERS group by ha
SELECT SERVERNAME,[DESCRIPTION] FROM DBADATA.DBO.DBA_ALL_SERVERS
--where ha  in ('NO HA')
--and [DESCRIPTION] not like '%express%'
where [DESCRIPTION] not in ('SSS')
and svr_status ='running' and Category in ('LIVE','PROD')

OPEN c_F_BAckup_Location
FETCH NEXT FROM c_F_BAckup_Location INTO @SERVERNAME,@DESC

WHILE @@FETCH_STATUS=0  
BEGIN
BEGIN TRY

set @text = 'EXEC(''SELECT * from OPENQUERY(['+@servername+'],
''''
select '''''''''+@Desc+''''''''',d.name,b.type,max(b.backup_finish_date),DATABASEPROPERTYEX(d.name, ''''''''Status'''''''') AS DBStatus
from  master.dbo.sysdatabases D 
left outer join msdb.dbo.backupset b
on d.name = b.database_name
where (b.type =''''''''D'''''''' or  b.type is null)
and d.name not in (''''''''ReportServer'''''''',''''''''ReportServerTempDB'''''''',''''''''tempdb'''''''')
group by d.name,b.type
'''')'')
'

--print @text
insert into tbl_no_full_backup_7days
exec (@text)

end try
BEGIN CATCH
--SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @DESC,'No_full_BAckup',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

PRINT 'SERVER ['+@SERVERNAME+']is not COMPLETED.'
END CATCH

FETCH NEXT FROM c_F_BAckup_Location INTO @SERVERNAME,@DESC
END
CLOSE c_F_BAckup_Location
DEALLOCATE c_F_BAckup_Location

/*
--select * from  DBA_ALL_SERVERS where Description='BLRCCRIP02'

select * from tbl_no_full_backup_7days 
where  Servername not in
(select Description from DBADATA.DBO.DBA_ALL_SERVERS)
*/


----------------------------------------------------
-- May be its time to send the report to my DBA
IF EXISTS(

SELECT 1
FROM DBADATA.DBO.tbl_no_full_backup_7days
where DATEADD(day,0,Last_backup_date) < DATEADD(day,-7,getdate())
and servername not in ('SS','SS')
and databasename not like '%DBAdata%'
and databasename not in('_DB','master','model','msdb')
and DB_Status='ONLINE'


)
BEGIN
DECLARE @SERVER_NAME VARCHAR(100)
DECLARE @database_name VARCHAR(100)
DECLARE @backup_type VARCHAR(10)
DECLARE @CREATE_DATE VARCHAR(50)


begin

/*


declare @day int
select @day=datediff(day, last_backup_date, dateadd(day,0, getdate())) from tbl_no_full_backup_7days

if (@day>7)

SELECT SERVERNAME,databasename,type,last_backup_date,
datediff(day, last_backup_date, dateadd(day,0, getdate())) as no_day,
 DATEADD(day,0,Last_backup_date) , DATEADD(day,-7,getdate())
 FROM DBADATA.DBO.tbl_no_full_backup_7days 
 where last_backup_date is not null
 and servername like '%ip%'
 order by last_backup_date 

 */

 

DECLARE c_Last_Full CURSOR FOR

SELECT SERVERNAME,databasename,case when type ='D' then 'Full' else 'no full'end
,Last_backup_date
FROM DBADATA.DBO.tbl_no_full_backup_7days
where DATEADD(day,0,Last_backup_date) < DATEADD(day,-7,getdate())
and servername not in ('SSS','SSS')
and databasename not like '%DBAdata%'
and databasename not in('_DB','master','model','msdb')
and DB_Status='ONLINE'
order by Last_backup_date

OPEN c_Last_Full

FETCH NEXT FROM c_Last_Full
INTO @SERVER_NAME,@database_name,@backup_type,@CREATE_DATE

DECLARE @BODY1 VARCHAR(max)
--#ECE5B6

SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>Followings are the databases not having full backup for last 10 days:</b> </font>

<P> 
 <font size=1 color=#FF00FF  face=''verdana''>
<Table border=5 width=1000 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">  
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold"> 
 <td width=600 color=white>SERVER NAME</td> 
 <td width=600 color=white>DB Name</td> 
 <td width=100 color=white>Type</td>
 <td width=600 color=white>Last backup date</td>
 </b> 
 </tr>'


WHILE @@FETCH_STATUS=0
BEGIN
SET @BODY1= @BODY1 +'<tr>
<td>'+ISNULL(@SERVER_NAME,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@database_name,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@backup_type,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@CREATE_DATE,'&nbsp')+'</td>'

FETCH NEXT FROM c_Last_Full
INTO @SERVER_NAME,@database_name,@backup_type,@CREATE_DATE

END
SET @BODY1=@BODY1+'</Table> </p>
<p>
<font style="color:#7E2217;font-face:verdana;font-size:9px;"> Generated on '
+convert(varchar(30),getdate(),100)+'. </BR>
This is an auto generated mail by  DBA Team. If you receive this email by mistake please contact us. 
 </br>
© Property of DBA Team.
 </font>'

CLOSE c_Last_Full
DEALLOCATE c_Last_Full
DECLARE @EMAILIDS VARCHAR(500)

SELECT @EMAILIDS=
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS  
FROM DBADATA.dbo.DBA_ALL_OPERATORS WHERE name ='muthu' and STATUS =1



DECLARE @EMAILIDS1 VARCHAR(500)
SELECT @EMAILIDS1=
COALESCE(@EMAILIDS1+';','')+EMAIL_ADDRESS  FROM DBAdata.DBO.DBA_ALL_OPERATORS
WHERE STATUS =1 and Mail_copy='CC'


EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@SUBJECT = 'DBA: No Full backup for last 10 Days',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,
@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';
--select @BODY1
-------------------------------------------------------
END
end

insert into DBADATA_Archive.DBO.tbl_no_full_backup_7days
select *,getdate() from DBADATA.DBO.tbl_no_full_backup_7days
where DATEADD(day,0,Last_backup_date) < DATEADD(day,-7,getdate())


END