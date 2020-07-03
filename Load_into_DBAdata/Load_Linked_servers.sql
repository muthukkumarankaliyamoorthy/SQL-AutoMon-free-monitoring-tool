-- drop table tbl_sys_servers
-- select *   from sysservers


USE [DBAdata]

GO
/*
USE [DBAdata]
GO

CREATE TABLE [dbo].[tbl_sys_servers](
	[ServerName] [varchar](300) NOT NULL,
	[srvid] [smallint] NULL,
	[srvstatus] [smallint] NULL,
	[srvname] [sysname] NOT NULL,
	[srvproduct] [sysname] NOT NULL,
	[providername] [nvarchar](128) NOT NULL,
	[datasource] [nvarchar](4000) NULL,
	[location] [nvarchar](4000) NULL,
	[providerstring] [nvarchar](4000) NULL,
	[schemadate] [datetime] NOT NULL,
	[topologyx] [int] NULL,
	[topologyy] [int] NULL,
	[catalog] [sysname] NULL,
	[srvcollation] [sysname] NULL,
	[connecttimeout] [int] NULL,
	[querytimeout] [int] NULL,
	[srvnetname] [char](30) NULL,
	[isremote] [bit] NULL,
	[rpc] [bit] NOT NULL,
	[pub] [bit] NOT NULL,
	[sub] [bit] NULL,
	[dist] [bit] NULL,
	[dpub] [bit] NULL,
	[rpcout] [bit] NOT NULL,
	[dataaccess] [bit] NOT NULL,
	[collationcompatible] [bit] NOT NULL,
	[system] [bit] NOT NULL,
	[useremotecollation] [bit] NOT NULL,
	[lazyschemavalidation] [bit] NOT NULL,
	[collation] [sysname] NULL,
	[nonsqlsub] [bit] NULL
)


select ServerName FROM tbl_sys_servers group by ServerName

select * from dbadata.dbo.dba_all_servers where svr_status in ('Running','NU') -- 115

select svr_status,count(*) FROM dba_all_servers group by svr_status




*/
use DBAdata
go
-- select * from [tbl_sys_servers]

alter PROCEDURE [dbo].[Usp_load_sys_servers]
/*
Summary:        [Usp_load_sys_servers]
Contact:        Muthukkumaran Kaliyamoorhty SQL DBA

ChangeLog:
Date                          Coder                                                    Description
2012-06-04                 Muthukkumaran Kaliyamoorhty               created
 
*******************All the SQL keywords should be written in upper case********************
*/
WITH ENCRYPTION
AS
BEGIN
SET nocount ON

--inserting the drive space
Truncate table dbadata.dbo.[tbl_sys_servers]


      DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @sql varchar(8000)
      DECLARE @minrow int
      DECLARE @maxrow int

---------------------------------------------------
--Put the local server first
---------------------------------------------------
 insert into tbl_sys_servers
select 'server',* from master.dbo.sysservers


 declare @Load_db_count table (id int  primary key identity, 
 servername varchar(100),Description varchar(100)) 
 
 insert into @Load_db_count
 select Servername , Description   from dbadata.dbo.dba_all_servers 
 where svr_status ='running' 
 
 
SELECT @minrow = MIN(id)FROM   @Load_db_count
SELECT @maxrow  = MAX(id) FROM   @Load_db_count
 
 while (@minrow <=@maxrow)
 begin
 begin try
 select @Server_name=Servername ,
 @Desc=Description   from @Load_db_count where ID = @minrow 
 
 ----------------------------------------------------------------
--insert the value to table
--select * from dbadata.dbo.tbl_get_logfiles_size where freespace <5000 and log_size >5000
-----------------------------------------------------------------
/*
set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''SELECT @@servername as server_name, count(*) as DB_count  from master..sysdatabases 
where dbid not in (1,2,3,4) and name not in (''''''''ReportServer'''''''',''''''''ReportServerTempDB'''''''')
               
'''')'')
      '

 insert into dbadata.dbo.tbl_sys_servers
 exec(@sql)
 --print @sql
 */
 -- select *  from sys.databases
 set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''
 select '''''''''+@Desc+''''''''',* from master.dbo.sysservers
'''')'')
      '

 insert into dbadata.dbo.tbl_sys_servers
 exec(@sql)

 --print ' sever'+@server_name+'completed.'
 end try
 BEGIN CATCH
--SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'tbl_sys_servers',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

PRINT 'SERVER ['+@SERVER_NAME+']is not COMPLETED.'
END CATCH
 set @minrow =@minrow +1 
 end
 
END


