

 -- Run this in Target server ===============================

USE [master]
GO
CREATE LOGIN [domain\CMS_SQL] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
GO

go
EXEC master..sp_addsrvrolemember @loginame = N'domain\CMS_SQL', @rolename = N'sysadmin'
GO


USE [master]
GO
CREATE LOGIN [DBA] WITH PASSWORD=N'G0d$peed@123', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
EXEC master..sp_addsrvrolemember @loginame = N'DBA', @rolename = N'sysadmin'
GO

EXEC sp_configure 'remote admin connections', 1;
 GO
 RECONFIGURE
 GO

EXEC sp_configure 'backup compression default', 1;
RECONFIGURE WITH OVERRIDE;
GO

-- check this value in the target server if run_value is 1 and change or comment the target server SP - [USP_TEMPSPACE_POP_percentage] to enable Ole Automation Procedures all the time. 
-- Since it is enabling and disabling by default, if your system needs to be enabled all the time change it accordingoly
--It should be 0(Disable) for security reason. By default it will be zero. 
--In our Store procedure [USP_TEMPSPACE_POP_percentage]if the run_value is 0, commentout the OLE Automation both enable and disable. 

exec master..sp_configure 'show advanced options', 1
RECONFIGURE; 
exec master..sp_configure 'Ole Automation Procedures'




/*

CREATE TABLE [dbo].[TEMPSPACE](
	[DRIVE] [varchar](20) NULL,
	[SPACE] [int] NULL
)

go


create PROCEDURE [dbo].[USP_TEMPSPACE_POP]
AS
BEGIN
TRUNCATE TABLE TEMPSPACE
INSERT INTO TEMPSPACE
EXEC XP_FIXEDDRIVES
END

GO
*/


---1


USE [master]
GO


CREATE TABLE [dbo].[tbl_OS_version](
	[value] [varchar](50) NULL,
	[OS] [varchar](100) NULL
) ON [PRIMARY]
GO


USE [master]
GO


create proc [dbo].[Usp_OS_version]
AS
BEGIN
TRUNCATE TABLE tbl_OS_version
INSERT INTO tbl_OS_version
exec master..xp_regread
      'HKEY_LOCAL_MACHINE'
    , 'SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    , 'ProductName'
end
go


-- 2

CREATE TABLE [dbo].[TEMPSPACE_percentage](
	[DRIVE] [char](1) NULL,
	[Lable_NAME] [varchar](50) NULL,
	[FREE_SPACE_IN_MB] [int] NULL,
	[used_SPACE_IN_MB] [int] NULL,
	[Total_SPACE_IN_MB] [int] NULL,
	[Precentage_free] [numeric](9, 0) NULL
)
go




create PROCEDURE [dbo].[USP_TEMPSPACE_POP_percentage]
AS
BEGIN
TRUNCATE TABLE TEMPSPACE_percentage

/*
exec master..sp_configure 'show advanced options', 1 
RECONFIGURE; 
exec master..sp_configure 'Ole Automation Procedures', 1 
RECONFIGURE;
*/



SET NOCOUNT ON


IF EXISTS (SELECT name FROM tempdb..sysobjects WHERE name = '##_DriveSpace')
	DROP TABLE ##_DriveSpace

IF EXISTS (SELECT name FROM tempdb..sysobjects WHERE name = '##_DriveInfo')
	DROP TABLE ##_DriveInfo


DECLARE @Result INT
	, @objFSO INT
	, @Drv INT 
	, @cDrive VARCHAR(13) 
	, @Size VARCHAR(50) 
	, @Free VARCHAR(50)
	, @Label varchar(10)

CREATE TABLE ##_DriveSpace 
	(
	 DriveLetter CHAR(1) not null
	, FreeSpace VARCHAR(10) not null

	 )

CREATE TABLE ##_DriveInfo
	(
	DriveLetter CHAR(1)
	, TotalSpace bigint
	, FreeSpace bigint
	, Label varchar(10)
	)

INSERT INTO ##_DriveSpace 
	EXEC master.dbo.xp_fixeddrives


-- Iterate through drive letters.
DECLARE curDriveLetters CURSOR
	FOR SELECT driveletter FROM ##_DriveSpace

DECLARE @DriveLetter char(1)
	OPEN curDriveLetters

FETCH NEXT FROM curDriveLetters INTO @DriveLetter
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN

		 SET @cDrive = 'GetDrive("' + @DriveLetter + '")' 

			EXEC @Result = sp_OACreate 'Scripting.FileSystemObject', @objFSO OUTPUT 

				IF @Result = 0 

					EXEC @Result = sp_OAMethod @objFSO, @cDrive, @Drv OUTPUT 

				IF @Result = 0 

					EXEC @Result = sp_OAGetProperty @Drv,'TotalSize', @Size OUTPUT 

				IF @Result = 0 

					EXEC @Result = sp_OAGetProperty @Drv,'FreeSpace', @Free OUTPUT 

				IF @Result = 0 

					EXEC @Result = sp_OAGetProperty @Drv,'VolumeName', @Label OUTPUT 

				IF @Result <> 0 
 
					EXEC sp_OADestroy @Drv 
					EXEC sp_OADestroy @objFSO 

			SET @Size = (CONVERT(BIGINT,@Size) / 1048576 )

			SET @Free = (CONVERT(BIGINT,@Free) / 1048576 )

			INSERT INTO ##_DriveInfo
				VALUES (@DriveLetter, @Size, @Free, @Label)

	END
	FETCH NEXT FROM curDriveLetters INTO @DriveLetter
END

CLOSE curDriveLetters
DEALLOCATE curDriveLetters


INSERT INTO master.dbo.TEMPSPACE_percentage
SELECT DriveLetter
	, Label
	, FreeSpace AS [FreeSpace MB]
	, (TotalSpace - FreeSpace) AS [UsedSpace MB]
	, TotalSpace AS [TotalSpace MB]
	, ((CONVERT(NUMERIC(9,0),FreeSpace) / CONVERT(NUMERIC(9,0),TotalSpace)) * 100) AS [Percentage Free]
	FROM ##_DriveInfo
ORDER BY [DriveLetter] ASC

DROP TABLE ##_DriveSpace
DROP TABLE ##_DriveInfo

/*
exec master..sp_configure 'Ole Automation Procedures', 0 
RECONFIGURE; 
exec master..sp_configure 'show advanced options', 0
RECONFIGURE;
*/

END

go

-- 3
--drop table tbl_datafile_free_used_size_mb
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

go

--drop proc[Usp_dba_send_DATAfiles_size_Express_limit_check_Target]

create PROCEDURE [dbo].[Usp_dba_send_DATAfiles_size_Express_limit_check_Target]
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
 

 