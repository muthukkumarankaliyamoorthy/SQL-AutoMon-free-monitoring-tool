USE [DBAdata]
GO

/****** Object:  StoredProcedure [dbo].[Usp_dba_send_logfiles_size]    Script Date: 06/06/2012 06:06:25 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
/*
use [DBAdata]
go
drop table tbl_get_logfiles_size
CREATE TABLE [dbo].[tbl_get_logfiles_size](
	[servername] [sysname] NULL,
	[dbname] [sysname] NOT NULL,
	[filename] [sysname] NOT NULL,
	[recovery_model] [sysname] NOT NULL,
	[log_size] [int] NULL,
	[log_reuse_wait_desc] [sysname] NOT NULL,
	[freespace] [varchar](50) NULL,
	[Drive_letter] [sysname] NULL	
)

use [DBAdata_Archive]
drop table tbl_get_logfiles_size
go
CREATE TABLE [dbo].[tbl_get_logfiles_size](
	[servername] [sysname] NULL,
	[dbname] [sysname] NOT NULL,
	[filename] [sysname] NOT NULL,
	[recovery_model] [sysname] NOT NULL,
	[log_size] [int] NULL,
	[log_reuse_wait_desc] [sysname] NOT NULL,
	[freespace] [varchar](50) NULL,
	[Drive_letter] [sysname] NULL,
	[Upload_date] [datetime] NULL
	
)
*/
use DBAdata
go
--DROP PROC [Usp_dba_send_logfiles_size]
-- Exec DBAdata.[dbo].[Usp_dba_send_logfiles_size] @disk_low_threshold =5000, @Log_growth_threshold =10000 -- alert where log file is larger than disk space
alter PROCEDURE [dbo].[Usp_dba_send_logfiles_size]
/*
Summary:        Send the log file size to DBA Team
Contact:        Muthukkumaran Kaliyamoorthy SQL DBA
Description:	Log file Utilization where @disk_low_threshold low and @Log_growth_threshold is high

ChangeLog:
Date                          Coder                                                    Description
2012-06-04                 Muthukkumaran Kaliyamoorthy               created	Large log file than drive space
 
*******************All the SQL keywords should be written in upper case********************
*/
--WITH ENCRYPTION
(@disk_low_threshold int, @Log_growth_threshold int)
AS
BEGIN
SET nocount ON


-- select * from dbadata.dbo.tbl_get_logfiles_size
Truncate table dbadata.dbo.dba_all_server_space
Truncate table dbadata.dbo.tbl_get_logfiles_size

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
print @server_name+'completed.'


--select * from dbadata.dbo.tbl_get_logfiles_size
INSERT INTO dbadata.dbo.tbl_get_logfiles_size
SELECT @@servername ,Db_name(f.database_id)db,f.name,d.recovery_model_desc ,
f.size / 128.0 as [Log Size (MB)],
d.log_reuse_wait_desc ,ds.freespace,LEFT(f.physical_name,1)

           
      FROM   MASTER.sys.databases d
             JOIN MASTER.sys.master_files f
               ON ( d.database_id = f.database_id )
             JOIN #drive_size AS DS
               ON ( LEFT(F.physical_name,1)=DS.drive )
                        
      WHERE  f.type_desc = 'log'
             
      GROUP  BY Db_name(f.database_id),
                f.name,d.recovery_model_desc,
                d.log_reuse_wait_desc,
                ds.freespace,f.physical_name,f.size / 128.0
                --bs.type,bs.backup_finish_date 
      ORDER  BY f.size / 128.0 desc
 
 declare @spaceinfo table (id int  primary key identity, 
 servername varchar(100),Description varchar(100)) 
 
 insert into @spaceinfo
 select Servername , Description   from dbadata.dbo.dba_all_servers 
 WHERE Version <>'SQL2000' -- and edition  not in ('Express')
 AND svr_status ='running' 
 
 
SELECT @minrow = MIN(id)FROM   @spaceinfo
SELECT @maxrow  = MAX(id) FROM   @spaceinfo
 
 while (@minrow <=@maxrow)
 begin
 begin try
 select @Server_name=Servername ,
 @Desc=Description   from @spaceinfo where ID = @minrow 
 
 exec ('exec ['+@server_name+'].master.dbo.usp_tempspace_pop')
 
