
-- drop table tbl_dm_server_services


-- select * from tbl_dm_server_services

USE [DBAdata]

GO
/*
drop table tbl_dm_server_services

CREATE TABLE [dbo].[tbl_dm_server_services](
	[server_name] [varchar](200) NULL,
	[servicename] [nvarchar](256) NOT NULL,
	[startup_type_desc] [nvarchar](256) NOT NULL,
	[status_desc] [nvarchar](256) NOT NULL,
	[last_startup_time] [datetimeoffset](7) NULL,
	[service_account] [nvarchar](256) NOT NULL,
	[is_clustered] [nvarchar](1) NOT NULL,
	[cluster_nodename] [nvarchar](256) NULL,
	[filename] [nvarchar](256) NOT NULL,
	[startup_type] [int] NULL,
	[status] [int] NULL,
	[process_id] [int] NULL
)

select * from tbl_dm_server_services

 select Servername , Description   from dbadata.dbo.dba_all_servers  where svr_status ='running' and Version  in ('SQL2005')

 -- add 2005
 select server_name,COUNT(*) from tbl_dm_server_services GROUP BY server_name HAVING COUNT(*) >2

 select server_name FROM tbl_dm_server_services group by server_name -- 115
select * from dbadata.dbo.dba_all_servers where svr_status in ('Running','NU') -- 115

 select svr_status,count(*) FROM dba_all_servers group by svr_status



*/
use DBAdata
go


alter PROCEDURE [dbo].[Usp_load_server_service]
/*
Summary:       [Usp_load_server_service]
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
Truncate table dbadata.dbo.[tbl_dm_server_services]


      DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @sql varchar(8000)
      DECLARE @minrow int
      DECLARE @maxrow int

---------------------------------------------------
--Put the local server first
---------------------------------------------------
 insert into tbl_dm_server_services
select 'servers' as server_name,
  

DSS.servicename,
        DSS.startup_type_desc,
        DSS.status_desc,
        DSS.last_startup_time,
        DSS.service_account,
        DSS.is_clustered,
        DSS.cluster_nodename,
        DSS.filename,
        DSS.startup_type,
        DSS.status,
        DSS.process_id 
FROM    sys.dm_server_services AS DSS 


 declare @Load_service_accounts table (id int  primary key identity, 
 servername varchar(100),Description varchar(100)) 
 
 -- select *   from dbadata.dbo.dba_all_servers 

 insert into @Load_service_accounts
 select Servername , Description   from dbadata.dbo.dba_all_servers 
 where svr_status ='running' and Version not in ('SQL2005')
 
 
SELECT @minrow = MIN(id)FROM   @Load_service_accounts
SELECT @maxrow  = MAX(id) FROM   @Load_service_accounts
 
 while (@minrow <=@maxrow)
 begin
 begin try
 select @Server_name=Servername ,
 @Desc=Description   from @Load_service_accounts where ID = @minrow 
 
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

 insert into dbadata.dbo.tbl_dm_server_services
 exec(@sql)
 --print @sql
 */
 
 -- select *  from sys.databases
 set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''
 select '''''''''+@Desc+''''''''',
		DSS.servicename,
        DSS.startup_type_desc,
        DSS.status_desc,
        DSS.last_startup_time,
        DSS.service_account,
        DSS.is_clustered,
        DSS.cluster_nodename,
        DSS.filename,
        DSS.startup_type,
        DSS.status,
        DSS.process_id 
FROM    sys.dm_server_services AS DSS 
'''')'')
      '

 insert into dbadata.dbo.tbl_dm_server_services
 exec(@sql)

 --print ' sever'+@server_name+'completed.'
 end try
 BEGIN CATCH
--SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'tbl_dm_server_services',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

PRINT 'SERVER ['+@SERVER_NAME+']is not COMPLETED.'
END CATCH
 set @minrow =@minrow +1 
 end
 
END


