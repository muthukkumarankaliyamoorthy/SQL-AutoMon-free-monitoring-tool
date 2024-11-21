SELECT DISTINCT 
       PublisherDB,
       PublisherName,
       SubscriberServerName,
       SubscriberDBName
       FROM (
                select  
                db_name() PublisherDB 
                , sp.name as PublisherName 
                , sa.name as TableName 
                , UPPER(srv.srvname) as SubscriberServerName 
                , s.dest_db as SubscriberDBName
                from dbo.syspublications sp  
                join dbo.sysarticles sa on sp.pubid = sa.pubid 
                join dbo.syssubscriptions s on sa.artid = s.artid 
                join master.dbo.sysservers srv on s.srvid = srv.srvid 
             ) R

--
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

IF EXISTS (SELECT 1 FROM master..sysdatabases WHERE name = 'Distribution')
BEGIN
	-- Get the publication name based on article 
	SELECT DISTINCT  
		 p.publication								AS Publication_Name
		,srv.srvname								AS Publication_Server  
		,a.publisher_db								AS Publication_Database
		,a.article									AS Publication_Table_Name
		,a. article_id								AS Publication_Article_ID
		,ss.srvname									AS Subscription_Server  
		,s.subscriber_db							AS Subscription_Database
		,a.destination_object 						AS Subscription_Table_Name
		,da.subscriber_login				 		AS Subscription_Login
		,da.name							 		AS Distribution_Agent_Job_Name
	FROM Distribution..MSArticles a  
	JOIN Distribution..MSpublications p 
		ON a.publication_id = p.publication_id 
	JOIN Distribution..MSsubscriptions s 
		ON p.publication_id = s.publication_id 
	JOIN master..sysservers ss 
		ON s.subscriber_id = ss.srvid 
	JOIN master..sysservers srv 
		ON srv.srvid = p.publisher_id 
	JOIN Distribution..MSdistribution_agents da 
		ON da.publisher_id = p.publisher_id  
		AND da.subscriber_id = s.subscriber_id 
	--where a.article like 'Home Dynamix, LLC_$Customer'
	where p.publication ='HDXDB-DR'
	order by a.article
END


--
--Script to run on Distribution database

--This script returns completed setup replication information. 
--Unless an orphan article exists, this will return a complete set of replication information. 
--I also added the distribution agent job name to show how easy it is to pull in 
--other configuration information. I recommend making this a stored procedure and 
--then creating a Reporting Services report, so that anyone can easily access this data.

 
USE Distribution 
GO 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
-- Get the publication name based on article 
SELECT DISTINCT  
srv.srvname publication_server  
, a.publisher_db 
, p.publication publication_name 
, a.article 
, a.destination_object 
, ss.srvname subscription_server 
, s.subscriber_db 
, da.name AS distribution_agent_job_name 
FROM MSArticles a  
JOIN MSpublications p ON a.publication_id = p.publication_id 
JOIN MSsubscriptions s ON p.publication_id = s.publication_id 
JOIN master..sysservers ss ON s.subscriber_id = ss.srvid 
JOIN master..sysservers srv ON srv.srvid = p.publisher_id 
JOIN MSdistribution_agents da ON da.publisher_id = p.publisher_id  
     AND da.subscriber_id = s.subscriber_id 
ORDER BY 1,2,3  



--Script to run on Publisher database
--
--This script returns what publications have been setup. 
--This will go through all the published databases and return information 
--if the database has replication enabled. Sometimes, I just want to see the publication 
--name and subscriber server names (no articles) to see what servers are being used with 
--replication other times I want all of the information, so I added a variable called @Detail 
--and if you set @Detail = 'Y' it will return data with the article list. Any other value will 
--only return the publisherDB, publisherName and SubscriberServerName

-- Run from Publisher Database  
-- Get information for all databases 
DECLARE @Detail CHAR(1) 
SET @Detail = 'Y' 
CREATE TABLE #tmp_replcationInfo ( 
PublisherDB VARCHAR(128),  
PublisherName VARCHAR(128), 
TableName VARCHAR(128), 
SubscriberServerName VARCHAR(128), 
) 
EXEC sp_msforeachdb  
'use ?; 
IF DATABASEPROPERTYEX ( db_name() , ''IsPublished'' ) = 1 
insert into #tmp_replcationInfo 
select  
db_name() PublisherDB 
, sp.name as PublisherName 
, sa.name as TableName 
, UPPER(srv.srvname) as SubscriberServerName 
from dbo.syspublications sp  
join dbo.sysarticles sa on sp.pubid = sa.pubid 
join dbo.syssubscriptions s on sa.artid = s.artid 
join master.dbo.sysservers srv on s.srvid = srv.srvid 
' 
IF @Detail = 'Y' 
   SELECT * FROM #tmp_replcationInfo 
ELSE 
SELECT DISTINCT  
PublisherDB 
,PublisherName 
,SubscriberServerName  
FROM #tmp_replcationInfo 
DROP TABLE #tmp_replcationInfo 

 


--Script to run on Subscriber database
--
--This script returns what article(s) is/are being replicated to the 
--subscriber database. I also use this to find orphaned subscribers. 
--This is rather simple since there is not much information to pull.

-- Run from Subscriber Database 
SELECT distinct publisher, publisher_db, publication
FROM dbo.MSreplication_subscriptions
ORDER BY 1,2,3