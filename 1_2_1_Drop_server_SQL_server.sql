-- Drop from table and linked server as SQL


alter PROCEDURE [dbo].[USP_DBA_DROPSERVER_FOR_MONITOR]
/*
Summary:     Drop server into AutoMon
Contact:     Muthukkumaran Kaliyamoorthy SQL DBA
Description: Drop server into AutoMon

ChangeLog:
Date         Coder							Description
2013-jan-21	 Muthukkumaran Kaliyamoorthy     Updated the 2012 functionality                   


*/

@P_SERVER SYSNAME,
@P_VERSION SYSNAME,
@P_DESC VARCHAR(50)
--@P_USERNAME SYSNAME,
--@P_PWD VARCHAR(100)
WITH ENCRYPTION

AS 
 BEGIN

DECLARE @SERVER SYSNAME
DECLARE @VERSION SYSNAME
DECLARE @DESC VARCHAR(50)
--DECLARE @USERNAME SYSNAME
--DECLARE @PWD VARCHAR(100)
DECLARE @droplogins VARCHAR(100)


SET @SERVER=@P_SERVER
SET @VERSION=@P_VERSION
SET @DESC=@P_DESC
--SET @USERNAME=@P_USERNAME
--SET @PWD=@P_PWD

DECLARE @TABSQL VARCHAR(500)
DECLARE @PROCSQL VARCHAR(500)
SET @PROCSQL='
USE [MASTER];
DROP TABLE [DBO].[TEMPSPACE]'
SET @TABSQL='DROP PROCEDURE [DBO].[USP_TEMPSPACE_POP]'



--SELECT LEN(@PROCSQL)
EXEC ('EXEC ['+ @SERVER + '].MASTER.DBO.SP_EXECUTESQL N'''+ @PROCSQL+'''')
PRINT 'TABLE DROPED'
EXEC ('EXEC ['+ @SERVER + '].MASTER.DBO.SP_EXECUTESQL N'''+ @TABSQL+'''')
PRINT 'PROCEDURE DROPED'

select * FROM [DBADATA].[DBO].[DBA_ALL_SERVERS]
WHERE [SERVERNAME]=@SERVER AND [DESCRIPTION]=@DESC

DELETE FROM [DBADATA].[DBO].[DBA_ALL_SERVERS]
WHERE [SERVERNAME]=@SERVER AND [DESCRIPTION]=@DESC
PRINT 'DELETE THE SERVER NAME FROM AUTOMATION TABLE'

EXEC SP_DROPSERVER @SERVER=@SERVER,@droplogins='droplogins'
--EXEC SP_DROPLINKEDSRVLOGIN @RMTSRVNAME='DBA_SNIPPETUHC',@LOCALLOGIN=NULL--,@RMTUSER=@USERNAME
--EXEC SP_DROPLINKEDSRVLOGIN @RMTSRVNAME=@SERVER,@locallogin=@USERNAME
PRINT 'LINKED SERVER DROPED'



END