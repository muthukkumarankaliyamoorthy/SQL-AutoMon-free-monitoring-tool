
-- check join table count
select SVR_status FROM  DBADATA.DBO.DBA_ALL_SERVERS group by SVR_status--

select count (*) FROM  DBADATA.DBO.DBA_ALL_SERVERS where SVR_status ='running' -- 110
select count (*) FROM DBADATA.DBO.tbl_load_inventory_settings --
select count (*) FROM DBADATA.DBO.tbl_SQL_inventory_PeteM where Comments='Working'--


select count (*) FROM DBADATA.DBO.tbl_load_Inventory_CPU_RAM_count --
select count (*) FROM tbl_OS_version --
select count (*) FROM DBADATA.DBO.tbl_SQL_ESXI_Host_Details where svr_status ='running' and base_location = 'broker'
select count (*) FROM DBADATA.DBO.tbl_Patch_OS_EOL  where svr_status ='running'


-- broker server count
select computer_name [Server Name],count(*) [Instance Count]FROM DBADATA.DBO.DBA_ALL_SERVERS 
where SVR_status like 'running' 
group by computer_name

select computer_name [Server Name],count(*) [Instance Count]FROM server.DBADATA.DBO.DBA_ALL_SERVERS 
where SVR_status like 'running' 
group by computer_name


--===========================
 -- Sheet 2
 --===========================
select computer_name [Server Name],count(*) [Instance Count], Is_VM [Server Type],
CR_New_build as 'New build Remarks',Added_date as [Support Taken Date], install_date as [Install Date], CR_Decom_build as 'Decom Remarks',maintenance_date as [Decom Date],SVR_status as [Server state], 'Broker' as [Site]
FROM DBADATA.DBO.DBA_ALL_SERVERS 
--where SVR_status like 'running'
group by computer_name,Is_VM,CR_New_build,Added_date,install_date,CR_Decom_build,maintenance_date,SVR_status order by 1

-- D&P server count

select computer_name [Server Name],count(*) [Instance Count], Is_VM [Server Type],
CR_New_build as 'New build Remarks',Added_date as [Support Taken Date], install_date as [Install Date], CR_Decom_build as 'Decom Remarks',maintenance_date as [Decom Date],SVR_status as [Server state], 'D&P' as [Site]
FROM server.DBADATA.DBO.DBA_ALL_SERVERS
--where SVR_status like 'running'
group by computer_name,Is_VM,CR_New_build,Added_date,install_date,CR_Decom_build,maintenance_date,SVR_status order by 1

--===========================
 -- Sheet 3 
 --===========================
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
,s.SQL_Version [SQL Base],p.Environment,s.Edition, s.SP,S.Server_type,D.Location, D.Domain, 'Broker'as Base_Location,
S.local_net_address [IP],D.MS_Patch,D.SP_E_EOL as E_EOL,D.EOL,OE.WSUS_Patch,V.OS_Version,D.OS_EOL,
E.Datacenter,E.Cluster,E.Host, -- E
D.is_Appaware,D.is_full_machine,D.is_SolwarWinds,D.is_Splunk, --D
C.Number_of_Logical_CPU,C.hyperthread_ratio,C.Total_Physical_Memory_KB, -- C
P.Applications,P.Business_Owner,D.Critical_Service_Level,D.Severity, --P
CR_New_build as 'New build Remarks',Added_date as [Support Taken Date], D.install_date as [Install Date], CR_Decom_build as 'Decom Remarks',maintenance_date as [Decom Date],D.SVR_status as [Server state]

FROM DBADATA.DBO.tbl_load_inventory_settings S join 
DBADATA.DBO.tbl_SQL_inventory_PeteM P on S.server_name=P.SQL_full_name
join  DBADATA.DBO.DBA_ALL_SERVERS D on  P.SQL_full_name=D.Description
join DBADATA.DBO.tbl_load_Inventory_CPU_RAM_count C on D.Description=C.servername
JOIN DBADATA.DBO.tbl_OS_version V on V.Servername=C.servername
Join DBADATA.DBO.tbl_SQL_ESXI_Host_Details E on V.Servername=E.server_name
join DBADATA.DBO.tbl_Patch_OS_EOL OE on OE.Server_name=E.server_name
--and D.Edition like 'Enter%'
--and Server_type like 'v%'
 --where D.SVR_status <>'Decom' --and D.Comments <>'Just monitoring'
 
 order by [SQL Name]

 ---=====================================D&P
 
-- check join table count
select SVR_status FROM  server.DBADATA.DBO.DBA_ALL_SERVERS group by SVR_status--


