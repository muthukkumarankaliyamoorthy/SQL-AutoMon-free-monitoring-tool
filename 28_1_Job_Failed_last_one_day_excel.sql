/*

use dbadata
go
DROP TABLE DBA_all_failed_job_last_One_day
CREATE TABLE [dbo].[DBA_all_failed_job_last_One_day](
	[Server] [varchar](100) NULL,
	[job_name] [varchar](max) NULL,
	[run_date] [varchar](10) NULL,
	[run_time] [varchar](10) NULL,
	[Failure_Count] [int],
	[Owner] varchar (200)
	)
	

use dbadata_archive
go
drop table DBA_all_failed_job_last_One_day

	CREATE TABLE [dbo].[DBA_all_failed_job_last_One_day](
	[Server] [varchar](100) NULL,
	[job_name] [varchar](max) NULL,
	[run_date] [varchar](10) NULL,
	[run_time] [varchar](10) NULL,
	[Failure_Count] [int],
	[Owner] varchar (200),
	[upload_date] [datetime] NULL
)

select server,job_Name,count(run_Date) from DBA_all_failed_job_last_One_day 
group by server,job_Name,failure_count
order by 3 desc

select SERVER,JOB_NAME,RUN_DATE,max(RUN_TIME)  from DBA_all_failed_job_last_One_day
WHERE RUN_DATE>=@DATE_CURRENT AND RUN_TIME >= @TIME_CURRENT
group by SERVER,JOB_NAME,RUN_DATE order by RUN_DATE desc 

*/


USE [DBADATA]
GO
/****** Object:  StoredProcedure [dbo].[USP_DBA_GETFAILEDJOBS_last_one_day]    Script Date: 07/11/2012 16:16:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  
--DROP PROC [USP_DBA_GETFAILEDJOBS_last_one_day]
alter PROCEDURE [dbo].[USP_DBA_GETFAILEDJOBS_last_one_day]
/*
Summary:     Failed job findings
Contact:     Muthukkumaran Kaliyamoorhty SQL DBA
Description: Failed job findings

ChangeLog:
Date         Coder							Description
2017-jun-21	 Muthukkumaran Kaliyamoorhty     Updated the 2012 functionality                   


*/
 
--WITH ENCRYPTION
          
AS  
BEGIN     
SET NOCOUNT ON       
TRUNCATE TABLE DBA_all_failed_job_last_One_day 
--select * from DBA_all_failed_job_last_One_day

DECLARE @DATE_CURRENT VARCHAR(8)        
DECLARE @TIME_CURRENT VARCHAR(8)    
DECLARE @DATE_CURRENT_Loop VARCHAR(8)        
DECLARE @TIME_CURRENT_loop VARCHAR(8)    
DECLARE @DATE_CURRENT_US VARCHAR(8)        
DECLARE @TIME_CURRENT_US VARCHAR(8)   
--DECLARE @DATE_CURRENT_CHINA VARCHAR(8)        
DECLARE @TIME_CURRENT_CHINA VARCHAR(8)      
DECLARE @DESCRIPTION VARCHAR(200)    
DECLARE @SERVER VARCHAR(200)    
Declare @Days int  
 
set @Days=1
        
    
SET  @DATE_CURRENT=CONVERT(CHAR(8),DATEADD(day,@Days*-1,GETDATE()),112)    
--SET  @TIME_CURRENT=REPLACE(CONVERT(CHAR(8),DATEADD(day,@Days*-1,GETDATE()),108),':','')    

--select @DATE_CURRENT,@TIME_CURRENT

/*SET  @DATE_CURRENT_US=CONVERT(CHAR(8),DATEADD(HH,(@Days*-1)-12,GETDATE()),112)    
SET  @TIME_CURRENT_US=REPLACE(CONVERT(CHAR(8),DATEADD(HH,(@Days*-1)-10,GETDATE()),108),':','')    
SET  @DATE_CURRENT_CHINA=CONVERT(CHAR(8),DATEADD(HH,(@Days*-1)+2,GETDATE()),112)    
SET  @TIME_CURRENT_CHINA=REPLACE(CONVERT(CHAR(8),DATEADD(HH,(@Days*-1)+2,GETDATE()),108),':','')    
*/
--SELECT @DATE_CURRENT    
--SELECT @TIME_CURRENT    
  --** PUT LOCAL SERVER FIRST.        