----------------------------------------------------------------
--insert the value to table
--select * from dbadata.dbo.tbl_get_logfiles_size where freespace <5000 and log_size >5000
-----------------------------------------------------------------
set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''SELECT '''''''''+@Desc+''''''''',Db_name(f.database_id),
f.name,d.recovery_model_desc ,
f.size / 128.0 as [Log Size (MB)],
d.log_reuse_wait_desc ,ds.space,LEFT(f.physical_name,1)
             
      FROM   MASTER.sys.databases d
             
             JOIN MASTER.sys.master_files f
               ON ( d.database_id = f.database_id )                    
             JOIN master.dbo.tempspace ds
               ON ( LEFT(F.physical_name,1)=DS.drive )
               
      WHERE  f.type_desc = ''''''''log''''''''
             
       GROUP  BY Db_name(f.database_id),
                f.name,d.recovery_model_desc,
                d.log_reuse_wait_desc,
                ds.space,f.physical_name,f.size / 128.0
                ORDER  BY f.size / 128.0 desc '''')'')
      '

 insert into dbadata.dbo.tbl_get_logfiles_size
 exec(@sql)

 --print ' sever'+@server_name+'completed.'
 end try
 BEGIN CATCH
--SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'LOG',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

PRINT 'SERVER ['+@SERVER_NAME+']is not COMPLETED.'
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
      DECLARE @mode varchar(100)
      DECLARE @baktime varchar(100)
      DECLARE @log_size_mb varchar(100)
      DECLARE @log_usedsize varchar(100)
      DECLARE @log_usedsize_per varchar(100)
      DECLARE @log_used_size varchar(100)
      DECLARE @waittype varchar(100)
      DECLARE @drive_size varchar(100)
	  DECLARE @drive_letter varchar(100)
   
--select * from dbadata.dbo.tbl_get_logfiles_size where freespace <5000 and log_size >5000
if exists (select 1 from dbadata.dbo.tbl_get_logfiles_size where freespace <@disk_low_threshold and log_size >@Log_growth_threshold and servername not in ('aaa'))
 
begin

DECLARE SPACECUR CURSOR FOR

SELECT servername,dbname, filename,Drive_letter,
recovery_model,log_size,log_reuse_wait_desc,freespace
FROM tbl_get_logfiles_size
where freespace <@disk_low_threshold and log_size >@Log_growth_threshold
and servername not in ('abcd')

OPEN SPACECUR

FETCH NEXT FROM SPACECUR
INTO @servername,@dbname, @file,@drive_letter,
@mode,@log_size_mb,
@waittype,@drive_size

DECLARE @BODY1 VARCHAR(max)
SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>Log file usage:</b> </font>
<P> 
 <font size=1 color=#FF00FF  face=''verdana''>
<Table border=5 width=1000 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">  
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold"> 
 <td width=600 color=white>SERVER</td> 
 <td width=600 color=white>DB Name</td> 
 <td width=600 color=white>File Name</td> 
 <td width=600 color=white>Drive Letter</td>
 <td width=150 color=white>Mode</td> 
 <td width=150 color=white>Log size MB</td> 
 
 <td width=250 color=white>Wait</td> 
 <td width=150 color=white>DRIVE</td>  
  </b>  

 </tr>'
WHILE @@FETCH_STATUS=0
BEGIN
SET @BODY1= @BODY1 +'<tr>
<td>'+ISNULL(@SERVERNAME,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@dbname,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@file,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@drive_letter,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@mode,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@log_size_mb,'&nbsp')+'</td>'+

'<td align=center>'+ISNULL(@waittype,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@drive_size,'&nbsp')+'</td>'


FETCH NEXT FROM SPACECUR
INTO @servername,@dbname, @file,@drive_letter,
@mode,@log_size_mb,
@waittype,@drive_size

END
SET @BODY1=@BODY1+'</Table> </p>
<p>
<font style="color:#7E2217;font-face:verdana;font-size:9px;"> Generated on '
+convert(varchar(30),getdate(),100)+'. </BR>
This is an auto generated mail by DBA TEAM. If you receive this email by mistake please contact us. 
</br>
© Property of DBA Team.
</font>'

CLOSE SPACECUR
DEALLOCATE SPACECUR

DECLARE @EMAILIDS VARCHAR(500)
SELECT @EMAILIDS=
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS  FROM dbo.DBA_ALL_OPERATORS
WHERE STATUS=1


DECLARE @EMAILIDS1 VARCHAR(500)
--SELECT @EMAILIDS1= 'abcd@xxx.com;xyz@xxx.com'
SELECT @EMAILIDS1= 'dbateam@xxx.com'



EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@SUBJECT = 'DBA: Large log file than drive space',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,

@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';
--select @BODY1

-------------------------------------------------------

end

-- select * from DBAdata_Archive.dbo.tbl_get_logfiles_size
-- select * from DBAdata.dbo.tbl_get_logfiles_size
insert into DBAdata_Archive.dbo.tbl_get_logfiles_size
select *,getdate() from dbadata.dbo.tbl_get_logfiles_size


END