select count (*) FROM server.DBADATA.DBO.tbl_load_inventory_settings --
select count (*) FROM server. DBADATA.DBO.tbl_SQL_inventory_PeteC where Comments='Working'--
select count (*) FROM server.DBADATA.DBO.DBA_ALL_SERVERS where SVR_status ='running' -- 114

select count (*) FROM server.DBADATA.DBO.tbl_load_Inventory_CPU_RAM_count --
select count (*) FROM server.DBADATA.DBO.tbl_OS_version --
select count (*) FROM DBADATA.DBO.tbl_SQL_ESXI_Host_Details where svr_status ='running' and base_location ='d&p' -- from local and base location
select count (*) FROM server.DBADATA.DBO.tbl_Patch_OS_EOL  where svr_status ='running'

 
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
,s.SQL_Version [SQL Base], p.Category AS Environment,s.Edition, s.SP,S.Server_type,D.Location, D.Domain,'D&P'as Base_Location,
S.local_net_address [IP],D.MS_Patch,D.SP_E_EOL as E_EOL,D.EOL,OE.WSUS_Patch,V.OS_Version,D.OS_EOL,
E.Datacenter,E.Cluster,E.Host,
D.is_Appaware,D.is_full_machine,D.is_SolwarWinds,D.is_Splunk,
C.Number_of_Logical_CPU,C.hyperthread_ratio,C.Total_Physical_Memory_KB,
P.System AS Applications,P.Business_Contact AS Business_Owner,D.Critical_Service_Level,D.Severity,
CR_New_build as 'New build Remarks',Added_date as [Support Taken Date], D.install_date as [Install Date], CR_Decom_build as 'Decom Remarks',maintenance_date as [Decom Date],D.SVR_status as [Server state]

FROM server.DBADATA.DBO.tbl_load_inventory_settings S join 
server.DBADATA.DBO.tbl_SQL_inventory_PeteC P on S.server_name=P.Servername
join  server.DBADATA.DBO.DBA_ALL_SERVERS D on  P.Servername=D.Description
join server.DBADATA.DBO.tbl_load_Inventory_CPU_RAM_count C on D.Description=C.servername
JOIN server.DBADATA.dbo.tbl_OS_version V on V.Servername=C.servername
Join DBADATA.DBO.tbl_SQL_ESXI_Host_Details E on V.Servername=E.server_name
join server.DBADATA.DBO.tbl_Patch_OS_EOL OE on OE.Server_name=E.server_name

 where D.SVR_status <>'Decom' 

 
 --AND P.Category <>'Live'
 order by [SQL Name]

 
--===========================
 -- Sheet 4
 --===========================
 ---============================ DB count -- Replcae date 2020-05-31 23:59:59.999 -- 4 places

Exec [Usp_load_sys_databases]
Exec [Usp_load_db_count] '2020-05-31 23:59:59.999'
go

/* select * from tbl_sys_databases where name not in ('tempdb') and crdate <='2020-05-31 23:59:59.999'
select * from tbl_DB_Mapping_application_Owners
select  1166-1057 -- 109
*/
select SD.ServerName as [Server Name],SD.name as [Database Name],SD.crdate [Create Date],
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

'Broker' [Site Name], getdate() as [Load Date]


from tbl_sys_databases SD left join tbl_DB_Mapping_application_Owners AO
on SD.ServerName=AO.Server_Name
and sd.name=ao.Database_Name
where name not in ('tempdb') and crdate <='2020-05-31 23:59:59.999'
--group by  SD.ServerName,SD.name ,SD.crdate,AO.Comments,AO.Business_Owner,AO.[Application_Name]
order by crdate desc

-- D&P
Exec server.DBADATA.DBO.[Usp_load_sys_databases] 
Exec server.DBADATA.DBO.[Usp_load_db_count]  '2020-05-31 23:59:59.999'
/*
select * from server.DBADATA.DBO.tbl_sys_databases where name not in ('tempdb') and crdate <='2020-05-31 23:59:59.999'
select * from server.DBADATA.DBO.tbl_DB_Mapping_application_Owners
select 832-792 -- 
*/
go
select SD.ServerName as [Server Name],SD.name as [Database Name],SD.crdate [Create Date],
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
END  AS [Business Owner] , AO.Comments [Comments] ,
'D&P' [Site Name], getdate() as [Load Date]

