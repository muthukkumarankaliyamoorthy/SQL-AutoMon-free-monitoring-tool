/*
--drop table tbl_alwayson_Quorum

select * from tbl_alwayson_Quorum

use dbadata
go
--drop table tbl_alwayson_Quorum
go

CREATE TABLE [dbo].[tbl_alwayson_Quorum](
	[server_name] [nvarchar](256) NOT NULL,
	[Member_name] [nvarchar](256) NOT NULL,
	[Status] [varchar](10) NOT NULL,
	[Vote] [int] NULL,
	[Upload_date] [datetime] NULL
)

use DBAdata_Archive
go
--drop table tbl_alwayson_Quorum
go
CREATE TABLE [dbo].[tbl_alwayson_Quorum](
	[server_name] [nvarchar](256) NOT NULL,
	[Member_name] [nvarchar](256) NOT NULL,
	[Status] [varchar](10) NOT NULL,
	[Vote] [int] NULL,
	[Upload_date] [datetime] NULL
)

*/


use dbadata
go
--DROP PROC [dbo].[Usp_Alwayson_Quorum]
create proc [dbo].[Usp_Alwayson_Quorum]
/*
Summary:     Alwayson Quorum status
Contact:     Muthukkumaran Kaliyamoorthy SQL DBA
Description: Alwayson Quorum status alert


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

TRUNCATE TABLE tbl_alwayson_Quorum


declare @Quorum table (id int  primary key identity, 
servername varchar(100),Description varchar(100)) 
 
insert into @Quorum

select Servername , Description   from dbadata.dbo.dba_all_servers 
WHERE ha ='alwayson' and
  Version  not in('sql2000','sql2005','sql2008','sql2008r2')
 and SVR_status='running'

 --select *  from dbadata.dbo.dba_all_servers
SELECT @minrow = MIN(id)FROM   @Quorum
SELECT @maxrow  = MAX(id) FROM   @Quorum
 
 while (@minrow <=@maxrow)
 begin
 BEGIN TRY
 
 select @Server_name=Servername ,
 @Desc=Description   from @Quorum where ID = @minrow 

 -- select * from sys.dm_hadr_cluster_members

set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''select @@servername,member_name,member_state_desc,number_of_quorum_votes,getdate()  from sys.dm_hadr_cluster_members
--where member_state_desc <>''''''''up''''''''
'''')'')
'
insert into dbadata.dbo.tbl_alwayson_Quorum
exec(@sql)
--SELECT @sql
end try
BEGIN CATCH
SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'AlwaysON_Quorum',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()


END CATCH
 
set @minrow =@minrow +1 
end

--/*
----------------------------------------------------------------
--Send an email to DBA team
-----------------------------------------------------------------
      
      DECLARE @servername varchar(100)
	  DECLARE @Member varchar(100)
      DECLARE @health_Status varchar(100)
      DECLARE @vote varchar(100)
     
      
      
--SELECT * FROM dbadata.dbo.tbl_alwayson_Quorum
IF EXISTS (
SELECT 1 FROM dbadata.dbo.tbl_alwayson_Quorum
where Status <>'up'
) 
begin

DECLARE HADR_CuR_Quorum CURSOR FOR

select server_name,Member_name,Status ,vote  from tbl_alwayson_Quorum
where Status <>'up'


OPEN HADR_CuR_Quorum
FETCH NEXT FROM HADR_CuR_Quorum
INTO @servername,@Member,@health_Status, @vote

DECLARE @BODY1 VARCHAR(max)
SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>Followings are AlwaysON Quorum Status:</b> </font>
<P> 
<font size=1 color=#FF00FF  face=''verdana''>
<Table border=5 width=1000 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">  
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold"> 
 <td width=600 color=white>Server Name</td>
 <td width=600 color=white>Member Name</td>
 <td width=600 color=white>Health State</td> 
 <td width=600 color=white>Vote</td> 
 </b>  

 </tr>'
WHILE @@FETCH_STATUS=0
BEGIN
SET @BODY1= @BODY1 +'<tr>
<td>'+ISNULL(@servername,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@Member,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@health_Status,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@vote,'&nbsp')+'</td>'

FETCH NEXT FROM HADR_CuR_Quorum
INTO @servername,@Member,@health_Status, @vote

END
SET @BODY1=@BODY1+'</Table> </p>
<p>
<font style="color:#7E2217;font-face:verdana;font-size:9px;"> Generated on '
+convert(varchar(30),getdate(),100)+'. </BR>
This is an auto generated mail by DBA. If you receive this email by mistake please contact us. 
 </br>
© Property of DBA Team.
 </font>'

CLOSE HADR_CuR_Quorum
DEALLOCATE HADR_CuR_Quorum
DECLARE @EMAILIDS VARCHAR(500)

SELECT @EMAILIDS=
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS 
FROM DBADATA.dbo.DBA_ALL_OPERATORS WHERE name ='muthu' and STATUS =1


DECLARE @EMAILIDS1 VARCHAR(500)
SELECT @EMAILIDS1=
COALESCE(@EMAILIDS1+';','')+EMAIL_ADDRESS  FROM DBAdata.DBO.DBA_ALL_OPERATORS
WHERE STATUS =1 and Mail_copy='CC'


EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@SUBJECT = 'DBA: AlwaysON Quorum Status ',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,
@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';
--select @BODY1
-------------------------------------------------------

end  

insert into DBAdata_Archive.dbo.tbl_alwayson_Quorum
select * from tbl_alwayson_Quorum
--*/

END


