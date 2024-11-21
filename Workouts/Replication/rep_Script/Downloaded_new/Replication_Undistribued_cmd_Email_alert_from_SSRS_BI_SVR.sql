
/*
Create TABLE DBAUtil.dbo.TBL_UnDist_CMD_Archive ( publisher SYSNAME , publisher_db SYSNAME, publication SYSNAME, subscriber SYSNAME, subscriber_db SYSNAME, Pending_Commands int , time_to_deliver_pending_Commands int, Load_Date datetime)
select * from DBAUtil.dbo.TBL_UnDist_CMD_Archive
*/
Use DBAUtil;
GO
Set NOCOUNT ON;
GO

alter proc USP_Repl_Undistriuted_cmd_SSRS_BI
as

begin

---- send an excel
 

Exec [REPL_HOMESQL01\HOMESQL01].DBAUtil.dbo.USP_Repl_Undistriuted_cmd
 
IF EXISTS(
select * from [REPL_HOMESQL01\HOMESQL01].DBAUtil.dbo.TBL_temp_sub2_UnDist_CMD where pending_commands> '100' and publication not in ('HDXDB-DR')

)  

BEGIN 

DECLARE @html nvarchar(MAX);
EXEC spQueryToHtmlTable @html = @html OUTPUT,  
 @query = N'select * from [REPL_HOMESQL01\HOMESQL01].DBAUtil.dbo.TBL_temp_sub2_UnDist_CMD where pending_commands> ''100'' and publication not in (''HDXDB-DR'')', @orderBy = N'ORDER BY [pending_commands]';

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
    @subject = 'Replication Undistributed Commands:',
    @body = @html,
    @body_format = 'HTML',
    @query_no_truncate = 1,
    @attach_query_result_as_file = 0;
   
end
--select * from DBAUtil.dbo.tbl_Replication_lag_Archive
insert into DBAUtil.dbo.TBL_UnDist_CMD_Archive
select *,GETDATE() from [REPL_HOMESQL01\HOMESQL01].DBAUtil.dbo.TBL_temp_sub2_UnDist_CMD
--*/

end