from server.DBADATA.DBO.tbl_sys_databases SD left join server.DBADATA.DBO.tbl_DB_Mapping_application_Owners AO
on SD.ServerName=AO.Server_Name
and sd.name=ao.Database_Name
where name not in ('tempdb') and crdate <='2020-05-31 23:59:59.999'
group by  SD.ServerName,SD.name ,SD.crdate,AO.Comments,AO.Business_Owner,AO.[Application_Name]
order by crdate desc

--New DB application owners mapping

--broker
truncate table tbl_DB_Mapping_application_Owners_temp_monthly
BULK INSERT tbl_DB_Mapping_application_Owners_temp_monthly  FROM 'D:\Source\DB_maaping_broker_monthly.txt'WITH (FIELDTERMINATOR = '<>',ROWTERMINATOR = '\n')

-- select * from tbl_DB_Mapping_application_Owners order by create_date desc
insert into tbl_DB_Mapping_application_Owners
select * from tbl_DB_Mapping_application_Owners_temp_monthly
select * from tbl_DB_Mapping_application_Owners where load_date ='2020-06-01 00:00:00.000'
----==============D&P ==================do this in d&p server=====================
truncate table tbl_DB_Mapping_application_Owners_temp_monthly
BULK INSERT tbl_DB_Mapping_application_Owners_temp_monthly  FROM '\\BTJSDBVWD001.ARL.ADRESOURCE.NET\SQL_Backup\DB_maaping_DP_monthly.txt'WITH (FIELDTERMINATOR = '<>',ROWTERMINATOR = '\n')

insert into tbl_DB_Mapping_application_Owners
select * from tbl_DB_Mapping_application_Owners_temp_monthly

/*
select Server_Name,Database_Name,count (*) from tbl_DB_Mapping_application_Owners group by Server_Name,Database_Name
having count(*)>1

select load_date LD,* from tbl_DB_Mapping_application_Owners where load_date = '2020-06-01 00:00:00.000' order by load_date desc
delete from tbl_DB_Mapping_application_Owners where load_date = '2020-06-01 00:00:00.000'

select load_date LD,* from tbl_DB_Mapping_application_Owners where server_name like '%FINPBPDB01%' order by load_date desc
delete from tbl_DB_Mapping_application_Owners where server_name like '%FINPBPDB01%' 

*/

--===========================
 -- Sheet 5
 --===========================


--==============Db count
select * from [tbl_db_count]
select * from server.DBADATA.DBO.[tbl_db_count]

--================== count the database and instance load it to table

-- Broker site
 --select svr_status FROM DBADATA.DBO.DBA_ALL_SERVERS group by svr_status
 
 select count(*) FROM DBADATA.DBO.DBA_ALL_SERVERS where svr_status='Running'
 select count(dbid) FROM tbl_sys_databases

 -- DP site
 --select svr_status FROM server.DBADATA.DBO.DBA_ALL_SERVERS group by svr_status
 
 select count(*) FROM server.DBADATA.DBO.DBA_ALL_SERVERS where svr_status in ('Running','NU')
 select count(dbid) FROM server.DBADATA.DBO.tbl_sys_databases

 --===== delete and load it
delete from tbl_server_Db_count_load
insert into tbl_server_Db_count_load values ('Broker',109,1166,'Including DMZ and Tesco')
insert into tbl_server_Db_count_load values ('D&P',40,832,'Including DMZ and sys DBs')

select sum(db) [Total SQL DBs]from tbl_server_Db_count_load
select sum(server)  [Total SQL Servers] from tbl_server_Db_count_load
--select * from tbl_server_Db_count_load
-- select 1091+ 815 -- 2161
-- select 120+43

--===========================
 -- Sheet 1 -- update and mark Decom & install
 --===========================

-- Install & Decom details
select Added_date as Install,SVR_status, * FROM DBADATA.DBO.DBA_ALL_SERVERS order by Added_date desc
select install_date as Install,SVR_status, * FROM DBADATA.DBO.DBA_ALL_SERVERS order by install_date desc

select Added_date as Install,SVR_status, * FROM server.DBADATA.DBO.DBA_ALL_SERVERS order by Added_date desc
select install_date as Install,SVR_status, * FROM server.DBADATA.DBO.DBA_ALL_SERVERS order by install_date desc


select maintenance_date as Decom,SVR_status as state, * FROM DBADATA.DBO.DBA_ALL_SERVERS where SVR_status<>'running' order by maintenance_date desc
select maintenance_date as Decom,SVR_status as state, * FROM server.DBADATA.DBO.DBA_ALL_SERVERS where SVR_status<>'running' order by maintenance_date desc

--===========================
 -- Sheet 6
 --===========================

