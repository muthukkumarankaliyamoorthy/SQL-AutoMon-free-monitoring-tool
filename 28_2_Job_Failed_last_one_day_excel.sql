/*

use dbadata
go
drop table DBA_all_failed_job_last_One_day_new
CREATE TABLE [dbo].[DBA_all_failed_job_last_One_day_new](
server_name varchar (500),
[Job_Name] [nvarchar](128) NULL,
[Step_Name] [sysname] NOT NULL,
[no_Fail] [int] NULL,
[Min_Date] [char](11) NULL,
[Max_Date] [char](11) NULL,
[StepDuration] [int] NULL,
[ExecutionStatus] [varchar](11) NULL,
Owner varchar (500) null
)

use dbadata_archive
go
drop table DBA_all_failed_job_last_One_day_new

CREATE TABLE [dbo].[DBA_all_failed_job_last_One_day_new](
server_name varchar (500),
[Job_Name] [nvarchar](128) NULL,
[Step_Name] [sysname] NOT NULL,
[no_Fail] [int] NULL,
[Min_Date] [char](11) NULL,
[Max_Date] [char](11) NULL,
[StepDuration] [int] NULL,
[ExecutionStatus] [varchar](11) NULL,
Owner varchar (500) null,
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
  

alter PROCEDURE [dbo].[USP_DBA_GETFAILEDJOBS_last_one_day_new]
  
/*
Summary:     Failed job findings
Contact:     Muthukkumaran Kaliyamoorhty SQL DBA
Description: Failed job findings

ChangeLog:
Date         Coder							Description
2017-jun-21	 Muthukkumaran Kaliyamoorhty     Updated the 2012 functionality                   


*/
         
AS  
BEGIN     
SET NOCOUNT ON       
TRUNCATE TABLE DBA_all_failed_job_last_One_day_new 
--select * from DBA_all_failed_job_last_One_day_new

     
DECLARE @DESCRIPTION VARCHAR(200)    
DECLARE @SERVER VARCHAR(200)    
Declare @Days int  
 

        
 DECLARE  ALLSERVER CURSOR        
 FOR        
 SELECT SERVERNAME,DESCRIPTION FROM DBADATA.DBO.DBA_ALL_SERVERS
 WHERE edition <>'express' 

 AND svr_status ='running'
       
 OPEN ALLSERVER        
 FETCH NEXT FROM ALLSERVER INTO  @SERVER,@DESCRIPTION        
        
 WHILE @@FETCH_STATUS=0        
  BEGIN    


Begin try  
  EXEC ('  

INSERT INTO DBA_all_failed_job_last_One_day_new                  
SELECT  

'''+@DESCRIPTION+''' [SERVER],
SUBSTRING(T2.name,1,140) AS [SQL Job Name],
T1.step_name AS [Step Name],
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
 
--/*
 ---- send an excel
 
-- select * from DBA_all_failed_job_last_One_day_new order by 5 desc
IF EXISTS(
select * from DBA_all_failed_job_last_One_day_new
where step_name not like 'job outcome'
and step_name not in ('Check if job should run','Check files exist','Check files to process','Restart the log'
,'Load The Previous Trace Data','Delete Archived T-Logs')

)  

BEGIN 

DECLARE @html nvarchar(MAX);
EXEC spQueryToHtmlTable @html = @html OUTPUT,  
@query = N'
select ROW_NUMBER() OVER (ORDER BY a.job_name)  Sequence_no,
a.server_name,a.Job_Name,a.Step_Name,
a.no_Fail,count(b.Job_Name) as Weekly_count ,a.Min_Date,
a.Max_Date,a.StepDuration,a.ExecutionStatus,a.Owner
from  DBA_all_failed_job_last_One_day_new  A left join  DBAdata_Archive.dbo.DBA_all_failed_job_last_One_day_new  B
on a.server_name=b.server_name and a.Job_Name=b.Job_Name

where a.step_name not like ''job outcome''
and a.step_name not in (''Check if job should run'',''Check files exist'',''Check files to process'',''Restart the log'',
''Load The Previous Trace Data'',''Delete Archived T-Logs'')
and b.upload_date > getdate()-7 
group by  b.server_name,b.job_name,
a.server_name,a.Job_Name,a.Step_Name,a.no_Fail,a.Min_Date,
a.Max_Date,a.StepDuration,a.ExecutionStatus,a.Owner


'

/*
@query = N'
select * from DBA_all_failed_job_last_One_day_new
where step_name not like ''job outcome''
and step_name not in (''Check if job should run'',''Check files exist'',''Check files to process'',''Restart the log'',
''Load The Previous Trace Data'',''Delete Archived T-Logs'')

'
*/

EXEC msdb.dbo.sp_send_dbmail
    @PROFILE_NAME=@@servername,
    @recipients = 'aa@abc.com',
@copy_recipients='aa@abc.com',
    @subject = 'Last one day failed jobs:',
    @body = @html,
    @body_format = 'HTML',
    @query_no_truncate = 1,
    @attach_query_result_as_file = 0;
   
end
insert into DBAdata_Archive.dbo.DBA_all_failed_job_last_One_day_new
select *,GETDATE() from DBA_all_failed_job_last_One_day_new
--*/
END  