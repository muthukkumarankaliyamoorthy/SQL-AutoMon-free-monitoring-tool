--/*

-- Enable xp_cmdshell
-- Create SP sp_DatabaseRestore https://www.brentozar.com/archive/2017/03/databaserestore-open-source-database-restore-stored-procedure/
-- Alter SP with net use to allow permission to the prod backup share
-- Run recent-backup-finding.sql to get the data, copy and paste the CMD column into new query windwos and run
ex:
EXEC dbo.sp_DatabaseRestore @Database ='DBA_Trace_Load_14_feb_2022',@BackupPathFull ='\\x.x.x.x\Database_Backup_Daily\xx-SQL001$SQLEXPRESS\DBA_Trace_Load_14_feb_2022\FULL\',@ContinueLogs = 0,@RunRecovery = 1;
--*/

sp_configure 'show advan',1;reconfigure

sp_configure 'xp_cmdshell',1;reconfigure


exec xp_cmdshell 'net use \\x.x.x.x\Dropbox\Database_Backup  /USER:x.x.x.x\Administrator password'
exec xp_cmdshell 'net use \\x.x.x.x\Dropbox\Database_Backup  /DELETE /y'

--Run with -- @Execute = 'N' and find out your restore is correct and Data & log path are correct

EXEC dbo.sp_DatabaseRestore @Database ='dbname',
@BackupPathFull ='\\x.x.x.x\Dropbox\TechSupport\Database_Backup_Daily\WIN-VMC-SQL001$SQLEXPRESS\dbname\FULL\'
,@RunRecovery = 1,@ContinueLogs = 0,@Execute = 'N',@MoveFiles=1,@MoveDataDrive='E:\SQL_DataBase\',@MoveLogDrive='F:\SQL_Database\';



