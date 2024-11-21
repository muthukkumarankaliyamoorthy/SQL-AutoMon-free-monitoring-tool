/*
CREATE VIEW V_RunningSQLJobs
AS
SELECT job.NAME
    ,job.job_id
    ,job.originating_server
    ,activity.run_requested_date
    ,DATEDIFF(SECOND, activity.run_requested_date, GETDATE()) AS Elapsed
FROM msdb.dbo.sysjobs_view job
JOIN msdb.dbo.sysjobactivity activity ON job.job_id = activity.job_id
JOIN msdb.dbo.syssessions sess ON sess.session_id = activity.session_id
JOIN (
    SELECT MAX(agent_start_date) AS max_agent_start_date
    FROM msdb.dbo.syssessions
    ) sess_max ON sess.agent_start_date = sess_max.max_agent_start_date
WHERE run_requested_date IS NOT NULL
    AND stop_execution_date IS NULL
*/

SELECT NAME [Job Name],job_id,originating_server,run_requested_date,GETDATE() [TodayDate],Elapsed,
DATEDIFF(SECOND, run_requested_date, GETDATE())/60.0/60.0 as [Elapsed_in_HH],DATENAME(dw,GETDATE()) as Day
FROM DBAUtil.dbo.V_RunningSQLJobs

select DATENAME(dw,GETDATE()) as Day,GETDATE() [TodayDate]


SELECT job.NAME    
    ,job.originating_server
    ,activity.run_requested_date
	,DATEDIFF(Minute, activity.run_requested_date, GETDATE()) AS Elapsed_Minute
    ,DATEDIFF(HOUR, activity.run_requested_date, GETDATE()) AS Elapsed_Hours
	,'Running'Status
FROM msdb.dbo.sysjobs_view job
JOIN msdb.dbo.sysjobactivity activity ON job.job_id = activity.job_id
JOIN msdb.dbo.syssessions sess ON sess.session_id = activity.session_id
JOIN (
    SELECT MAX(agent_start_date) AS max_agent_start_date
    FROM msdb.dbo.syssessions
    ) sess_max ON sess.agent_start_date = sess_max.max_agent_start_date
WHERE run_requested_date IS NOT NULL
    AND stop_execution_date IS NULL


/*


EXEC msdb.dbo.sp_send_dbmail
    @PROFILE_NAME='dba',
    @recipients = 'email',
--@copy_recipients='aa@abc.com',
    @subject = 'Test:',
      @query_no_truncate = 1,
    @attach_query_result_as_file = 0;




--Logic

	IF NOT EXISTS(SELECT * FROM DBAUtil.dbo.V_RunningSQLJobs WHERE name='Daily Order Status ETL') 
	-- not exixts not running then run the following
BEGIN 
 Print 'Inside the job block - Start the job'
 exec msdb.dbo.sp_start_job @JobName ='Daily Order Status Scale ETL'

END

Else

Print 'Daily Order Status ETL is currently running'


*/