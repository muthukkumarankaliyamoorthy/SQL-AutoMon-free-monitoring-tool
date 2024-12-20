USE [DBAdata]
GO
/****** Object:  StoredProcedure [dbo].[USP_DBA_GETNEW_DB_AND_LOGIN]    Script Date: 9/27/2013 7:44:10 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
use dbadata
go
go
--drop table DBA_NEW_OBJECT_LOGIN_LIST
go
CREATE TABLE [dbo].[DBA_NEW_OBJECT_LOGIN_LIST](
	[SERVER_NAME] [varchar](100),
	[NAME] [sysname] NOT NULL,
	[CREATE_DATE] [datetime] NULL,
	[TYPE] [varchar](10) NULL
)


use dbadata_archive
go
--drop table DBA_NEW_OBJECT_LOGIN_LIST
go
CREATE TABLE [dbo].[DBA_NEW_OBJECT_LOGIN_LIST](
	[SERVER_NAME] [varchar](100),
	[NAME] [sysname] NOT NULL,
	[CREATE_DATE] [datetime] NULL,
	[TYPE] [varchar](10) NULL,
	[Upload_date] [varchar](10) NULL
)

*/


CREATE PROCEDURE [dbo].[USP_DBA_GETNEW_DB_AND_LOGIN]

/*
Summary:     New DB & Login alert
Contact:     Muthukkumaran Kaliyamoorthy SQL DBA


ChangeLog:
Date         Coder							Description
2013-jan-21	 Muthukkumaran Kaliyamoorhty     Updated the 2012 functionality                   


*/

AS BEGIN
SET NOCOUNT ON
TRUNCATE TABLE DBADATA.DBO.DBA_NEW_OBJECT_LOGIN_LIST

DECLARE @SERVERNAME VARCHAR(200)
DECLARE @DESC VARCHAR(200)



DECLARE ALLNEW_DB_LOGIN CURSOR
FOR
SELECT SERVERNAME,[DESCRIPTION] FROM DBADATA.DBO.DBA_ALL_SERVERS where SVR_status ='running'
OPEN ALLNEW_DB_LOGIN
FETCH NEXT FROM ALLNEW_DB_LOGIN INTO @SERVERNAME,@DESC

WHILE @@FETCH_STATUS=0  
BEGIN
BEGIN TRY


EXEC('INSERT INTO DBADATA.DBO.DBA_NEW_OBJECT_LOGIN_LIST
SELECT '''+@DESC+''',NAME,CRDATE,''DATABASE'' FROM ['+@SERVERNAME+'].MASTER.DBO.SYSDATABASES
WHERE CRDATE >= GETDATE()-1')

EXEC('INSERT INTO DBADATA.DBO.DBA_NEW_OBJECT_LOGIN_LIST
SELECT '''+@DESC+''',LOGINNAME,CREATEDATE,''LOGIN'' FROM ['+@SERVERNAME+'].MASTER.DBO.SYSLOGINS
WHERE CREATEDATE >=GETDATE()-1')

--PRINT 'SERVER ' +@SERVERNAME+' COMPLETED.'

end try
BEGIN CATCH
--SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @DESC,'NEW_DB',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

PRINT 'SERVER ['+@SERVERNAME+']is not COMPLETED.'
END CATCH

FETCH NEXT FROM ALLNEW_DB_LOGIN INTO @SERVERNAME,@DESC
END
CLOSE ALLNEW_DB_LOGIN
DEALLOCATE ALLNEW_DB_LOGIN

----------------------------------------------------
-- May be its time to send the report to my DBA
IF EXISTS(
SELECT 1 FROM [DBADATA].[DBO].[DBA_NEW_OBJECT_LOGIN_LIST]
WHERE CREATE_DATE >=GETDATE()-1
)


BEGIN 

DECLARE @html nvarchar(MAX);
EXEC spQueryToHtmlTable @html = @html OUTPUT,  
@query = N'
SELECT * FROM [DBADATA].[DBO].[DBA_NEW_OBJECT_LOGIN_LIST]
WHERE CREATE_DATE >=GETDATE()-1
'


DECLARE @EMAILIDS VARCHAR(500)

SELECT @EMAILIDS=
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS  FROM dbo.DBA_ALL_OPERATORS
WHERE STATUS=1
DECLARE @EMAILIDS1 VARCHAR(500)
SELECT @EMAILIDS1=
COALESCE(@EMAILIDS1+';','')+EMAIL_ADDRESS  FROM DBAdata.DBO.DBA_ALL_OPERATORS
WHERE STATUS =1 and Mail_copy='CC'

EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@subject = 'FOLLOWING ARE NEWLY CREATED DBs AND LOGINs:',
@BODY = @html,
@copy_recipients=@EMAILIDS1,
--@blind_copy_recipients='HCL_NOC@sandisk.com',
@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='BIDATALOAD',
@query_no_truncate = 1,
@attach_query_result_as_file = 0;


end

insert into DBADATA_Archive.DBO.DBA_NEW_OBJECT_LOGIN_LIST
select *,getdate() from DBADATA.DBO.DBA_NEW_OBJECT_LOGIN_LIST

END