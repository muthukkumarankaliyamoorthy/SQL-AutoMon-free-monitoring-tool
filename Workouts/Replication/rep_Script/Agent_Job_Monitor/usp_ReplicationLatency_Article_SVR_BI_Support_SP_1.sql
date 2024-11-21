USE [DBAUtil]
GO

/****** Object:  StoredProcedure [dbo].[usp_ReplicationLatency_Article_SVR_BI]    Script Date: 2/2/2024 4:07:36 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*

create table Tbl_ReplicationLatency_Each_article
(
cur_latency numeric(9,2),
publisher varchar(50),
publisher_db varchar(50),
publication varchar(50),
article varchar(100),
subscriber varchar(50),
subscriber_db varchar(50),
UndelivCmdsInDistDB varchar(50),
agent_status varchar(15),
schedule varchar(100)
)

select * from Tbl_ReplicationLatency_Each_article where UndelivCmdsInDistDB>0

*/
--drop proc[usp_ReplicationLatency_All]

CREATE procedure [dbo].[usp_ReplicationLatency_Article_SVR_BI]
as
begin
set nocount on

truncate table Tbl_ReplicationLatency_Each_article

set transaction isolation level read uncommitted

declare @distdbname varchar(100)
declare @sql varchar(8000)

set @distdbname = ''


while exists( select top 1 name from sys.databases where is_distributor = 1 and name > @distdbname )
begin

select top 1 @distdbname = name from sys.databases where is_distributor = 1 and name > @distdbname

insert into Tbl_ReplicationLatency_Each_article
--set @sql =
exec ('select
convert(numeric(9,2),cur_latency/60.00),
s.srvname,
d.publisher_db,
d.publication,
b.article as article,
c.srvname,
a.subscriber_db,
isnull(UndelivCmdsInDistDB,0),
case mrm.status when 1 then ''Started''
when 2 then ''Succeeded''
when 3 then ''In progress''
when 4 then ''Idle''
when 5 then ''Retrying''
when 6 then ''Failed''
end as agent_status,

case when msdb.dbo.udf_schedule_description(sc.freq_type,sc.freq_interval,sc.freq_subday_type,sc.freq_subday_interval,sc.freq_relative_interval,sc.freq_recurrence_factor,sc.active_start_date,sc.active_end_date,sc.active_start_time,sc.active_end_time) = ''Automatically starts when SQLServerAgent starts.''
then ''Continuous'' else msdb.dbo.udf_schedule_description(sc.freq_type,sc.freq_interval,sc.freq_subday_type,sc.freq_subday_interval,sc.freq_relative_interval,sc.freq_recurrence_factor,sc.active_start_date,sc.active_end_date,sc.active_start_time,sc.active_end_time) end as schedule
FROM ' + @distdbname + '.dbo.MSsubscriptions a with (nolock)
inner join ' + @distdbname + '.dbo.MSarticles b with (nolock)
on a.publication_id=b.publication_id and a.article_id =b.article_id
inner join master..sysservers c with(nolock) on a.subscriber_id=c.srvid
inner join master..sysservers s with (nolock) on a.publisher_id = s.srvid
inner join ' + @distdbname + '.dbo.MSpublications d with (nolock) on a.publication_id = d.publication_id
left outer join ' + @distdbname + '.dbo.MSdistribution_agents mdm
on d.publication = mdm.publication
and mdm.subscriber_id = c.srvid
left outer join ' + @distdbname + '.dbo.MSdistribution_status mds
on mds.article_id = b.article_id
and mds.agent_id = mdm.id
left outer join ' + @distdbname + '.dbo.MSreplication_monitordata mrm
on mrm.agent_id = a.agent_id
join msdb.dbo.sysjobs j
on j.name = mrm.agent_name
join msdb.dbo.sysjobschedules sjc
on sjc.job_id = j.job_id
join msdb.dbo.sysschedules sc
on sc.schedule_id = sjc.schedule_id
where mrm.agent_type = 3
--and convert(numeric(9,2),cur_latency/60.00) > 30
--and isnull(UndelivCmdsInDistDB,0) > 500
')


--print @sql


end

/*
if (select count(1) from Tbl_ReplicationLatency_Each_article where Agent_status != 'Succeeded') > 0
begin

DECLARE @tableHTML NVARCHAR(MAX) ,
@subj varchar(100)
SET @tableHTML =
N'Replication Latency Report' +
N'' +
N'Please investigate on the below Replication for High Latency !!!'+
N'Distribution Server: ' + @@SERVERNAME + N'' +
N'' +
N'' +
N'Latency Mins'+
N'PublisherPublisher_DBPublicationArticleSubscriberSubscriber_dbUndelievered' +

N'DistributorStatus
DistributionSchedule
' +
CAST ( (select
td= cast( convert(numeric(9,2),cur_latency) as varchar(10)),'',
td= cast(publisher as varchar(50)),'',
td= cast(publisher_db as varchar(50)),'',
td= cast(publication as varchar(50)),'',
td= cast(article as varchar(100)),'',
td= cast(subscriber as varchar(50)),'',
td= cast(subscriber_db as varchar(50)),'',
td= cast(isnull(UndelivCmdsInDistDB,0) as varchar(50)),'',
td = cast(agent_status as varchar(50)), '',

td = cast(schedule as varchar(50))

FROM Tbl_ReplicationLatency_Each_article
where Agent_status != 'Succeeded'
order by publisher, publisher_db, cur_latency desc, publication,subscriber

FOR XML PATH('tr'), TYPE
) AS NVARCHAR(MAX) ) +
N'' --+



/*
SET @subj = 'Replication Latency Report ' + @@servername

EXEC msdb.dbo.sp_send_dbmail
@profile_name = '',
@recipients = '',
-- @query = N'select @@servername as DISTRIBUTION_SERVER',
@subject = @subj,
@body = @tableHTML,
@body_format = 'HTML'
*/
end

select * from Tbl_ReplicationLatency_Each_article

*/

end

GO


