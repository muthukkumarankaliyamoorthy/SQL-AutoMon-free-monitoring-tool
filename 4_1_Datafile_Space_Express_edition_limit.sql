
/*

use [DBAdata]
drop table tbl_get_datafiles_size_express_edition
--select * from tbl_get_datafiles_size_express_edition
CREATE TABLE [dbo].[tbl_get_datafiles_size_express_edition](
	[ServerNAME] [varchar](max) NULL,
	[DBNAME] [nvarchar](128) NULL,
	[FILENAME] [sysname] NOT NULL,
	[CURRENTSIZE_MB] [numeric](17, 6) NULL,
	[USEDSPACE_MB] [numeric](19, 6) NULL,
	[FREESPACEMB] [numeric](18, 6) NULL,
	[PHYSICAL_NAME] [nvarchar](260) NOT NULL,
	[RECOVERY_MODEL] [sql_variant] NULL,
	[TYPE_DESC] [nvarchar](200) NULL,
	[AUTO_GROW] [varchar](200) NULL,
	[Edition] varchar (200)
)

use [DBAdata_Archive]
drop table tbl_get_datafiles_size_express_edition
CREATE TABLE [dbo].[tbl_get_datafiles_size_express_edition](
	[ServerNAME] [varchar](max) NULL,
	[DBNAME] [nvarchar](128) NULL,
	[FILENAME] [sysname] NOT NULL,
	[CURRENTSIZE_MB] [numeric](17, 6) NULL,
	[USEDSPACE_MB] [numeric](19, 6) NULL,
	[FREESPACEMB] [numeric](18, 6) NULL,
	[PHYSICAL_NAME] [nvarchar](260) NOT NULL,
	[RECOVERY_MODEL] [sql_variant] NULL,
	[TYPE_DESC] [nvarchar](200) NULL,
	[AUTO_GROW] [varchar](200) NULL,
	[Edition] varchar (200),
	upload_date datetime default (getdate())
)

*/
-- select * from tbl_get_datafiles_size_express_edition
use [DBAdata]
go

alter PROCEDURE [dbo].[Usp_dba_send_DATAfiles_size_Express_limit_check]
/*
Summary:     Data file Utilization findings for express edition 10 gb limit
Contact:     Muthukkumaran Kaliyamoorhty SQL DBA
Description: Data file Utilization findings

ChangeLog:
Date         Coder							Description
2013-jan-21	 Muthukkumaran Kaliyamoorhty     Updated the 2012 functionality                   
2015-mar-30	 Muthukkumaran Kaliyamoorhty     Removed the  free space condition to upload all data files


*/
--WITH ENCRYPTION
AS
BEGIN
SET nocount ON

--inserting the drive space
--Truncate table dbadata.dbo.dba_all_server_space
Truncate table dbadata.dbo.tbl_get_datafiles_size_express_edition

--Create table #drive_size (drive char(1),freespace int)

      DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @sql varchar(8000)
      DECLARE @minrow int
      DECLARE @maxrow int

---------------------------------------------------
--Put the local server first
---------------------------------------------------
      
 
 declare @spaceinfo_express table (id int  primary key identity, 
 servername varchar(100),Description varchar(100)) 
 
 insert into @spaceinfo_express
 select Servername , Description   from dbadata.dbo.dba_all_servers 
 WHERE Version <>'SQL2000'  and edition   like'%Express%'
 AND svr_status ='running'-- 
 

 --select *  from dbadata.dbo.dba_all_servers
SELECT @minrow = MIN(id)FROM   @spaceinfo_express
SELECT @maxrow  = MAX(id) FROM   @spaceinfo_express
 
 while (@minrow <=@maxrow)
 begin
 BEGIN TRY
 select @Server_name=Servername ,
 @Desc=Description   from @spaceinfo_express where ID = @minrow 
 
  exec ('exec ['+@server_name+'].master.dbo.Usp_dba_send_DATAfiles_size_Express_limit_check_Target')
 
