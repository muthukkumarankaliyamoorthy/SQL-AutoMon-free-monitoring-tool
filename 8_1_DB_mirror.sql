/*
use DBAdata
go
drop table [tbl_DB_mirroring_status]
CREATE TABLE [dbo].[tbl_DB_mirroring_status](
	[name] [sysname] NOT NULL,
	[principal_server_name] [nvarchar](128) NULL,
	[mirroring_role_desc] [nvarchar](60) NULL,
	[mirroring_partner_name] [nvarchar](128) NULL,
	[mirroring_witness_name] [nvarchar](128) NULL,
	[mirroring_state_desc] [nvarchar](60) NULL,
	[mirroring_witness_state_desc] [nvarchar](60) NULL,
	[upload_date] [datetime] NOT NULL
) 

use DBAdata_archive
go
drop table [tbl_DB_mirroring_status]
CREATE TABLE [dbo].[tbl_DB_mirroring_status](
	[name] [sysname] NOT NULL,
	[principal_server_name] [nvarchar](128) NULL,
	[mirroring_role_desc] [nvarchar](60) NULL,
	[mirroring_partner_name] [nvarchar](128) NULL,
	[mirroring_witness_name] [nvarchar](128) NULL,
	[mirroring_state_desc] [nvarchar](60) NULL,
	[mirroring_witness_state_desc] [nvarchar](60) NULL,
	[upload_date] [datetime] NOT NULL
)

*/ 
use DBAdata
go
-- DROP PROC [Usp_DB_Mirror_Monitoring]
alter proc [dbo].Usp_DB_Mirror_Monitoring
/*
Summary:     DB mirroring status
Contact:     Muthukkumaran Kaliyamoorthy SQL DBA
Description: DB mirroring status alert


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

TRUNCATE TABLE tbl_DB_mirroring_status


declare @DB_mirror table (id int  primary key identity, 
servername varchar(100),Description varchar(100)) 
 
insert into @DB_mirror
select Servername , Description  from dbadata.dbo.dba_all_servers 
--WHERE ha like'DB_mirror'
where Version not in ('sql2000')
and SVR_status ='running'

 --select *  from dbadata.dbo.dba_all_servers
SELECT @minrow = MIN(id)FROM   @DB_mirror
SELECT @maxrow  = MAX(id) FROM   @DB_mirror
 
 while (@minrow <=@maxrow)
 begin
 BEGIN TRY
 
 select @Server_name=Servername ,
 @Desc=Description   from @DB_mirror where ID = @minrow 

set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''SELECT a.name,@@servername as principal_server_name,b.mirroring_role_desc,
b.mirroring_partner_name,b.mirroring_witness_name,b.mirroring_state_desc,b.mirroring_witness_state_desc, getdate() as upload_date
FROM
sys.databases A
INNER JOIN sys.database_mirroring B
ON A.database_id=B.database_id
WHERE a.database_id > 4
--and mirroring_state_desc not like ''''''''SY%''''''''
ORDER BY A.NAME
'''')'')
'
insert into dbadata.dbo.tbl_DB_mirroring_status
exec(@sql)
--SELECT @sql
end try
BEGIN CATCH
SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'DB_mirror',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()


END CATCH
 
set @minrow =@minrow +1 
end

----------------------------------------------------------------
--Send an email to DBA team
-----------------------------------------------------------------
      
      DECLARE @principal_server_name varchar(100)
	  DECLARE @DBname varchar(100)
      DECLARE @mirroring_state_desc varchar(100)
	  DECLARE @mirroring_witness_state_descs varchar(100)
      DECLARE @Role varchar(100)
     
      
 
--SELECT * FROM dbadata.dbo.tbl_alwayson_monitoring
IF EXISTS (
SELECT 1 FROM dbadata.dbo.tbl_DB_mirroring_status
where mirroring_state_desc not like 'SY%'
) 
begin

DECLARE DBmirror_CuR CURSOR FOR

-- select * FROM dbadata.dbo.tbl_DB_mirroring_status 
SELECT principal_server_name,name,mirroring_state_desc,mirroring_witness_state_desc
FROM dbadata.dbo.tbl_DB_mirroring_status 
where mirroring_state_desc not like 'SY%'

OPEN DBmirror_CuR
FETCH NEXT FROM DBmirror_CuR
INTO @principal_server_name,@DBname,@mirroring_state_desc, @mirroring_witness_state_descs

DECLARE @BODY1 VARCHAR(max)
SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>Followings are Database Mirroring Status:</b> </font>
<P> 
<font size=1 color=#FF00FF  face=''verdana''>
<Table border=5 width=1000 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">  
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold"> 
 <td width=600 color=white>Principal Server</td>
 <td width=600 color=white>DB Name</td> 
 <td width=600 color=white>Mirroring State</td> 
 <td width=600 color=white>Mirroring witness State</td> 
 </b>  

 </tr>'
WHILE @@FETCH_STATUS=0
BEGIN
SET @BODY1= @BODY1 +'<tr>
<td>'+ISNULL(@principal_server_name,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@DBname,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@mirroring_state_desc,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@mirroring_witness_state_descs,'&nbsp')+'</td>'

FETCH NEXT FROM DBmirror_CuR
INTO @principal_server_name,@DBname,@mirroring_state_desc, @mirroring_witness_state_descs

END
SET @BODY1=@BODY1+'</Table> </p>
<p>
<font style="color:#7E2217;font-face:verdana;font-size:9px;"> Generated on '
+convert(varchar(30),getdate(),100)+'. </BR>
This is an auto generated mail by DBA Team. If you receive this email by mistake please contact us. 
 </br>
© Property of DBA Team.
 </font>'

CLOSE DBmirror_CuR
DEALLOCATE DBmirror_CuR
DECLARE @EMAILIDS VARCHAR(500)

SELECT @EMAILIDS=
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS 
FROM DBADATA.dbo.DBA_ALL_OPERATORS WHERE name ='muthu' and STATUS =1

DECLARE @EMAILIDS1 VARCHAR(500)

--SELECT @EMAILIDS1= 'dba@abcd.com'


EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@SUBJECT = 'DBA: Database Mirroring Status',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,
@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';
--select @BODY1

-------------------------------------------------------

end  

insert into DBAdata_Archive.dbo.[tbl_DB_mirroring_status]
select * from DBAdata.dbo.[tbl_DB_mirroring_status]

END


--select * from DBAdata_Archive.dbo.tbl_alwayson_monitoring