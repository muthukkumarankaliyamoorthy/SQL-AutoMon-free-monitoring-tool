

-- select * from tbl_load_inventory_settings

USE [DBAdata]

GO
/*
drop table tbl_load_inventory_settings
go
 CREATE TABLE [dbo].[tbl_load_inventory_settings](
	server_name [varchar](100) not null primary key,
	[Instance] [sql_variant] NOT NULL,
	[SQL_Version] [sql_variant] NULL,
	[SP] [sql_variant] NULL,
	[login_mode] [varchar](7) NOT NULL,
	[edition] [sql_variant] NULL,
	[IsClustered] [varchar](11) NOT NULL,
	[Collation] [sql_variant] NULL,
	[BuildClrVersion] [sql_variant] NULL,
	[net_transport] [sql_variant] NULL,
	[protocol_type] [sql_variant] NULL,
	[auth_scheme] [sql_variant] NULL,
	[local_net_address] [sql_variant] NULL,
	[local_tcp_port] [sql_variant] NULL,
	[client_net_address] [sql_variant] NULL,
	[virtual_machine_type_desc] [nvarchar](60) NOT NULL,
	[Server_type] [varchar](8) NOT NULL,
	[uploaddate] [datetime] NOT NULL
) 

--ALTER TABLE [tbl_load_inventory_settings] ALTER COLUMN [server_name] varchar(100) NOT NULL
--alter table tbl_load_inventory_settings add primary key (server_name)

select * from tbl_load_inventory_settings

select * from dba_all_servers where description not in (select server_name from [tbl_load_inventory_settings] )and SVR_status='running'


-- insert manually 2005
select Servername , Description,svr_status,*   from dbadata.dbo.dba_all_servers  where svr_status <>'running' --and Version  in ('SQL2000','SQL2005') 




select * from tbl_load_inventory_settings where local_net_address is null
select * from tbl_load_inventory_settings where server_type is null
 -- update null


select * from dba_all_servers where description not in (select server_name from [tbl_load_inventory_settings] )and SVR_status='running'


*/



use DBAdata
go

create PROCEDURE [dbo].[Usp_load_settings]
/*
Summary:       [Usp_load_settings]
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

-- select * from [tbl_load_inventory_settings]
Truncate table dbadata.dbo.[tbl_load_inventory_settings]


      DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @sql varchar(8000)
      DECLARE @minrow int
      DECLARE @maxrow int

---------------------------------------------------
--Put the local server first
---------------------------------------------------
 /*insert into tbl_load_inventory_settings
SELECT 'server',

isnull(serverproperty ('InstanceName'),'Default')as Instance,
serverproperty('ProductVersion') as SQL_Version,
serverproperty ('ProductLevel')as SP,
case when serverproperty ('IsIntegratedSecurityOnly')=0 then 'SQL' else 'Windows'end as login_mode,
serverproperty ('Edition')as edition,
case when serverproperty ('IsClustered')=0 then 'Stand alone' else 'Clustered'end as IsClustered ,
serverproperty ('Collation') as Collation,
serverproperty ('BuildClrVersion') as  BuildClrVersion,


   CONNECTIONPROPERTY('net_transport') AS net_transport,
   CONNECTIONPROPERTY('protocol_type') AS protocol_type,
   CONNECTIONPROPERTY('auth_scheme') AS auth_scheme,
   CONNECTIONPROPERTY('local_net_address') AS local_net_address,
   CONNECTIONPROPERTY('local_tcp_port') AS local_tcp_port,
   CONNECTIONPROPERTY('client_net_address') AS client_net_address ,


dosi.virtual_machine_type_desc
,Server_type = CASE 
WHEN dosi.virtual_machine_type = 1
THEN 'Virtual' 
ELSE 'Physical'
END
,getdate() as uploaddate --into tbl_load_inventory_monthly_once
FROM sys.dm_os_sys_info dosi 
*/

 declare @Load_db_count table (id int  primary key identity, 
 servername varchar(100),Description varchar(100)) 
 -- select *   from dbadata.dbo.dba_all_servers 
 insert into @Load_db_count
 select Servername , Description   from dbadata.dbo.dba_all_servers 
 where svr_status ='running' and Version not in ('SQL2000','SQL2005') 
 
 
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

 insert into dbadata.dbo.tbl_load_inventory_settings
 exec(@sql)
 --print @sql
 */
 
 -- select *  from sys.databases
 set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''
 select '''''''''+@Desc+''''''''',

isnull(serverproperty (''''''''InstanceName''''''''),''''''''Default'''''''')as Instance,
serverproperty(''''''''ProductVersion'''''''') as SQL_Version,
serverproperty (''''''''ProductLevel'''''''')as SP,
case when serverproperty (''''''''IsIntegratedSecurityOnly'''''''')=0 then ''''''''SQL'''''''' else ''''''''Windows''''''''end as login_mode,
serverproperty (''''''''Edition'''''''')as edition,
case when serverproperty (''''''''IsClustered'''''''')=0 then ''''''''Stand alone'''''''' else ''''''''Clustered''''''''end as IsClustered ,
serverproperty (''''''''Collation'''''''') as Collation,
serverproperty (''''''''BuildClrVersion'''''''') as  BuildClrVersion,


   CONNECTIONPROPERTY(''''''''net_transport'''''''') AS net_transport,
   CONNECTIONPROPERTY(''''''''protocol_type'''''''') AS protocol_type,
   CONNECTIONPROPERTY(''''''''auth_scheme'''''''') AS auth_scheme,
   CONNECTIONPROPERTY(''''''''local_net_address'''''''') AS local_net_address,
   CONNECTIONPROPERTY(''''''''local_tcp_port'''''''') AS local_tcp_port,
   CONNECTIONPROPERTY(''''''''client_net_address'''''''') AS client_net_address ,


dosi.virtual_machine_type_desc
,Server_type = CASE 
WHEN dosi.virtual_machine_type = 1
THEN ''''''''Virtual'''''''' 
ELSE ''''''''Physical''''''''
END
,getdate() as uploaddate
FROM sys.dm_os_sys_info dosi 

'''')'')
      '

 insert into dbadata.dbo.tbl_load_inventory_settings
 exec(@sql)
 --print @sql

 --print ' sever'+@server_name+'completed.'
 end try
 BEGIN CATCH
--SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'tbl_load_inventory_settings',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

PRINT 'SERVER ['+@SERVER_NAME+']is not COMPLETED.'
END CATCH
 set @minrow =@minrow +1 
 end

END


