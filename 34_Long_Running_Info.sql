/*

USE [DBAdata]
GO
--drop table [tbl_long_running_query]
CREATE TABLE [dbo].[tbl_long_running_query](
server_name varchar (200),
[db_name] [nvarchar](128) NULL,
[cmd] [nchar](26) NOT NULL,
[program_name] [nchar](128) NOT NULL,
[loginame] [nchar](128) NOT NULL,
[Run_Status] [nchar](30) NULL,
[RunTime_minute] [int] NULL,
[RunTime_Day] [int] NULL,
[spid] [smallint] NOT NULL,
[blocked] [smallint] NOT NULL,
[hostname] [nchar](128) NOT NULL,
[login_time] [datetime] NOT NULL,
[last_batch] [datetime] NOT NULL,
[Run_date] [datetime] NOT NULL
)

GO



use dbadata_archive
go

--drop table [tbl_long_running_query]
CREATE TABLE [dbo].[tbl_long_running_query](
server_name varchar (200),
[db_name] [nvarchar](128) NULL,
[cmd] [nchar](26) NOT NULL,
[program_name] [nchar](128) NOT NULL,
[loginame] [nchar](128) NOT NULL,
[Run_Status] [nchar](30) NULL,
[RunTime_minute] [int] NULL,
[RunTime_Day] [int] NULL,
[spid] [smallint] NOT NULL,
[blocked] [smallint] NOT NULL,
[hostname] [nchar](128) NOT NULL,
[login_time] [datetime] NOT NULL,
[last_batch] [datetime] NOT NULL,
[Run_date] [datetime] NOT NULL

)

select * from tbl_long_running_query  

*/


USE [DBADATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  

create PROCEDURE [dbo].[USP_DBA_GET_Long_running_Details]
/*
Summary:     Failed job findings
Contact:     Muthukkumaran Kaliyamoorhty SQL DBA
Description: Failed job findings

ChangeLog:
Date         CoderDescription
2017-jun-21 Muthukkumaran Kaliyamoorhty     Updated the 2012 functionality                   


*/
 
--WITH ENCRYPTION
          
AS  
BEGIN     
SET NOCOUNT ON       
TRUNCATE TABLE tbl_long_running_query 
--select * from tbl_long_running_query

     
DECLARE @DESCRIPTION VARCHAR(200)    
DECLARE @SERVER VARCHAR(200)    
Declare @Days int  
 

        
 DECLARE  ALLSERVER CURSOR        
 FOR        
 SELECT SERVERNAME,DESCRIPTION FROM DBADATA.DBO.DBA_ALL_SERVERS
 --WHERE edition <>'express' 

 where svr_status ='running'
       
 OPEN ALLSERVER        
 FETCH NEXT FROM ALLSERVER INTO  @SERVER,@DESCRIPTION        
        
 WHILE @@FETCH_STATUS=0        
  BEGIN    


Begin try  
  EXEC ('  

INSERT INTO tbl_long_running_query                  
SELECT  
'''+@DESCRIPTION+''' [SERVER], db_name(dbid) as [db_name],cmd,program_name,loginame,max(status) as [Run_Status],datediff(minute,login_time,getdate()) as [RunTime_minute],
datediff(day,login_time,getdate()) as [RunTime_Day]
,spid,blocked, hostname,login_time,last_batch,getdate()  [Run_date] --into tbl_long_running_query
FROM ['+@SERVER+'].master.DBO.sysprocesses where status not in (''sleeping'',''background'') and spid >51
and cmd not in (''WAITFOR'',''AWAITING COMMAND'') -- removing commands
--and lastwaittype not in (''MISCELLANEOUS'',''WAITFOR'') -- removing MISCELLANEOUS waits
and dbid not in (1,2,3,4) and db_name(dbid) not in (''dbutil'') -- removing system dbs and dbutil
and datediff(Minute,login_time,getdate()) > =15 -- more than xx minutes
group by dbid ,cmd,program_name,spid,blocked, hostname,login_time,last_batch,loginame

'  
   )     
end try
BEGIN CATCH
--SELECT @SERVER, ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
-- select * from tbl_Error_handling
SELECT @SERVER,'Long Run',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
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
 
-- select * from tbl_long_running_query order by 5 desc
IF EXISTS(
select * from tbl_long_running_query

)  

BEGIN 

DECLARE @html nvarchar(MAX);
EXEC spQueryToHtmlTable @html = @html OUTPUT,  
@query = N'
select * from tbl_long_running_query

'
/*
EXEC msdb.dbo.sp_send_dbmail
    @PROFILE_NAME=@@servername,
    @recipients = 'abcd.com',
@copy_recipients='abcd.com',
    @subject = 'Long running sessions:',
    @body = @html,
    @body_format = 'HTML',
    @query_no_truncate = 1,
    @attach_query_result_as_file = 0;
*/

DECLARE @EMAILIDS VARCHAR(500)
SELECT @EMAILIDS=
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS  FROM DBAdata.DBO.DBA_ALL_OPERATORS
WHERE STATUS =1

DECLARE @EMAILIDS1 VARCHAR(500)
SELECT @EMAILIDS1=
COALESCE(@EMAILIDS1+';','')+EMAIL_ADDRESS  FROM DBAdata.DBO.DBA_ALL_OPERATORS
WHERE STATUS =1 and Mail_copy='CC'

EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@PROFILE_NAME='muthu',
@subject = 'Long running sessions:',
@BODY = @html,
@copy_recipients=@EMAILIDS1,
@BODY_FORMAT = 'HTML',
@query_no_truncate = 1,
@attach_query_result_as_file = 0;
  
end
insert into DBAdata_Archive.dbo.tbl_long_running_query
select * from tbl_long_running_query

END  