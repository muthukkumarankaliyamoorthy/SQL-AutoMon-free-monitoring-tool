
use DBAData
go
alter PROCEDURE [dbo].[USP_DBA_ADDSERVER_FOR_MONITOR]
/*
Summary:     Add server into AutoMon
Contact:     Muthukkumaran Kaliyamoorthy SQL DBA
Description: Add server into AutoMon

ChangeLog:
Date         Coder							Description
2013-jan-21	 Muthukkumaran Kaliyamoorthy     Updated the 2012 functionality                   


*/

@P_LINK_SERVER SYSNAME,
@P_SERVER SYSNAME,
@P_VERSION SYSNAME,
@P_DESC VARCHAR(50),
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

DECLARE @LINK_SERVER SYSNAME
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

SET @LINK_SERVER=@P_LINK_SERVER
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

IF ( @VERSION not like '%2000%')

Begin

IF (@login_mode='SQL')

BEGIN

set @ls_script='
EXEC SP_ADDLINKEDSERVER @SERVER='''+@LINK_SERVER +''',@PROVIDER=''SQLOLEDB'',@SRVPRODUCT='''+@VERSION+''',@DATASRC='''+@SERVER+''',@CATALOG=''MASTER''
EXEC SP_ADDLINKEDSRVLOGIN @RMTSRVNAME='''+@LINK_SERVER +''',@USESELF=''FALSE'',@LOCALLOGIN=NULL,@RMTUSER='''+@USERNAME+''',@RMTPASSWORD='''+@PWD+'''
EXEC SP_SERVEROPTION @SERVER='''+@LINK_SERVER +''',@OPTNAME=''RPC'',@OPTVALUE=''TRUE''
EXEC SP_SERVEROPTION @SERVER='''+@LINK_SERVER +''',@OPTNAME=''RPC OUT'',@OPTVALUE=''TRUE''
'
END

ELSE 
BEGIN
set @ls_script='
EXEC SP_ADDLINKEDSERVER @SERVER='''+@LINK_SERVER +''',@PROVIDER=''SQLOLEDB'',@SRVPRODUCT='''+@VERSION+''',@DATASRC='''+@SERVER+''',@CATALOG=''MASTER''
EXEC SP_ADDLINKEDSRVLOGIN @RMTSRVNAME='''+@LINK_SERVER +''',@USESELF=''true''
EXEC SP_SERVEROPTION @SERVER='''+@LINK_SERVER +''',@OPTNAME=''RPC'',@OPTVALUE=''TRUE''
EXEC SP_SERVEROPTION @SERVER='''+@LINK_SERVER +''',@OPTNAME=''RPC OUT'',@OPTVALUE=''TRUE''
'
END

END

ELse
-- sql 2000
BEGIN
set @ls_script='
EXEC SP_ADDLINKEDSERVER @SERVER='''+@LINK_SERVER +''',@PROVIDER=''MSDASQL'',@SRVPRODUCT='''+@VERSION+''',@provstr=N''DRIVER={SQL Server};SERVER='+@SERVER+';''
EXEC SP_ADDLINKEDSRVLOGIN @RMTSRVNAME='''+@LINK_SERVER +''',@USESELF=''FALSE'',@LOCALLOGIN=NULL,@RMTUSER=''SA'',@RMTPASSWORD=''SApassword''
EXEC SP_SERVEROPTION @SERVER='''+@LINK_SERVER +''',@OPTNAME=''RPC'',@OPTVALUE=''TRUE''
EXEC SP_SERVEROPTION @SERVER='''+@LINK_SERVER +''',@OPTNAME=''RPC OUT'',@OPTVALUE=''TRUE''
'


END


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
EXEC ('EXEC ['+@LINK_SERVER + '].MASTER.DBO.SP_EXECUTESQL N'''+@TABSQL+'''')
PRINT 'PROCEDURE CREATED'
EXEC ('EXEC ['+@LINK_SERVER + '].MASTER.DBO.SP_EXECUTESQL N'''+@PROCSQL+'''')
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
           (@LINK_SERVER
           ,@DESC
           ,@VERSION
           ,@category
           ,@location
           ,'not added'+@login_mode
           ,@edition
           ,@svr_status)
PRINT 'AUTOMATION COPMLETED'


set @sql='EXEC(''SELECT * from OPENQUERY(['+@LINK_SERVER+'],
''''SELECT name FROM master.dbo.sysobjects WHERE name = ''''''''tempspace''''''''
 '''')'')'

insert into #insert
exec (@sql)
--select * from #insert
IF EXISTS (select 1 from #insert where name='tempspace') 
begin
update [DBA_ALL_SERVERS]set Login_mode =@login_mode+'_Login' where DESCRIPTION=@DESC
end

END
ELSE 
PRINT 'Pass the @P_VERSION parameter excluding space'
END

/*

--Custom Script to add all the servers:
select 'EXEC USP_DBA_ADDSERVER_FOR_MONITOR','''DBA_'+ServerName+''',',''''+ServerName+''',',
''''+Version+''',',''''+ServerName+''',','''SA'',','''SApassword'',',
''''+Category+''',','''India'',',''''+Edition+''',','''Running'',',''''+Login_Mode+''''
from dbo.tbl_SQL_AutoMON where svr_Status <>'Server Not running'

--Custom Script to Drop all the servers:

select 'EXEC USP_DBA_DROPSERVER_FOR_MONITOR','''DBA_'+ServerName+''',',''''+ServerName+''',',
''''+Version+''',',''''+ServerName+''''
from dbo.tbl_SQL_AutoMON where servername like '%ii%'

*/



