
/**************************************************************************************
https://dba.stackexchange.com/questions/205528/dba-blocking-query-email-alert
Author:		KIN SHAH
Date	:	03/02/2011

Adapt the script as per your env --> places to change ---- CHANGE HERE !!

This script will create 
	- a blocking detection alert
	- table to hold blocking information
	- modify the 'blocked process threshold' sp_configure option to 5 mins (300 sec) 
	- create a sql agent job that will fire in resonse to the alert to capture blocking info

Disclaimer
The views expressed on my posts on this site are mine alone and do not reflect the views of my company. All posts of mine are provided "AS IS" with no warranties, and confers no rights.
 
The following disclaimer applies to all code, scripts and demos available on my posts:
 
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED “AS IS” WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. 
 
************************************************************************************/
USE [dbaalert] ---- CHANGE HERE !!
GO

IF OBJECT_ID('dbo.Scores', 'U') IS NOT NULL
 drop table [dbo].[BlockingInfo];
-- *************change the blocking threshold to 5mins (300sec) ********** ---- 
EXEC sp_configure 'blocked process threshold', 300 ---- CHANGE HERE !!
go
reconfigure with override
go
--------- **** create table to hold blocking data ********* ----------

/****** Object:  Table [dbo].[BlockingInfo]    Script Date: 02/17/2011 15:41:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[BlockingInfo](
	[RecordId] [int] IDENTITY(1,1) NOT NULL,
	[AlertTime] [datetime] NOT NULL,
	[BlockingDetails] [xml] NULL,
	[Notified] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[RecordId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[BlockingInfo] ADD  CONSTRAINT [DF_blocking_flag]  DEFAULT ((0)) FOR [Notified]
GO
SET QUOTED_IDENTIFIER OFF;
GO
---------------------------- disable old and create new job---------------------------------------------
USE [msdb]
GO

--- disable old job on the server
IF  EXISTS (SELECT name FROM msdb.dbo.sysjobs WHERE name = N'DBA Group - Monitoring - Blocking Detector')
EXEC msdb.dbo.sp_update_job @job_name=N'DBA Group - Monitoring - Blocking Detector', @enabled = 0
GO

USE [msdb]
GO

/****** Object:  Job [DBA Group - Monitoring - Blocked Process Detector]    Script Date: 03/02/2011 11:47:32 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 03/02/2011 11:47:33 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA Group - Monitoring - Blocked Process Detector', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Authors: Kin Shah', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Insert Blocking info]    Script Date: 03/02/2011 11:47:34 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Insert Blocking info', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'INSERT INTO dbo.BlockingInfo (

AlertTime,

BlockingDetails

)

VALUES (

GETDATE(),

''$(ESCAPE_NONE(WMI(TextData)))''

)', 
		@database_name=N'dbaalert', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Send Email]    Script Date: 03/02/2011 11:47:35 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Send Email', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
if exists (select 1 from dbo.BlockingInfo where Notified = 0 ) 
begin

DECLARE @AlertTime datetime
DECLARE @BlockingDetails xml
DECLARE @RecordID int
-- Block Events table.
if object_id (''tempdb..#BlockEvents'') > 0 drop table #BlockEvents
create table #BlockEvents (
AlertTime datetime,
BlockingDetails xml,
RecordID int
) ;
if object_id (''tempdb..#dba_job_name'') > 0 
drop table #dba_job_name
create table #dba_job_name
(
 id int identity (1,1),
 job_sid varchar(256) NULL,
 job_name varchar(256) NULL 
)
-- Block Info table.
if object_id (''tempdb..#BlockInfo'') > 0 
drop table #BlockInfo
create table #BlockInfo (
RecordID int,
BlockedDBName  sysname null,
BlockedHostName sysname null,
BlockingDBName  sysname null,
BlockingHostName sysname null,
BlockedWaitResource varchar (256) NULL,
WaitTime_sec int null,
BlockedTransactionName varchar(256) NULL,
BlockedSPID int NULL,
BlockedProgram varchar(256) NULL,
BlockedProgram_sid varchar(256) NULL,
BlockedProgram_jn varchar(256) NULL,
BlockingSPID int NULL,
BlockingProgram varchar(256) NULL,
BlockingProgram_sid varchar(256) NULL,
BlockingProgram_jn varchar(256) NULL

) ;

-- Get all blocking events within selected period.
INSERT INTO #BlockEvents (
AlertTime,
BlockingDetails,
RecordID
)

SELECT
AlertTime,
BlockingDetails,
RecordID
FROM dbo.BlockingInfo where Notified = 0;

WHILE EXISTS (SELECT RecordID FROM #BlockEvents)

BEGIN
	SELECT TOP 1 @AlertTime = AlertTime,
	@BlockingDetails = BlockingDetails,
	@RecordID = RecordID
	FROM #BlockEvents
	ORDER BY RecordID DESC

	-- Insert into temporary table for processing.

	INSERT INTO #BlockInfo
	SELECT @RecordID,db_name(a.BlockedCurrentDb),a.BlockedHostName,db_name(a.BlockingCurrentDb),a.BlockingHostName, a.BlockedWaitResource
	,a.BlockedWaitTime/(1000) as WaitTime_sec,a.BlockedTransactionName,a.BlockedSPID,a.BlockedProgram,null,null
	,a.BlockingSPID,a.BlockingProgram,null,null
	FROM
	(SELECT
	ref.value(''./blocked-process[1]/process[1]/@waitresource'', ''varchar(512)'') AS BlockedWaitResource,
	ref.value(''./blocked-process[1]/process[1]/@waittime'', ''int'') AS BlockedWaitTime,
	ref.value(''./blocked-process[1]/process[1]/@transactionname'', ''sysname'') AS BlockedTransactionName,
	ref.value(''./blocked-process[1]/process[1]/@spid'', ''int'') AS BlockedSPID,
	ref.value(''./blocked-process[1]/process[1]/@clientapp'', ''varchar(256)'') AS BlockedProgram,
	ref.value(''./blocked-process[1]/process[1]/@hostname'', ''varchar(256)'') AS BlockedHostName,
	ref.value(''./blocked-process[1]/process[1]/@loginname'', ''varchar(256)'') AS BlockedLoginName,
	ref.value(''./blocked-process[1]/process[1]/@currentdb'', ''varchar(256)'') AS BlockedCurrentDb,

	ref.value(''./blocking-process[1]/process[1]/@waitresource'', ''varchar(512)'') AS BlockingWaitResource,
	ref.value(''./blocking-process[1]/process[1]/@waittime'', ''int'') AS BlockingWaitTime,
	ref.value(''./blocking-process[1]/process[1]/@transactionname'', ''sysname'') AS BlockingTransactionName,
	ref.value(''./blocking-process[1]/process[1]/@spid'', ''int'') AS BlockingSPID,
	ref.value(''./blocking-process[1]/process[1]/@clientapp'', ''varchar(256)'') AS BlockingProgram,
	ref.value(''./blocking-process[1]/process[1]/@hostname'', ''varchar(256)'') AS BlockingHostName,
	ref.value(''./blocking-process[1]/process[1]/@loginname'', ''varchar(256)'') AS BlockingLoginName,
	ref.value(''./blocking-process[1]/process[1]/@currentdb'', ''varchar(256)'') AS BlockingCurrentDb
	FROM @BlockingDetails.nodes(''//blocked-process-report'')
	AS node(ref)) AS a

	DELETE FROM #BlockEvents
	WHERE RecordID = @RecordID

END

insert into #dba_job_name (job_sid)
select distinct left(right(([BlockedProgram]),44),34) from #BlockInfo where lower(BlockedProgram) like ''sqlagent%''
union
select distinct left(right(([BlockingProgram]),44),34) from #BlockInfo where lower(BlockingProgram) like ''sqlagent%''

-- update job_name on #dba_job_name
-- Due to uniqueidentifier problem, we need to run under @sqltext
declare @cur int,@tol int
select @cur=1,@tol =0
select @tol= max(id) from #dba_job_name
declare @job_id varchar(max),@sqltext varchar(max)

while (@cur<=@tol)
begin
	select @job_id = job_sid from #dba_job_name where id = @cur
	select @sqltext=''update #dba_job_name set job_name  = (select [name]  from msdb..sysjobs with (nolock) where job_id = ''+@job_id+'') where id =''+convert(varchar(max),@cur)
	exec (@sqltext);
   select @cur=@cur+1
end

-- strip out job_id
update #BlockInfo 
set BlockedProgram_sid = case when (lower(BlockedProgram) like ''sqlagent%'') then left(right(([BlockedProgram]),44),34) end,
    BlockingProgram_sid = case when (lower(BlockingProgram) like ''sqlagent%'') then left(right(([BlockingProgram]),44),34) end

-- update job_name for BlockedProgram
update b
set b.BlockedProgram_jn = j.job_name
from #BlockInfo b join #dba_job_name j
on b.BlockedProgram_sid = j.job_sid

-- update job_name for BlockingProgram
update b
set b.BlockingProgram_jn = j.job_name
from #BlockInfo b join #dba_job_name j
on b.BlockingProgram_sid = j.job_sid

declare @tableHTML nvarchar(max)
set @tableHTML =N''<H3><FONT SIZE="3" FACE="Tahoma">Blocking Has occured.. Please Investigate on ''+ @@servername +''</FONT></H3>''
set @tableHTML = @tableHTML + N''<table border="1">'' +
           N''<FONT SIZE="2" FACE="Calibri">'' +            
            N''<tr><th align="center">RecordId</th>'' +
			N''<th align="center">BlockedDBName</th>'' +
			N''<th align="center">BlockedHostName</th>'' +
            N''<th align="center">BlockingDBName</th>'' +
            N''<th align="center">BlockingHostName</th>'' +
        N''<th align="center">BlockedWaitResource</th>'' +
        N''<th align="center">WaitTime_sec</th>'' +
        N''<th align="center">BlockedTransactionName</th>'' +
        N''<th align="center">BlockedSPID</th>'' +
        N''<th align="center">BlockedProgram</th>'' +
        N''<th align="center">BlockingSPID</th>'' +
        N''<th align="center">BlockingProgram</th>'' +
			N''</tr>'' +
           ISNULL(CAST ( ( 
							select  td = '''',
									td = ISNULL(RecordId,''''),'''',
                              		td = ISNULL(BlockedDBName,''**No data available**''),'''',
                              		td = ISNULL(BlockedHostName,''**No data available**''),'''',
									td = ISNULL(BlockingDBName,''**No data available**''),'''',
									td = ISNULL(BlockingHostName,''**No data available**''),'''',
									td = ISNULL(BlockedWaitResource,''**No data available**''),'''',
									td = ISNULL(WaitTime_sec,''''),'''',
									td = ISNULL(BlockedTransactionName,''**No data available**''),'''',
									td = ISNULL(BlockedSPID,''''),'''',
									td = ISNULL(COALESCE(BlockedProgram_jn,BlockedProgram),''**No data available**''),'''',
									td = ISNULL(BlockingSPID,''''),'''',
									td = ISNULL(COALESCE(BlockingProgram_jn,BlockingProgram),''**No data available**''),''''
							  from #BlockInfo where  BlockingDBName is not null 
							 
	FOR XML PATH(''tr''), TYPE 

            ) AS NVARCHAR(MAX) ),'''') +
            N''</FONT>'' +
            N''</table>'' ;
   ------------ send email         
declare @subject1 varchar(50)
set @subject1 = ''Blocked Process Report for ''+@@servername
EXEC msdb.dbo.sp_send_dbmail 
            @profile_name = ''You db mail profile'',			---- CHANGE HERE !!
            @recipients=''yourcompanyDBATEAM@company.com'',	    ---- CHANGE HERE !!
            @subject = @subject1,
            @body = @tableHTML,
            @body_format = ''HTML'' ;
end
go

-- drop all temp tables
if object_id (''tempdb..#BlockEvents'') > 0 drop table #BlockEvents
if object_id (''tempdb..#dba_job_name'') > 0 drop table #dba_job_name
if object_id (''tempdb..#BlockInfo'') > 0 drop table #BlockInfo

-- update the BlockingInfo table so that when the job runs it wont send out alert
update  dbo.BlockingInfo
set Notified = 1 where Notified = 0

', 
		@database_name=N'dbaalert', ---- CHANGE HERE !!
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Trim Records Older than 15 days]    Script Date: 03/02/2011 11:47:35 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trim Records Older than 15 days', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'use dbaalert   ---- CHANGE HERE !!
go
declare @starttime datetime
-- trim records older than 15 days
select @starttime = CONVERT(varchar,GETDATE()-15,112) 
--select @starttime
delete from BlockingInfo where convert(varchar, AlertTime, 112) <= @starttime and Notified =1', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

------------ create alert (this is dynamic for default and named instances)
USE [msdb]
GO
-- create an WMI alert to respond to blocking 
IF EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Respond to Blocking')
EXEC msdb.dbo.sp_delete_alert @name=N'Respond to Blocking'
GO
DECLARE @server_namespace varchar(255)
IF ISNULL(CHARINDEX('\', @@SERVERNAME), 0) > 0
SET @server_namespace = N'\\.\root\Microsoft\SqlServer\ServerEvents\' + SUBSTRING(@@SERVERNAME, ISNULL(CHARINDEX('\', @@SERVERNAME), 0) + 1, LEN(@@SERVERNAME) - ISNULL(CHARINDEX('/', @@SERVERNAME), 0))
ELSE
SET @server_namespace = N'\\.\root\Microsoft\SqlServer\ServerEvents\MSSQLSERVER'
EXEC msdb.dbo.sp_add_alert @name=N'Respond to Blocking',
@wmi_namespace=@server_namespace,
@wmi_query=N'SELECT * FROM BLOCKED_PROCESS_REPORT', 
@job_name=N'DBA Group - Monitoring - Blocked Process Detector' ---- CHANGE HERE  job name!!
GO
