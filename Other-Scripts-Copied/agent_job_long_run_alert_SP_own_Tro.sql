
/*

use DBAUtil
go

drop table Tbl_long_run_job_own

CREATE TABLE [dbo].[Tbl_long_run_job_own](
	[job_id] [uniqueidentifier] NOT NULL,
	[JobName] [sysname] NOT NULL,
	[ExecutionDate] [datetime] NULL,
	[Historical Avg Duration (secs)] [numeric](38, 6) NULL,
	[Min Threshhold (secs)] [float] NULL
)

select * from Tbl_long_run_job_own
*/

-- Exec DBAutil.dbo.USP_long_run_agent_Job

use DBAUtil
go
--alter proc USP_long_run_agent_Job_own
--as
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
--select * from DBAutil.dbo.Tbl_long_run_job_own

--Truncate table  DBAutil.dbo.Tbl_long_run_job_own

DECLARE   @HistoryStartDate datetime 
  ,@HistoryEndDate datetime  
  ,@MinHistExecutions int   
  ,@MinAvgSecsDuration int  

SET @HistoryStartDate = '20240701'
SET @HistoryEndDate = GETDATE()
SET @MinHistExecutions =10.0
SET @MinAvgSecsDuration = 600.0 -- 10 minutes is 600 seconds

DECLARE @currently_running_jobs_own TABLE (
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
INSERT INTO @currently_running_jobs_own
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
  SELECT jd.job_id


       ,case 
		when Duration_Seconds = 0 then AVG(secs_duration*1.)
		else Duration_Seconds end AvgDuration
		         
  FROM JobHistData HD join tbl_job_duration JD on HD.job_id=JD.job_id

  WHERE date_executed >= DATEADD(day, DATEDIFF(day,'19000101',@HistoryStartDate),'19000101')
  AND date_executed < DATEADD(day, 1 + DATEDIFF(day,'19000101',@HistoryEndDate),'19000101')   
  GROUP BY jd.job_id,Duration_Seconds
  HAVING COUNT(*) >= @MinHistExecutions  AND AVG(secs_duration*1.) >= @MinAvgSecsDuration
)



--insert into  DBAutil.dbo.Tbl_long_run_job_own

SELECT jd.job_id,
      j.name AS [JobName]
      ,MAX(act.start_execution_date) AS [ExecutionDate]
      ,AvgDuration AS [AvgDuration_Sec]
	  ,DATEDIFF(SECOND,act.start_execution_date,GetDate()) AS [Run_secs_duration]
      
	  --into DBAutil.dbo.Tbl_long_run_job_own
FROM JobHistData jd
JOIN JobHistStats jhs on jd.job_id = jhs.[job_id]
JOIN msdb..sysjobs j on jd.job_id = j.job_id
JOIN @currently_running_jobs_own crj ON crj.job_id = jd.job_id
JOIN msdb..sysjobactivity AS act ON act.job_id = jd.job_id
AND act.stop_execution_date IS NULL
AND act.start_execution_date IS NOT NULL

WHERE DATEDIFF(SS, act.start_execution_date, GETDATE()) > AvgDuration -- you can comment this to troubleshoot
AND crj.job_state = 1 -- comment this line if you want to report on all jobs
--and act.start_execution_date >=GETDATE()-5
--/*
and not exists( -- make sure this is the most recent run
    select 1
    from msdb..sysjobactivity new
    where new.job_id = act.job_id
    and new.start_execution_date > act.start_execution_date
)
--*/
--and act.start_execution_date >GETDATE()-1
GROUP BY jd.job_id, j.name, AvgDuration,act.start_execution_date


/*
select * from DBAutil.dbo.Tbl_long_run_job_own
select * from DBAutil.dbo.Tbl_long_run_job_own

select * from tbl_job_duration
where duration_seconds <>0

-- update tbl_job_duration set duration_seconds=1500 where name ='SCM Cube Process 2019 To Date'
-- update tbl_job_duration set duration_seconds=0 where name ='SCM Cube Process 2019 To Date'
*/