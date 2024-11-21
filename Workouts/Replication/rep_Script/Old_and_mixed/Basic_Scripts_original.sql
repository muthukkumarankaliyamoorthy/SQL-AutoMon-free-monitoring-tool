--Replication Monitor


SELECT publisher,
publisher_db,
publication_id,
CASE publication_type
    WHEN 0 then '0 - Transactional publication'
    WHEN 1 then '1 - Snapshot publication'
    WHEN 2 then '2 - Merge publication'
END AS publication_type_desc,
publication,
CASE agent_type
    WHEN 1 then '1 - Snapshot Agent'
    WHEN 2 then '2 - Log Reader Agent'
    WHEN 3 then '3 - Distribution Agent'
    WHEN 4 then '4 - Merge Agent'
    WHEN 9 then '9 - Queue Reader Agent'
END AS agent_type,
agent_name,
CASE status
    WHEN 1 THEN '1 - Started'
    WHEN 2 THEN '2 - Succeeded'
    WHEN 3 THEN '3 - In progress'
    WHEN 4 THEN '4 - Idle'
    WHEN 5 THEN '5 - Retrying'
    WHEN 6 THEN '6 - Failed'
END AS agent_status,
RIGHT('0' + CAST(cur_latency / 3600 AS VARCHAR),2) + ':' +
RIGHT('0' + CAST((cur_latency / 60) % 60 AS VARCHAR),2) + ':' +
RIGHT('0' + CAST(cur_latency % 60 AS VARCHAR),2) AS cur_latency,
RIGHT('0' + CAST(worst_latency / 3600 AS VARCHAR),2) + ':' +
RIGHT('0' + CAST((worst_latency / 60) % 60 AS VARCHAR),2) + ':' +
RIGHT('0' + CAST(worst_latency % 60 AS VARCHAR),2) AS max_latency,
RIGHT('0' + CAST(best_latency / 3600 AS VARCHAR),2) + ':' +
RIGHT('0' + CAST((best_latency / 60) % 60 AS VARCHAR),2) + ':' +
RIGHT('0' + CAST(best_latency % 60 AS VARCHAR),2) AS min_latency,
RIGHT('0' + CAST(avg_latency / 3600 AS VARCHAR),2) + ':' +
RIGHT('0' + CAST((avg_latency / 60) % 60 AS VARCHAR),2) + ':' +
RIGHT('0' + CAST(avg_latency % 60 AS VARCHAR),2) AS avg_latency,
last_distsync AS last_time_dist_agent_run,
isagentrunningnow AS is_agent_running_now, 
agentstoptime AS agent_stop_time,
CASE warning
    WHEN 1 THEN 'Expiration'
    WHEN 2 THEN 'Latency'
    WHEN 4 THEN 'Merge expiration '
    WHEN 16 THEN 'Merge slow run duration '
    WHEN 32 THEN 'Merge fast run speed '
    WHEN 64 THEN 'Merge slow run speed'
END AS warning,
CASE retention_period_unit
    WHEN 1 THEN CAST(retention AS VARCHAR)+' Week'
    WHEN 2 THEN CAST(retention AS VARCHAR)+' Month'
    WHEN 3 THEN CAST(retention AS VARCHAR)+' Year'
END AS pub_retention_period,
distdb AS distribution_db
FROM distribution.dbo.MSreplication_monitordata
WHERE publisher_db = 'your_publisher_db'
AND publication IN ('ALL','your_publication_name')
ORDER BY publisher, 
agent_type, 
publication

--Replication alerts



SELECT A.alert_id,
A.error_id,
A.time AS alert_time,
E.time AS error_time,
A.publisher,
A.publisher_db,
CASE A.publication_type 
    WHEN 0 THEN 'Snapshot'
    WHEN 1 THEN 'Transactional'
    WHEN 2 THEN 'Merge'
END AS publication_type_desc,
A.publication as publication_name,
A.subscriber,
A.subscriber_db,
A.article,
A.source_object,
A.destination_object,
E.error_text,
A.alert_error_text,
A.agent_id,
CASE A.agent_type 
    WHEN 1 THEN 'Snapshot Agent'
    WHEN 2 THEN 'Log Reader Agent'
    WHEN 3 THEN 'Distribution Agent'
    WHEN 4 THEN 'Merge Agent'
    ELSE 'Unknown'
