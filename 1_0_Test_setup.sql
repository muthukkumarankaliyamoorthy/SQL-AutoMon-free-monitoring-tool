
select * from tbl_Error_handling

truncate table tbl_Error_handling

drop table tbl_SQL_AutoMON
go
use DBAData
go
create table tbl_SQL_AutoMON
(
	[Servername] [varchar](100) NULL,
	[ComputerNamePhysicalNetBIOS] [varchar](50) NULL,
	[Instance] [varchar](50) NULL,
	[Login_mode] [varchar](20) NULL,
	[Edition] [varchar](100) NULL,
	[ProductBuild] [varchar](50) NULL,
	[ProductBuildType] [varchar](50) NULL,
	[ProductLevel] [varchar](50) NULL,
	[ProductMajorVersion] [varchar](50) NULL,
	[ProductMinorVersion] [varchar](50) NULL,
	[ProductUpdateLevel] [varchar](50) NULL,
	[ProductUpdateReference] [varchar](50) NULL,
	[Version] [varchar](50) NULL,
	[ResourceLastUpdateDateTime] [varchar](50) NULL,
	[ResourceVersion] [varchar](50) NULL,
	[MachineName] [varchar](50) NULL,
	[IsClustered] [varchar](11) NULL,
	[IsFullTextInstalled] [varchar](50) NULL,
	[IsHadrEnabled] [varchar](50) NULL,
	[IsLocalDB] [varchar](50) NULL,
	[IsPolyBaseInstalled] [varchar](50) NULL,
	[IsSingleUser] [varchar](50) NULL,
	[IsXTPSupported] [varchar](50) NULL,
	[LCID] [varchar](50) NULL,
	[LicenseType] [varchar](50) NULL,
	[NumLicenses] [varchar](50) NULL,
	[ProcessID] [varchar](50) NULL,
	[SqlCharSet] [varchar](50) NULL,
	[SqlCharSetName] [varchar](50) NULL,
	[SqlSortOrder] [varchar](50) NULL,
	[SqlSortOrderName] [varchar](50) NULL,
	[FilestreamShareName] [varchar](50) NULL,
	[FilestreamConfiguredLevel] [varchar](50) NULL,
	[FilestreamEffectiveLevel] [varchar](50) NULL,
	[CollationID] [varchar](50) NULL,
	[ComparisonStyle] [varchar](50) NULL,
	[EditionID] [varchar](50) NULL,
	[EngineEdition] [varchar](50) NULL,
	[HadrManagerStatus] [varchar](50) NULL,
	[InstanceDefaultDataPath] [varchar](max) NULL,
	[InstanceDefaultLogPath] [varchar](max) NULL,
	[IsAdvancedAnalyticsInstalled] [varchar](50) NULL,
	[net_transport] [varchar](50) NULL,
	[protocol_type] [varchar](50) NULL,
	[auth_scheme] [varchar](50) NULL,
	[IP] [varchar](50) NULL,
	[local_tcp_port] [varchar](50) NULL,
	[client_net_address] [varchar](50) NULL,
	[HA] [varchar](20) NULL,
	[Domain] [varchar](13) NULL,
	[OS] [varchar](50) NULL,
	[server_type] [varchar](20) NULL,
	[No_of_logical_cpu] [int] NULL,
	[hyperthread_ratio] [int] NULL,
	[No_of_physical_cpu] [int] NULL,
	[physical_memory_kb] [bigint] NULL,
	[Category] [varchar](20) NULL,
	[Location] [varchar](20) NULL,
	[Applications] [varchar](19) NULL,
	[Business_owner] [varchar](21) NULL,
	[Critical_service_level] [varchar](29) NULL,
	[Severity] [varchar](15) NULL,
	[SVR_status] [varchar](20) NULL,
	[is_win_A_path] [varchar](20) NULL,
	[Is_SQL_Auto_Path] [varchar](16) NULL,
	[Is_backup] [varchar](21) NULL,
	[Is_monitoring] [varchar](25) NULL,
	[License_Detalis] [varchar](23) NULL,
	[comments_1] [varchar](20) NULL,
	[comments_2] [varchar](20) NULL,
	[Added_date] [datetime] NULL default (getdate()),
	[Maintenance_date] [datetime] NULL default (getdate())
)

BULK INSERT tbl_SQL_AutoMON  FROM 'D:\temp\servers.txt'WITH (FIELDTERMINATOR = '<>',ROWTERMINATOR = '\n')

select Servername,COUNT(*) from dbo. tbl_SQL_AutoMON group by Servername having COUNT(*) >1

-- select * from tbl_SQL_AutoMON

