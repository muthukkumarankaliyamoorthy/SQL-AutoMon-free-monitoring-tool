
-- check join table count
select SVR_status FROM  DBADATA.DBO.DBA_ALL_SERVERS group by SVR_status--

select count (*) FROM  DBADATA.DBO.DBA_ALL_SERVERS where SVR_status ='running' -- 110
select count (*) FROM DBADATA.DBO.tbl_load_inventory_settings --
select count (*) FROM DBADATA.DBO.tbl_SQL_inventory_AppOwners where SVR_status='running'--


select count (*) FROM DBADATA.DBO.tbl_load_Inventory_CPU_RAM_count --
select count (*) FROM tbl_OS_version --
select count (*) FROM DBADATA.DBO.tbl_SQL_ESXI_Host_Details where svr_status ='running' 
select count (*) FROM DBADATA.DBO.tbl_Patch_OS_EOL  where svr_status ='running'

-- Site1 server count
select computer_name [Server Name],count(*) [Instance Count]FROM DBADATA.DBO.DBA_ALL_SERVERS 
where SVR_status like 'running' 
group by computer_name


select computer_name [Server Name],count(*) [Instance Count], Is_VM [Server Type],
CR_New_build as 'New build Remarks',Added_date as [Support Taken Date], install_date as [Install Date], CR_Decom_build as 'Decom Remarks',maintenance_date as [Decom Date],SVR_status as [Server state], 'Site1' as [Site]
FROM DBADATA.DBO.DBA_ALL_SERVERS 
--where SVR_status like 'running'
group by computer_name,Is_VM,CR_New_build,Added_date,install_date,CR_Decom_build,maintenance_date,SVR_status order by 1


select D.computer_name [Computer Name],S.server_name [SQL Name], 
CASE   
		 WHEN convert(VARCHAR(30),s.SQL_Version) like '15%' THEN 'SQL 2019'  
         WHEN convert(VARCHAR(30),s.SQL_Version) like '14%' THEN 'SQL 2017'  
         WHEN convert(VARCHAR(30),s.SQL_Version) like '13%' THEN 'SQL 2016' 
         WHEN convert(VARCHAR(30),s.SQL_Version) like '12%' THEN 'SQL 2014' 
         WHEN convert(VARCHAR(30),s.SQL_Version) like '11%' THEN 'SQL 2012'
		 WHEN convert(VARCHAR(30),s.SQL_Version) like '10.5%' THEN 'SQL 2008R2'
		 WHEN convert(VARCHAR(30),s.SQL_Version) like '10%' THEN 'SQL 2008'
		 WHEN convert(VARCHAR(30),s.SQL_Version) like '9%' THEN 'SQL 2005'
		 WHEN convert(VARCHAR(30),s.SQL_Version) like '8%' THEN 'SQL 2000'
         --ELSE 'Need to update' 
      END  AS 'SQL Version'
,s.SQL_Version [SQL Base],D.Category,s.Edition, s.SP,S.Server_type,D.Location, D.Domain, 'Site1'as Base_Location,
S.local_net_address [IP],D.MS_Patch,D.E_EOL as E_EOL,D.EOL,D.Patch_Software,V.OS_Version,D.OS_EOL,
E.Datacenter,E.Cluster,E.Host, -- E
D.Is_DB_level_Backup,D.Is_server_backup,D.Is_monitoring, --D
C.Number_of_Logical_CPU,C.hyperthread_ratio,C.Total_Physical_Memory_KB, -- C
AP.Application_Name,AP.Business_Owner,D.Critical_Service_Level,D.Severity, --AP
CR_New_build as 'New build Remarks',Added_date as [Support Taken Date], D.install_date as [Install Date], CR_Decom_build as 'Decom Remarks',
Maintenance_date as [Decom Date],D.SVR_status as [Server state]

FROM DBADATA.DBO.tbl_load_inventory_settings S join 
DBADATA.DBO.tbl_SQL_inventory_AppOwners AP on S.server_name=AP.Server_Name
join  DBADATA.DBO.DBA_ALL_SERVERS D on  AP.Server_Name=D.Description
join DBADATA.DBO.tbl_load_Inventory_CPU_RAM_count C on D.Description=C.servername
JOIN DBADATA.DBO.tbl_OS_version V on V.Servername=C.servername
Join DBADATA.DBO.tbl_SQL_ESXI_Host_Details E on V.Servername=E.server_name
join DBADATA.DBO.tbl_Patch_OS_EOL OE on OE.Server_name=E.server_name
 --where D.SVR_status <>'Decom' --and D.Comments <>'Just monitoring'
 --and S.server_name like '%%'
 order by [SQL Name]

  ---============================ DB count -- Replcae date 2020-05-31 23:59:59.999 -- 4 places

Exec [Usp_load_sys_databases]
Exec [Usp_load_db_count] '2020-05-31 23:59:59.999'
go

/* select * from tbl_sys_databases where name not in ('tempdb') and create_date <='2020-05-31 23:59:59.999'
select * from tbl_DB_Mapping_application_Owners
select  1166-1057 -- 109
*/
select SD.Server_Name as [Server Name],SD.name as [Database Name],SD.Create_Date [Create Date],
CASE   
		 WHEN convert(VARCHAR(30),SD.name) like 'master' THEN 'System DB'
		 WHEN convert(VARCHAR(30),SD.name) like 'model' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like 'msdb' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like 'tempdb' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like '%ReportServer%' THEN 'SSRS Portal'  
		 ELSE AO.[Application_Name]
