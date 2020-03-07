
select * from tbl_Error_handling

truncate table tbl_Error_handling

drop table tbl_SQL_AutoMON
go
use DBAData
go
create table tbl_SQL_AutoMON
(
	Servername varchar(50) NOT NULL,Description varchar(50) NOT NULL,Instance varchar(50),Edition varchar(50) NOT NULL,
	Version varchar(20) NOT NULL,Version_number varchar(20),SP varchar(20),Login_mode varchar(20) NOT NULL,	HA varchar(20),
	IS_clustered varchar(20),Collation varchar(50),BuildClrVersion varchar(20),Domain varchar(20),
	OS_version varchar(50),IP varchar(20),IS_VM varchar(20),CPU_logical int,hyperthread_ratio int,
	CPU_physical int,RAM bigint,Category varchar(20),location varchar(20),Applications varchar(200),
	Business_owner varchar(200),Critical_service_level varchar(50),Severity varchar(50),SVR_status varchar(20),
	is_win_A_path varchar (30), Is_SQL_Auto_Path varchar (30), Is_backup varchar(30),Is_monitoring varchar(30),
	License_Detalis varchar(50),comments_1 varchar(20),comments_2 varchar(20),Added_date datetime,Maintenance_date datetime
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
	Servername varchar(50) NOT NULL,ComputerName varchar(50) NOT NULL,Description varchar(50) NOT NULL,Instance varchar(50),Edition varchar(50) NOT NULL,
	Version varchar(20) NULL,Version_number varchar(20),SP varchar(20),Login_mode varchar(20) NOT NULL,	HA varchar(20),
	IS_clustered varchar(20),Collation varchar(50),BuildClrVersion varchar(20),Domain varchar(20),
	OS_version varchar(50),IP varchar(20),IS_VM varchar(20),CPU_logical int,hyperthread_ratio int,
	CPU_physical int,RAM bigint,Category varchar(20),location varchar(20),Applications varchar(200),
	Business_owner varchar(200),Critical_service_level varchar(50),Severity varchar(50),SVR_status varchar(20),
	is_win_A_path varchar (20), Is_SQL_Auto_Path varchar (20), Is_backup varchar(20),Is_monitoring varchar(20),
	License_Detalis varchar(50),comments_1 varchar(20),comments_2 varchar(20),Added_date datetime,Maintenance_date datetime

PRIMARY KEY CLUSTERED 
(
	Servername ASC
)
)

--Custom Script to add all the servers:
select 'EXEC USP_DBA_ADDSERVER_FOR_MONITOR','''DBA_'+ServerName+''',',''''+ServerName+''',',
''''+Version+''',',''''+ServerName+''',','''SA'',','''SApassword'',',
''''+Category+''',','''India'',',''''+Edition+''',','''Running'',',''''+Login_Mode+''''
from dbo.tbl_SQL_AutoMON where svr_Status <>'Server Not running'

--Custom Script to Drop all the servers:

select 'EXEC USP_DBA_DROPSERVER_FOR_MONITOR','''DBA_'+ServerName+''',',''''+ServerName+''',',
''''+Version+''',',''''+ServerName+''''
from dbo.tbl_SQL_AutoMON where servername like '%ii%'

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

