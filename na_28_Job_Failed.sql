/*

use dbadata
go
DROP TABLE DBA_all_failed_job
CREATE TABLE [dbo].[DBA_all_failed_job](
	[Server] [varchar](100) NULL,
	[job_name] [varchar](max) NULL,
	[run_date] [varchar](10) NULL,
	[run_time] [varchar](10) NULL,
	[Failure_Count] [int]
	)
	

use dbadata_archive
go
drop table DBA_all_failed_job

	CREATE TABLE [dbo].[DBA_all_failed_job](
	[Server] [varchar](100) NULL,
	[job_name] [varchar](max) NULL,
	[run_date] [varchar](10) NULL,
	[run_time] [varchar](10) NULL,
	[Failure_Count] [int],
	[upload_date] [datetime] NULL
)


select SERVER,JOB_NAME,RUN_DATE,max(RUN_TIME)  from DBA_ALL_FAILED_JOB
WHERE RUN_DATE>=@DATE_CURRENT AND RUN_TIME >= @TIME_CURRENT
group by SERVER,JOB_NAME,RUN_DATE order by RUN_DATE desc 

*/


USE [DBADATA]
GO
/****** Object:  StoredProcedure [dbo].[USP_DBA_GETFAILEDJOBS]    Script Date: 07/11/2012 16:16:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  
--DROP PROC [USP_DBA_GETFAILEDJOBS]
alter PROCEDURE [dbo].[USP_DBA_GETFAILEDJOBS]
/*
Summary:     Failed job findings
Contact:     Muthukkumaran Kaliyamoorhty SQL DBA
Description: Failed job findings

ChangeLog:
Date         Coder							Description
2017-jun-21	 Muthukkumaran Kaliyamoorhty     Updated the 2012 functionality                   


*/
 
WITH ENCRYPTION
          
AS  
BEGIN     
SET NOCOUNT ON       
TRUNCATE TABLE DBA_ALL_FAILED_JOB 
       
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
Declare @Hours int  
DECLARE @duration int  
set @Hours=1       
set @duration=10000           
    
SET  @DATE_CURRENT=CONVERT(CHAR(8),DATEADD(HH,@Hours*-1,GETDATE()),112)    
SET  @TIME_CURRENT=REPLACE(CONVERT(CHAR(8),DATEADD(HH,@Hours*-1,GETDATE()),108),':','')    
--select @DATE_CURRENT,@TIME_CURRENT
/*SET  @DATE_CURRENT_US=CONVERT(CHAR(8),DATEADD(HH,(@Hours*-1)-12,GETDATE()),112)    
SET  @TIME_CURRENT_US=REPLACE(CONVERT(CHAR(8),DATEADD(HH,(@Hours*-1)-10,GETDATE()),108),':','')    
SET  @DATE_CURRENT_CHINA=CONVERT(CHAR(8),DATEADD(HH,(@Hours*-1)+2,GETDATE()),112)    
SET  @TIME_CURRENT_CHINA=REPLACE(CONVERT(CHAR(8),DATEADD(HH,(@Hours*-1)+2,GETDATE()),108),':','')    
*/
--SELECT @DATE_CURRENT    
--SELECT @TIME_CURRENT    
  --** PUT LOCAL SERVER FIRST.        
--select * from MSDB.DBO.SYSJOBHISTORY 
  
  
;With Job_recent As (

SELECT max(RUN_TIME) as RUN_TIME,MAX(ID) ID, count(name) Failure_count,@@servername as SERVER_NAME,name,RUN_DATE
		FROM 
(

select  ROW_NUMBER() OVER (ORDER BY NAME,RUN_DATE,RUN_TIME) ID,
@@servername as SERVER_NAME,NAME,RUN_DATE,RUN_TIME,RUN_STATUS,RUN_DURATION,RETRIES_ATTEMPTED
         
FROM MSDB.DBO.SYSJOBHISTORY SJH         
JOIN MSDB.DBO.SYSJOBS_VIEW  SJ          
ON (SJ.JOB_ID = SJH.JOB_ID)  
WHERE  SJH.run_status = 0       
-- and SJH.RUN_DATE =cast(@DATE_CURRENT   as int)  
--AND SJH.RUN_TIME >= cast(@TIME_CURRENT   as int)  
--AND SJH.STEP_ID=0 
) Jobs 	GROUP BY SERVER_NAME,name,RUN_DATE


),

		
		BACKUP_ALL AS
		(
		
select  ROW_NUMBER() OVER (ORDER BY NAME,RUN_DATE,RUN_TIME) ID,
@@servername as SERVER_NAME,NAME,RUN_DATE,RUN_TIME,RUN_STATUS,RUN_DURATION,RETRIES_ATTEMPTED
         
FROM MSDB.DBO.SYSJOBHISTORY SJH         
JOIN MSDB.DBO.SYSJOBS_VIEW  SJ          
ON (SJ.JOB_ID = SJH.JOB_ID)  
WHERE  SJH.run_status = 0       
-- and SJH.RUN_DATE =cast(@DATE_CURRENT   as int)  
--AND SJH.RUN_TIME >= cast(@TIME_CURRENT   as int)  
--AND SJH.STEP_ID=0 
)

