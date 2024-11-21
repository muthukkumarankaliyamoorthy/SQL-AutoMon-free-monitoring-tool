
/*

use DBAUtil
go

drop table Tbl_long_run_job

CREATE TABLE [dbo].[Tbl_long_run_job](
	[job_id] [uniqueidentifier] NOT NULL,
	[JobName] [sysname] NOT NULL,
	[ExecutionDate] [datetime] NULL,
	[Historical Avg Duration (secs)] [numeric](38, 6) NULL,
	[Min Threshhold (secs)] [float] NULL
)

select * from Tbl_long_run_job
*/

-- Exec DBAutil.dbo.USP_long_run_agent_Job

use DBAUtil
go
alter proc USP_long_run_agent_Job
as
/*=============================================
  File: long_running_jobs.sql

  Author: Thomas LaRock, https://thomaslarock.com/contact-me/

  Summary: This script will check to see if any currently
                        running jobs are running long. 

  Variables:
        @MinHistExecutions - Minimum number of job runs we want to consider 
        @MinAvgSecsDuration - Threshold for minimum duration we care to monitor
        @HistoryStartDate - Start date for historical average
        @HistoryEndDate - End date for historical average

        These variables allow for us to control a couple of factors. First
        we can focus on jobs that are running long enough on average for
        us to be concerned with (say, 30 seconds or more). Second, we can
        avoid being alerted by jobs that have run so few times that the
        average and standard deviations are not quite stable yet. This script
        leaves these variables at 1.0, but I would advise you alter them
        upwards after testing.

  Returns: One result set containing a list of jobs that
        are currently running and are running longer than two standard deviations 
        away from their historical average. The "Min Threshold" column
        represents the average plus two standard deviations. 

  Date: October 3rd, 2012

  SQL Server Versions: SQL2005, SQL2008, SQL2008R2, SQL2012

  You may alter this code for your own purposes. You may republish
  altered code as long as you give due credit. 

  THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY
  OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
  LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR
  FITNESS FOR A PARTICULAR PURPOSE.

=============================================*/
--select * from DBAutil.dbo.Tbl_long_run_job

Truncate table  DBAutil.dbo.Tbl_long_run_job

DECLARE   @HistoryStartDate datetime 
  ,@HistoryEndDate datetime  
  ,@MinHistExecutions int   
  ,@MinAvgSecsDuration int  

SET @HistoryStartDate = '19000101'
SET @HistoryEndDate = GETDATE()
SET @MinHistExecutions =1.0
SET @MinAvgSecsDuration = 300.0 -- 10 minutes is 600 seconds

DECLARE @currently_running_jobs TABLE (
    job_id UNIQUEIDENTIFIER NOT NULL
    ,last_run_date INT NOT NULL
    ,last_run_time INT NOT NULL
    ,next_run_date INT NOT NULL
    ,next_run_time INT NOT NULL
    ,next_run_schedule_id INT NOT NULL
    ,requested_to_run INT NOT NULL
    ,request_source INT NOT NULL
    ,request_source_id SYSNAME NULL
    ,running INT NOT NULL
    ,current_step INT NOT NULL
    ,current_retry_attempt INT NOT NULL
    ,job_state INT NOT NULL
    ) 

--capture details on jobs
INSERT INTO @currently_running_jobs
EXECUTE master.dbo.xp_sqlagent_enum_jobs 1,''

;WITH JobHistData AS
(
  SELECT job_id
        ,date_executed=msdb.dbo.agent_datetime(run_date, run_time)
        ,secs_duration=run_duration/10000*3600
                      +run_duration%10000/100*60
                      +run_duration%100
  FROM msdb.dbo.sysjobhistory
  WHERE step_id = 0   --Job Outcome
  AND run_status = 1  --Succeeded
)
,JobHistStats AS
(
  SELECT job_id
        ,AvgDuration = AVG(secs_duration*1.)
        ,AvgPlus2StDev = AVG(secs_duration*1.) + 2*stdevp(secs_duration)
  FROM JobHistData
  WHERE date_executed >= DATEADD(day, DATEDIFF(day,'19000101',@HistoryStartDate),'19000101')
  AND date_executed < DATEADD(day, 1 + DATEDIFF(day,'19000101',@HistoryEndDate),'19000101')   GROUP BY job_id   HAVING COUNT(*) >= @MinHistExecutions
  AND AVG(secs_duration*1.) >= @MinAvgSecsDuration
)
insert into  DBAutil.dbo.Tbl_long_run_job
SELECT jd.job_id
      ,j.name AS [JobName]
      ,MAX(act.start_execution_date) AS [ExecutionDate]
      ,AvgDuration AS [Historical Avg Duration (secs)]
      ,AvgPlus2StDev AS [Min Threshhold (secs)]
	  --into DBAutil.dbo.Tbl_long_run_job
FROM JobHistData jd
JOIN JobHistStats jhs on jd.job_id = jhs.job_id
JOIN msdb..sysjobs j on jd.job_id = j.job_id
JOIN @currently_running_jobs crj ON crj.job_id = jd.job_id
JOIN msdb..sysjobactivity AS act ON act.job_id = jd.job_id
AND act.stop_execution_date IS NULL
AND act.start_execution_date IS NOT NULL
WHERE secs_duration > AvgPlus2StDev
AND DATEDIFF(SS, act.start_execution_date, GETDATE()) > AvgPlus2StDev
AND crj.job_state = 1
--and act.start_execution_date >GETDATE()-1
GROUP BY jd.job_id, j.name, AvgDuration, AvgPlus2StDev
-- select * from DBAutil.dbo.Tbl_long_run_job


---- send an excel
 
-- select * from DBA_all_failed_job_last_One_day_new order by 5 desc
IF EXISTS(
select *  FROM Tbl_long_run_job 
)  

BEGIN 
EXEC [server1].DBAUtil.dbo.sp_WhoIsActive @get_plans = 1,@get_task_info = 2,@get_locks = 1,@format_output = 1,@destination_table = 'DBAutil.dbo.Whoisactive_Long_job_Capture'    


--/*
DECLARE @html nvarchar(MAX);
EXEC DBAutil.dbo.spQueryToHtmlTable @html = @html OUTPUT,  
 @query = N'select *  FROM Tbl_long_run_job';



EXEC msdb.dbo.sp_send_dbmail
    @PROFILE_NAME='DBA',
    @recipients = 'email',
--@copy_recipients='aa@abc.com',
    @subject = 'Long running Agent Job Status:',
    @body = @html,
    @body_format = 'HTML',
    @query_no_truncate = 1,
    @attach_query_result_as_file = 0;
--*/

end