END  AS [Application Name],  
 
 CASE   
		 WHEN convert(VARCHAR(30),SD.name) like 'master' THEN 'System DB'
		 WHEN convert(VARCHAR(30),SD.name) like 'model' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like 'msdb' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like 'tempdb' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like '%ReportServer%' THEN 'SSRS Portal'  
		 ELSE AO.Business_Owner
END  AS [Business Owner], AO.Comments [Comments] ,

'Site1' [Site Name], getdate() as [Load Date]


from tbl_sys_databases SD left join tbl_DB_Mapping_application_Owners AO
on SD.Server_Name=AO.Server_Name
and sd.name=ao.Database_Name
where name not in ('tempdb') and SD.Create_Date <='2020-05-31 23:59:59.999'
group by  SD.Server_Name,SD.name ,SD.Create_Date,AO.Comments,AO.Business_Owner,AO.[Application_Name]
order by SD.Create_Date desc


--New DB application owners mapping
/*
--Site1
truncate table tbl_DB_Mapping_application_Owners_temp_monthly
BULK INSERT tbl_DB_Mapping_application_Owners_temp_monthly  FROM 'D:\Source\DB_maaping_Site1_monthly.txt'WITH (FIELDTERMINATOR = '<>',ROWTERMINATOR = '\n')

-- select * from tbl_DB_Mapping_application_Owners order by create_date desc
insert into tbl_DB_Mapping_application_Owners
select * from tbl_DB_Mapping_application_Owners_temp_monthly
select * from tbl_DB_Mapping_application_Owners where load_date ='2020-06-01 00:00:00.000'
*/

/*
select Server_Name,Database_Name,count (*) from tbl_DB_Mapping_application_Owners group by Server_Name,Database_Name
having count(*)>1

select load_date LD,* from tbl_DB_Mapping_application_Owners where load_date = '2020-06-01 00:00:00.000' order by load_date desc
delete from tbl_DB_Mapping_application_Owners where load_date = '2020-06-01 00:00:00.000'

select load_date LD,* from tbl_DB_Mapping_application_Owners where server_name like '%FINPBPDB01%' order by load_date desc
delete from tbl_DB_Mapping_application_Owners where server_name like '%FINPBPDB01%' 

*/
--==============Db count
select * from [tbl_db_count]

--================== count the database and instance load it to table

-- Site1 site
 --select svr_status FROM DBADATA.DBO.DBA_ALL_SERVERS group by svr_status
 
 select count(*) FROM DBADATA.DBO.DBA_ALL_SERVERS where svr_status='Running'
 select count(database_id) FROM tbl_sys_databases

 
 --===== delete and load it
 -- create table tbl_server_Db_count_load (Site varchar (20), server int, DB int, comments varchar(200))
delete from tbl_server_Db_count_load
insert into tbl_server_Db_count_load values ('Site1',109,1166,'Including DMZ and Tesco')
insert into tbl_server_Db_count_load values ('Site2',40,832,'Including DMZ and sys DBs')

select sum(db) [Total SQL DBs]from tbl_server_Db_count_load
select sum(server)  [Total SQL Servers] from tbl_server_Db_count_load

-- Install & Decom details
select Added_date as Install,SVR_status, * FROM DBADATA.DBO.DBA_ALL_SERVERS order by Added_date desc
select install_date as Install,SVR_status, * FROM DBADATA.DBO.DBA_ALL_SERVERS order by install_date desc

select maintenance_date as Decom,SVR_status as state, * FROM DBADATA.DBO.DBA_ALL_SERVERS where SVR_status<>'running' order by maintenance_date desc


--============== OS EOL
--https://support.microsoft.com/en-us/lifecycle/search?alpha=Windows%20Server%202016%20Standard
-- Site1
select OS_Version,count(*) [Count] ,
CASE   
		 WHEN convert(VARCHAR(30),OS_Version) like '%Microsoft Windows Server 2003%' THEN '4/14/2009'  
         WHEN convert(VARCHAR(30),OS_Version) like '%Windows 7 Professional%' THEN '4/9/2013'  
         WHEN convert(VARCHAR(30),OS_Version) like '%Windows Server (R) 2008%' THEN '7/12/2011' 
         --WHEN convert(VARCHAR(30),OS_Version) like '%Windows Server (R) 2008 Standard%' THEN '7/12/2011' 
         WHEN convert(VARCHAR(30),OS_Version) like '%Windows Server 2008 R2%' THEN '4/9/2013'
		 --WHEN convert(VARCHAR(30),OS_Version) like '%Windows Server 2008 R2%' THEN '4/9/2013'
		 WHEN convert(VARCHAR(30),OS_Version) like '%Windows Server 2012%' THEN '10/10/2023'
		 --WHEN convert(VARCHAR(30),OS_Version) like '%Windows Server 2012 Standard%' THEN '10/10/2023'
		 WHEN convert(VARCHAR(30),OS_Version) like '%Windows Server 2016 Standard%' THEN '1/12/2027'
         --ELSE 'Need to update' 
       END  AS 'EOL', 'Site1'Site

FROM tbl_OS_version 

group by OS_Version
order by 3 desc


--============== SQL EOL
-- SQL server version EOL Site1
select Version [SQL Version],count(*) [Count],  E_EOL [EOL], 'Site1' [Site]
 FROM DBA_All_servers where SVR_status ='running'
 group by Version,E_EOL order by E_EOL


-- server count 
--- computer name based group by 
select computer_name, count(*) FROM DBADATA.DBO.DBA_ALL_SERVERS where SVR_status ='running'
group by computer_name order by 2 desc

--- ip based group by 
select count(ip) FROM DBADATA.DBO.DBA_ALL_SERVERS where SVR_status ='running'
group by ip 


