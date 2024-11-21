
/*

use [DBAdata]
--drop table tbl_get_datafiles_size
--select * from tbl_get_datafiles_size
CREATE TABLE [dbo].[tbl_get_datafiles_size](
	[servername] [sysname] NULL,
	[dbname] [sysname] NOT NULL,
	[filename] [sysname] NOT NULL,
	[data_size] [int] NULL,
	[freespace] [varchar](50) NULL,
	[Drive_letter] [sysname] NULL,
	
)
go
use [DBAdata_Archive]
--drop table tbl_get_datafiles_size
CREATE TABLE [dbo].[tbl_get_datafiles_size](
	[servername] [sysname] NULL,
	[dbname] [sysname] NOT NULL,
	[filename] [sysname] NOT NULL,
	[data_size] [int] NULL,
	[freespace] [varchar](50) NULL,
	[Drive_letter] [sysname] NULL,
	[Upload_date] datetime
	
)

*/
-- select * from tbl_get_datafiles_size
use [DBAdata]
go
-- Exec [DBAdata].[dbo].[Usp_dba_send_DATAfiles_size] @disk_free_threshold = 5000 -- alert less than 5 gb drive free
--DROP PROC [Usp_dba_send_DATAfiles_size]
create PROCEDURE [dbo].[Usp_dba_send_DATAfiles_size]
/*
Summary:     Data file Utilization findings
Contact:     Muthukkumaran Kaliyamoorhty SQL DBA
Description: Data file Utilization where freespace <5000 in the drive

ChangeLog:
Date         Coder							Description
2013-jan-21	 Muthukkumaran Kaliyamoorhty     Updated the 2012 functionality                   
2015-mar-30	 Muthukkumaran Kaliyamoorhty     Removed the  free space condition to upload all data files


*/
--WITH ENCRYPTION
(@disk_free_threshold int)
AS
BEGIN
SET nocount ON

-- select * from dbadata.dbo.tbl_get_datafiles_size
Truncate table dbadata.dbo.dba_all_server_space
Truncate table dbadata.dbo.tbl_get_datafiles_size

Create table #drive_size (drive char(1),freespace int)

      DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @sql varchar(8000)
      DECLARE @minrow int
      DECLARE @maxrow int

---------------------------------------------------
--Put the local server first
---------------------------------------------------
      
 INSERT INTO #drive_size
 EXEC MASTER..Xp_fixeddrives
 
INSERT INTO dbadata.dbo.dba_all_server_space
select *,@@servername as servernamae from #drive_size
--print @server_name+'completed.'


--select * from dbadata.dbo.tbl_get_logfiles_size
INSERT INTO dbadata.dbo.tbl_get_datafiles_size

SELECT @@servername ,Db_name(f.database_id)db,f.name,
f.size/128 as [Data Size (MB)],ds.freespace,LEFT(f.physical_name,1)

           
      FROM   MASTER.sys.databases d
               JOIN MASTER.sys.master_files f
               ON ( d.database_id = f.database_id )
             JOIN #drive_size AS DS
               ON ( LEFT(F.physical_name,1)=DS.drive )
            
            
      WHERE   f.type_desc = 'rows'
             

      GROUP  BY Db_name(f.database_id),
                f.name,f.size/128,
               ds.freespace,f.physical_name
                
      ORDER  BY f.size/128 desc
 
 declare @spaceinfo table (id int  primary key identity, 
 servername varchar(100),Description varchar(100)) 
 
 insert into @spaceinfo
 select Servername , Description   from dbadata.dbo.dba_all_servers 
 WHERE Version <>'SQL2000' -- and edition  not in ('Express')
 AND svr_status ='running'

 --select *  from dbadata.dbo.dba_all_servers