END AS agent_type_desc,
COALESCE(S.name,L.name,D.name,M.name) AS agent_name,
E.session_id AS agent_session_id,
CASE status 
    WHEN 0 THEN 'Unserviced'
    WHEN 1 THEN 'serviced'
END AS status_desc
FROM msdb.dbo.sysreplicationalerts AS A
LEFT JOIN distribution.dbo.MSrepl_errors AS E ON A.error_id = E.id
LEFT JOIN distribution.dbo.MSsnapshot_agents AS S ON S.id = A.agent_id
LEFT JOIN distribution.dbo.MSlogreader_agents AS L ON L.id = A.agent_id
LEFT JOIN distribution.dbo.MSdistribution_agents AS D ON D.id = A.agent_id
LEFT JOIN distribution.dbo.MSmerge_agents AS M ON M.id = A.agent_id
WHERE A.time >= GETUTCDATE()-1
AND A.publisher_db = 'your_publisher_db_name'
AND A.publication = 'your_publication_name'
AND A.subscriber_db = 'your_subscriber_db_name'
ORDER BY A.alert_id DESC

--Undistributed commands

EXEC distribution.dbo.sp_replmonitorsubscriptionpendingcmds 
    @publisher = 'your_publisher_server_name', 
    @publisher_db = 'your_publisher_db_name', 
    @publication = N'your_publication_name',
    @subscriber = 'your_subscriber_server_name', 
    @subscriber_db = 'your_subscriber_db_name',
    @subscription_type = 1 -- 0=push subscription and 1=pull

--Undistributed commands for each table
SELECT  
p.name as publisher_server,
da.publisher_db,
s.name as subscriber_server,
da.subscriber_db,
da.publication as publication,
a.destination_object as table_name,
ds.DelivCmdsInDistDB as delivered_commands_in_distribution_db,
ds.UndelivCmdsInDistDB as undelivered_commands_in_distribution_db
FROM distribution.dbo.MSdistribution_status ds 
INNER JOIN distribution.dbo.MSdistribution_agents da ON da.id = ds.agent_id                          
INNER JOIN distribution.dbo.MSArticles a ON a.publisher_id = da.publisher_id AND a.publisher_db = da.publisher_db AND a.article_id = ds.article_id
INNER JOIN master.sys.servers  s ON s.server_id = da.subscriber_id 
INNER JOIN master.sys.servers  p ON p.server_id = da.publisher_id 
WHERE p.name = 'your_publisher_server_name'
AND s.name = 'your_subscriber_server_name'
AND da.publisher_db = 'your_publisher_db_name'
AND da.subscriber_db = 'your_subscriber_db_name'
AND ds.UndelivCmdsInDistDB <> 0
ORDER BY undelivered_commands_in_distribution_db DESC, 
table_name ASC

--Find replication errors in error log.
EXEC sys.sp_readerrorlog 0,1,'Replication','-'

--Agent History
SELECT H.time AS message_log_time,
H.agent_id,
A.name AS agent_name,
H.runstatus,
CASE runstatus 
    WHEN 1 THEN 'Start'
    WHEN 2 THEN 'Succeed'
    WHEN 3 THEN 'In progress'
    WHEN 4 THEN 'Idle'
    WHEN 5 THEN 'Retry'
    WHEN 6 THEN 'Fail'
END AS runstatus_desc,
H.start_time AS job_exec_start_time,
H.duration AS session_duration_in_sec,
H.comments AS message_text,
H.delivered_transactions AS transactions_delivered_in_session,
H.delivered_commands AS delivered_commands_per_sec,
H.delivery_rate AS delivery_rate_per_sec,
A.publisher_db,
A.publication,
H.error_id,
E.time AS error_time,
E.error_code,
E.error_text
FROM distribution.dbo.MSsnapshot_history AS H
INNER JOIN distribution.dbo.MSsnapshot_agents AS A ON H.agent_id = A.id
LEFT JOIN distribution.dbo.MSrepl_errors AS E ON E.id = H.error_id
WHERE H.time >= GETUTCDATE()-7
AND A.publisher_db = 'your_publisher_db_name'
ORDER BY message_log_time desc

