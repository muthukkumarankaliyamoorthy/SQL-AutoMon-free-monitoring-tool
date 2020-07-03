
-- drop table tbl_Patch_OS_EOL
-- select * from tbl_Patch_OS_EOL


USE [DBAdata]

GO
/*

USE [DBAdata]
GO

/****** Object:  Table [dbo].[tbl_Patch_OS_EOL]    Script Date: 03/06/2020 16:12:04 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tbl_Patch_OS_EOL](
	[Server_name] [varchar](200) NOT NULL,
	[IP] [varchar](200) NULL,
	[OS_version] [varchar](500) NULL,
	[Product] [varchar](50) NULL,
	[Is_patch_compliance] [varchar](20) NULL,
	[Is_auto_pacth] [varchar](50) NULL,
	[Is_manual_patch] [varchar](50) NULL,
	[Schedule_time] [varchar](100) NULL,
	[CAU] [varchar](200) NULL,
	[comments] [varchar](200) NULL,
	[load_date] [datetime] NULL,
	[WSUS_Patch] [varchar](200) NULL,
	[WSUS_GPO_Schedule] [varchar](200) NULL,
	[svr_status] [varchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[Server_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[tbl_Patch_OS_EOL] ADD  DEFAULT (getdate()) FOR [load_date]
GO



*/
use DBAdata
go


create PROCEDURE [dbo].[Usp_load_OS_verion_Patch_EOL]
/*
Summary:        [Usp_load_OS_Info]
Contact:        Muthukkumaran Kaliyamoorhty SQL DBA

ChangeLog:
Date                          Coder                                                    Description
2012-06-04                 Muthukkumaran Kaliyamoorhty               created
 
*******************All the SQL keywords should be written in upper case********************
*/

AS
BEGIN
SET nocount ON

--inserting the drive space
Truncate table dbadata.dbo.[tbl_Patch_OS_EOL]


      DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @sql varchar(8000)
	  DECLARE @sql1 varchar(8000)
      DECLARE @minrow int
      DECLARE @maxrow int

---------------------------------------------------
--Put the local server first
---------------------------------------------------
 

CREATE TABLE #tbl_Patch_OS_EOL
(
value VARCHAR(50),
OS VARCHAR(500))

/*

INSERT INTO #tbl_Patch_OS_EOL
exec master..xp_regread
      'HKEY_LOCAL_MACHINE'
    , 'SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    , 'ProductName'

INSERT INTO tbl_Patch_OS_EOL
SELECT 'FINSQLVM01.FORTIS-UK.FORTIS.COM'  AS SERVERNAME,* FROM #tbl_Patch_OS_EOL
*/

DECLARE Load_OS_version CURSOR
FOR

SELECT SERVERNAME,	[DESCRIPTION] FROM DBADATA.DBO.DBA_ALL_SERVERS
WHERE  svr_status ='running' --

OPEN Load_OS_version
FETCH NEXT FROM Load_OS_version INTO @SERVER_NAME,@DESC

WHILE @@FETCH_STATUS=0  
BEGIN
BEGIN TRY

TRUNCATE TABLE #tbl_Patch_OS_EOL


EXEC ('EXEC [' + @SERVER_NAME+'].MASTER.DBO.Usp_OS_version')
EXEC ('INSERT INTO  #tbl_Patch_OS_EOL SELECT * FROM [' + @SERVER_NAME+'].MASTER.DBO.tbl_OS_version')

INSERT INTO tbl_Patch_OS_EOL (Server_name,OS_version,Product)
SELECT @DESC AS SERVERNAME ,*  FROM #tbl_Patch_OS_EOL

--PRINT 'SERVER ' +@SERVER_NAME+' COMPLETED.'
END TRY

BEGIN CATCH
--SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
--select * from tbl_Error_handling

insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'Load OS version EOL',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

--PRINT 'SERVER ['+@SERVER_NAME+']is not COMPLETED.'
END CATCH

FETCH NEXT FROM Load_OS_version INTO @SERVER_NAME,@DESC
END
CLOSE Load_OS_version
DEALLOCATE Load_OS_version
DROP TABLE #tbl_Patch_OS_EOL
END


