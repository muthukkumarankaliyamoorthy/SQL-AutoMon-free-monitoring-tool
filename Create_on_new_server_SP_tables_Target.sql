USE DBAData
go
/*

select 'EXEC USP_DBA_Create_SP_Table_temp',''''+ServerName+''',',''''+ServerName+''',',
''''+Version+''',',''''+ServerName+''',',
''''+Category+''',','''location'',',''''+Edition+''',','''Running'',',''''+Login_Mode+''''
from dbo.DBA_All_servers where svr_Status ='running' -- and edition   like'%Express%'


SELECT * FROM dbo.DBA_All_servers

*/

alter PROCEDURE [dbo].[USP_DBA_Create_SP_Table_temp]

@P_LINK_SERVER SYSNAME,
@P_SERVER SYSNAME,
@P_VERSION SYSNAME,
@P_DESC VARCHAR(50),
--@P_USERNAME SYSNAME,
--@P_PWD VARCHAR(100),
@P_category VARCHAR(100),
@P_location VARCHAR(100),
@P_edition VARCHAR(50),
@P_svr_status VARCHAR(20),
@P_login_mode VARCHAR(20)

WITH ENCRYPTION

AS 
 BEGIN

DECLARE @LINK_SERVER SYSNAME
DECLARE @SERVER SYSNAME
DECLARE @VERSION SYSNAME
DECLARE @DESC VARCHAR(50)
DECLARE @USERNAME SYSNAME
DECLARE @PWD VARCHAR(100)
DECLARE @category VARCHAR(100)
DECLARE @location VARCHAR(100)
DECLARE @edition VARCHAR(50)
DECLARE @svr_status VARCHAR(20)
DECLARE @login_mode VARCHAR(20)

declare @sql varchar(8000)
declare @ls_script  varchar(8000)

SET @LINK_SERVER=@P_LINK_SERVER
SET @SERVER=@P_SERVER
SET @VERSION=@P_VERSION
SET @DESC=@P_DESC
--SET @USERNAME=@P_USERNAME
--SET @PWD=@P_PWD
SET @category=@P_category
SET @location=@P_location
SET @edition=@p_edition
SET @svr_status=@p_svr_status
SET @login_mode=@P_login_mode 

DECLARE @TABSQL VARCHAR(5000)
DECLARE @PROCSQL VARCHAR(5000)
SET @TABSQL='
USE [MASTER];

IF object_id(''''tbl_datafile_free_used_size_mb'''') is not null
    PRINT ''''Present!''''
ELSE
begin
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
end
'

SET @PROCSQL='
if  exists ( select * from sysobjects 
            where name=''''Usp_dba_send_DATAfiles_size_Express_limit_check_Target'''' and objectproperty(id,''''IsProcedure'''')=1 )

exec(''''

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
 select name  from master.sys.databases where state_desc=''''''''ONLINE''''''''
 
 
SELECT @minrow = MIN(id)FROM   @spaceinfo_express_DB
SELECT @maxrow  = MAX(id) FROM   @spaceinfo_express_DB
 
 while (@minrow <=@maxrow)
 begin

 select  @name=name   from @spaceinfo_express_DB where ID = @minrow 
 --select @name
 set @sql=''''''''
use [''''''''+@name+'''''''']
insert into master.dbo.tbl_datafile_free_used_size_mb
SELECT DB_NAME() AS DBNAME,
NAME AS FILENAME,
SIZE/128.0 AS CURRENTSIZE_MB,
SIZE/128.0 - ((SIZE/128.0) - CAST(FILEPROPERTY(NAME, ''''''''''''''''SPACEUSED'''''''''''''''') AS INT)/128.0) AS USEDSPACE_MB,
SIZE/128.0 - CAST(FILEPROPERTY(NAME, ''''''''''''''''SPACEUSED'''''''''''''''') AS INT)/128.0 AS FREESPACEMB,
PHYSICAL_NAME,DATABASEPROPERTYEX (DB_NAME(),''''''''''''''''RECOVERY'''''''''''''''') AS RECOVERY_MODEL,TYPE_DESC,
CASE WHEN IS_PERCENT_GROWTH = 0
THEN LTRIM(STR(GROWTH * 8.0 / 1024,10,1)) + '''''''''''''''' MB, ''''''''''''''''
ELSE ''''''''''''''''BY '''''''''''''''' + CAST(GROWTH AS VARCHAR) + '''''''''''''''' PERCENT, ''''''''''''''''END +
CASE WHEN MAX_SIZE = -1 THEN ''''''''''''''''UNRESTRICTED GROWTH''''''''''''''''
ELSE ''''''''''''''''RESTRICTED GROWTH TO '''''''''''''''' +LTRIM(STR(MAX_SIZE * 8.0 / 1024,10,1)) + '''''''''''''''' MB''''''''''''''''
END AS AUTO_GROW
, convert (varchar(200),SERVERPROPERTY (''''''''''''''''edition''''''''''''''''))
FROM master.SYS.MASTER_FILES
WHERE DATABASE_ID = DB_ID()
and Type_Desc=''''''''''''''''Rows''''''''''''''''
''''''''

exec (@sql)
--print (@sql)

set @minrow =@minrow +1 
 end
 


'''')
'

--SELECT LEN(@PROCSQL)
EXEC ('EXEC ['+@LINK_SERVER + '].MASTER.DBO.SP_EXECUTESQL N'''+@TABSQL+'''')
--print (@TABSQL)
PRINT 'PROCEDURE CREATED'
EXEC ('EXEC ['+@LINK_SERVER + '].MASTER.DBO.SP_EXECUTESQL N'''+@PROCSQL+'''')
--print (@PROCSQL)
PRINT 'TABLE CREATED'


END


