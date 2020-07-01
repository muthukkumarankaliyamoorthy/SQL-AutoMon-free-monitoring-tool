/*
drop table tbl_datafile_free_used_size_mb
go
CREATE TABLE [dbo].[tbl_datafile_free_used_size_mb](
	[DBNAME] [nvarchar](128) NULL,
	[FILENAME] [sysname] NOT NULL,
	[CURRENTSIZE_MB] [numeric](17, 6) NULL,
	[USEDSPACE_MB] [numeric](19, 6) NULL,
	[FREESPACEMB] [numeric](18, 6) NULL,
	[PHYSICAL_NAME] [nvarchar](260) NOT NULL,
	[RECOVERY_MODEL] [sql_variant] NULL,
	[TYPE_DESC] [nvarchar](100) NULL,
	[AUTO_GROW] [varchar](100) NULL,
	[Edition] varchar (100)
)
*/

--drop proc[Usp_dba_send_DATAfiles_size_Express_limit_check_Target]

alter PROCEDURE [dbo].[Usp_dba_send_DATAfiles_size_Express_limit_check_Target]
as
	  DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @name varchar(max)
	  DECLARE @SQL varchar(max)
      DECLARE @minrow int
      DECLARE @maxrow int
--select * from tbl_datafile_free_used_size_mb
 truncate table tbl_datafile_free_used_size_mb
 declare @spaceinfo_express_DB table (id int  primary key identity,  name varchar(200)) 
 
 insert into @spaceinfo_express_DB
select name  from sys.databases where state_desc='ONLINE'
 -- select *  from sys.databases where state_desc='ONLINE'
 
SELECT @minrow = MIN(id)FROM   @spaceinfo_express_DB
SELECT @maxrow  = MAX(id) FROM   @spaceinfo_express_DB
 
 while (@minrow <=@maxrow)
 begin

 select  @name=name   from @spaceinfo_express_DB where ID = @minrow 
 --select @name
 set @sql='
use ['+@name+']
insert into master.dbo.tbl_datafile_free_used_size_mb
SELECT DB_NAME() AS DBNAME,
NAME AS FILENAME,
SIZE/128.0 AS CURRENTSIZE_MB,
SIZE/128.0 - ((SIZE/128.0) - CAST(FILEPROPERTY(NAME, ''SPACEUSED'') AS INT)/128.0) AS USEDSPACE_MB,
SIZE/128.0 - CAST(FILEPROPERTY(NAME, ''SPACEUSED'') AS INT)/128.0 AS FREESPACEMB,
PHYSICAL_NAME,DATABASEPROPERTYEX (DB_NAME(),''RECOVERY'') AS RECOVERY_MODEL,TYPE_DESC,
CASE WHEN IS_PERCENT_GROWTH = 0
THEN LTRIM(STR(GROWTH * 8.0 / 1024,10,1)) + '' MB, ''
ELSE ''BY '' + CAST(GROWTH AS VARCHAR) + '' PERCENT, ''END +
CASE WHEN MAX_SIZE = -1 THEN ''UNRESTRICTED GROWTH''
ELSE ''RESTRICTED GROWTH TO '' +LTRIM(STR(MAX_SIZE * 8.0 / 1024,10,1)) + '' MB''
END AS AUTO_GROW
, convert (varchar(200),SERVERPROPERTY (''edition''))
FROM master.SYS.MASTER_FILES
WHERE DATABASE_ID = DB_ID()
and Type_Desc=''Rows''
'

exec (@sql)
--print (@sql)

set @minrow =@minrow +1 
 end
 

 --select * from tbl_datafile_free_used_size_mb