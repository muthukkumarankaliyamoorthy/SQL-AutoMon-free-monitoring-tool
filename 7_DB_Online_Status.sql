/*

use DBAdata
go

--drop table [tbl_database_online_status]
CREATE TABLE [dbo].[tbl_database_online_status](
	[servername] [nvarchar](128) NULL,
	[dbname] [sysname] NOT NULL,
	[state_desc] [nvarchar](60) NULL,
	[upload_date] [datetime] NOT NULL
)
--select * from tbl_database_online_status

use DBAdata_archive
go

--drop table [tbl_database_online_status]
CREATE TABLE [dbo].[tbl_database_online_status](
	[servername] [nvarchar](128) NULL,
	[dbname] [sysname] NOT NULL,
	[state_desc] [nvarchar](60) NULL,
	[upload_date] [datetime] NOT NULL
)

*/ 
use DBAdata
go

-- select * from tbl_database_online_status
-- DROP PROC [Usp_DB_Online_status]
create proc [dbo].Usp_DB_Online_status
/*
Summary:     DB onile status
Contact:     Muthukkumaran Kaliyamoorthy SQL DBA
Description: DB onile status alert


ChangeLog:
Date         Coder							Description
2013-jan-21	 Muthukkumaran Kaliyamoorthy     Updated the 2012 functionality                   


*/
--with Encryption
as
begin

	  DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @sql varchar(8000)
      DECLARE @minrow int
      DECLARE @maxrow int

TRUNCATE TABLE tbl_database_online_status


declare @DB_online table (id int  primary key identity, 
servername varchar(100),Description varchar(100)) 
 
insert into @DB_online

select Servername , Description  from dbadata.dbo.dba_all_servers 
--WHERE ha like'DB_mirror'
where Version not in ('sql2000')
and SVR_status='running'

 --select *  from dbadata.dbo.dba_all_servers
SELECT @minrow = MIN(id)FROM   @DB_online
SELECT @maxrow  = MAX(id) FROM   @DB_online
 
 while (@minrow <=@maxrow)
 begin
 BEGIN TRY
 
 select @Server_name=Servername ,
 @Desc=Description   from @DB_online where ID = @minrow 

set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''SELECT @@servername as servername, name as dbname,state_desc, getdate() as upload_date  
FROM sys.databases where state_desc not in (''''''''online'''''''',''''''''RESTORING'''''''')
'''')'')
'
insert into dbadata.dbo.tbl_database_online_status
exec(@sql)
--SELECT @sql
end try
BEGIN CATCH
SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'DB_online',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()


END CATCH
 
set @minrow =@minrow +1 
end


----------------------------------------------------------------
--Send an email to DBA team
-----------------------------------------------------------------
      
      DECLARE @servername varchar(100)
	  DECLARE @DBname varchar(100)
      DECLARE @state_desc varchar(100)
	  
     
      
 
--SELECT * FROM dbadata.dbo.tbl_alwayson_monitoring
IF EXISTS (
SELECT 1 FROM dbadata.dbo.tbl_database_online_status
where state_desc  not in ('online','RESTORING','offline')
and dbname not in('xxx-OLD')
and (servername  not in('server\DEV'))


) 
begin

DECLARE DBoline_CuR CURSOR FOR

-- select * FROM dbadata.dbo.tbl_database_online_status 
SELECT servername,dbname,state_desc
FROM dbadata.dbo.tbl_database_online_status 
where state_desc  not in ('online','RESTORING','offline')
and dbname not in('xxx-OLD')
and (servername  not in('server\DEV'))

OPEN DBoline_CuR
FETCH NEXT FROM DBoline_CuR
INTO @servername,@DBname,@state_desc

DECLARE @BODY1 VARCHAR(max)
SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>Followings are Database Status:</b> </font>
<P> 
<font size=1 color=#FF00FF  face=''verdana''>
<Table border=5 width=1000 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">  
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold"> 
 <td width=600 color=white>Server Name</td>
 <td width=600 color=white>DB Name</td> 
  <td width=600 color=white>DB Status</td> 
 </b>  

 </tr>'
WHILE @@FETCH_STATUS=0
BEGIN
SET @BODY1= @BODY1 +'<tr>
<td>'+ISNULL(@servername,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@DBname,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@state_desc,'&nbsp')+'</td>'

FETCH NEXT FROM DBoline_CuR
INTO @servername,@DBname,@state_desc

END
SET @BODY1=@BODY1+'</Table> </p>
<p>
<font style="color:#7E2217;font-face:verdana;font-size:9px;"> Generated on '
+convert(varchar(30),getdate(),100)+'. </BR>
This is an auto generated mail by DBA Team. If you receive this email by mistake please contact us. 
 </br>
© Property of DBA Team.
 </font>'

CLOSE DBoline_CuR
DEALLOCATE DBoline_CuR
DECLARE @EMAILIDS VARCHAR(500)

SELECT @EMAILIDS=
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS 
FROM DBADATA.dbo.DBA_ALL_OPERATORS WHERE name ='muthu' and STATUS =1

DECLARE @EMAILIDS1 VARCHAR(500)
--SELECT @EMAILIDS1= 'dba@abcd.com'


EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@SUBJECT = 'DBA: Database Status',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,
@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';
--select @BODY1

-------------------------------------------------------

end  

insert into DBAdata_Archive.dbo.tbl_database_online_status
select * from DBAdata.dbo.tbl_database_online_status

END

-- Usp_DB_Online_status
