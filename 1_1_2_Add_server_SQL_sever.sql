-- Linked server as SQL:
--EXEC USP_DBA_ADDSERVER_FOR_MONITOR	@P_SERVER='LAPTOP-ISGUKEUC\MUTHU',	@P_DESC='LAPTOP-ISGUKEUC\MUTHU',	@P_VERSION='SQL2014',	@P_USERNAME='SA',	@P_PWD='SApassword',	@P_category='Prod',	@P_location='India',	@P_edition='Enterprise Edition: Core-based Licensing (64-bit)',	@P_svr_status='Running',	@P_login_mode='Windows'



use DBAData
go
create PROCEDURE [dbo].[USP_DBA_ADDSERVER_FOR_MONITOR]
/*
Summary:     Add server into AutoMon
Contact:     Muthukkumaran Kaliyamoorthy SQL DBA
Description: Add server into AutoMon

ChangeLog:
Date         Coder							Description
2013-jan-21	 Muthukkumaran Kaliyamoorthy     Updated the 2012 functionality                   


*/

@P_SERVER SYSNAME,
@P_DESC VARCHAR(50),
@P_VERSION SYSNAME,
@P_USERNAME SYSNAME,
@P_PWD VARCHAR(100),
@P_category VARCHAR(100),
@P_location VARCHAR(100),
@P_edition VARCHAR(50),
@P_svr_status VARCHAR(20),
@P_login_mode VARCHAR(20)

--WITH ENCRYPTION

AS 
 BEGIN

DECLARE @SERVER SYSNAME
DECLARE @DATASRC SYSNAME
DECLARE @VERSION SYSNAME
DECLARE @DESC VARCHAR(50)
DECLARE @USERNAME SYSNAME
DECLARE @PWD VARCHAR(100)
DECLARE @category VARCHAR(100)
DECLARE @location VARCHAR(100)
DECLARE @edition VARCHAR(50)
DECLARE @svr_status VARCHAR(20)
DECLARE @login_mode VARCHAR(20)

declare @sql varchar(8000)
declare @ls_script  varchar(8000)


SET @SERVER=@P_SERVER
SET @DATASRC=@P_SERVER
SET @VERSION=@P_VERSION
SET @DESC=@P_DESC
SET @USERNAME=@P_USERNAME
SET @PWD=@P_PWD
SET @category=@P_category
SET @location=@P_location
SET @edition=@p_edition
SET @svr_status=@p_svr_status
SET @login_mode=@P_login_mode 

create table #insert (name varchar(50))

IF PATINDEX ('% %',@P_VERSION)=0
BEGIN

--IF ( @VERSION not like '%2000%')

--Begin

IF (@login_mode='SQL')

BEGIN

set @ls_script='
EXEC SP_ADDLINKEDSERVER @SERVER='''+@SERVER +''',@SRVPRODUCT=''SQL Server''
EXEC SP_ADDLINKEDSRVLOGIN @RMTSRVNAME='''+@SERVER +''',@USESELF=''FALSE'',@LOCALLOGIN=NULL,@RMTUSER='''+@USERNAME+''',@RMTPASSWORD='''+@PWD+'''
EXEC SP_SERVEROPTION @SERVER='''+@SERVER +''',@OPTNAME=''RPC'',@OPTVALUE=''TRUE''
EXEC SP_SERVEROPTION @SERVER='''+@SERVER +''',@OPTNAME=''RPC OUT'',@OPTVALUE=''TRUE''
'
END

ELSE 
BEGIN
set @ls_script='
EXEC SP_ADDLINKEDSERVER @SERVER='''+@SERVER +''',@SRVPRODUCT=''SQL Server''
EXEC SP_ADDLINKEDSRVLOGIN @RMTSRVNAME='''+@SERVER +''',@USESELF=''true''
EXEC SP_SERVEROPTION @SERVER='''+@SERVER +''',@OPTNAME=''RPC'',@OPTVALUE=''TRUE''
EXEC SP_SERVEROPTION @SERVER='''+@SERVER +''',@OPTNAME=''RPC OUT'',@OPTVALUE=''TRUE''
'
END

END

--ELse

