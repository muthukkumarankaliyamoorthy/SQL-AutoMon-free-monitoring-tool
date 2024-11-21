
 

/*
Make sure your agents are in the correct category 
i.e Merge agents under REPL-Merge, 
Distribution agents under REPL-Distribution 
and LogReader agent under REPL-LogReader
select * from Tbl_Repl_Agent_Satus
drop table Tbl_Repl_Agent_Satus

USE [DBAUtil]
GO

/****** Object:  StoredProcedure [dbo].[USP_Repl_Agent_Satus]    Script Date: 2/2/2024 4:01:35 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[USP_Repl_Agent_Satus]
as
truncate table Tbl_Repl_Agent_Satus
select s.job_id,s.name,s.enabled,c.name as categoryname into #JobList
from msdb.dbo.sysjobs s inner join msdb.dbo.syscategories c on s.category_id = c.category_id
where c.name in ('REPL-Merge','REPL-Distribution','REPL-LogReader')--,'REPL-Snapshot')

create TABLE #xp_results  
   (job_id                UNIQUEIDENTIFIER NOT NULL,
    last_run_date         INT              NOT NULL,
    last_run_time         INT              NOT NULL,
    next_run_date         INT              NOT NULL,
    next_run_time         INT              NOT NULL,
    next_run_schedule_id  INT              NOT NULL,
    requested_to_run      INT              NOT NULL, 
    request_source        INT              NOT NULL,
    request_source_id     sysname          COLLATE database_default NULL,
    running               INT              NOT NULL,
    current_step          INT              NOT NULL,
    current_retry_attempt INT              NOT NULL,
    job_state             INT              NOT NULL)

insert into #xp_results 
exec master.dbo.xp_sqlagent_enum_jobs 1, ''

insert into Tbl_Repl_Agent_Satus
select j.name,j.categoryname,j.enabled, AgentStatus = CASE WHEN r.running =1 THEN 'Running' else 'Stopped'   end
,last_run_date,last_run_time,next_run_date,current_retry_attempt --into Tbl_Repl_Agent_Satus
from #JobList j inner join #xp_results r on j.job_id=r.job_id

-- Uncomment the below portion and use correct parameters to send email alert
/*
if exists (select j.name,j.categoryname,j.enabled,r.running
from #JobList j inner join #xp_results r   on j.job_id=r.job_id where running =0 )
begin
   declare @subject nvarchar(100)
   select @subject = N'Replication Agents Status on '+@@servername

   EXEC msdb.dbo.sp_send_dbmail
      @profile_name = 'ProfileName',
      @recipients = N'email id',
      @subject = @subject,
      @body = 'One or more agents found stopped'
end
*/
drop table #JobList,#xp_results

--select * from Tbl_Repl_Agent_Satus
GO




*/

use DBAUtil
go
Alter proc USP_Repl_Agent_Satus_SSRS_BI
as

Exec [REPL_HOMESQL01\HOMESQL01].[DBAUtil].DBO.[USP_Repl_Agent_Satus]

---- send an excel
 
-- select * from DBA_all_failed_job_last_One_day_new order by 5 desc
IF EXISTS(
select *  FROM [REPL_HOMESQL01\HOMESQL01].[DBAUtil].DBO.Tbl_Repl_Agent_Satus where AgentStatus <>'Running' and name not in ('HOMESQL01\HOMESQL01-HDXDB-HDXDB-DR-HDX-DR-SQL02-149')
)  

BEGIN 

DECLARE @html nvarchar(MAX);
EXEC spQueryToHtmlTable @html = @html OUTPUT,  
 @query = N'select *  FROM [REPL_HOMESQL01\HOMESQL01].[DBAUtil].DBO.Tbl_Repl_Agent_Satus where AgentStatus <>''Running'' and name not in (''HOMESQL01\HOMESQL01-HDXDB-HDXDB-DR-HDX-DR-SQL02-149'')';

/*
@query = N'
select * from DBA_all_failed_job_last_One_day_new
where step_name not like ''job outcome''
and step_name not in (''Check if job should run'',''Check files exist'',''Check files to process'',''Restart the log'',
''Load The Previous Trace Data'',''Delete Archived T-Logs'')

'
*/

EXEC msdb.dbo.sp_send_dbmail
    @PROFILE_NAME='BIDATALOAD',
    @recipients = 'saranyam@unitedtechno.com',
--@copy_recipients='aa@abc.com',
    @subject = 'Replication Agent Status:',
    @body = @html,
    @body_format = 'HTML',
    @query_no_truncate = 1,
    @attach_query_result_as_file = 0;
   
end