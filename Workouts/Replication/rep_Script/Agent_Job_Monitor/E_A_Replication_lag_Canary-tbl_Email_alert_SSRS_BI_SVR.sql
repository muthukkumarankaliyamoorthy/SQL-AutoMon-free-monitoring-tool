
/*

USE [DBAUtil]
GO
drop table tbl_Replication_lag
go
CREATE TABLE [dbo].[tbl_Replication_lag](
	[ServerName] [varchar](200) NULL,
	[Pulisher Name] [varchar](200) NOT NULL,
	[Subscriber Server] [varchar](200) NOT NULL,
	[Subscriber DB] [varchar](200) NOT NULL,
	[CurrentTime] [datetime] NOT NULL,
	[ReplicationTime] [datetime] NOT NULL,
	[LAG DD:HH:MM] [varchar](200) NULL
) 

USE [DBAUtil]
GO
drop table tbl_Replication_lag_Archive
go
CREATE TABLE [dbo].[tbl_Replication_lag_Archive](
	[ServerName] [varchar](200) NULL,
	[Pulisher Name] [varchar](200) NOT NULL,
	[Subscriber Server] [varchar](200) NOT NULL,
	[Subscriber DB] [varchar](200) NOT NULL,
	[CurrentTime] [datetime] NOT NULL,
	[ReplicationTime] [datetime] NOT NULL,
	[LAG DD:HH:MM] [varchar](200) NULL,
	[load_Date] [datetime] NOT NULL,
) 


Exec [DBAUtil].[dbo].USP_Replication_lag
go


/*
DECLARE @html nvarchar(MAX);
EXEC spQueryToHtmlTable @html = @html OUTPUT,  @query = N'select * from  [DBAUtil].[dbo].tbl_Replication_lag where [LAG DD:HH:MM] > ''0:1:0'' ', @orderBy = N'ORDER BY [LAG DD:HH:MM]';

EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'BIDATALOAD',
    @recipients = 'saranyam@unitedtechno.com',
    @subject = 'Replication Lag Latency',
    @body = @html,
    @body_format = 'HTML',
    @query_no_truncate = 1,
    @attach_query_result_as_file = 0;



*/
	
*/
use DBAUtil
go
-- Exec USP_Replication_lag @lag_Time='0:0:15'
alter proc USP_Replication_lag
(@lag_Time varchar (200))
as
begin
truncate table [tbl_Replication_lag]

--HOMESQL01_Local
insert into [tbl_Replication_lag]
SELECT 'HOMESQL01\HOMESQL01' AS [ServerName] ,
'HOMESQL01_Local' [Pulisher Name],
'homesql01\homesql01'[Subscriber Server],
'HDXDB_Replica'[Subscriber DB],
GETDATE() AS [CurrentTime] ,
Currenttime AS [ReplicationTime] ,
CONVERT (VARCHAR(10), DATEDIFF(mi, currenttime, getdate()) / 1440)
+ ':' + CONVERT (VARCHAR(10), ( DATEDIFF(mi, currenttime, getdate())
% 1440 ) / 60) + ':'
+ CONVERT (VARCHAR(10), ( DATEDIFF(mi, currenttime, getdate()) % 60 )) AS [LAG DD:HH:MM]
FROM [REPL_HOMESQL01\HOMESQL01].[HDXDB_Replica].DBO.Canary_PubName

--HDXDB-BI
insert into [tbl_Replication_lag]
SELECT 'HOMESQL01\HOMESQL01' AS [ServerName] ,
'HDXDB-BI' [Pulisher Name],
'hdx-dr-sql01'[Subscriber Server],
'HDXDB-BI'[Subscriber DB],
GETDATE() AS [CurrentTime] ,
[Currenttime] AS [ReplicationTime] ,
CONVERT (VARCHAR(10), DATEDIFF(mi, Currenttime, getdate()) / 1440)+ ':' + CONVERT (VARCHAR(10), ( DATEDIFF(mi, Currenttime, getdate())% 1440 ) / 60) + ':'+ CONVERT (VARCHAR(10), ( DATEDIFF(mi, Currenttime, getdate()) % 60 )) AS [LAG DD:HH:MM]
FROM [repl_hdx-dr-sql01].[hdxdb-bi].dbo.Canary_PubName

--HDXDB_Replica

insert into [tbl_Replication_lag]
SELECT 'HOMESQL01\HOMESQL01' AS [ServerName] ,
'HDXDB_Replica' [Pulisher Name],
'hdx-dr-sql01'[Subscriber Server],
'HDXDB_Replica'[Subscriber DB],
GETDATE() AS [CurrentTime] ,
Currenttime AS [ReplicationTime] ,
CONVERT (VARCHAR(10), DATEDIFF(mi, Currenttime, getdate()) / 1440)+ ':' + CONVERT (VARCHAR(10), ( DATEDIFF(mi, Currenttime, getdate())% 1440 ) / 60) + ':'+ CONVERT (VARCHAR(10), ( DATEDIFF(mi, Currenttime, getdate()) % 60 )) AS [LAG DD:HH:MM]
FROM [REPL_hdx-dr-sql01].[HDXDB_Replica].DBO.Canary_PubName


/*
insert into [tbl_Replication_lag]
SELECT 'HOMESQL01\HOMESQL01' AS [ServerName] ,
'HDXDB-DR' [Pulisher Name],
'hdx-dr-sql02'[Subscriber Server],
'HDXDB'[Subscriber DB],
GETDATE() AS [CurrentTime] ,
Currenttime AS [ReplicationTime] ,
CONVERT (VARCHAR(10), DATEDIFF(mi, currenttime, getdate()) / 1440)
+ ':' + CONVERT (VARCHAR(10), ( DATEDIFF(mi, currenttime, getdate())
% 1440 ) / 60) + ':'
+ CONVERT (VARCHAR(10), ( DATEDIFF(mi, currenttime, getdate()) % 60 )) AS [LAG DD:HH:MM]
FROM [REPL_hdx-dr-sql02].[HDXDB].DBO.Canary_PubName

*/

---- send an excel
 
-- select * from DBA_all_failed_job_last_One_day_new order by 5 desc
IF EXISTS(
select * from  [DBAUtil].[dbo].tbl_Replication_lag where [LAG DD:HH:MM] >= @lag_Time
-- select * from  [DBAUtil].[dbo].tbl_Replication_lag where [LAG DD:HH:MM] > '0:0:0'
)  

BEGIN 

DECLARE @html nvarchar(MAX);
EXEC spQueryToHtmlTable @html = @html OUTPUT,  
 @query = N'select * from  [DBAUtil].[dbo].tbl_Replication_lag', @orderBy = N'ORDER BY [LAG DD:HH:MM]';

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
    @subject = 'Replication Lag Latency:',
    @body = @html,
    @body_format = 'HTML',
    @query_no_truncate = 1,
    @attach_query_result_as_file = 0;
 
 --*/
end
--select * from DBAUtil.dbo.tbl_Replication_lag_Archive
insert into DBAUtil.dbo.tbl_Replication_lag_Archive
select *,GETDATE() from DBAUtil.dbo.tbl_Replication_lag
--*/
END  