--Get details about log reader agent history

SELECT H.time AS message_log_time,
H.agent_id,
A.name AS agent_name,
H.runstatus,
CASE runstatus 
    WHEN 1 THEN 'Start'
    WHEN 2 THEN 'Succeed'
    WHEN 3 THEN 'In progress'
    WHEN 4 THEN 'Idle'
    WHEN 5 THEN 'Retry'
    WHEN 6 THEN 'Fail'
END AS runstatus_desc,
H.start_time AS job_exec_start_time,
H.duration AS session_duration_in_sec,
H.comments AS message_text,
H.delivered_transactions AS transactions_delivered_in_session,
H.delivered_commands AS delivered_commands_per_sec,
H.delivery_rate AS delivery_rate_per_sec,
A.publisher_db,
A.publication,
H.error_id,
E.time AS error_time,
E.error_code,
E.error_text
FROM distribution.dbo.MSlogreader_history AS H
INNER JOIN distribution.dbo.MSlogreader_agents AS A ON H.agent_id = A.id
LEFT JOIN distribution.dbo.MSrepl_errors AS E ON E.id = H.error_id
WHERE H.time >= GETUTCDATE()-7
AND A.publisher_db = 'your_publisher_db_name'
ORDER BY message_log_time desc

--Get details about distribution agent history
SELECT H.time AS message_log_time,
H.agent_id,
A.name AS agent_name,
H.runstatus,
CASE runstatus 
    WHEN 1 THEN 'Start'
    WHEN 2 THEN 'Succeed'
    WHEN 3 THEN 'In progress'
    WHEN 4 THEN 'Idle'
    WHEN 5 THEN 'Retry'
    WHEN 6 THEN 'Fail'
END AS runstatus_desc,
H.start_time AS job_exec_start_time,
H.duration AS session_duration_in_sec,
H.comments AS message_text,
H.current_delivery_rate AS current_delivery_rate_per_sec,
H.current_delivery_latency/1000  AS current_delivery_latency_in_sec,
H.delivery_rate AS delivery_rate_per_sec,
H.delivery_latency/1000 AS delivery_latency_in_sec,
H.delivered_transactions AS transactions_delivered_in_session,
H.delivered_commands AS commands_delivered_in_session,
H.average_commands AS average_commands_in_session,
H.total_delivered_commands, --total commands delivered since subscription was created
A.publisher_db,
A.publication,
A.subscriber_db,
H.error_id,
E.time AS error_time,
E.error_code,
E.error_text
FROM distribution.dbo.MSdistribution_history AS H
INNER JOIN distribution.dbo.MSdistribution_agents AS A ON H.agent_id = A.id
LEFT JOIN distribution.dbo.MSrepl_errors AS E ON E.id = H.error_id
WHERE H.time >= GETUTCDATE()-2
AND A.publisher_db = 'your_publisher_db_name'
AND A.publication = 'your_publiication_name'
AND A.subscriber_db = 'your_subscriber_db_name'
ORDER BY message_log_time desc

--Agents Detail
SELECT *, 
CASE publication_type 
    WHEN 0 THEN 'Transactional'
    WHEN 1 THEN 'Snapshot'
    WHEN 2 THEN 'Merge'
END AS publication_type_desc,
CASE publisher_security_mode 
    WHEN 0 THEN 'Microsoft SQL Server Authentication'
    WHEN 1 THEN 'Microsoft Windows Authentication'
END AS publisher_security_mode_desc
FROM distribution.dbo.MSsnapshot_agents
WHERE publisher_db = 'your_publisher_db_name'
AND publication = 'your_publication_name'
ORDER BY id

--Get details about log reader agents
SELECT *, 
CASE publisher_security_mode 
    WHEN 0 THEN 'Microsoft SQL Server Authentication'
    WHEN 1 THEN 'Microsoft Windows Authentication'
END AS publisher_security_mode_desc
FROM distribution.dbo.MSlogreader_agents
WHERE publisher_db = 'your_publisher_db_name'
ORDER BY id

--Get details about distribution agents
SELECT * ,
CASE subscription_type 
    WHEN 0 THEN 'Push'
    WHEN 1 THEN 'Pull'
    WHEN 2 THEN 'Anonymous'