---- sql 2000
--BEGIN
--set @ls_script='
--EXEC SP_ADDLINKEDSERVER @SERVER='''+@SERVER +''',@PROVIDER=''MSDASQL'',@SRVPRODUCT=''SQL Server'',@provstr=N''DRIVER={SQL Server};SERVER='+@SERVER+';''
--EXEC SP_ADDLINKEDSRVLOGIN @RMTSRVNAME='''+@SERVER +''',@USESELF=''FALSE'',@LOCALLOGIN=NULL,@RMTUSER=''SA'',@RMTPASSWORD=''SAPassword''
--EXEC SP_SERVEROPTION @SERVER='''+@SERVER +''',@OPTNAME=''RPC'',@OPTVALUE=''TRUE''
--EXEC SP_SERVEROPTION @SERVER='''+@SERVER +''',@OPTNAME=''RPC OUT'',@OPTVALUE=''TRUE''
--'


--END


--print @ls_script
exec (@ls_script)
PRINT 'LINKED SERVER CREATED'

--SELECT * FROM 
DECLARE @TABSQL VARCHAR(5000)
DECLARE @PROCSQL VARCHAR(5000)
SET @TABSQL='
USE [MASTER];

IF object_id(''''TEMPSPACE'''') is not null
    PRINT ''''Present!''''
ELSE
 begin
 CREATE TABLE [DBO].[TEMPSPACE](
	[DRIVE] [VARCHAR](20) NULL,
	[SPACE] [INT] NULL
) ON [PRIMARY]
end
'
SET @PROCSQL='

if not exists ( select * from sysobjects 
            where name=''''USP_TEMPSPACE_POP'''' and objectproperty(id,''''IsProcedure'''')=1 )
exec(''''
create PROCEDURE [dbo].[USP_TEMPSPACE_POP]
AS
BEGIN
TRUNCATE TABLE TEMPSPACE
INSERT INTO TEMPSPACE
EXEC XP_FIXEDDRIVES
END
'''')
'

--SELECT LEN(@PROCSQL)
EXEC ('EXEC ['+@SERVER + '].MASTER.DBO.SP_EXECUTESQL N'''+@TABSQL+'''')
PRINT 'PROCEDURE CREATED'
EXEC ('EXEC ['+@SERVER + '].MASTER.DBO.SP_EXECUTESQL N'''+@PROCSQL+'''')
PRINT 'TABLE CREATED'

INSERT INTO [DBADATA].[DBO].[DBA_ALL_SERVERS]
           ([SERVERNAME]
           ,[DESCRIPTION]
           ,[VERSION]
           ,[Category] 
           ,[location] 
           ,[Login_mode]
           ,[Edition] 
           ,[SVR_status]  
           )
     VALUES
           (@SERVER
           ,@DESC
           ,@VERSION
           ,@category
           ,@location
           ,'not added'+@login_mode
           ,@edition
           ,@svr_status)
PRINT 'AUTOMATION COPMLETED'


set @sql='EXEC(''SELECT * from OPENQUERY(['+@SERVER+'],
''''SELECT name FROM master.dbo.sysobjects WHERE name = ''''''''tempspace''''''''
 '''')'')'

insert into #insert
exec (@sql)
--select * from #insert
IF EXISTS (select 1 from #insert where name='tempspace') 
begin
update [DBA_ALL_SERVERS]set Login_mode =@login_mode+'_Login' where DESCRIPTION=@DESC
end

--END
ELSE 
PRINT 'Pass the @P_VERSION parameter excluding space'
END


/*

--Custom Script to add all the servers:

select 'EXEC USP_DBA_ADDSERVER_FOR_MONITOR','@P_SERVER='''+ServerName+''',','@P_DESC='''+ServerName+''',',
'@P_VERSION='''+Version+''',','@P_USERNAME=''SA'',','@P_PWD=''SApassword'',',
'@P_category='''+Category+''',','@P_location=''India'',','@P_edition='''+Edition+''',','@P_svr_status=''Running'',','@P_login_mode='''+Login_Mode+''''
from dbo.tbl_SQL_AutoMON where svr_Status <>'Server Not running'

--Custom Script to Drop all the servers:

select 'EXEC USP_DBA_DROPSERVER_FOR_MONITOR','@P_SERVER='''+ServerName+''',',
'@P_VERSION='''+Version+''',','@P_DESC='''+ServerName+''''
from dbo.tbl_SQL_AutoMON where servername like '%ii%'


*/