----------------------------------------------------------------
--insert the value to table
-----------------------------------------------------------------
set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''SELECT '''''''''+@Desc+''''''''',* from master.dbo.tbl_datafile_free_used_size_mb '''')'')
      '
 
insert into dbadata.dbo.tbl_get_datafiles_size_express_edition
exec(@sql)
--print @sql

end try
BEGIN CATCH
SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'DATAFILE_express',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

--PRINT 'SERVER ['+@SERVER_NAME+']is not COMPLETED.'
END CATCH
 
set @minrow =@minrow +1 
 end
 
--/*
  
----------------------------------------------------------------
--Send an email to DBA team
-----------------------------------------------------------------
      DECLARE @minid INT
      DECLARE @maxid INT
      DECLARE @servername varchar(100)
      DECLARE @dbname varchar(100)
      DECLARE @file varchar(100)
      DECLARE @Drive_letter  varchar(1)
	  DECLARE @Edition  varchar(100)
      DECLARE @CURRENTSIZE_MB varchar(100)         
      DECLARE @USEDSPACE_MB varchar(100)
	  DECLARE @FREESPACEMB varchar(100)
	  
-- select * from dbadata.dbo.tbl_get_datafiles_size_express_edition 
if exists (

select 1 from dbadata.dbo.tbl_get_datafiles_size_express_edition where CURRENTSIZE_MB >8000

)

begin

DECLARE DBfile_CUR CURSOR FOR

SELECT ServerNAME,DBNAME,FILENAME,CURRENTSIZE_MB,USEDSPACE_MB,FREESPACEMB,left(PHYSICAL_NAME,1) as Drive,Edition
FROM tbl_get_datafiles_size_express_edition 
where CURRENTSIZE_MB >8000
order by CURRENTSIZE_MB

OPEN DBfile_CUR

FETCH NEXT FROM DBfile_CUR
INTO @servername,@dbname, @file,@CURRENTSIZE_MB,@USEDSPACE_MB,@FREESPACEMB,@Drive_letter,@edition


DECLARE @BODY1 VARCHAR(max)
SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>Data files usage Express Edition 10GB limit:</b> </font>
<P> 
 <font size=1 color=#FF00FF  face=''verdana''>
<Table border=5 width=1000 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">  
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold"> 
 <td width=900 color=white>SERVER</td> 
 <td width=600 color=white>DB Name</td> 
 <td width=600 color=white>File Name</td>
 <td width=600 color=white>Size MB</td>
 <td width=600 color=white>Used MB</td>
 <td width=600 color=white>Free MB</td>   
   <td width=600 color=white>DRIVE</td>  
   <td width=900 color=white>Edition</td> 
  </b>  

 </tr>'
WHILE @@FETCH_STATUS=0
BEGIN
SET @BODY1= @BODY1 +'<tr>
<td>'+ISNULL(@SERVERNAME,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@dbname,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@file,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@CURRENTSIZE_MB,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@USEDSPACE_MB,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@FREESPACEMB,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@Drive_letter,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@Edition,'&nbsp')+'</td>'

FETCH NEXT FROM DBfile_CUR
INTO @servername,@dbname, @file,@CURRENTSIZE_MB,@USEDSPACE_MB,@FREESPACEMB,@Drive_letter,@edition

END
SET @BODY1=@BODY1+'</Table> </p>
<p>
<font style="color:#7E2217;font-face:verdana;font-size:9px;"> Generated on '
+convert(varchar(30),getdate(),100)+'. </BR>
This is an auto generated mail by DBA team. If you receive this email by mistake please contact us. 
 </br>
© Property of DBA Team.
 </font>'

CLOSE DBfile_CUR
DEALLOCATE DBfile_CUR
DECLARE @EMAILIDS VARCHAR(500)

SELECT @EMAILIDS=
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS  FROM dbo.DBA_ALL_OPERATORS
WHERE STATUS=1


 DECLARE @EMAILIDS1 VARCHAR(500)
SELECT @EMAILIDS1= 'dbateam@xxx.com'


EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@SUBJECT = 'DBA: DATA FILES SPACE INFO - Express Limit 10GB',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,
@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';
--select @BODY1

-------------------------------------------------------

end
insert into DBAdata_Archive.dbo.tbl_get_datafiles_size_express_edition
select *,GETDATE() from tbl_get_datafiles_size_express_edition
--*/
END



