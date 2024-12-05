/*

use dbadata
go
drop table DBA_all_failed_job_last_One_day_new
CREATE TABLE [dbo].[DBA_all_failed_job_last_One_day_new](
	[Server_name] [nvarchar](128) NULL,
	[SQL_Job_Name] [nvarchar](128) NULL,
	[Step_Name] [sysname] NOT NULL,
	[TotalFailures] [int] NULL,
	[MinFailure Date] [char](11) NULL,
	[MaxFailure Date] [char](11) NULL,
	[StepDuration] [int] NULL,
	[Failled] [varchar](11) NULL,
	[Last_Run_Status] [varchar](50) NOT NULL,
	[owner_sid] [nvarchar](128) NULL
) 

drop table tbl_DBA_all_failed_job_last_One_day_non_success
CREATE TABLE [dbo].[tbl_DBA_all_failed_job_last_One_day_non_success](
	[server_name] [nvarchar](128) NULL,
	[SQL_Job_Name] [nvarchar](128) NULL,
	[Step_Name] [sysname] NOT NULL,
	[TotalFailures] [int] NULL,
	[MinFailure Date] [char](11) NULL,
	[MaxFailure Date] [char](11) NULL,
	[StepDuration] [int] NULL,
	[ExecutionStatus] [varchar](11) NULL,
	[owner_sid] [nvarchar](128) NULL
)

drop table tbl_DBA_all_failed_job_last_One_day_only_success
CREATE TABLE [dbo].[tbl_DBA_all_failed_job_last_One_day_only_success](
	[server_name] [nvarchar](128) NULL,
	[SysJobName] [sysname] NOT NULL,
	[JobName] [sysname] NOT NULL,
	[StepNumber] [int] NOT NULL,
	[StepName] [sysname] NOT NULL,
	[Last_Run_Status] [varchar](50) NOT NULL,
	[ExecutedAt] [datetime] NULL,
	[ExecutingHours] [int] NULL,
	[ExecutingMinutes] [int] NULL,
	[Message] [nvarchar](4000) NULL
)


use dbadata_archive
go
drop table DBA_all_failed_job_last_One_day_new

CREATE TABLE [dbo].[DBA_all_failed_job_last_One_day_new](
	[Server_name] [nvarchar](128) NULL,
	[SQL_Job_Name] [nvarchar](128) NULL,
	[Step_Name] [sysname] NOT NULL,
	[TotalFailures] [int] NULL,
	[MinFailure Date] [char](11) NULL,
	[MaxFailure Date] [char](11) NULL,
	[StepDuration] [int] NULL,
	[Failled] [varchar](11) NULL,
	[Last_Run_Status] [varchar](50) NOT NULL,
	[owner_sid] [nvarchar](128) NULL,
	upload_date datetime null default getdate()
)

select * from DBA_all_failed_job_last_One_day_new  where step_name like '%Check files to process%'
select step_name,count(*) from DBA_all_failed_job_last_One_day_new group by step_name


*/


