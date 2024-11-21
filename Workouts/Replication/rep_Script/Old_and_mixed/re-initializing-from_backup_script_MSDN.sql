--https://repltalk.com/2020/08/25/initialize-subscriber-from-differential-backup/
/*
The main steps shown below are to create the publication, change allow init from backup, then take a full backup.

Create the publication using user interface Replication Wizard.

Under subscription options for the publication, set “allow initialization from backup files” to true

Create a new full backup of the publisher database. If you have existing full backup of the publisher database, you can still use that backup set but we have take a new log backup or differential backup of the publisher database and restore at the subscriber.

Replication UI does not allow the option to create the subscription to allow initialization from back. We have to TSQL when creating the subscription.
exec sp_addsubscription @publication = N’Repl2000′, 
@sync_type = N’initialize with backup’,
@backupdevicetype=‘Disk’,
@backupdevicename=‘C:\Repl2000_RestoreThis.bak’–this is the last backup used to restore on the subscriber that was taken after the publication was created
go

exec sp_addpushsubscription_agent
go
*/

--Pre-request
-- This is the last backup used to restore on the subscriber that was taken after the publication was created 

--1
--Publisher 
BACKUP DATABASE [ReplDB] TO  DISK = N'C:\tmp\repl_backups\ReplDB.bak' WITH NOFORMAT, NOINIT,  
NAME = N'ReplDB-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

-- Subscriber
USE [master]

RESTORE DATABASE [ReplDB] FROM  DISK = N'C:\tmp\repl_backups\ReplDB.bak' WITH NORECOVERY,  NOUNLOAD,  REPLACE,  STATS = 5

GO
--2
-- Publisher
insert into ReplTable (number) values (1);

select * from ReplTable; 

--3
-- Publisher
use [ReplDB]
 exec sp_replicationdboption @dbname = N'ReplDB', @optname = N'publish', @value = N'true'

GO
exec [ReplDB].sys.sp_addlogreader_agent @job_login = N'login_name', @job_password = null, @publisher_security_mode = 1, @job_name = null
GO
-- Adding the transactional publication. Change the login and password as needed

exec sp_addpublication @publication = N'PublicationTest', @description = N'Transactional publication of database ''ReplDB'' from Publisher ''SQL1\SQL2016''.', 
@sync_method = N'concurrent', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'false', @enabled_for_internet = N'false',
@snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @allow_subscription_copy = N'false', @add_to_active_directory = N'false',
@repl_freq = N'continuous', @status = N'active', @independent_agent = N'true', @immediate_sync = N'false', @allow_sync_tran = N'false', @allow_queued_tran = N'false', 
@allow_dts = N'false', @replicate_ddl = 1, <strong>@allow_initialize_from_backup = N'true'</strong>, @enabled_for_p2p = N'false', @enabled_for_het_sub = N'false'
GO

exec sp_addpublication_snapshot @publication = N'PublicationTest', @frequency_type = 1, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, 
@frequency_subday = 8, @frequency_subday_interval = 1, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, 
@job_login = N'login_name', @job_password = null, @publisher_security_mode = 1
GO

exec sp_addarticle @publication = N'PublicationTest', @article = N'ReplTable', @source_owner = N'dbo', @source_object = N'ReplTable', @type = N'logbased', @description = null, 
@creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @id<code>entityrangemanagementoption = N'manual', @destination_table = N'ReplTable', 
@destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboReplTable', @del_cmd = N'CALL sp_MSdel_dboReplTable', @upd_cmd = N'SCALL sp_MSupd_dboReplTable'


--4
-- Publisher
insert into ReplTable (number) values (2);

select * from ReplTable;

--5
--Publisher
BACKUP DATABASE [ReplDB] TO  DISK = N'C:\tmp\repl_backups\ReplDB_diff.bak' WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N'ReplDB-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

--Subscriber
RESTORE DATABASE [ReplDB] FROM  DISK = N'C:\tmp\repl_backups\ReplDB_diff.bak' WITH RECOVERY
GO

select * from ReplTable;
--6
--Publihser
USE [ReplDB]
GO
-- Add the Subscription on the Publisher (note DIIF.bak)
EXEC sp_addsubscription
@publication = N'PublicationTest', 
@subscriber = N'SQL2\SQL2016', 
@destination_db = N'ReplDB', 
@sync_type = N'initialize with backup', 
@backupdevicetype='Disk', 
@backupdevicename='C:\tmp\repl_backups\ReplDB_diff.bak',
@subscription_type = N'pull', 
@update_mode = N'read only'
GO
--7
--Publisher
insert into ReplTable (number) values (3);
GO

select * from ReplTable;
GO

--Subscriber
use [ReplDB]
-- Add the Pull Subscription
EXEC sp_addpullsubscription
@publisher = N'SQL1\SQL2016', 
@publication = N'PublicationTest', 
@publisher_db = N'ReplDB', 
@independent_agent = N'True', 
@subscription_type = N'pull', 
@description = N'', 
@update_mode = N'read only', 
@immediate_sync = 0
GO
-- Add the Pull Subscription Agent. Change login and password
EXEC sp_addpullsubscription_agent
@publisher = N'SQL1\SQL2016', 
@publisher_db =  N'ReplDB',  
@publication = N'PublicationTest',
@distributor = N'SQL1\SQL2016', 
@distributor_security_mode = 1, 
@distributor_login = N'', 
@distributor_password = null, 
@enabled_for_syncmgr = N'False', 
@frequency_type = 64, 
@frequency_interval = 0, 
@frequency_relative_interval = 0, 
@frequency_recurrence_factor = 0, 
@frequency_subday = 0, 
@frequency_subday_interval = 0, 
@active_start_time_of_day = 0, 
@active_end_time_of_day = 235959, 
@active_start_date = 20200801, 
@active_end_date = 99991231, 
@alt_snapshot_folder = N'', 
@working_directory = N'',
@use_ftp = N'False', 
@job_login = '', 
@job_password = '', 
@publication_type = 0
GO

--8. Verify Log Reader and Distribution Agents are running
--9. Insert Tracer Token and confirm if all transactions were delivered.
--10 
--Subscriber
select * from ReplTable;
GO