select version from tbl_SQL_AutoMON group by version
update tbl_SQL_AutoMON set version   ='SQL2000' where version like '8%'
update tbl_SQL_AutoMON set version   ='SQL2005' where version like '9%'
update tbl_SQL_AutoMON set version   ='SQL2008' where version like '10.0%'
update tbl_SQL_AutoMON set version   ='SQL2008R2' where version like '10.5%'
update tbl_SQL_AutoMON set version   ='SQL2012' where version like '11%'
update tbl_SQL_AutoMON set version   ='SQL2014' where version like '12%'
update tbl_SQL_AutoMON set version   ='SQL2016' where version like '13%'
update tbl_SQL_AutoMON set version   ='SQL2017' where version like '14%'
update tbl_SQL_AutoMON set version   ='SQL2019' where version like '15%'

-- update category

UPDATE tbl_SQL_AutoMON set category ='Non-Prod' where servername not like '%ip%'

select * from tbl_SQL_AutoMON
select * from DBA_All_servers


use DBAData
go
drop table DBA_All_servers

CREATE TABLE dbo.DBA_All_servers(
	id int NOT NULL identity,
	[Servername] [varchar](100) NOT NULL,
	[ComputerName] [varchar](100) NULL,
	[Description] [varchar](100) NOT NULL,
	[Instance] [varchar](50) NULL,
	[Login_mode] [varchar](20) NULL,
	[Edition] [varchar](500) NOT NULL,
	[ProductBuild] [varchar](50) NULL,
	[ProductBuildType] [varchar](50) NULL,
	[ProductLevel] [varchar](50) NULL,
	[ProductMajorVersion] [varchar](50) NULL,
	[ProductMinorVersion] [varchar](50) NULL,
	[ProductUpdateLevel] [varchar](50) NULL,
	[ProductUpdateReference] [varchar](50) NULL,
	[Version] [varchar](50) NOT NULL,
	[ResourceLastUpdateDateTime] [varchar](50) NULL,
	[ResourceVersion] [varchar](50) NULL,
	[MachineName] [varchar](50) NULL,
	[IsClustered] [varchar](11) NULL,
	[IsFullTextInstalled] [varchar](50) NULL,
	[IsHadrEnabled] [varchar](50) NULL,
	[IsLocalDB] [varchar](50) NULL,
	[IsPolyBaseInstalled] [varchar](50) NULL,
	[IsSingleUser] [varchar](50) NULL,
	[IsXTPSupported] [varchar](50) NULL,
	[LCID] [varchar](50) NULL,
	[LicenseType] [varchar](50) NULL,
	[NumLicenses] [varchar](50) NULL,
	[ProcessID] [varchar](50) NULL,
	[SqlCharSet] [varchar](50) NULL,
	[SqlCharSetName] [varchar](50) NULL,
	[SqlSortOrder] [varchar](50) NULL,
	[SqlSortOrderName] [varchar](50) NULL,
	[FilestreamShareName] [varchar](50) NULL,
	[FilestreamConfiguredLevel] [varchar](50) NULL,
	[FilestreamEffectiveLevel] [varchar](50) NULL,
	[CollationID] [varchar](50) NULL,
	[ComparisonStyle] [varchar](50) NULL,
	[EditionID] [varchar](50) NULL,
	[EngineEdition] [varchar](50) NULL,
	[HadrManagerStatus] [varchar](50) NULL,
	[InstanceDefaultDataPath] [varchar](max) NULL,
	[InstanceDefaultLogPath] [varchar](max) NULL,
	[IsAdvancedAnalyticsInstalled] [varchar](50) NULL,
	[net_transport] [varchar](50) NULL,
	[protocol_type] [varchar](50) NULL,
	[auth_scheme] [varchar](50) NULL,
	[IP] [varchar](50) NULL,
	[local_tcp_port] [varchar](50) NULL,
	[client_net_address] [varchar](50) NULL,
	[HA] [varchar](20) NULL,
	[Domain] [varchar](50) NULL,
	[OS] [varchar](50) NULL,
	[server_type] [varchar](20) NULL,
	[No_of_logical_cpu] [int] NULL,
	[hyperthread_ratio] [int] NULL,
	[No_of_physical_cpu] [int] NULL,
	[physical_memory_kb] [bigint] NULL,
	[Category] [varchar](50) NOT NULL,
	[Location] [varchar](20) NOT NULL,
	[Applications] [varchar](max) NULL,
	[Business_owner] [varchar](max) NULL,
	[Critical_service_level] [varchar](50) NULL,
	[Severity] [varchar](50) NULL,
	[SVR_status] [varchar](20) NOT NULL,
	[MS_Patch] [varchar](50),
	[EOL] [Datetime],
	[E_EOL] [Datetime],
	[OS_EOL] [Datetime],
	[Esxi_mapping] [varchar](200),
	[Esxi_hostName] [varchar](200),
	[Patch_compliance] [varchar](15),
	[is_win_A_path] [varchar](20) NULL,
	[Is_SQL_Auto_Path] [varchar](20) NULL,
	[Is_backup] [varchar](20) NULL,
	[Is_monitoring] [varchar](25) NULL,
	[License_Detalis] [varchar](20) NULL,
	[comments_1] [varchar](100) NULL,
	[comments_2] [varchar](100) NULL,
	[Added_date] [datetime] NULL default (getdate()),
	[Maintenance_date] [datetime] NULL default (getdate())

PRIMARY KEY CLUSTERED 
(
	Servername ASC
)
)

