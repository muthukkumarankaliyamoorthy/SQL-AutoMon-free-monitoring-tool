
--https://sqlworldwide.com/monitoring-transaction-replication-latency-in-real-time/

--Run this on Publisher database
/**********************************************************************
TODO
**********************************************************************
1) Replace PublisherDBName with your publisher database name.
2) Make sure all decalred variables have the correct value
*********************************************************************/

DECLARE @subscriber sysname
DECLARE @destinationdb sysname
DECLARE @replication_jobaccount_login as nvarchar(257)
DECLARE @replication_jobaccount_password as nvarchar(257)

SET @subscriber = N'node2'
SET @destinationdb=N'muthu_3'
SELECT @replication_jobaccount_login = N'MUTHU\Svc_repl_distributer'
SELECT @replication_jobaccount_password = N'G0d$peed'

IF ( @replication_jobaccount_password = ' ' OR @replication_jobaccount_login = '')
GOTO ERROR
USE [Muthu_3] --Publisher database name
--Drop the table if exist
IF object_id ('dbo.PublisherTime', 'U') IS NOT null
DROP TABLE [dbo].[PublisherTime]
--Create a table with only one column
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
--drop table [PublisherTime]
CREATE TABLE [dbo].[PublisherTime](
[FixedId] [SMALLINT],
[Currenttime] [DATETIME] NOT NULL
CONSTRAINT [PK_sPublisherTime] PRIMARY KEY CLUSTERED
(
[FixedId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
--Insert timestamp which will be update via a sql job every minute and be subscribed to measure latency
INSERT INTO dbo.publishertime VALUES (1,GETDATE())
--SELECT * FROM dbo.publishertime
EXEC sp_addpublication @publication = N'MonitorReplication',
@description = N'Publication for Replication latency monitoring', @sync_method = N'native',
@retention = 0, @allow_push = N'true', @allow_pull = N'true',
@allow_anonymous = N'false', @enabled_for_internet = N'false',
@snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false',
@ftp_port = 21, @ftp_login = N'anonymous',
@allow_subscription_copy = N'false', @add_to_active_directory = N'false',
@repl_freq = N'continuous', @status = N'active',
@independent_agent = N'false', @immediate_sync = N'false',
@allow_sync_tran = N'false', @autogen_sync_procs = N'false',
@allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1,
@allow_initialize_from_backup = N'false', @enabled_for_p2p = N'false',
@enabled_for_het_sub = N'false'
EXEC sp_addpublication_snapshot @publication = N'MonitorReplication',
@frequency_type = 1, @frequency_interval = 0,
@frequency_relative_interval = 0, @frequency_recurrence_factor = 0,
@frequency_subday = 0, @frequency_subday_interval = 0,
@active_start_time_of_day = 0, @active_end_time_of_day = 235959,
@active_start_date = 0, @active_end_date = 0, @job_login = NULL,
@job_password = NULL, @publisher_security_mode = 1
EXEC sp_grant_publication_access @publication = N'MonitorReplication',
@login = N'sa'
EXEC sp_grant_publication_access @publication = N'MonitorReplication',
@login = N'MUTHU\Svc_repl_distributer'
EXEC sp_addarticle @publication = N'MonitorReplication',
@article = N'PublisherTime', @source_owner = N'dbo',
@source_object = N'PublisherTime', @type = N'logbased', @description = N'',
@creation_script = N'', @pre_creation_cmd = N'drop',
@schema_option = 0x00000000000000F3,
@identityrangemanagementoption = N'none',
@destination_table = N'PublisherTime', @destination_owner = N'dbo',
@status = 16, @vertical_partition = N'false',
@ins_cmd = N'CALL [sp_MSins_PublisherTime]',
@del_cmd = N'CALL [sp_MSdel_PublisherTime]',
@upd_cmd = N'MCALL [sp_MSupd_PublisherTime]'
EXEC sp_addsubscription @publication = N'MonitorReplication',
@subscriber = @subscriber, @destination_db = @destinationdb,
@subscription_type = N'Push', @sync_type = N'automatic', @article = N'all',
@update_mode = N'read only', @subscriber_type = 0
EXEC sp_addpushsubscription_agent @publication = N'MonitorReplication',
@subscriber = @subscriber, @subscriber_db = @destinationdb,
@job_login = NULL, @job_password = NULL, @subscriber_security_mode = 0,
@subscriber_login = @replication_jobaccount_login, @subscriber_password = @replication_jobaccount_password,
@frequency_type = 64, @frequency_interval = 1,
@frequency_relative_interval = 1, @frequency_recurrence_factor = 0,
@frequency_subday = 4, @frequency_subday_interval = 5,
@active_start_time_of_day = 0, @active_end_time_of_day = 235959,
@active_start_date = 0, @active_end_date = 0,
@dts_package_location = N'Distributor'
-- Execute at the Publisher to reinitialize the push subscription.
EXEC sp_reinitsubscription
@subscriber = @subscriber,
@publication =N'MonitorReplication';
GOTO ENDSCRIPT
ERROR:
PRINT 'ERROR: A variable has empty value, please provide correct value for all variables declared.'
ENDSCRIPT:

--2

/*

--Run this on the server where your distribution server reside.
--This will start the sanpshot job for this one publication "MonitorReplication"

USE [msdb]
GO
DECLARE @job_name SYSNAME;
SELECT @job_name = [sj].[name]
FROM [dbo].[sysjobs] [sj]
WHERE [sj].[category_id] IN ( SELECT [sc].[category_id]
FROM [dbo].[syscategories] [sc]
WHERE [sc].[name] LIKE 'REPL-Snapshot' )
AND sj.name LIKE '%MonitorReplication%'
EXEC [dbo].[sp_start_job] @job_name = @job_name

*/

--3


/*

--Run this on the server where publisher reside.
--This will create the job to update the timestamp on the publisher table every minute
/**********************************************************************
TO DO
**********************************************************************
1) Replace PublisherDBName with your publisher database name
*********************************************************************/
USE [msdb]
GO
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Data LifeCycle]' AND category_class=1)
BEGIN
 EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Data LifeCycle]'
 IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
 GOTO QuitWithRollback
END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode = msdb.dbo.sp_add_job @job_name=N'DBA UpdateReplicationMonitorTable',
  @enabled=1,
  @notify_level_eventlog=0,
  @notify_level_email=0,
  @notify_level_netsend=0,
  @notify_level_page=0,
  @delete_level=0,
  @description=N'No description available.',
  @category_name=N'[Data LifeCycle]',
  @owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
  EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'update time',
  @step_id=1,
  @cmdexec_success_code=0,
  @on_success_action=1,
  @on_success_step_id=0,
  @on_fail_action=2,
  @on_fail_step_id=0,
  @retry_attempts=0,
  @retry_interval=0,
  @os_run_priority=0, @subsystem=N'TSQL',
  @command=N'use PublisherDBName
  update dbo.PublisherTime
  SET Currenttime = GETDATE()
  Where FixedId=1
  go',
  @database_name=N'PublisherDBName',
  @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
  GOTO QuitWithRollback
  EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
  EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'every min',
  @enabled=1,
  @freq_type=4,
  @freq_interval=1,
  @freq_subday_type=4,
  @freq_subday_interval=1,
  @freq_relative_interval=0,
  @freq_recurrence_factor=0,
  @active_start_date=20140702,
  @active_end_date=99991231,
  @active_start_time=0,
  @active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
  GOTO QuitWithRollback
  EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
  COMMIT TRANSACTION
  GOTO EndSave
  QuitWithRollback:
IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
 EndSave:
GO

*/

--4

/*

--Once distribution agent apply the snapshot on subscriber side you run this on subscriber
USE [Subscription_database]
GO
SELECT @@servername AS [ServerName] ,
DB_NAME() AS [DataBase] ,
GETDATE() AS [CurrentTime] ,
Currenttime AS [ReplicationTime] ,
CONVERT (VARCHAR(10), DATEDIFF(mi, currenttime, getdate()) / 1440)
+ ':' + CONVERT (VARCHAR(10), ( DATEDIFF(mi, currenttime, getdate())
% 1440 ) / 60) + ':'
+ CONVERT (VARCHAR(10), ( DATEDIFF(mi, currenttime, getdate()) % 60 )) AS [LAG DD:HH:MM]
FROM PublisherTime

*/