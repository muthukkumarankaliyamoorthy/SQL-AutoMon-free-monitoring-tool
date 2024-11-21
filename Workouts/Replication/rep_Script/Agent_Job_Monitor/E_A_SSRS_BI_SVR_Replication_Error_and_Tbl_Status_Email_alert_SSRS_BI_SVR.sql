

--drop table Tbl_Repl_Error_Status_Count
--create table Tbl_Repl_Error_Status_Count (Count_no int, Alert_name varchar(200) )
--select * from Tbl_Repl_Error_Status_Count


use DBAutil 
go
-- Exec USP_Repl_Error_Status_Count @Error_Status_count_no =1
ALTER PROC USP_REPL_ERROR_STATUS_COUNT

@Error_Status_count_no int
as


truncate table [DBAUtil].[dbo].Tbl_Repl_Error_Status_Count

insert into [DBAUtil].[dbo].Tbl_Repl_Error_Status_Count
select count(*) [Tbl_status_Count],'Tbl_status_Count_Result' from [REPL_HOMESQL01\HOMESQL01].distribution.dbo.MSsubscriptions where status =0 and subscriber_db not in ('HDXDB')
insert into Tbl_Repl_Error_Status_Count
SELECT  count(*) [Error_Count], 'Error_Count_Result' FROM [REPL_HOMESQL01\HOMESQL01].distribution.dbo.msrepl_errors where time  between dateadd(hour, -1, getdate()) and getdate()
--SELECT  count(*) [Error_Count], 'Error_Count_Result' FROM [REPL_HOMESQL01\HOMESQL01].distribution.dbo.msrepl_errors where time > getdate()-1
--WHERE Date between dateadd(hour, -1, getdate()) and getdate()




IF EXISTS(
select * from  [DBAUtil].[dbo].Tbl_Repl_Error_Status_Count where count_no>@Error_Status_count_no
-- select * from  [DBAUtil].[dbo].Tbl_Repl_Error_Status_Count
)  

BEGIN 

DECLARE @html nvarchar(MAX);
EXEC spQueryToHtmlTable @html = @html OUTPUT,  
 @query = N'select * from  [DBAUtil].[dbo].Tbl_Repl_Error_Status_Count';

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
    @subject = 'Replication Error and Table Status:',
    @body = @html,
    @body_format = 'HTML',
    @query_no_truncate = 1,
    @attach_query_result_as_file = 0;
   
end

