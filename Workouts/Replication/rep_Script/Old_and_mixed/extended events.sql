--Monitoring subscription performance
--https://port1433.com/2017/03/08/monitoring-sql-server-replication-with-extended-events/#:~:text=More%20to%20the%20point%2C%20extended,you%20view%20and%20use%20it.

CREATE EVENT SESSION [Replica RPC Completed] ON SERVER 
ADD EVENT sqlserver.rpc_completed(SET collect_statement=(1)
    ACTION(sqlserver.database_name,sqlserver.nt_username,sqlserver.session_id)
    WHERE 
    (
        [sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name],N'AdventureWorks2019') 
        AND [sqlserver].[equal_i_sql_unicode_string]([sqlserver].[username],N'muthu\Svc_repl_distributer') )
    )
ADD TARGET package0.event_file(SET filename=N'Replica RPC Completed')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,
MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO


CREATE EVENT SESSION [Repl SP RPC Completed Filters] ON SERVER 
ADD EVENT sqlserver.rpc_completed(SET collect_statement=(1)
    ACTION(sqlserver.database_name,sqlserver.nt_username,sqlserver.session_id)
    WHERE 
    (
        [sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name],N'AdventureWorks2019') 
        AND [sqlserver].[equal_i_sql_unicode_string]([sqlserver].[username],N'muthu\Svc_repl_distributer') )
			AND
			(
			 [sqlserver].[like_i_sql_unicode_string]([statement],N'%sp_MSdel_%') 
            OR [sqlserver].[like_i_sql_unicode_string]([statement],N'%sp_MSins_%') 
            OR [sqlserver].[like_i_sql_unicode_string]([statement],N'%sp_MSupd_%')
			)

    )
ADD TARGET package0.event_file(SET filename=N'Replica RPC Completed')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,
MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO



--Distribution database performance
CREATE EVENT SESSION [Distribution Activity RPC] ON SERVER 
ADD EVENT sqlserver.rpc_completed(SET collect_statement=(1)
    ACTION(sqlserver.database_name,sqlserver.sql_text,sqlserver.username)
    WHERE ([sqlserver].[database_name]=N'distribution'))
ADD TARGET package0.event_file(SET filename=N'DistributionActivityRPC')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

CREATE EVENT SESSION [DistributionBlocking] ON SERVER 
ADD EVENT sqlserver.blocked_process_report(
    ACTION(sqlos.task_time,sqlserver.client_app_name,sqlserver.username))
ADD TARGET package0.event_file(SET filename=N'DistributionBlocking')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

CREATE EVENT SESSION [Distribution Wait Stats] ON SERVER 
ADD EVENT sqlos.wait_info(
    ACTION(sqlserver.database_name,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name],N'distribution') AND [package0].[greater_than_uint64]([duration],(200))))
ADD TARGET package0.event_file(SET filename=N'DistributionWaitStats')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

