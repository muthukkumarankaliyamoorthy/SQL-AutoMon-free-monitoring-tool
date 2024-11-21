
/*


create table Tbl_ReplicationLatency_Each_article_Local
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


USE [DBAUtil]
GO
create table Tbl_ReplicationLatency_Each_article_Archive
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
schedule varchar(100),
upload_date datetime
)

*/
	

use DBAUtil
go
-- Exec [usp_ReplicationLatency_Article_SVR_BI] @lag_Time_Article=0.04,@UndelivCmdsInDistDB = 0
-- select * from  [REPL_HOMESQL01\HOMESQL01].[DBAUtil].[dbo].Tbl_ReplicationLatency_Each_article where cur_latency >= 0.03 and UndelivCmdsInDistDB> 0

ALTER PROC [USP_REPLICATIONLATENCY_ARTICLE_SVR_BI]
(@lag_Time_Article numeric(9,2),@UndelivCmdsInDistDB varchar(50))
as
begin

truncate table Tbl_ReplicationLatency_Each_article_Local

Exec [REPL_HOMESQL01\HOMESQL01].DBAUtil.DBO.[usp_ReplicationLatency_Article_SVR_BI]

/* 

Declare @lag_Time_Article numeric(9,2),@UndelivCmdsInDistDB varchar(50)

select * from  [REPL_HOMESQL01\HOMESQL01].[DBAUtil].[dbo].Tbl_ReplicationLatency_Each_article
where cur_latency >=0.04  and UndelivCmdsInDistDB >0
--and publication<>'HDXDB-DR'

*/

insert into Tbl_ReplicationLatency_Each_article_Local
select * from  [REPL_HOMESQL01\HOMESQL01].[DBAUtil].[dbo].Tbl_ReplicationLatency_Each_article
 where  cur_latency >= @lag_Time_Article and UndelivCmdsInDistDB> @UndelivCmdsInDistDB
and publication<>'HDXDB-DR'

---- send an excel
 

IF EXISTS(
select * from  [DBAUtil].[dbo].Tbl_ReplicationLatency_Each_article_Local where  cur_latency >= @lag_Time_Article 
and UndelivCmdsInDistDB> @UndelivCmdsInDistDB and publication<>'HDXDB-DR'
)

/* 

Declare @lag_Time_Article numeric(9,2),@UndelivCmdsInDistDB varchar(50)

select * from  [DBAUtil].[dbo].Tbl_ReplicationLatency_Each_article_Local 
where cur_latency >=0.04  and UndelivCmdsInDistDB >0
and publication<>'HDXDB-DR'

*/



BEGIN 

DECLARE @html nvarchar(MAX);
EXEC spQueryToHtmlTable @html = @html OUTPUT,  
 @query = N'select * from  [DBAUtil].[dbo].Tbl_ReplicationLatency_Each_article_Local  where  cur_latency >=0.04';

/*
@query = N'
select * from DBA_all_failed_job_last_One_day_new
where step_name not like ''job outcome''
and step_name not in (''Check if job should run'',''Check files exist'',''Check files to process'',''Restart the log'',
''Load The Previous Trace Data'',''Delete Archived T-Logs'')

'
*/
--/*
EXEC msdb.dbo.sp_send_dbmail
    @PROFILE_NAME='BIDATALOAD',
    @recipients = 'saranyam@unitedtechno.com',
--@copy_recipients='aa@abc.com',
    @subject = 'Replication Lag Latency per Table:',
    @body = @html,
    @body_format = 'HTML',
    @query_no_truncate = 1,
    @attach_query_result_as_file = 0;
 
 --*/
end
--select * from DBAUtil.dbo.Tbl_ReplicationLatency_Each_article_Archive

insert into DBAUtil.dbo.Tbl_ReplicationLatency_Each_article_Archive
select *,GETDATE() from [REPL_HOMESQL01\HOMESQL01].[DBAUtil].[dbo].Tbl_ReplicationLatency_Each_article
--*/
END  
