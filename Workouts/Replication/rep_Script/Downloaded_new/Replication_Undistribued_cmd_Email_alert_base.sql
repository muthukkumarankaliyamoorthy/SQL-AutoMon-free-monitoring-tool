
/*
EXEC sp_configure 'show advanced options', 1
RECONFIGURE WITH OVERRIDE
GO
EXEC sp_configure 'ad hoc distributed queries', 1
RECONFIGURE WITH OVERRIDE
GO

Create TABLE DBAUtil.dbo.TBL_temp_sub2_UnDist_CMD ( publisher SYSNAME , publisher_db SYSNAME, publication SYSNAME, subscriber SYSNAME, subscriber_db SYSNAME, Pending_Commands int , time_to_deliver_pending_Commands int)

select * from DBAUtil.dbo.TBL_temp_sub2_UnDist_CMD
select * from DBAUtil.dbo.TBL_temp_sub2_UnDist_CMD_all

*/


Use DBAUtil;
GO
Set NOCOUNT ON;
GO

alter proc USP_Repl_Undistriuted_cmd
as
truncate table DBAUtil.dbo.TBL_temp_sub2_UnDist_CMD
truncate table DBAUtil.dbo.TBL_temp_sub2_UnDist_CMD_all


begin
DECLARE @publisher SYSNAME, @publisher_db SYSNAME,@publication SYSNAME,@subscriber SYSNAME,@subscriber_db SYSNAME

IF object_id('tempdb..#tempsub2') is not null

DROP TABLE #tempsub2

IF object_id('tempdb..#tempsub1') is not null

DROP TABLE #tempsub1

Create TABLE #tempsub2 ( publisher SYSNAME , publisher_db SYSNAME, publication SYSNAME, subscriber SYSNAME, subscriber_db SYSNAME, Pending_Commands int , time_to_deliver_pending_Commands int)



SELECT
sub3.publisher
,sub1.publisher_db
,sub1.publication
,CASE 
when sub1.publication ='HDXDB-BI' then UPPER ('hdx-dr-sql01') 
when sub1.publication ='HDXDB_Replica' then UPPER ('hdx-dr-sql01') 
when sub1.publication ='HDXDB-DR' then UPPER ('hdx-dr-sql02') 
when sub1.publication ='HOMESQL01_Local' then UPPER ('HOMESQL01\HOMESQL01') 
ELSE UPPER ('Find out') END 'Subscriber' -- pass subscriber name

,sub1.subscriber_db
,Sub1.job_id,sub1.id
,subscription_type
,sub1.name
into #tempsub1
FROM
(
SELECT * FROM distribution..msdistribution_agents agents
Where subscriber_db not in ('virtual') -- Don't retrieve Virtual subscriptions
and anonymous_subid is null -- Don't retrieve anonymous subscriptions
) sub1
Inner join
(
SELECT
publisher
,publisher_db
,publication
,publication_type
,agent_name
,publisher_srvid
,job_id
FROM distribution..MSreplication_monitordata
WHERE publication_id is not null
AND agent_type = 3 -- Distribution agent
)sub3

on sub1.publisher_id = sub3.publisher_srvid
and cast(sub1.job_id as uniqueidentifier) = sub3.job_id
and sub1.publisher_db=sub3.publisher_db
and sub1.publication= sub3.publication
and sub1.subscription_type=sub3.publication_type
and sub1.name =sub3.agent_name
join master.sys.servers as srv
on srv.server_id = sub1.subscriber_id

DECLARE subscribers cursor for SELECT publisher, publisher_db ,publication ,subscriber ,subscriber_db from #tempsub1

OPEN subscribers FETCH NEXT FROM subscribers INTO @publisher, @publisher_db ,@publication ,@subscriber ,@subscriber_db

WHILE @@FETCH_STATUS = 0 BEGIN

INSERT into #tempsub2

EXEC
(
'
SELECT '''+ @publisher +''' , '''+ @publisher_db +''' ,'''+ @publication + ''' , ''' + @subscriber + ''' , ''' + @subscriber_db + ''' ,*
FROM OPENROWSET (''SQLOLEDB'',''Server=HOMESQL01\HOMESQL01;TRUSTED_CONNECTION=YES;'',''set fmtonly off EXEC distribution..sp_replmonitorsubscriptionpENDingcmds @publisher= '''''+ @publisher +''''' ,@subscription_type=0, @publisher_db= '''''+ @publisher_db +''''',@publication = '''''+ @publication+''''',@subscriber= '''''+@subscriber+''''' ,@subscriber_db='''''+@subscriber_db+''''''')
'
)
--select * from sys.sysservers
FETCH NEXT FROM subscribers INTO @publisher,@publisher_db ,@publication ,@subscriber ,@subscriber_db

END

CLOSE subscribers DEALLOCATE subscribers

 insert into DBAUtil.dbo.TBL_temp_sub2_UnDist_CMD
 select * from #tempsub2

--/*
 insert into DBAUtil.dbo.TBL_temp_sub2_UnDist_CMD_all
SELECT
Pending_commands.*
,comment.comments
,comment.delivery_latency 'Delivery_latency MSs'
,comment.time 'Time of message'
,CASE comment.runstatus

when 1 then 'Started'

when 2 then 'Succeeded'

when 3 then 'In progress'

when 4 then 'Idle'

when 5 then 'Retrying'

when 6 then 'Failed ' END status ,

CASE Info.subscription_type When 0 then 'Push' When 1 then 'Pull' When 2 then 'Anonymous' END 'Subscription Type'
,Info.name 'Distribution agent name'
,jobs.name 'Distribution_agent_job'


FROM

#tempsub1 Info

inner join

#tempsub2 PENDing_commands

on Info.publisher_db = PENDing_commands.publisher_db
and Info.publication = PENDing_commands.publication
and Info.subscriber = PENDing_commands.subscriber
and Info.subscriber_db = PENDing_commands.subscriber_db

left outer join msdb..sysjobs jobs

on Info.job_id=jobs.job_id

inner join
(
SELECT time, agent_id ,runstatus,delivery_latency, comments,row_number() over ( partition by agent_id order by time desc ) as pos

FROM distribution..MSdistribution_history
)comment

on comment.agent_id = Info.id

where comment.pos =1 ;

--*/
DROP TABLE #tempsub1 ;
-- email alert



end
