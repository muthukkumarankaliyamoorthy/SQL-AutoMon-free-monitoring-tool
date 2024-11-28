/*

USE [DBAdata]
GO
--drop table tbl_Blocking_Details
go
CREATE TABLE [dbo].[tbl_Blocking_Details](
[server_name] [varchar](1000) NULL,
[spid] [smallint] NOT NULL,
[blocked] [smallint] NOT NULL,
[last_batch] [datetime] NOT NULL,
[waittime] [bigint] NOT NULL,
[waitresource] [nchar](256) NOT NULL,
[lastwaittype] [nchar](32) NOT NULL,
[cmd] [nchar](26) NOT NULL,
[DBid] [int] NULL,
[loginame] [nchar](128) NOT NULL,
[hostname] [nchar](128) NOT NULL,
[cpu] [int] NOT NULL
)

GO



use dbadata_archive
go
--drop table tbl_Blocking_Details
go
CREATE TABLE [dbo].[tbl_Blocking_Details](
[server_name] [varchar](1000) NULL,
[spid] [smallint] NOT NULL,
[blocked] [smallint] NOT NULL,
[last_batch] [datetime] NOT NULL,
[waittime] [bigint] NOT NULL,
[waitresource] [nchar](256) NOT NULL,
[lastwaittype] [nchar](32) NOT NULL,
[cmd] [nchar](26) NOT NULL,
[DBid] [int] NULL,
[loginame] [nchar](128) NOT NULL,
[hostname] [nchar](128) NOT NULL,
[cpu] [int] NOT NULL,
date Datetime
)


select * from tbl_Blocking_Details  

*/


USE [DBADATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  

create PROCEDURE [dbo].[USP_DBA_GET_Blocking_running_Details]
/*
Summary:     Failed job findings
Contact:     Muthukkumaran Kaliyamoorhty SQL DBA


ChangeLog:
Date         CoderDescription
2017-jun-21 Muthukkumaran Kaliyamoorhty     Updated the 2012 functionality                   


*/
 
--WITH ENCRYPTION
          
AS  
BEGIN     
SET NOCOUNT ON       
TRUNCATE TABLE tbl_Blocking_Details 
-- select * from tbl_Blocking_Details

     
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

INSERT INTO tbl_Blocking_Details 

select 
'''+@DESCRIPTION+''' [SERVER],sp.spid,sp.blocked, sp.last_batch,sp.waittime,sp.waitresource,sp.lastwaittype,sp.cmd, sp.dbid,
sp.loginame,sp.hostname,sp.cpu 
from ['+@SERVER+'].master.dbo.sysprocesses sp
where sp.spid>50 and sp.spid<>sp.blocked and sp.blocked<>0 and datediff(MINUTE,last_batch,GETDATE())>5

'  
   )     
end try
BEGIN CATCH
--SELECT @SERVER, ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
-- select * from tbl_Error_handling
SELECT @SERVER,'Blocking Run',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
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
 
-- select * from tbl_Blocking_Details order by 5 desc
IF EXISTS(
select * from tbl_Blocking_Details

)  

BEGIN 

DECLARE @html nvarchar(MAX);
EXEC spQueryToHtmlTable @html = @html OUTPUT,  
@query = N'
select * from tbl_Blocking_Details

'
/*
EXEC msdb.dbo.sp_send_dbmail
    @PROFILE_NAME=@@servername,
    @recipients = 'abcd.com',
@copy_recipients='abcd.com',

    @subject = 'Blocking Details:',
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
@subject = 'Blocking Details:',
@BODY = @html,
@copy_recipients=@EMAILIDS1,
@BODY_FORMAT = 'HTML',
@query_no_truncate = 1,
@attach_query_result_as_file = 0;

end
insert into DBAdata_Archive.dbo.tbl_Blocking_Details
select *, getdate() to_date from tbl_Blocking_Details
-- select * from DBAdata_Archive.dbo.tbl_Blocking_Details
--*/

END  