END AS subscription_type_desc
FROM distribution.dbo.MSdistribution_agents
WHERE publisher_db = 'your_publisher_db_name'
AND publication = 'your_publication_name'
AND subscriber_db = 'your_subscriber_db_name'
ORDER BY id

--Get details about merge agents
SELECT *, 
CASE publisher_security_mode 
    WHEN 0 THEN 'Microsoft SQL Server Authentication'
    WHEN 1 THEN 'Microsoft Windows Authentication'
END AS publisher_security_mode_desc,
CASE subscriber_security_mode 
    WHEN 0 THEN 'Microsoft SQL Server Authentication'
    WHEN 1 THEN 'Microsoft Windows Authentication'
END AS subscriber_security_mode_desc
FROM distribution.dbo.MSmerge_agents
WHERE publisher_db = 'your_publisher_db_name'
AND publication = 'your_publication_name'
ORDER BY id
--Get details about Q-reader agents
SELECT * 
FROM distribution.dbo.MSqreader_agents

--Get details about the agent profiles
SELECT profile_id,
profile_name,
agent_type,
CASE agent_type 
    WHEN 1 THEN 'Snapshot Agent'
    WHEN 2 THEN 'Log Reader Agent'
    WHEN 3 THEN 'Distribution Agent'
    WHEN 4 THEN 'Merge Agent'
    WHEN 9 THEN 'Queue Reader Agent'
END AS agent_type_desc,
type AS profile_type,
CASE type 
    WHEN 0 THEN 'System'
    WHEN 1 THEN 'Custom'
END AS profile_type_desc,
def_profile AS is_default_profile
FROM msdb.dbo.MSagent_profiles
ORDER BY agent_type

--Publisher Detail
SELECT id, 
publisher_id, 
publisher_db, 
publisher_engine_edition, 
CASE publisher_engine_edition 
    WHEN 10 THEN 'Personal Edition' 
    WHEN 11 THEN 'Desktop Engine (MSDE)' 
    WHEN 20 THEN 'Standard' 
    WHEN 21 THEN 'Workgroup' 
    WHEN 30 THEN 'Enterprise (Evaluation)' 
    WHEN 31 THEN 'Developer' 
    ELSE 'Express'
END AS publisher_engine_edition_name
FROM distribution.dbo.MSpublisher_databases
ORDER BY id

--Subscriber Detail
-- Execute in Publisher Server
EXEC sp_helpsubscriberinfo;

--Get subscription details
USE your_publisher_db;
EXEC sp_helpsubscription;
--Get subscriber schedule details

SELECT 
publisher,
subscriber,
CASE agent_type 
    WHEN 0 THEN '0 = Distribution Agent'
    WHEN 1 THEN '1 = Merge Agent'
END AS agent_type,
frequency_interval,
CASE frequency_type 
    WHEN 1 THEN '1 = One time.'
    WHEN 2 THEN '2 = On demand.'
    WHEN 4 THEN '4 = Daily.'
    WHEN 8 THEN '8 = Weekly.'
    WHEN 16 THEN '16 = Monthly.'
    WHEN 32 THEN '32 = Monthly relative.'
    WHEN 64 THEN '64 = Autostart.'
    WHEN 128 THEN '128 = Recurring.'
END AS frequency_type,
--frequency_relative_interval,
--frequency_recurrence_factor,
frequency_subday_interval,
CASE frequency_subday 
    WHEN 1 THEN '1 = Once.'
    WHEN 2 THEN '2 = Second.'
    WHEN 4 THEN '4 = Minute.'
    WHEN 8 THEN '8 = Hour.'
END AS frequency_subday,
active_start_date,
active_start_time_of_day,
active_end_date,
active_end_time_of_day 
FROM distribution.dbo.MSsubscriber_schedule

--How to find which command has failed in SQL Server Replication?
SELECT top 1 
entry_time AS trans_entry_time_in_dist_db,
publisher_database_id,
xact_id,
xact_seqno
FROM distribution.dbo.MSrepl_transactions
ORDER BY entry_time DESC

EXEC distribution.dbo.sp_browsereplcmds 
@xact_seqno_start = '0x0005B68700176AEC000C' 
--replace the xact_seqno from the previous query

