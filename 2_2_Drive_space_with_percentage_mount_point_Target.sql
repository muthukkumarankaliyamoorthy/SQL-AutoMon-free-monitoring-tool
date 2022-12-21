USE [master]
GO
/****** Object:  StoredProcedure [dbo].[USP_drivespace_mount_point]    Script Date: 21/12/2022 15:00:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
select * from tbl_driveinfo_mount_point
drop table [tbl_driveinfo_mount_point]
CREATE TABLE [dbo].[tbl_driveinfo_mount_point](
	[volume_mount_point] [nvarchar](512) NULL,
	[available_bytes] [bigint] NULL,
	[total_bytes] [bigint] NULL,
	[PercentFree] [bigint] NULL
) 
*/
create PROC [dbo].[USP_drivespace_mount_point]

AS

BEGIN

DECLARE @unit VARCHAR(4) = 'GB'
DECLARE @divisor BIGINT
SELECT @divisor =	CASE @unit
						WHEN 'BYTE' THEN 1
						WHEN 'KB' THEN 1024
						WHEN 'MB' THEN POWER(1024,2)
						WHEN 'GB' THEN POWER(1024,3)
						WHEN 'TB' THEN POWER(CAST(1024 AS BIGINT),4)
					END


truncate table tbl_driveinfo_mount_point
			
CREATE TABLE [dbo].[#tbl_driveinfo_mount_point_T](
	[volume_mount_point] [nvarchar](512) NULL,
	[available_bytes] [bigint] NULL,
	[total_bytes] [bigint] NULL,
	[logical_volume_name] [nvarchar](512) NULL
) 




INSERT INTO #tbl_driveinfo_mount_point_T (volume_mount_point,available_bytes,total_bytes,logical_volume_name)

SELECT DISTINCT
volumestats.volume_mount_point,
volumestats.available_bytes,
volumestats.total_bytes,
logical_volume_name
FROM 
(
	SELECT 
	[database_id],
	[file_id],
	ROW_NUMBER() OVER (PARTITION BY SUBSTRING(physical_name,1,LEN(physical_name)-CHARINDEX('\',REVERSE(physical_name))+1) 
						ORDER BY SUBSTRING(physical_name,1,LEN(physical_name)-CHARINDEX('\',REVERSE(physical_name))+1) ASC) AS RowNum
	FROM sys.master_files
	WHERE database_id IN (SELECT database_id FROM sys.databases WHERE state = 0)
) DistinctDrives
CROSS APPLY sys.dm_os_volume_stats([DistinctDrives].[database_id],[DistinctDrives].[file_id]) volumestats
WHERE DistinctDrives.RowNum = 1

insert into tbl_driveinfo_mount_point
SELECT	volume_mount_point,
			CAST(CAST(available_bytes AS DECIMAL(20,2)) / @divisor AS DECIMAL(20,2)) AS Available,
			CAST(CAST(total_bytes AS DECIMAL(20,2)) / @divisor AS DECIMAL(20,2)) AS Total,
			CAST(available_bytes AS DECIMAL(20,2))/CAST(total_bytes AS DECIMAL(20,2)) * 100  AS PercentFree
			--,@DESC AS SERVERNAME
	FROM #tbl_driveinfo_mount_point_T

END