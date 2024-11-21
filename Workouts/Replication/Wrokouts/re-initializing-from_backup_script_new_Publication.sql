/*
https://www.youtube.com/watch?v=wAP_tykTHdY

Pre request:

You need to drop the tables in subscripber since backup and restore will take whole DB. Remove tables, 
if any filter n column and rows make sure to remove that 

For existing Connect to the Publisher and remove the subscription
For new replication create the publication with out snapshot both option

Trun on Allow initialized from backup - true
*/


--T-SQL: To enable this publication option we need execute the "sp_changepublication" stored procedure at the Publisher on the publication database.
use master
backup database [muthu] to disk ='\\NODE2\LS_Copy_Logfile\muthu-BI_full.bak'

-- Publisher
USE muthu
GO
EXEC sp_replicationdboption 	@dbname = N'muthu', 	@optname = N'publish', 	@value = N'true'
GO
GO
-- If you have sperate DB publication . Log reader is for each publication.
--exec [ReplDB].sys.sp_addlogreader_agent @job_login = N'login_name', @job_password = null, @publisher_security_mode = 1, @job_name = null
GO

--1
GO
-- Adding the transactional publication
use [muthu]
exec sp_addpublication @publication = N'muthu-BI', @description = N'Transactional publication of database ''muthu'' from Publisher ''Node1''.',		 @sync_method = N'concurrent', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'false', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'continuous', @status = N'active', @independent_agent = N'true', @immediate_sync = N'false', @allow_sync_tran = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1, @allow_initialize_from_backup = N'true', @enabled_for_p2p = N'false', @enabled_for_het_sub = N'false'
--exec sp_addpublication @publication = N'PublicaonTest', @description = N'Transactional publication of database ''ReplDB'' from Publisher ''SQL1\SQL2016''.', @sync_method = N'concurrent', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'false', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'continuous', @status = N'active', @independent_agent = N'true', @immediate_sync = N'false', @allow_sync_tran = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1, @allow_initialize_from_backup = N'true', @enabled_for_p2p = N'false', @enabled_for_het_sub = N'false'

GO
exec sp_addpublication_snapshot @publication = N'muthu-BI', @frequency_type = 1, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, @frequency_subday = 8, @frequency_subday_interval = 1, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = N'muthu\Svc_repl_snapshot', @job_password = 'G0d$peed', @publisher_security_mode = 0, @publisher_login = N'tncreplicator1', @publisher_password = N'G0d$peed'
--exec sp_addpublication_snapshot @publication = N'PublicionTest', @frequency_type = 1, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, @frequency_subday = 8, @frequency_subday_interval = 1, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = N'login_name', @job_password = null, @publisher_security_mode = 1
GO
use [muthu]
exec sp_addarticle @publication = N'muthu-BI', @article = N'Repl_Tbl1', @source_owner = N'dbo', @source_object = N'Repl_Tbl1', @type = N'logbased', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'Repl_Tbl1', @destination_owner = N'dbo',  @vertical_partition = N'false', @ins_cmd = N'CALL [dbo].[sp_MSins_dboRepl_Tbl1]', @del_cmd = N'CALL [dbo].[sp_MSdel_dboRepl_Tbl1]', @upd_cmd = N'SCALL [dbo].[sp_MSupd_dboRepl_Tbl1]'
--exec sp_addarticle @publication = N'PublicionTest', @article = N'ReplTable', @source_owner = N'dbo', @source_object = N'ReplTable', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'ReplTable', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboReplTable', @del_cmd = N'CALL sp_MSdel_dboReplTable', @upd_cmd = N'SCALL sp_MSupd_dboReplTable'
GO
exec sp_addarticle @publication = N'muthu-BI', @article = N'Repl_Tbl2', @source_owner = N'dbo', @source_object = N'Repl_Tbl2', @type = N'logbased', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'Repl_Tbl2', @destination_owner = N'dbo',  @vertical_partition = N'false', @ins_cmd = N'CALL [dbo].[sp_MSins_dboRepl_Tbl2]', @del_cmd = N'CALL [dbo].[sp_MSdel_dboRepl_Tbl2]', @upd_cmd = N'SCALL [dbo].[sp_MSupd_dboRepl_Tbl2]'

  
  backup database [muthu] to disk ='\\NODE2\LS_Copy_Logfile\muthu-BI_diff.bak' with differential

  Go to subscriber

  use master
 
alter database [muthu-BI] set single_user with rollback immediate

restore filelistonly from disk ='\\NODE2\LS_Copy_Logfile\muthu-BI_full.bak' 

  restore database [muthu-BI] from disk ='\\NODE2\LS_Copy_Logfile\muthu-BI_full.bak' 
  with 
  move 'Muthu'to'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\Muthu_BI.mdf',
  move 'Muthu_log'to'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\Muthu_BI_log.ldf',
  replace,norecovery
  restore database [muthu-BI] from disk ='\\NODE2\LS_Copy_Logfile\muthu-BI_diff.bak' with recovery

  
/*
Execute the stored procedure sp_addsubscription at the Publisher on the publication database, 
 Specify the following parameter:
 @sync_type = 'initialize with backup',
   @backupdevicetype = 'Disk',
 @backupdevicename = 'Backup Path'
 */

--Publihser

DECLARE @publication AS sysname;
DECLARE @subscriber AS sysname;
DECLARE @subscriptionDB AS sysname;
SET @publication = N'muthu-BI';
SET @subscriber = N'Node2';
SET @subscriptionDB = N'muthu-BI';

--Add a push subscription to a transactional publication.
USE [muthu]
EXEC sp_addsubscription 
  @publication = @publication, 
  @subscriber = @subscriber, 
  @destination_db = @subscriptionDB, 
  @subscription_type = N'push',
  @sync_type = 'initialize with backup',
  @backupdevicetype = 'Disk',
  @backupdevicename = '\\NODE2\LS_Copy_Logfile\muthu-BI_diff.bak',
  @update_mode = N'read only';

-- You will get this error - This database is not enabled for publication.. This can be ignored

--publisher
use [muthu]
exec sp_addsubscription @publication = N'muthu-BI', @subscriber = N'Node2', @destination_db = N'muthu-BI', @subscription_type = N'Push', @sync_type = N'automatic', @article = N'all', @update_mode = N'read only', @subscriber_type = 0
--EXEC sp_addpullsubscription @publisher = N'SQL1\SQL2016', @publication = N'PublicationTest', @publisher_db = N'ReplDB', @independent_agent = N'True', @subscription_type = N'pull', @description = N'', @update_mode = N'read only', @immediate_sync = 0

exec sp_addpushsubscription_agent @publication = N'muthu-BI', @subscriber = N'Node2', @subscriber_db = N'muthu-BI', @job_login = N'muthu\Svc_repl_distributer', @job_password = 'G0d$peed', @subscriber_security_mode = 0, @subscriber_login = N'tncreplicator1', @subscriber_password = 'G0d$peed', @frequency_type = 64, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, @frequency_subday = 4, @frequency_subday_interval = 5, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @dts_package_location = N'Distributor'
GO


----
Go to subscription property and make sure to have correct distribution agent account. 
MUTHU\Svc_repl_distributer -- G0d$peed

Verify the replication status
Do some DML
Add one more new article and see all working as expected

