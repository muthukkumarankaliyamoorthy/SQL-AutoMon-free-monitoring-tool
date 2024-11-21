
use DBAutil

go
Alter proc USP_Blocking_Alert
as
begin


IF EXISTS(
select 'server' [Local Server],sp.spid,sp.blocked, (CONVERT(DATETIME,CAST(sp.last_batch AS CHAR(8)),101))  as last_batch,sp.waittime,
sp.waitresource,sp.lastwaittype,sp.cmd,sp.program_name ,sp.dbid,
sp.loginame,sp.hostname [Blocked Host],sp.cpu 
from [LS_Server].master.dbo.sysprocesses sp
where sp.spid>50 and sp.spid<>sp.blocked and sp.blocked<>0 
and waittime>100000 -- milli seconnds 100000 MS is 1.5 Seconds
--and datediff(Second,last_batch,GETDATE())>30

)  

BEGIN 

-- capture blocking
--select * from DBAUtil.DBO.Tbl_Blocking_Details
--truncate table DBAUtil.DBO.Tbl_Blocking_Details

insert into DBAUtil.DBO.Tbl_Blocking_Details
select 'server' [Local Server],sp.spid,sp.blocked, (CONVERT(DATETIME,CAST(sp.last_batch AS CHAR(8)),101))  as last_batch,sp.waittime,
sp.waitresource,sp.lastwaittype,sp.cmd,sp.program_name ,sp.dbid,
sp.loginame,sp.hostname [Blocked Host],sp.cpu, getdate() Date_Now 
from [LS_Server].master.dbo.sysprocesses sp
where sp.spid>50 and sp.spid<>sp.blocked and sp.blocked<>0 
and waittime>100000 -- milli seconnds 100000 MS is 1.5 Seconds
--and datediff(Second,last_batch,GETDATE())>30

-- capture blocking via whoisactive
EXEC [LS_Server].DBAUtil.dbo.sp_WhoIsActive @get_plans = 1,@get_task_info = 2,@get_locks = 1,@format_output = 1,@destination_table = 'DBAutil.dbo.Whoisactive_Blocking_Capture'

-- email blocking
DECLARE @html nvarchar(MAX);

EXEC spQueryToHtmlTable @html = @html OUTPUT,  
 @query = N'select ''server'' [Local Server],sp.spid,sp.blocked, (CONVERT(DATETIME,CAST(sp.last_batch AS CHAR(8)),101))  as last_batch,sp.waittime,
sp.waitresource,sp.lastwaittype,sp.cmd,sp.program_name ,sp.dbid,
sp.loginame,sp.hostname [Blocked Host],sp.cpu 
from [LS_Server].master.dbo.sysprocesses sp
where sp.spid>50 and sp.spid<>sp.blocked and sp.blocked<>0 
and waittime>100000';


EXEC msdb.dbo.sp_send_dbmail
    @PROFILE_NAME='dba',
    @recipients = 'email',
--@copy_recipients='aa@abc.com',
    @subject = 'Blocking Query Details:',
    @body = @html,
    @body_format = 'HTML',
    @query_no_truncate = 1,
    @attach_query_result_as_file = 0;

	-----=========================
	--email 2 running jobs
DECLARE @html_2 nvarchar(MAX);
EXEC spQueryToHtmlTable @html = @html_2 OUTPUT,  
 @query = N'SELECT job.NAME  as [Job Name]
    ,job.originating_server as [Server Name]
    ,activity.Run_requested_date
	,DATEDIFF(Minute, activity.run_requested_date, GETDATE()) AS Elapsed_Minute
    ,DATEDIFF(HOUR, activity.run_requested_date, GETDATE()) AS Elapsed_Hours
	,''Running'' [Status]
FROM msdb.dbo.sysjobs_view job
JOIN msdb.dbo.sysjobactivity activity ON job.job_id = activity.job_id
JOIN msdb.dbo.syssessions sess ON sess.session_id = activity.session_id
JOIN (
    SELECT MAX(agent_start_date) AS max_agent_start_date
    FROM msdb.dbo.syssessions
    ) sess_max ON sess.agent_start_date = sess_max.max_agent_start_date
WHERE run_requested_date IS NOT NULL
    AND stop_execution_date IS NULL';

EXEC msdb.dbo.sp_send_dbmail
    @PROFILE_NAME='dba',
    @recipients = 'email',
--@copy_recipients='aa@abc.com',
    @subject = 'Running Job with Blocking Query Details:',
    @body = @html_2,
    @body_format = 'HTML',
    @query_no_truncate = 1,
    @attach_query_result_as_file = 0;

   
END

end