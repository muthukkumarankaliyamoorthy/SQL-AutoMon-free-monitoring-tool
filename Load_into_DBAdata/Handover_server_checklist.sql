--WSUS_Patch,Datacenter,Cluster,Host,is_Appaware,is_full_machine,is_SolwarWinds,is_Splunk


select S.server_name [SQL Name], 
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
,s.SQL_Version [SQL Base],D.Category,s.Edition, s.SP,S.Server_type,D.Location, D.Domain, 'Broker'as Base_Location,
S.local_net_address [IP],OE.WSUS_Patch,V.OS_Version,
E.Datacenter,E.Cluster,E.Host, -- E
D.Is_DB_level_Backup,D.Is_server_backup,D.Is_monitoring, --D
P.Application_name,P.Business_Owner,D.Critical_Service_Level,D.Severity --P

FROM DBADATA.DBO.tbl_load_inventory_settings S join 
DBADATA.DBO.tbl_DB_Mapping_application_Owners P on S.server_name=P.Server_Name
join  DBADATA.DBO.DBA_ALL_SERVERS D on  P.Server_Name=D.Description
join DBADATA.DBO.tbl_load_Inventory_CPU_RAM_count C on D.Description=C.servername
JOIN DBADATA.DBO.tbl_OS_version V on V.Servername=C.servername
Join DBADATA.DBO.tbl_SQL_ESXI_Host_Details E on V.Servername=E.server_name
join DBADATA.DBO.tbl_Patch_OS_EOL OE on OE.Server_name=E.server_name
 where D.SVR_status <>'Decom' --and D.Comments <>'Just monitoring'
 order by [SQL Name]

 -- site2
 select S.server_name [SQL Name], 
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
,s.SQL_Version [SQL Base],p.Category,s.Edition, s.SP,S.Server_type,D.Location, D.Domain, 'Broker'as Base_Location,
S.local_net_address [IP],OE.WSUS_Patch,V.OS_Version,
E.Datacenter,E.Cluster,E.Host, -- E
D.is_Appaware,D.is_full_machine,D.is_SolwarWinds,D.is_Splunk, --D
P.System,P.Business_Contact,D.Critical_Service_Level,D.Severity --P

FROM Server.DBADATA.DBO.tbl_load_inventory_settings S join 
Server.DBADATA.DBO.tbl_SQL_inventory_PeteC P on S.server_name=P.Servername
join  Server.DBADATA.DBO.DBA_ALL_SERVERS D on  P.Servername=D.Description
join Server.DBADATA.DBO.tbl_load_Inventory_CPU_RAM_count C on D.Description=C.servername
JOIN Server.DBADATA.dbo.tbl_OS_version V on V.Servername=C.servername
Join DBADATA.DBO.tbl_SQL_ESXI_Host_Details E on V.Servername=E.server_name
join Server.DBADATA.DBO.tbl_Patch_OS_EOL OE on OE.Server_name=E.server_name
 where D.SVR_status <>'Decom' --and D.Comments <>'Just monitoring'

 order by [SQL Name]