SELECT @minrow = MIN(id)FROM   @spaceinfo
SELECT @maxrow  = MAX(id) FROM   @spaceinfo
 
 while (@minrow <=@maxrow)
 begin
 BEGIN TRY
 select @Server_name=Servername ,
 @Desc=Description   from @spaceinfo where ID = @minrow 
 
 exec ('exec ['+@server_name+'].master.dbo.usp_tempspace_pop')
 
----------------------------------------------------------------
--insert the value to table
-----------------------------------------------------------------
set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''SELECT '''''''''+@Desc+''''''''',Db_name(f.database_id),
f.name,f.size/128 as [data_size],ds.space,LEFT(f.physical_name,1)            
      FROM   MASTER.sys.databases d
               JOIN MASTER.sys.master_files f
               ON ( d.database_id = f.database_id )                    
             JOIN master.dbo.tempspace ds
               ON ( LEFT(F.physical_name,1)=DS.drive )
               
      WHERE  f.type_desc = ''''''''rows''''''''
       
       GROUP  BY Db_name(f.database_id),
                f.name,f.size/128,
                ds.space,f.physical_name               
      ORDER  BY f.size/128 '''')'')
      '
 
 insert into dbadata.dbo.tbl_get_datafiles_size
 exec(@sql)
end try
BEGIN CATCH
SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'DATAFILE',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

--PRINT 'SERVER ['+@SERVER_NAME+']is not COMPLETED.'
END CATCH
 
set @minrow =@minrow +1 
 end
 
 
  
----------------------------------------------------------------
--Send an email to DBA team
-----------------------------------------------------------------
      DECLARE @minid INT
      DECLARE @maxid INT
      DECLARE @servername varchar(100)
      DECLARE @dbname varchar(100)
      DECLARE @file varchar(100)
      DECLARE @Drive_letter  varchar(1)
      DECLARE @Data_size_mb varchar(100)         
      DECLARE @drive_size varchar(100)
-- select * from dbadata.dbo.tbl_get_datafiles_size 
if exists (

select 1 from dbadata.dbo.tbl_get_datafiles_size where freespace <@disk_free_threshold
and servername not in ('aa','bb','cc')
)

begin

DECLARE DBfile_CUR CURSOR FOR

SELECT servername,dbname, filename,Drive_letter,
data_size,freespace
FROM tbl_get_datafiles_size 
where freespace <@disk_free_threshold
and servername not in ('aa','bb','cc')
order by freespace

OPEN DBfile_CUR

FETCH NEXT FROM DBfile_CUR
INTO @servername,@dbname, @file,@Drive_letter,
@Data_size_mb,@drive_size

DECLARE @BODY1 VARCHAR(max)
SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>Data files usage:</b> </font>
<P> 
 <font size=1 color=#FF00FF  face=''verdana''>
<Table border=5 width=1000 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">  
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold"> 
 <td width=600 color=white>SERVER</td> 
 <td width=600 color=white>DB Name</td> 
 <td width=600 color=white>File Name</td>
 <td width=600 color=white>Drive Letter</td>
  <td width=600 color=white>Data file MB</td> 
   <td width=600 color=white>DRIVE MB</td>  
  </b>  

 </tr>'
WHILE @@FETCH_STATUS=0
BEGIN
SET @BODY1= @BODY1 +'<tr>
<td>'+ISNULL(@SERVERNAME,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@dbname,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@file,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@Drive_letter,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@Data_size_mb,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@drive_size,'&nbsp')+'</td>'


FETCH NEXT FROM DBfile_CUR
INTO @servername,@dbname, @file,@Drive_letter,
@Data_size_mb,@drive_size

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
--SELECT @EMAILIDS1= 'abc@xxx.com;xyz@xxx.com'
SELECT @EMAILIDS1= 'dbateam@xxx.com'



EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@SUBJECT = 'DBA: DATA FILES SPACE INFO',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,

@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';
--select @BODY1

-------------------------------------------------------

end
insert into DBAdata_Archive.dbo.tbl_get_datafiles_size
select *,GETDATE() from tbl_get_datafiles_size

END



