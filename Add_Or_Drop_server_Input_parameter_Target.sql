select* from DBA_All_servers where Description like '%server%'


-- add server
-- CHeck HA
-- ebnale dac
-- CREATE SP FOR space percentage, make sure Ole Automation Procedures enabled or not, alter the SP accordingly

select @@servername,isnull(serverproperty ('InstanceName'),'Default')as Instance,
serverproperty('ProductVersion') as Build,serverproperty ('ProductLevel')as SP,
case when serverproperty ('IsIntegratedSecurityOnly')=0 then 'SQL' else 'Windows'end as login_mode,
serverproperty ('Edition')as edition,
case when serverproperty ('IsClustered')=0 then 'Stand alone' else 'Clustered'end as IsClustered 


EXEC USP_DBA_ADDSERVER_FOR_MONITOR 'DBA_LAPTOP-ISGUKEUC\MUTHU','LAPTOP-ISGUKEUC\MUTHU','SQL2014','LAPTOP-ISGUKEUC\MUTHU','DBA','G0d$peed','Non PROD','UK','Standard Edition (64-bit)','Running','Windows'
EXEC USP_DBA_DROPSERVER_FOR_MONITOR	'server',	'server',	'SQL2019',	'server'


EXEC sp_configure 'remote admin connections', 1;
 GO
 RECONFIGURE
 GO

EXEC sp_configure 'backup compression default', 1;
RECONFIGURE WITH OVERRIDE;
GO

exec master..sp_configure 'show advanced options', 1 
RECONFIGURE; 
exec master..sp_configure 'Ole Automation Procedures', 1 
RECONFIGURE;

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

use master
go
Create table tbl_OS_version
(Value varchar (50),
OS varchar (100)
)
use master
go
create proc Usp_OS_version
as
begin

Truncate table tbl_OS_version
insert into tbl_OS_version
exec master..xp_regread
'HKEY_LOCAL_MACHINE','SOFTWARE\Microsoft\Windows NT\CurrentVersion','productname'
end

go

use master
go

CREATE TABLE [dbo].[TEMPSPACE_percentage](
	[DRIVE] [char](1) NULL,
	[Lable_NAME] [varchar](50) NULL,
	[FREE_SPACE_IN_MB] [int] NULL,
	[used_SPACE_IN_MB] [int] NULL,
	[Total_SPACE_IN_MB] [int] NULL,
	[Precentage_free] [numeric](9, 0) NULL
)
go


use master
go
CREATE PROCEDURE [dbo].[USP_TEMPSPACE_POP_percentage]
AS
BEGIN
TRUNCATE TABLE TEMPSPACE_percentage

-- Ole Automation need to be checked in the system by default this is been disabled
-- Check before enable and disable, if the system needs this should be enabled all the time, make adjustment

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