/*
use DBAUtil
go
CREATE TABLE [dbo].[TBL_Repl_Row_Count_Email_Alert_Archive](
	[publisher_srv] [varchar](255) NULL,
	[publisher_db] [varchar](255) NULL,
	[subscriber_srv] [varchar](255) NULL,
	[subscriber_db] [varchar](255) NULL,
	[publication] [varchar](255) NULL,
	[object_type] [varchar](255) NULL,
	[source_objectname] [varchar](511) NULL,
	[destination_objectname] [varchar](511) NULL,
	[rowcount_diff] [int] NULL,
	upload_date datetime
)

select * from TBL_Repl_Row_Count_Email_Alert_Archive

*/

use DBAUtil
go
alter proc USP_Repl_Row_Count_cmd_SSRS_BI
as
begin


Exec [REPL_HOMESQL01\HOMESQL01].DBAUtil.dbo.USP_Repl_Row_Count
 
IF EXISTS(
select * from [REPL_HOMESQL01\HOMESQL01].DBAUtil.dbo.TBL_Repl_Row_Count_Email_Alert where rowcount_diff >500

)  

BEGIN 

DECLARE @html nvarchar(MAX);
EXEC spQueryToHtmlTable @html = @html OUTPUT,  
 @query = N'select * from [REPL_HOMESQL01\HOMESQL01].DBAUtil.dbo.TBL_Repl_Row_Count_Email_Alert where rowcount_diff >500', @orderBy = N'ORDER BY [rowcount_diff]';

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
    @subject = 'Replication RowCount Difference:',
    @body = @html,
    @body_format = 'HTML',
    @query_no_truncate = 1,
    @attach_query_result_as_file = 0;
   
end
--select * from DBAUtil.dbo.tbl_Replication_lag_Archive
insert into DBAUtil.dbo.TBL_Repl_Row_Count_Email_Alert_Archive
select *,GETDATE() from [REPL_HOMESQL01\HOMESQL01].DBAUtil.dbo.TBL_Repl_Row_Count_Email_Alert
--*/

End