--Custom Script to add all the servers: SQL linked server
select 'EXEC USP_DBA_ADDSERVER_FOR_MONITOR','@P_SERVER='''+ServerName+''',','@P_DESC='''+ServerName+''',',
'@P_VERSION='''+Version+''',','@P_USERNAME=''SA'',','@P_PWD=''SApassword'',',
'@P_category='''+Category+''',','@P_location=''India'',','@P_edition='''+Edition+''',','@P_svr_status=''Running'',','@P_login_mode='''+Login_Mode+''''
from dbo.tbl_SQL_AutoMON --where svr_Status <>'Server Not running'


--Custom Script to add all the servers: Other source
select 'EXEC USP_DBA_ADDSERVER_FOR_MONITOR','@P_LINK_SERVER=''DBA_'+ServerName+''',@P_SERVER='''+ServerName+''',','@P_DESC='''+ServerName+''',',
'@P_VERSION='''+Version+''',','@P_USERNAME=''SA'',','@P_PWD=''SApassword'',',
'@P_category='''+Category+''',','@P_location=''India'',','@P_edition='''+Edition+''',','@P_svr_status=''Running'',','@P_login_mode='''+Login_Mode+''''
from dbo.tbl_SQL_AutoMON --where svr_Status <>'Server Not running'


--Custom Script to Drop all the servers:
--Custom Script to drop all the servers: SQL linked server
select 'EXEC USP_DBA_DROPSERVER_FOR_MONITOR',''''+ServerName+''',',
''''+Version+''',',''''+ServerName+''''
from dbo.tbl_SQL_AutoMON --where servername like '%ii%'

--Custom Script to drop all the servers: Other source

--Custom Script to Drop all the servers:
--Custom Script to drop all the servers: SQL linked server
select 'EXEC USP_DBA_DROPSERVER_FOR_MONITOR','''DBA_'+ServerName+''',',''''+ServerName+''',',
''''+Version+''',',''''+ServerName+''''
from dbo.tbl_SQL_AutoMON --where servername like '%ii%'


/*
-- Install Details
create table tbl_server_installed
(Server_name varchar (50), Version varchar(20), Install_Date datetime, Tickert_no varchar (50),
Business_Owner varchar(50),Application varchar(50), Catagory varchar (20), Location varchar(20),
Domain varchar(20), Is_added_backup varchar (20), Is_Added_monitoring varchar(20), Is_added_Patch varchar(20),
Comments varchar(50), Added_date datetime default getdate()
)

-- Decommission Details
create table tbl_server_decommission
(Server_name varchar (50), Version varchar(20), Server_or_DB varchar(30), Decom_Date datetime, Tickert_no varchar (50),
Business_Owner varchar(50),Application varchar(50), Catagory varchar (20), Location varchar(20),
Domain varchar(20), Is_removed_backup varchar (20), Is_removed_monitoring varchar(20), Is_Removed_Patch varchar(20),
Comments varchar(50), Added_date datetime default getdate()
)



-- Migration Details
create table tbl_server_Migration
(Source_Server_name varchar (50),Migrated_server_name varchar (50), Old_Version varchar(20), New_Version varchar(20),
Server_or_DB varchar(30), Migration_Date datetime, Tickert_no varchar (50),
Business_Owner varchar(50),Application varchar(50), Catagory varchar (20), Location varchar(20),
Domain varchar(20), Is_added_backup varchar (20), Is_Added_monitoring varchar(20), Is_added_Patch varchar(20),
Comments varchar(50), Added_date datetime default getdate()
)


-- Upgrade Details
create table tbl_server_Upgrade
(Server_name varchar (50), Old_Version varchar(20), New_Version varchar(20),
Upgrade_Date datetime, Tickert_no varchar (50),
Business_Owner varchar(50),Application varchar(50), Catagory varchar (20), Location varchar(20),
Domain varchar(20), Is_added_backup varchar (20), Is_Added_monitoring varchar(20), Is_added_Patch varchar(20),
Comments varchar(50), Added_date datetime default getdate()
)

*/

