
WITH LastBackUp AS
(
SELECT  bs.database_name,
        bs.backup_size,
        bs.backup_start_date,
        --replace (bmf.physical_device_name,'G:','\\10.10.93.20') as physical_device_name,
		 replace(LEFT(bmf.physical_device_name,CHARINDEX('\FULL\',bmf.physical_device_name,1) + LEN('FULL\')),'G:','\\x.x.x.x')  as physical_device_name,
        Position = ROW_NUMBER() OVER( PARTITION BY bs.database_name ORDER BY bs.backup_start_date DESC )
FROM  msdb.dbo.backupmediafamily bmf
JOIN msdb.dbo.backupmediaset bms ON bmf.media_set_id = bms.media_set_id
JOIN msdb.dbo.backupset bs ON bms.media_set_id = bs.media_set_id
WHERE   bs.[type] = 'D'
AND bs.is_copy_only = 0
)
--EXEC dbo.sp_DatabaseRestore @Database = 'dbPainTrax_2',@BackupPathFull = '\\10.10.93.20\Dropbox\Database_Backup\',@ContinueLogs = 0,@RunRecovery = 0;
SELECT 
'EXEC dbo.sp_DatabaseRestore @Database ='''+sd.name+''',@BackupPathFull ='''+physical_device_name+''',@ContinueLogs = 0,@RunRecovery = 1
,@MoveFiles=1,@MoveDataDrive=''E:\SQL_DataBase\'',@MoveLogDrive=''F:\SQL_Database\'',@Execute = ''Y'';' as cmd,
        sd.name AS [Database],
        CAST(backup_size / 1048576 AS DECIMAL(10, 2) ) AS [BackupSizeMB],
        backup_start_date AS [Last Full DB Backup Date],
        physical_device_name AS [Backup File Location]
FROM sys.databases AS sd
LEFT JOIN LastBackUp AS lb
    ON sd.name = lb.database_name
    AND Position = 1
	where database_name not in ('master','model','msdb','tempdb')
ORDER BY [BackupSizeMB];




/*
EXEC dbo.sp_DatabaseRestore @Database ='db_PharmaTrax_Test_New',
@BackupPathFull ='\\x.x.x.x\Dropbox\TechSupport\Database_Backup_Daily\WIN-VMC-SQL001$SQLEXPRESS\db_PharmaTrax_Test_New\FULL\'
,@RunRecovery = 1,@ContinueLogs = 0,@Execute = 'N',@MoveFiles=1,@MoveDataDrive='E:\SQLDataBase\',@MoveLogDrive='F:\SQLDatabase\';
*/