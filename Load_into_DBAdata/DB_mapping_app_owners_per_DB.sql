/*
drop table tbl_DB_Mapping_application_Owners

create table tbl_DB_Mapping_application_Owners(
Server_Name varchar(200), Database_Name varchar(200),	Create_Date	varchar(200),Application_Name varchar(max),	Business_Owner varchar(max),
Comments varchar(200),	Site_Name varchar(20),load_date datetime default getdate())

BULK INSERT tbl_DB_Mapping_application_Owners   FROM 'D:\Source\DB_maaping_Site1.txt'WITH (FIELDTERMINATOR = '<>',ROWTERMINATOR = '\n')

create table tbl_SQL_inventory_AppOwners (Server_Name varchar(200),Application_Name varchar(max),Business_Owner varchar(max),
Svr_status varchar (20),load_date datetime default getdate())


*/
select * from tbl_DB_Mapping_application_Owners where Business_Owner like '%tele%'
select Business_Owner,count(*) from tbl_DB_Mapping_application_Owners group by Business_Owner
select * from tbl_sys_databases

select * from tbl_DB_Mapping_application_Owners where business_owner is null
select * from tbl_DB_Mapping_application_Owners where application_name is null

update tbl_DB_Mapping_application_Owners set business_owner='DBA team' where Database_Name like'DBA%'
update tbl_DB_Mapping_application_Owners set application_name='DBA Maintenance DB' where Database_Name like'DBA%'

select * from tbl_DB_Mapping_application_Owners where server_name like '%%'

update tbl_DB_Mapping_application_Owners set business_owner='owner' where Server_Name like'server%'
update tbl_DB_Mapping_application_Owners set application_name='app name' where Server_Name like'server%'


select * from tbl_DB_Mapping_application_Owners where server_name like '%server%'
select * from tbl_DB_Mapping_application_Owners where Database_Name like '%psi%'
	

select SD.ServerName as [Server Name],SD.name as [Database Name],SD.crdate [Create Date],
CASE   
		 WHEN convert(VARCHAR(30),SD.name) like 'master' THEN 'System DB'
		 WHEN convert(VARCHAR(30),SD.name) like 'model' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like 'msdb' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like 'tempdb' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like '%ReportServer%' THEN 'SSRS Portal'  
		 ELSE AO.[Application_Name]
END  AS [Application Name],  
 AO.Comments [Comments] ,
 CASE   
		 WHEN convert(VARCHAR(30),SD.name) like 'master' THEN 'System DB'
		 WHEN convert(VARCHAR(30),SD.name) like 'model' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like 'msdb' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like 'tempdb' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like '%ReportServer%' THEN 'SSRS Portal'  
		 ELSE AO.Business_Owner
END  AS [Business Owner],

'Site1' [Site Name]


from tbl_sys_databases SD left join tbl_DB_Mapping_application_Owners AO
on SD.ServerName=AO.Server_Name
and sd.name=ao.Database_Name
where name not in ('tempdb') and crdate <='2020-04-30 23:59:26.680'
order by crdate desc


-- Site2
select * from Server.DBADATA.DBO.tbl_DB_Mapping_application_Owners
select * from Server.DBADATA.DBO.tbl_sys_databases

select * from Server.DBADATA.DBO.tbl_DB_Mapping_application_Owners where application_name is null
select * from Server.DBADATA.DBO.tbl_DB_Mapping_application_Owners where Business_Owner is null

select SD.ServerName as [Server Name],SD.name as [Database Name],SD.crdate [Create Date],
CASE   
		 WHEN convert(VARCHAR(30),SD.name) like 'master' THEN 'System DB'
		 WHEN convert(VARCHAR(30),SD.name) like 'model' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like 'msdb' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like 'tempdb' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like '%ReportServer%' THEN 'SSRS Portal'  
		 ELSE AO.[Application_Name]
END  AS [Application Name],  
 AO.Comments [Comments] ,
 CASE   
		 WHEN convert(VARCHAR(30),SD.name) like 'master' THEN 'System DB'
		 WHEN convert(VARCHAR(30),SD.name) like 'model' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like 'msdb' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like 'tempdb' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like '%ReportServer%' THEN 'SSRS Portal'  
		 ELSE AO.Business_Owner
END  AS [Business Owner] ,

'Site2' [Site Name]


from Server.DBADATA.DBO.tbl_sys_databases SD join Server.DBADATA.DBO.tbl_DB_Mapping_application_Owners AO
on SD.ServerName=AO.Server_Name
and sd.name=ao.Database_Name
where name not in ('tempdb') and crdate <='2020-04-30 23:59:26.680'
order by crdate desc


--select * from tbl_DB_Mapping_application_Owners order by load_date desc
--delete from tbl_DB_Mapping_application_Owners where load_date='2020-05-28 00:00:00.000'
---
drop table tbl_DB_Mapping_application_Owners_temp_monthly

create table tbl_DB_Mapping_application_Owners_temp_monthly(
Server_Name varchar(200), Database_Name varchar(200),	Create_Date	varchar(200),Application_Name varchar(max),	Business_Owner varchar(max),
Comments varchar(200),	Site_Name varchar(20),load_date datetime default getdate())

--Site1
truncate table tbl_DB_Mapping_application_Owners_temp_monthly
BULK INSERT tbl_DB_Mapping_application_Owners_temp_monthly  FROM 'D:\Source\DB_maaping_Site1_monthly.txt'WITH (FIELDTERMINATOR = '<>',ROWTERMINATOR = '\n')

insert into tbl_DB_Mapping_application_Owners
select * from tbl_DB_Mapping_application_Owners_temp_monthly
--Site2 -- open a new query and run from fortis
truncate table tbl_DB_Mapping_application_Owners_temp_monthly
BULK INSERT tbl_DB_Mapping_application_Owners_temp_monthly  FROM '\\server\SQL_Backup\DB_maaping_DP.txt'WITH (FIELDTERMINATOR = '<>',ROWTERMINATOR = '\n')

insert into tbl_DB_Mapping_application_Owners
select * from tbl_DB_Mapping_application_Owners_temp_monthly