INSERT INTO DBA_ALL_FAILED_JOB 
SELECT  Job_recent.SERVER_NAME [SERVER],Job_recent.name [Job Name],Job_recent.[Run_date], Job_recent.[Run_time],Failure_count
FROM Job_recent ,BACKUP_ALL 
WHERE Job_recent.ID=BACKUP_ALL.ID 
and Job_recent.RUN_DATE =cast(@DATE_CURRENT   as int)  
AND Job_recent.RUN_TIME >= cast(@TIME_CURRENT   as int)  
--AND Job_recent.STEP_ID=0 
 
        
 DECLARE  ALLSERVER CURSOR        
 FOR        
 SELECT SERVERNAME,DESCRIPTION FROM DBADATA.DBO.DBA_ALL_SERVERS
 WHERE edition <>'express' 
 --AND Category ='PROD' 
 --AND (DESCRIPTION NOT LIKE 'y%' and DESCRIPTION NOT LIKE 'c%' )
 --and DESCRIPTION not in('SCFS1\BKUPEXEC','DUBSMSIP01')
 AND svr_status ='running'
       
 OPEN ALLSERVER        
 FETCH NEXT FROM ALLSERVER INTO  @SERVER,@DESCRIPTION        
        
 WHILE @@FETCH_STATUS=0        
  BEGIN    
       
If  @DESCRIPTION like 'A%' or @DESCRIPTION like 'B%'
Begin 
set @DATE_CURRENT_Loop=@DATE_CURRENT_US;  
set @TIME_CURRENT_Loop=@TIME_CURRENT_US;  
--Print @DATE_CURRENT_Loop +' '+@TIME_CURRENT_Loop +' '+@DESCRIPTION+': Non UK'  
end  
  
else  
Begin  
set @DATE_CURRENT_Loop=@DATE_CURRENT;  
set @TIME_CURRENT_Loop=@TIME_CURRENT;  
--Print @DATE_CURRENT_Loop +' '+@TIME_CURRENT_Loop +' '+@DESCRIPTION+': UK' 

 
end  
  
 
Begin try  
  EXEC ('  
  
;With Job_recent As (

SELECT max(RUN_TIME) as RUN_TIME,MAX(ID) ID, count(name) Failure_count,name,RUN_DATE
		FROM 
(

select  ROW_NUMBER() OVER (ORDER BY NAME,RUN_DATE,RUN_TIME) ID,
@@servername as SERVER_NAME,NAME,RUN_DATE,RUN_TIME,RUN_STATUS,RUN_DURATION,RETRIES_ATTEMPTED
         
FROM ['+@SERVER+'].MSDB.DBO.SYSJOBHISTORY SJH         
JOIN ['+@SERVER+'].MSDB.DBO.SYSJOBS_VIEW  SJ          
ON (SJ.JOB_ID = SJH.JOB_ID)  
WHERE  SJH.run_status = 0       
-- and SJH.RUN_DATE =cast('+@DATE_CURRENT_Loop+'   as int)  
--AND SJH.RUN_TIME >= cast('+@TIME_CURRENT_loop+'   as int)  
--AND SJH.STEP_ID=0 
) Jobs 	GROUP BY SERVER_NAME,name,RUN_DATE


),

		
		BACKUP_ALL AS
		(
		
select  ROW_NUMBER() OVER (ORDER BY NAME,RUN_DATE,RUN_TIME) ID,
@@servername as SERVER_NAME,NAME,RUN_DATE,RUN_TIME,RUN_STATUS,RUN_DURATION,RETRIES_ATTEMPTED
         
FROM ['+@SERVER+'].MSDB.DBO.SYSJOBHISTORY SJH         
JOIN ['+@SERVER+'].MSDB.DBO.SYSJOBS_VIEW  SJ          
ON (SJ.JOB_ID = SJH.JOB_ID)  
WHERE  SJH.run_status = 0       
-- and SJH.RUN_DATE =cast('+@DATE_CURRENT_Loop+'   as int)  
--AND SJH.RUN_TIME >= cast('+@TIME_CURRENT_loop+'   as int)  
--AND SJH.STEP_ID=0 
)

INSERT INTO DBA_ALL_FAILED_JOB 
SELECT  '''+@DESCRIPTION+''' [SERVER],Job_recent.name [Job Name],Job_recent.[Run_date], Job_recent.[Run_time],Failure_count
FROM Job_recent ,BACKUP_ALL 
WHERE Job_recent.ID=BACKUP_ALL.ID 
and Job_recent.RUN_DATE =cast('+@DATE_CURRENT_Loop+'   as int)  
AND Job_recent.RUN_TIME >= cast('+@TIME_CURRENT_loop+'   as int)  
--AND Job_recent.STEP_ID=0 
'  
   )     
