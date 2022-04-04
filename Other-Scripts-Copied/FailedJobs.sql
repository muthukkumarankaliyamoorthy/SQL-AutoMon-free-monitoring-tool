-- Failed Jobs executed since the Last run hours, where the last status is failed. 
--This skips jobs that failed once,and subsequently executed successfully on the following run(s).
/*
DECLARE @dt CHAR(8);
SET @dt= CASE 
                        WHEN DATENAME(dw,GETDATE()) = 'Monday' 
                        THEN CONVERT(CHAR(8), (SELECT DATEADD (DAY,(-3), GETDATE())), 112)  
                        ELSE CONVERT(CHAR(8), (SELECT DATEADD (DAY,(-1), GETDATE())), 112)  
                      END

select @dt
*/
--select convert(char(8),dateadd(hh,-24,getdate()),112)
SELECT  

CONVERT(varchar(128),@@SERVERNAME) As Servername,
T1.step_name AS [Step Name],
SUBSTRING(T2.name,1,140) AS [SQL Job Name],
--msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime',
COUNT(*) AS TotalFailures,
CAST(MIN(CONVERT(DATETIME,CAST(run_date AS CHAR(8)),101)) AS CHAR(11)) AS [MinFailure Date],
CAST(MAX(CONVERT(DATETIME,CAST(run_date AS CHAR(8)),101)) AS CHAR(11)) AS [MaxFailure Date],
MAX(msdb.dbo.agent_datetime(T1.run_date, T1.run_time)) AS 'RunDateTime',
MIN(T1.run_duration) StepDuration,
CASE MIN(T1.run_status)
WHEN 0 THEN 'Failed'
WHEN 1 THEN 'Succeeded'
WHEN 2 THEN 'Retry'
WHEN 3 THEN 'Cancelled'
WHEN 4 THEN 'In Progress'
END AS ExecutionStatus
--,MAX(T1.message) AS [Error Message]
FROM
msdb..sysjobhistory T1 INNER JOIN msdb..sysjobs T2 ON T1.job_id = T2.job_id
WHERE
T1.run_status NOT IN (1,2,4)
AND T1.step_id != 0
AND run_date >= convert(char(8),dateadd(hh,-24,getdate()),112)
GROUP BY 
  T1.step_name,
  T2.name