--select * from MSDB.DBO.SYSJOBHISTORY 
  
  
;With Job_recent As (


SELECT max(RUN_TIME) as RUN_TIME,MAX(ID) ID, count(name) Failure_count,@@servername as SERVER_NAME,name,RUN_DATE, J_Owner
		FROM 
(

select  ROW_NUMBER() OVER (ORDER BY NAME,RUN_DATE,RUN_TIME) ID,
@@servername as SERVER_NAME,NAME,RUN_DATE,RUN_TIME,RUN_STATUS,RUN_DURATION,RETRIES_ATTEMPTED,SUSER_SNAME(SJ.owner_sid) as J_Owner
         
FROM MSDB.DBO.SYSJOBHISTORY SJH         
JOIN MSDB.DBO.SYSJOBS_VIEW  SJ          
ON (SJ.JOB_ID = SJH.JOB_ID)  
WHERE  SJH.run_status = 0    
group by   NAME,RUN_DATE,RUN_TIME,RUN_STATUS,RUN_DURATION,RETRIES_ATTEMPTED,SUSER_SNAME(SJ.owner_sid)      
-- and SJH.RUN_DATE =cast(@DATE_CURRENT   as int)  
--AND SJH.RUN_TIME >= cast(@TIME_CURRENT   as int)  
--AND SJH.STEP_ID=0 
) as Jobs 	GROUP BY SERVER_NAME,name,RUN_DATE,J_Owner
    


),

		
		BACKUP_ALL AS
		(
		
select  ROW_NUMBER() OVER (ORDER BY NAME,RUN_DATE,RUN_TIME) ID,
@@servername as SERVER_NAME,NAME,RUN_DATE,RUN_TIME,RUN_STATUS,RUN_DURATION,RETRIES_ATTEMPTED,SUSER_SNAME(SJ.owner_sid)  as J_Owner
         
FROM MSDB.DBO.SYSJOBHISTORY SJH         
JOIN MSDB.DBO.SYSJOBS_VIEW  SJ          
ON (SJ.JOB_ID = SJH.JOB_ID)  
WHERE  SJH.run_status = 0     
group by   NAME,RUN_DATE,RUN_TIME,RUN_STATUS,RUN_DURATION,RETRIES_ATTEMPTED,SUSER_SNAME(SJ.owner_sid)
-- and SJH.RUN_DATE =cast(@DATE_CURRENT   as int)  
--AND SJH.RUN_TIME >= cast(@TIME_CURRENT   as int)  
--AND SJH.STEP_ID=0 
)

INSERT INTO DBA_all_failed_job_last_One_day 
SELECT  --*
Job_recent.SERVER_NAME [SERVER],Job_recent.name [Job Name],Job_recent.[Run_date], Job_recent.[Run_time],Failure_count,Job_recent.J_Owner
FROM Job_recent ,BACKUP_ALL 
WHERE Job_recent.ID=BACKUP_ALL.ID 
and Job_recent.RUN_DATE =cast(@DATE_CURRENT   as int)  
--AND Job_recent.RUN_DATE >= cast(@DATE_CURRENT   as int)  
--AND Job_recent.STEP_ID=0 
 
        
 DECLARE  ALLSERVER CURSOR        
 FOR        
 SELECT SERVERNAME,DESCRIPTION FROM DBADATA.DBO.DBA_ALL_SERVERS
 WHERE edition <>'express' 

 AND svr_status ='running'
       
 OPEN ALLSERVER        
 FETCH NEXT FROM ALLSERVER INTO  @SERVER,@DESCRIPTION        
        
 WHILE @@FETCH_STATUS=0        
  BEGIN    

/*      
If  @DESCRIPTION like 'ABC%' or @DESCRIPTION like 'XYZ%'

Begin 
set @DATE_CURRENT_Loop=@DATE_CURRENT_US;  
set @TIME_CURRENT_Loop=@TIME_CURRENT_US;  
--Print @DATE_CURRENT_Loop +' '+@TIME_CURRENT_Loop +' '+@DESCRIPTION+': Non UK'  
end  
  
else  
Begin  
set @DATE_CURRENT_Loop=@DATE_CURRENT;  
set @TIME_CURRENT_Loop=@TIME_CURRENT;  
-- Print @DATE_CURRENT_Loop +' '+@TIME_CURRENT_Loop +' '+@DESCRIPTION+': UK' 

 
end  
 */
  
set @DATE_CURRENT_Loop=@DATE_CURRENT;  
set @TIME_CURRENT_Loop=@TIME_CURRENT;  
--Print @DATE_CURRENT_Loop +' '+@TIME_CURRENT_Loop +' '+@DESCRIPTION+': UK' 