--============== OS EOL
--https://support.microsoft.com/en-us/lifecycle/search?alpha=Windows%20Server%202016%20Standard
-- broker
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
       END  AS 'EOL', 'Broker'Site

FROM tbl_OS_version 

group by OS_Version
order by 3 desc

-- D&P


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
      END  AS 'EOL', 'D&P'Site

FROM server.DBADATA.DBO.tbl_OS_version 

group by OS_Version
order by 3 desc

--============== SQL EOL
-- SQL server version EOL broker
select Version [SQL Version],count(*) [Count],  SP_E_EOL [EOL], 'Broker' [Site]
 FROM DBA_All_servers where SVR_status ='running'
 group by Version,SP_E_EOL order by SP_E_EOL

-- D&P

select Version [SQL Version],count(*) [Count],  SP_E_EOL [EOL], 'D&P' [Site]
 FROM server.DBADATA.DBO.DBA_All_servers where SVR_status ='running'
 group by Version,SP_E_EOL order by SP_E_EOL

 -- 
 
-- server count 
--- computer name based group by 
select computer_name, count(*) FROM DBADATA.DBO.DBA_ALL_SERVERS where SVR_status ='running'
group by computer_name order by 2 desc

select computer_name, count(*) FROM server.DBADATA.DBO.DBA_ALL_SERVERS where SVR_status ='running'
group by computer_name order by 2 desc

--- ip based group by 
select count(ip) FROM DBADATA.DBO.DBA_ALL_SERVERS where SVR_status ='running'
group by ip 
select count(ip) FROM server.DBADATA.DBO.DBA_ALL_SERVERS where SVR_status ='running'
group by ip 


--===========================
 -- Sheet 7 Look at the script named 
 --Monthly_Patching_Report_SWG_EOL_patched_non_patched-monthly-Report
 --Patching_Report
 --===========================


 --Patch
 /*
 -- Run this PS on both site
-- \\share\rr\data\muthu_DBA_Team\SQLDBA\ -- EOL_Patch_SQL_PS

update the null values of CU & SP
-- Broker
-- Above 2016 only CU
select Namelevel [SQL Version],count(CUTarget) [Compliance Count], SupportedUntil [EOL],CUlevel,CUTarget,'Broker'[Site Name],'' [Comments]
 FROM SQLPatch_EOL
where Namelevel >'2016'
group by Namelevel,SupportedUntil, CUlevel,CUTarget 
order by SupportedUntil

-- select * FROM SQLPatch_EOL

-- Below 2017 only SP
select Namelevel [SQL Version],count(SPTarget) [Compliance Count], SupportedUntil [EOL], Splevel,SPTarget ,'Broker'[Site Name],'' [Comments]
FROM SQLPatch_EOL
where Namelevel <'2017'
group by Namelevel,SupportedUntil, Splevel,SPTarget 
order by SupportedUntil

-- D&P
-- Above 2016 only CU
select Namelevel [SQL Version],count(CUTarget) [Compliance Count], SupportedUntil [EOL],CUlevel,CUTarget,'D&P'[Site Name],'' [Comments]
 FROM server.DBADATA.DBO.SQLPatch_EOL
where Namelevel >'2016'
group by Namelevel,SupportedUntil, CUlevel,CUTarget 
order by SupportedUntil

-- select * FROM SQLPatch_EOL

-- Below 2017 only SP
select Namelevel [SQL Version],count(SPTarget) [Compliance Count], SupportedUntil [EOL], Splevel,SPTarget ,'D&P'[Site Name],'' [Comments]
FROM server.DBADATA.DBO.SQLPatch_EOL
where Namelevel <'2017'
group by Namelevel,SupportedUntil, Splevel,SPTarget 
order by SupportedUntil
*/

 /* -- Application mapping excel
 
 select ServerName as [Server Name],name as [Database Name],crdate [Create Date],
 '' [Ticket Number],''[Application Name], 
 '' [Business Owner], ''[Application Server],'Broker' [Site Name],'' [Comments] 
from tbl_sys_databases 
where dbid not in (1,2,3,4) and crdate <='2020-04-01'
and name not in ('DBAUtil')
order by crdate desc


select ServerName as [Server Name],name as [Database Name],crdate [Create Date],
 '' [Ticket Number],''[Application Name], 
 '' [Business Owner], ''[Application Server],'D&P' [Site Name],'' [Comments] 
from server.DBADATA.DBO.tbl_sys_databases
where dbid not in (1,2,3,4) and crdate <='2020-04-01'
and name not in ('DBAUtil')
order by crdate desc
*/