end try
BEGIN CATCH
--SELECT @SERVER, ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER,'Jobs',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()


END CATCH  
--PRINT 'SERVER ' +@SERVER+' COMPLETED.'    
FETCH NEXT FROM  ALLSERVER INTO  @SERVER,@DESCRIPTION         
  END         
 CLOSE ALLSERVER        
 DEALLOCATE ALLSERVER  
 

-- SELECT * FROM  DBADATA.DBO.DBA_ALL_FAILED_JOB  


IF EXISTS(
select 1 from DBA_ALL_FAILED_JOB
--WHERE RUN_DATE>=@DATE_CURRENT AND RUN_TIME >= @TIME_CURRENT group by SERVER,JOB_NAME,RUN_DATE
)  
  
BEGIN  
  
DECLARE @JOBNAME VARCHAR(200)    
DECLARE @SERVERNAME VARCHAR(200)    
DECLARE @RUNDATE VARCHAR(200)    
DECLARE @RUNTIME VARCHAR(200)   
DECLARE @RUNduration VARCHAR(200)     
DECLARE @failure_count VARCHAR(200)  
   
DECLARE  FAILEDJOBS CURSOR FOR 
    
select SERVER,JOB_NAME,RUN_DATE,RUN_TIME,failure_count  from DBA_ALL_FAILED_JOB
--WHERE RUN_DATE>=@DATE_CURRENT AND RUN_TIME >= @TIME_CURRENT
--group by SERVER,JOB_NAME,RUN_DATE,RUN_TIME order by RUN_TIME desc 
  
  
OPEN FAILEDJOBS    
    
FETCH NEXT FROM  FAILEDJOBS    
INTO @SERVERNAME,@JOBNAME,@RUNDATE,@RUNTIME,@failure_count
    
DECLARE @BODY1 VARCHAR(MAX)    
SET @BODY1= '<font size=2 color=#385D7C   face=''verdana''><B>FAILED JOBS IN LAST HOURS</b> </font>    
<P>     
<font size=1 color=#385D7C   face=''verdana''>    
  
<Table border=2  bgcolor=#B3F4FF cellpadding=1  style="color:#385D7C;font-face:verdana;font-size:12px;">    
<b> <tr bgcolor=#385D7C align=center style="color:WHITE;font-weight:bold">   
<td width=450 color=white>SERVER</td>    
<td width=450 color=white>JOB NAME</td>  
<td width=100 color=white>RUN DATE</td>   
<td width=100 color=white>RUN TIME</td>    
<td width=100 color=white>Failure Count</td>    

</tr>'  
  
/*<Table border=0  bgcolor=#B3F4FF cellspacing=5 CELLPADDING=5  style="color:#385D7C ;font-face:verdana;font-size:12px;">      
     
</tr>' */  
   
WHILE @@FETCH_STATUS=0    
BEGIN    
SET @BODY1= @BODY1 +    
'<tr>    
<td>'+@SERVERNAME+'</TD>'+    
'<td>'+@JOBNAME+'</TD>'+    
'<td>'+isnull(STUFF(STUFF(@RUNDATE,7,0,'/'),5,0,'/'),'')+'</TD>'+    
'<td>'+isnull(STUFF(STUFF(right(cast(cast(@RUNTIME as int)+1000000 as varchar(7)),6),5,0,':'),3,0,':'),'')+'</TD>'+
'<td>'+@failure_count+'</TD>'+  
--'<td>'+@run_status+'</TD>
+'</TR>'    
    
FETCH NEXT FROM  FAILEDJOBS    
INTO @SERVERNAME,@JOBNAME,@RUNDATE,@RUNTIME,@failure_count
END    
CLOSE FAILEDJOBS    
DEALLOCATE FAILEDJOBS    
SET @BODY1=@BODY1+'</Table> </p>    
<p>    
<font style="color:#385D7C ;font-face:verdana;font-size:9px;"> Generated on '    
+convert(varchar(30),getdate(),100)+'  </BR>    
This is an auto generated mail by CNA DBA Team. If you receive this email by mistake please contact us. 
 </br>
© Property of DBA Team.    
 </font>'    
  
DECLARE @EMAILIDS VARCHAR(500)    
    
SELECT @EMAILIDS=  
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS   
FROM DBADATA.dbo.DBA_ALL_OPERATORS WHERE name ='muthu' and STATUS =1


DECLARE @EMAILIDS1 VARCHAR(500)
SELECT @EMAILIDS1=
COALESCE(@EMAILIDS1+';','')+EMAIL_ADDRESS  FROM DBAdata.DBO.DBA_ALL_OPERATORS
WHERE STATUS =1 and Mail_copy='CC'

EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,    
    @SUBJECT = 'DBA: FAILED JOBS FOR LAST ONE HOURS',    
    @BODY = @BODY1, 
    @copy_recipients=@EMAILIDS1,
    @BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';    
    
    
END     

insert into DBAdata_Archive.dbo.DBA_all_failed_job
select *,GETDATE() from DBA_all_failed_job

END  
  