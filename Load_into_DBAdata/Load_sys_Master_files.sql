USE [DBAdata]

GO
/*
drop table [tbl_sys_master_files]

CREATE TABLE [dbo].[tbl_sys_master_files](
	servername varchar(300),
	[DBname] [nvarchar](128) NULL,
	[DBfile] [sysname] NOT NULL,
	[CurrentSizeMB] [numeric](17, 6) NULL,
	[recovery_model_desc] [nvarchar](60) NULL,
	[type_desc] [nvarchar](60) NULL,
	[Autogrow] [varchar](77) NULL
) 


select * from tbl_sys_master_files where autogrow like '0.0%' -- show the auto growth disabled


-- drop table tbl_sys_master_files_staging
select * into tbl_sys_master_files_staging from tbl_sys_master_files -- load on staging
-- delete the known data

select type_desc,count(*)  from tbl_sys_master_files_staging group by type_desc

select *  from tbl_sys_master_files_staging where type_desc ='FILESTREAM' order by autogrow  --FILESTREAM
select *  from tbl_sys_master_files_staging where type_desc ='FULLTEXT' order by autogrow  --FULLTEXT

select *  from tbl_sys_master_files_staging where type_desc ='ROWS' order by autogrow   --ROWS
select *  from tbl_sys_master_files_staging where type_desc ='ROWS' and autogrow like '%Limited growth to%' order by autogrow 

select *  from tbl_sys_master_files_staging where type_desc ='LOG' order by autogrow  --LOG
select *  from tbl_sys_master_files_staging where type_desc ='LOG' and autogrow not like '%Limited growth to 2097152.0 MB%' order by autogrow 

-- drop table tbl_sys_master_files_staging_log

select * into tbl_sys_master_files_staging_log from tbl_sys_master_files_staging where type_desc ='LOG' and autogrow not like '%Limited growth to 2097152.0 MB%' order by autogrow 
select * from tbl_sys_master_files_staging_log where autogrow ='By 10 percent, Unlimited growth'
delete from tbl_sys_master_files_staging_log where autogrow ='By 10 percent, Unlimited growth'

select * from tbl_sys_master_files_staging_log order by autogrow  --LOG
select *  from tbl_sys_master_files_staging_log where type_desc ='LOG' and autogrow like '%Limited growth to%' order by autogrow 


*/
use DBAdata
go
-- select count(*)as database_count from master.dbo.sysdatabases where dbid not in (1,2,3,4)

alter PROCEDURE [dbo].[Usp_load_sys_Master_files]
/*
Summary:        [Usp_load_sys_Master_files]
Contact:        Muthukkumaran Kaliyamoorhty SQL DBA

ChangeLog:
Date                          Coder                                                    Description
2012-06-04                 Muthukkumaran Kaliyamoorhty               created
 
*******************All the SQL keywords should be written in upper case********************
*/
WITH ENCRYPTION
AS
BEGIN
SET nocount ON

--inserting the drive space
Truncate table dbadata.dbo.[tbl_sys_master_files]


      DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @sql varchar(8000)
      DECLARE @minrow int
      DECLARE @maxrow int

---------------------------------------------------
--Put the local server first
---------------------------------------------------
 --insert into tbl_sys_master_files


 declare @Load_db_count table (id int  primary key identity, 
 servername varchar(100),Description varchar(100)) 
 
 insert into @Load_db_count
 select Servername , Description   from dbadata.dbo.dba_all_servers 
 where svr_status ='running' 
 
 
SELECT @minrow = MIN(id)FROM   @Load_db_count
SELECT @maxrow  = MAX(id) FROM   @Load_db_count
 
 while (@minrow <=@maxrow)
 begin
 begin try
 select @Server_name=Servername ,
 @Desc=Description   from @Load_db_count where ID = @minrow 
 
 ----------------------------------------------------------------
--insert the value to table
--select * from dbadata.dbo.tbl_get_logfiles_size where freespace <5000 and log_size >5000
-----------------------------------------------------------------
/*
set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''SELECT @@servername as server_name, count(*) as DB_count  from master..sysdatabases 
where dbid not in (1,2,3,4) and name not in (''''''''ReportServer'''''''',''''''''ReportServerTempDB'''''''')
               
'''')'')
      '

 insert into dbadata.dbo.tbl_sys_master_files
 exec(@sql)
 --print @sql
 */
 
 -- select *  from sys.databases
 set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''
select '''''''''+@Desc+''''''''',db_name(a.database_id) as DBname,a.name as DBfile ,
size/128.0 AS CurrentSizeMB,
--size/128.0 - ((size/128.0) - CAST(FILEPROPERTY(a.name, ''''''''SpaceUsed'''''''') AS INT)/128.0) AS UsedSpaceMB,
--size/128.0 - CAST(FILEPROPERTY(a.name, ''''''''SpaceUsed'''''''') AS INT)/128.0 AS FreeSpaceMB,
b.recovery_model_desc,a.type_desc ,

CASE WHEN is_percent_growth = 0
THEN LTRIM(STR(a.growth * 8.0 / 1024,10,1)) + '''''''' MB, ''''''''
ELSE ''''''''By '''''''' + CAST(a.growth AS VARCHAR) + '''''''' percent, ''''''''END +
CASE WHEN max_size = -1 THEN ''''''''Unlimited growth''''''''
ELSE ''''''''Limited growth to '''''''' +LTRIM(STR(max_size * 8.0 / 1024,10,1)) + '''''''' MB''''''''
END AS Autogrow --into tbl_sys_master_files

from sys.master_files a join sys.databases b
on a.database_id =b.database_id
order by a.size/128.0 desc

'''')'')
      '

 insert into dbadata.dbo.tbl_sys_master_files
 exec(@sql)

 --print ' sever'+@server_name+'completed.'
 end try
 BEGIN CATCH
--SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'tbl_sys_master_files',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

PRINT 'SERVER ['+@SERVER_NAME+']is not COMPLETED.'
END CATCH
 set @minrow =@minrow +1 
 end
 
END


