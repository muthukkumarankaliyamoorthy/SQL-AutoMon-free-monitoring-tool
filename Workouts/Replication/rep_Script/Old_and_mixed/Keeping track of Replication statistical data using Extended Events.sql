-- Replication speed monitoring -- By: SQL Service, Steinar Andersen -- Created: 2012-09-18

-- Part 1: Create objects for data collection, in master database

-- Create Results table, wich will hold the data collected via Extended Events

USE [master]

GO

IF EXISTS ( SELECT  *             FROM    dbo.sysobjects             WHERE   id = OBJECT_ID(N'[DF_repl_stats_history_last_updated]')                     AND type = 'D' )    

BEGIN        

ALTER TABLE [dbo].[repl_stats_history] DROP CONSTRAINT [DF_repl_stats_history_last_updated]    

END

GO

USE [master]

GO

IF EXISTS ( SELECT  *             FROM    sys.objects             WHERE   object_id = OBJECT_ID(N'[dbo].[repl_stats_history]')                     AND type IN ( N'U' ) )    

DROP TABLE [dbo].[repl_stats_history]

GO

USE [master]

GO

CREATE TABLE [dbo].[repl_stats_history]    

(       [JobName] [varchar](150) NULL ,      

[EventCount] [int] NULL ,      

[EventsTrunc] [int] NULL ,      

[last_updated] [datetime] NULL    

 )

ON  [PRIMARY]

GO

ALTER TABLE [dbo].[repl_stats_history]

ADD  CONSTRAINT [DF_repl_stats_history_last_updated]  DEFAULT (GETDATE()) FOR [last_updated]

GO

USE [master]

GO

IF EXISTS ( SELECT  *             FROM    sys.indexes            

WHERE   object_id = OBJECT_ID(N'[dbo].[repl_stats_history]')                    

AND name = N'Idx_Last_Updated' )    

DROP INDEX [Idx_Last_Updated] ON [dbo].[repl_stats_history] WITH ( ONLINE = OFF ) GO

USE [master]

GO

CREATE CLUSTERED INDEX [Idx_Last_Updated] ON [dbo].[repl_stats_history]

( [last_updated] ASC, [JobName] ASC )

WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF,

DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]

 GO

 

-- Create an Event Session to Track RPC Completed per Client App Name

IF EXISTS ( SELECT  *             FROM    sys.server_event_sessions             WHERE   name = 'Repl_Stats' )    

DROP EVENT SESSION [Repl_Stats] ON SERVER;

CREATE EVENT SESSION [Repl_Stats] ON SERVER

ADD EVENT sqlserver. rpc_completed -- Count RPC Completed, as Replication uses Stored Procedures to make changes at the Subscriber. One SP will be fired per row changed, so the count of SP's run will equal number of rows impacted    

 ( ACTION ( sqlserver. client_app_name )

--WHERE (sqlserver.client_app_name = 'Microsoft SQL Server Management Studio -- Query')

--The Client Application name or names that you want to monitor. Replication will use one SQL Serve Agent Job for each replication article subscription. The Client App Name here is obviously just an example. )

ADD TARGET package0. asynchronous_bucketizer --Target=Bucket, as we only want to store the number of times the event is fired    

 ( SET source_type=1,          source='sqlserver.client_app_name' --Group events fired by Client App Name )

WITH ( MAX_DISPATCH_LATENCY = 5 SECONDS )

GO

-- Create proc to save stats and recycle counter.

IF EXISTS ( SELECT  *             FROM    sys.objects            

WHERE   object_id = OBJECT_ID(N'[dbo].[save_repl_stats]')                    

AND type IN ( N'P' ) )    

DROP PROC [dbo].[save_repl_stats]

GO

CREATE PROC dbo.save_repl_stats

AS    

BEGIN        

SET ANSI_PADDING ON        

INSERT  INTO master.dbo.repl_stats_history                

( JobName ,                  

EventCount ,                  

EventsTrunc                 ) --Insert data into history table                

 SELECT  ( n.value('(value)[1]', 'varchar(max)') ) AS JobName , 

n.value('(@count)[1]', 'int') AS EventCount ,

n.value('(@trunc)[1]', 'int') AS EventsTrunc 

FROM   