USE [DBADATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  

create PROCEDURE [dbo].[USP_DBA_GETFAILEDJOBS_last_one_day_new]
  
/*
Summary:     last one day failled job only failled
Contact:     Muthukkumaran Kaliyamoorthy SQL DBA


ChangeLog:
Date         Coder							Description
2013-jan-21	 Muthukkumaran Kaliyamoorhty     Updated the 2012 functionality                   


*/
         
AS  
BEGIN     
SET NOCOUNT ON  

TRUNCATE TABLE DBA_all_failed_job_last_One_day_new
TRUNCATE TABLE tbl_DBA_all_failed_job_last_One_day_non_success 
TRUNCATE TABLE tbl_DBA_all_failed_job_last_One_day_only_success
--select * from DBA_all_failed_job_last_One_day_new

     
DECLARE @DESCRIPTION VARCHAR(200)    
DECLARE @SERVER VARCHAR(200)    
Declare @Days int  
 

        
 DECLARE  ALLSERVER CURSOR        
 FOR        
 SELECT SERVERNAME,DESCRIPTION FROM DBADATA.DBO.DBA_ALL_SERVERS
 WHERE edition <>'express'

 AND svr_status ='running'
 and category ='Prod'
       
 OPEN ALLSERVER        
 FETCH NEXT FROM ALLSERVER INTO  @SERVER,@DESCRIPTION        
        
 WHILE @@FETCH_STATUS=0        
  BEGIN    


Begin try  
  EXEC ('  

INSERT INTO tbl_DBA_all_failed_job_last_One_day_non_success                  
SELECT  

'''+@DESCRIPTION+''' [SERVER],
SUBSTRING(T2.name,1,140) AS [SQL_Job_Name],
T1.step_name AS [Step_Name],
--msdb.dbo.agent_datetime(run_date, run_time) as [RunDateTime],
COUNT(*) AS TotalFailures,
CAST(MIN(CONVERT(DATETIME,CAST(run_date AS CHAR(8)),101)) AS CHAR(11)) AS [MinFailure Date],
CAST(MAX(CONVERT(DATETIME,CAST(run_date AS CHAR(8)),101)) AS CHAR(11)) AS [MaxFailure Date],
--MAX(msdb.dbo.agent_datetime(T1.run_date, T1.run_time)) AS [RunDateTime],
MIN(T1.run_duration) StepDuration,
CASE MIN(T1.run_status)
WHEN 0 THEN ''Failed''
WHEN 1 THEN ''Succeeded''
WHEN 2 THEN ''Retry''
WHEN 3 THEN ''Cancelled''
WHEN 4 THEN ''In Progress''
END AS [ExecutionStatus],
SUSER_SNAME(t2.owner_sid)

FROM ['+@SERVER+'].MSDB.DBO.sysjobhistory T1 INNER JOIN  ['+@SERVER+'].MSDB.DBO.sysjobs T2 ON T1.job_id = T2.job_id
WHERE
T1.run_status NOT IN (1,2,4)
AND T1.step_id != 0
AND run_date >= CONVERT(CHAR(8),DATEADD(HH,-24,GETDATE()),112)     
--and step_name not like ''job outcome''
--and step_name not in (''Check if job should run'',''Check files exist'')

GROUP BY 
  T1.step_name,  T2.name,SUSER_SNAME(t2.owner_sid)

'  
   )  
   

  
  EXEC ('  

INSERT INTO tbl_DBA_all_failed_job_last_One_day_only_success                  

SELECT  
'''+@DESCRIPTION+''' [SERVER],
SysJobName = J.name,
    H.*
FROM
    ['+@SERVER+'].MSDB.DBO.sysjobs AS J
    CROSS APPLY (
        SELECT TOP 1
            JobName = J.name,
            StepNumber = T.step_id,
            StepName = T.step_name,
            StepStatus = CASE T.run_status
                WHEN 0 THEN ''Failed''
                WHEN 1 THEN ''Succeeded''
                WHEN 2 THEN ''Retry''
                WHEN 3 THEN ''Canceled''
                ELSE ''Running'' END,
            ExecutedAt = msdb.dbo.agent_datetime(T.run_date, T.run_time),
            ExecutingHours = ((T.run_duration/10000 * 3600 + (T.run_duration/100) % 100 * 60 + T.run_duration % 100 + 31 ) / 60) / 60,
            ExecutingMinutes = ((T.run_duration/10000 * 3600 + (T.run_duration/100) % 100 * 60 + T.run_duration % 100 + 31 ) / 60) % 60,
            Message = T.message
        FROM
            ['+@SERVER+'].MSDB.DBO.sysjobhistory AS T
        WHERE
            T.job_id = J.job_id
			
        ORDER BY
            T.instance_id DESC) AS H
ORDER BY ExecutedAt desc

'  
   )  
   

end try
BEGIN CATCH
--SELECT @SERVER, ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
-- select * from tbl_Error_handling
SELECT @SERVER,'Jobs_excel',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()


END CATCH  
--PRINT 'SERVER ' +@SERVER+' COMPLETED.'    
FETCH NEXT FROM  ALLSERVER INTO  @SERVER,@DESCRIPTION         
  END         
 CLOSE ALLSERVER        
 DEALLOCATE ALLSERVER  
 
  -- load job table data to job table
--truncate table DBA_all_failed_job_last_One_day_new

-- select * from tbl_DBA_all_failed_job_last_One_day_only_success where server_name like '%scm%' and sysjobname like '%DOS BI Update Before Report is Published%'
-- select * from tbl_DBA_all_failed_job_last_One_day_non_success where server_name like '%scm%'


insert into DBA_all_failed_job_last_One_day_new

select distinct
NS.Server_name,
NS.[SQL_Job_Name],
NS.[Step_Name],
NS.TotalFailures,
NS.[MinFailure Date],
NS.[MaxFailure Date],
NS.StepDuration,
NS.ExecutionStatus [Failled],
[Last_Status] =case when S.[Last_Run_Status]  IS NULL then 'No success run' else S.[Last_Run_Status]  end,
NS.[owner_sid]
--into DBA_all_failed_job_last_One_day_new
from tbl_DBA_all_failed_job_last_One_day_only_success S
right outer join tbl_DBA_all_failed_job_last_One_day_non_success NS on (s.sysJobName=ns.[SQL_Job_Name])
where s.[Last_Run_Status] is null OR s.[Last_Run_Status] <>'Succeeded' -- exclude the Succeeded jobs

order by NS.[SQL_Job_Name] desc, NS.Server_name desc


--/*
 ---- send an excel
 
-- select * from DBA_all_failed_job_last_One_day_new order by 5 desc

IF EXISTS(

select * from DBA_all_failed_job_last_One_day_new

where step_name not in ('Check if job should run','Check files exist','Check files to process','Restart the log','Load The Previous Trace Data','Delete Archived T-Logs')
--AND (SQL_Job_name not like 'Daily Inventory Insert'and step_name NOT LIKE '%Insert Invetory Data EDW%')

AND SQL_Job_name not in ('FountainHead Exports TEST','Inv Job','Ladder Plan Feed ECOM','Daily Inventory Insert')
AND SQL_Job_name <> 'syspolicy_purge_history'


)  

BEGIN 

DECLARE @html nvarchar(MAX);
EXEC spQueryToHtmlTable @html = @html OUTPUT,  
@query = N'

select * from DBA_all_failed_job_last_One_day_new

where step_name not in (''Check if job should run'',''Check files exist'',''Check files to process'',''Restart the log'',''Load The Previous Trace Data'',''Delete Archived T-Logs'')
--AND (SQL_Job_name not like ''Daily Inventory Insert''and step_name NOT LIKE ''%Insert Invetory Data EDW%'')

AND SQL_Job_name not in (''FountainHead Exports TEST'',''Inv Job'',''Ladder Plan Feed ECOM'',''Daily Inventory Insert'')
AND SQL_Job_name <> ''syspolicy_purge_history''

'

/*
@query = N'
select * from DBA_all_failed_job_last_One_day_new
where step_name not like ''job outcome''
and step_name not in (''Check if job should run'',''Check files exist'',''Check files to process'',''Restart the log'',
''Load The Previous Trace Data'',''Delete Archived T-Logs'')

'
*/

/*
EXEC msdb.dbo.sp_send_dbmail
    @PROFILE_NAME=@@servername,
    @recipients = 'aa@abc.com',
@copy_recipients='aa@abc.com',
    @subject = 'Last one day failed jobs:',
    @body = @html,
    @body_format = 'HTML',
    @query_no_truncate = 1,
    @attach_query_result_as_file = 0;
*/

DECLARE @EMAILIDS VARCHAR(500)

SELECT @EMAILIDS=
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS  FROM dbo.DBA_ALL_OPERATORS
WHERE STATUS=1
DECLARE @EMAILIDS1 VARCHAR(500)
SELECT @EMAILIDS1=
COALESCE(@EMAILIDS1+';','')+EMAIL_ADDRESS  FROM DBAdata.DBO.DBA_ALL_OPERATORS
WHERE STATUS =1 and Mail_copy='CC'

EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@subject = 'Last one day failed jobs:',
@BODY = @html,
@copy_recipients=@EMAILIDS1,
--@blind_copy_recipients='HCL_NOC@sandisk.com',
@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='BIDATALOAD',
@query_no_truncate = 1,
@attach_query_result_as_file = 0;


end
insert into DBAdata_Archive.dbo.DBA_all_failed_job_last_One_day_new
select *,GETDATE() from DBA_all_failed_job_last_One_day_new
--*/

END  