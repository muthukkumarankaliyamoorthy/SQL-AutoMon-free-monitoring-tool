
create proc Usp_Automon_job_status
as

if exists (select name,enabled from msdb.dbo.sysjobs where enabled<>1 and name like 'DBA%')

begin

DECLARE @html nvarchar(MAX);
EXEC spQueryToHtmlTable @html = @html OUTPUT,  @query = N'select name,enabled from msdb.dbo.sysjobs where enabled<>1 and name like ''DBA%'' ';

EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'Muthu',
    @recipients = 'dba@abcd.com;',
    @subject = 'Automon job status',
    @body = @html,
    @body_format = 'HTML',
    @query_no_truncate = 1,
    @attach_query_result_as_file = 0;
end