/*
select * from msdb.dbo.sysjobs --where category_id =13
where name like 'HOMESQL%'
and name not like '%backup%'
and name not in (
'HOMESQL01\HOMESQL01-HDXDB-HDXDB_Replica-HDX-DR-SQL01-106',
'HOMESQL01\HOMESQL01-HDXDB-HDXDB-BI-HDX-DR-SQL01-103',
'HOMESQL01\HOMESQL01-HDXDB-HDXDB-DR-HDX-DR-SQL02-149',
'HOMESQL01\HOMESQL01-HDXDB-HOMESQL01_Local-HOMESQL01\HOMESQL01-171'
)


USE msdb ;  
GO  

EXEC dbo.sp_help_category  
    @type = N'LOCAL' ;  
GO  
*/
--https://techcommunity.microsoft.com/t5/sql-server-support-blog/how-to-find-sql-server-replication-related-jobs-and-t-sql/ba-p/1530496

-- distribution agent
use distribution---in distributor server

if not exists(select 1 from sys.tables where name ='MSreplservers')

begin

select job.name JobName,a.name AgentName, a.publisher_db,a.publication as publicationName,sp.name as publisherName ,ss.name as subscriber,a.subscriber_db, a.local_job From MSdistribution_agents a

inner join sys.servers sp on a.publisher_id=sp.server_id--publisher

inner join sys.servers ss on a.subscriber_id =ss.server_id--subscriber

left join msdb..sysjobs job on job.job_id=a.job_id

where a.subscription_type <>2--- filter out the anonymous subscriber

end

else

begin

select job.name JobName,a.name AgentName, a.publisher_db,a.publication as publicationName,sp.srvname as publisherName ,ss.srvname as subscriber,a.subscriber_db, a.local_job From MSdistribution_agents a

inner join msreplservers sp on a.publisher_id=sp.srvid--publisher

inner join msreplservers ss on a.subscriber_id =ss.srvid--subscriber

left join msdb..sysjobs job on job.job_id=a.job_id

where a.subscription_type <>2--- filter out the anonymous subscriber

end


-- snapshot agent
use distribution--in distributor server

if not exists(select 1 from sys.tables where name ='MSreplservers')

begin

select job.name JobName, a.name AgentName , publisher_db,publication, s.data_source as publisher,

case publication_type

when 0 then 'Transactional'

when 1 then 'snapshot'

when 2 then 'Merge'

end as publication_type

   From MSsnapshot_agents a inner join sys.servers s on a.publisher_id=s.server_id

   inner join msdb..sysjobs job on a.job_id=job.job_id

 

end

else

begin

select job.name JobName, a.name AgentName, publisher_db,publication, s.srvname as publisher,

case publication_type

when 0 then 'Transactional'

when 1 then 'snapshot'

when 2 then 'Merge'

end as publication_type

   From MSsnapshot_agents a inner join MSreplservers s on a.publisher_id=s.srvid

   inner join msdb..sysjobs job on a.job_id=job.job_id

end

--publisher



--- log reader agent
if not exists(select 1 from sys.tables where name ='MSreplservers')

begin

select job.name JobName, a.name AgentName, publisher_db,s.name as publisher

From MSlogreader_agents a inner join sys.servers s on a.publisher_id=s.server_id

Inner join msdb..sysjobs job on job.job_id=a.job_id

end

else

begin

select job.name JobName, a.name AgentName, publisher_db,s.srvname as publisher

From MSlogreader_agents a inner join MSreplservers s on a.publisher_id=s.srvid

Inner join msdb..sysjobs job on job.job_id=a.job_id

end


---
-- select  *  From MSdistribution_agents
