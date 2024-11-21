
 

/*
Make sure your agents are in the correct category 
i.e Merge agents under REPL-Merge, 
Distribution agents under REPL-Distribution 
and LogReader agent under REPL-LogReader
select * from Tbl_Repl_Agent_Satus
drop table Tbl_Repl_Agent_Satus

*/

use DBAUtil
go
Alter proc USP_Repl_Agent_Satus_SSRS_BI
as

---- send an excel
 
-- select * from DBA_all_failed_job_last_One_day_new order by 5 desc
IF EXISTS(
select *  FROM [REPL_HOMESQL01\HOMESQL01].[DBAUtil].DBO.Tbl_Repl_Agent_Satus where AgentStatus <>'Running' and name not in ('HOMESQL01\HOMESQL01-HDXDB-HDXDB-DR-HDX-DR-SQL02-149')
)  

BEGIN 

DECLARE @html nvarchar(MAX);
EXEC spQueryToHtmlTable @html = @html OUTPUT,  
 @query = N'select *  FROM [REPL_HOMESQL01\HOMESQL01].[DBAUtil].DBO.Tbl_Repl_Agent_Satus where AgentStatus <>''Running'' and name not in (''HOMESQL01\HOMESQL01-HDXDB-HDXDB-DR-HDX-DR-SQL02-149'')';

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
    @subject = 'Replication Agent Status:',
    @body = @html,
    @body_format = 'HTML',
    @query_no_truncate = 1,
    @attach_query_result_as_file = 0;
   
end