Begin try  
  EXEC ('  
  
;With Job_recent As (

SELECT max(RUN_TIME) as RUN_TIME,MAX(ID) ID, count(name) Failure_count,name,RUN_DATE,J_Owner
		FROM 
(

select  ROW_NUMBER() OVER (ORDER BY NAME,RUN_DATE,RUN_TIME) ID,
@@servername as SERVER_NAME,NAME,RUN_DATE,RUN_TIME,RUN_STATUS,RUN_DURATION,RETRIES_ATTEMPTED,SUSER_SNAME(SJ.owner_sid) as J_Owner
         
FROM ['+@SERVER+'].MSDB.DBO.SYSJOBHISTORY SJH         
JOIN ['+@SERVER+'].MSDB.DBO.SYSJOBS_VIEW  SJ          
ON (SJ.JOB_ID = SJH.JOB_ID)  
WHERE  SJH.run_status = 0 
group by   NAME,RUN_DATE,RUN_TIME,RUN_STATUS,RUN_DURATION,RETRIES_ATTEMPTED,SUSER_SNAME(SJ.owner_sid)   
-- and SJH.RUN_DATE =cast('+@DATE_CURRENT_Loop+'   as int)  
--AND SJH.RUN_TIME >= cast('+@TIME_CURRENT_loop+'   as int)  
--AND SJH.STEP_ID=0 
) Jobs 	GROUP BY SERVER_NAME,name,RUN_DATE,J_Owner


),

		
		BACKUP_ALL AS
		(
		
select  ROW_NUMBER() OVER (ORDER BY NAME,RUN_DATE,RUN_TIME) ID,
@@servername as SERVER_NAME,NAME,RUN_DATE,RUN_TIME,RUN_STATUS,RUN_DURATION,RETRIES_ATTEMPTED,SUSER_SNAME(SJ.owner_sid)  as J_Owner
         
FROM ['+@SERVER+'].MSDB.DBO.SYSJOBHISTORY SJH         
JOIN ['+@SERVER+'].MSDB.DBO.SYSJOBS_VIEW  SJ          
ON (SJ.JOB_ID = SJH.JOB_ID)  
WHERE  SJH.run_status = 0 
group by   NAME,RUN_DATE,RUN_TIME,RUN_STATUS,RUN_DURATION,RETRIES_ATTEMPTED ,SUSER_SNAME(SJ.owner_sid)        
-- and SJH.RUN_DATE =cast('+@DATE_CURRENT_Loop+'   as int)  
--AND SJH.RUN_TIME >= cast('+@TIME_CURRENT_loop+'   as int)  
--AND SJH.STEP_ID=0 
)

INSERT INTO DBA_all_failed_job_last_One_day 
SELECT  '''+@DESCRIPTION+''' [SERVER],Job_recent.name [Job Name],Job_recent.[Run_date], Job_recent.[Run_time],Failure_count,Job_recent.J_Owner
FROM Job_recent ,BACKUP_ALL 
WHERE Job_recent.ID=BACKUP_ALL.ID 
and Job_recent.RUN_DATE =cast('+@DATE_CURRENT_Loop+'   as int)  
--AND Job_recent.RUN_TIME >= cast('+@TIME_CURRENT_loop+'   as int)  
--AND Job_recent.STEP_ID=0 
order by Failure_count desc
'  
   )     
end try
BEGIN CATCH
--SELECT @SERVER, ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
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

-- select * from DBA_all_failed_job_last_One_day order by 5 desc
IF EXISTS(
select 1 from DBA_all_failed_job_last_One_day
--WHERE RUN_DATE>=@DATE_CURRENT AND RUN_TIME >= @TIME_CURRENT group by SERVER,JOB_NAME,RUN_DATE
)  

BEGIN 

DECLARE @html nvarchar(MAX);
EXEC spQueryToHtmlTable @html = @html OUTPUT,  
@query = N'select * from DBA_all_failed_job_last_One_day';

EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'muthu',
    @recipients = 'email address',
    @subject = 'Last one day failed jobs:',
    @body = @html,
    @body_format = 'HTML',
    @query_no_truncate = 1,
    @attach_query_result_as_file = 0;
	   
end
insert into DBAdata_Archive.dbo.DBA_all_failed_job_last_One_day
select *,GETDATE() from DBA_all_failed_job_last_One_day
--*/
END  
  