( SELECT    CAST(target_data AS XML) target_data 

FROM      sys.dm_xe_sessions AS s  

JOIN sys.dm_xe_session_targets t ON s.address = t.event_session_address

WHERE     s.name = 'Repl_Stats'

AND t.target_name = 'asynchronous_bucketizer'  )

AS tab                        

CROSS APPLY target_data.nodes('BucketizerTarget/Slot') AS q ( n )

ALTER EVENT SESSION [Repl_Stats] -- Stop EE session to zero out the values        

ON SERVER        

STATE=STOP

ALTER EVENT SESSION [Repl_Stats] -- Start EE session to start collecting values again        

ON SERVER        

STATE=START

END

go

-- Schedule data collection proc as job to run every 5 minutes. -- This job will fail the first time only, because the EE session is not started. Pay no attention to that! 😉

USE [msdb]

GO

IF EXISTS ( SELECT  job_id             FROM    msdb.dbo.sysjobs_view             WHERE   name = N'Collect Replication Statistics' )     EXEC msdb.dbo.sp_delete_job @job_id = N'9f703264-a99b-4285-9688-856a3031baf1′,         @delete_unused_schedule = 1 GO

USE [msdb]

GO

BEGIN TRANSACTION DECLARE @ReturnCode INT SELECT  @ReturnCode = 0

DECLARE @jobId BINARY(16) EXEC @ReturnCode = msdb.dbo.sp_add_job @job_name = N'Collect Replication Statistics',     @enabled = 1, @notify_level_eventlog = 0, @notify_level_email = 0,     @notify_level_netsend = 0, @notify_level_page = 0, @delete_level = 0,     @description = N'Uses Extended events to collect SQL Server Replication Statistics every 5 minutes                                                                                      Usage: exec master.dbo.get_repl_stats ”<jobname>”',     @category_name = N'[Uncategorized (Local)]', @owner_login_name = N'sa',     @job_id = @jobId OUTPUT IF ( @@ERROR <> 0      OR @ReturnCode <> 0    )     GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @jobId,     @step_name = N'Save Replication Statistics', @step_id = 1,     @cmdexec_success_code = 0, @on_success_action = 1, @on_success_step_id = 0,     @on_fail_action = 2, @on_fail_step_id = 0, @retry_attempts = 0,     @retry_interval = 0, @os_run_priority = 0, @subsystem = N'TSQL',     @command = N'exec dbo.save_repl_stats', @database_name = N'master',     @flags = 0 IF ( @@ERROR <> 0      OR @ReturnCode <> 0    )     GOTO QuitWithRollback EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1 IF ( @@ERROR <> 0      OR @ReturnCode <> 0    )     GOTO QuitWithRollback EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id = @jobId,     @name = N'Repl_Stats', @enabled = 1, @freq_type = 4, @freq_interval = 1,     @freq_subday_type = 4, @freq_subday_interval = 5,     @freq_relative_interval = 0, @freq_recurrence_factor = 0,     @active_start_date = 20120917, @active_end_date = 99991231,     @active_start_time = 0, @active_end_time = 235959,     @schedule_uid = N'90561def-ba8e-4339-b5f4-8cbf605408b1′ IF ( @@ERROR <> 0      OR @ReturnCode <> 0    )     GOTO QuitWithRollback EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId,     @server_name = N'(local)' IF ( @@ERROR <> 0      OR @ReturnCode <> 0    )     GOTO QuitWithRollback COMMIT TRANSACTION GOTO EndSave QuitWithRollback: IF ( @@TRANCOUNT > 0 )     ROLLBACK TRANSACTION EndSave:

GO

 

-- Part 2: Create objects to retrive data USE [master]

-- Create proc to get repl stats data -- Usage: exec master.dbo.get_repl_stats '<jobname>'

IF EXISTS

( SELECT  *   FROM    sys.objects            

WHERE   object_id = OBJECT_ID(N'[dbo].[get_repl_stats]')                    

AND type IN ( N'P' ) )    

DROP PROC [dbo].[get_repl_stats]

GO

CREATE PROC dbo.get_repl_stats @jobname VARCHAR(150)

 AS    

BEGIN        

SELECT TOP 1   ISNULL(eventcount, 0) AS ReturnValue        

FROM    master.[dbo].[repl_stats_history]        

WHERE   JobName = @jobname                

AND last_updated > DATEADD(minute, -5, GETDATE())        

ORDER BY last_updated DESC     END

 

GO

--The End!

