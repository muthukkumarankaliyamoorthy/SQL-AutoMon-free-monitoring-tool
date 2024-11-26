
-- add server by running 1_0_1_CMS.sql on target and collect data and paste over it
-- Check HA, for failover cluster add in comments
-- ebnale dac
-- ADD in Registered server
-- add in on AppownerTable table ========================= IP changes need to be update in Backup calander table
--
-- ===============================


/*Since the SP name is same for both SQL and non SQL linked server, make sure to run either of one
USP_DBA_ADDSERVER_FOR_MONITOR & USP_DBA_DROPSERVER_FOR_MONITOR*/

-- Add SQL based linked server

EXEC [dbo].[USP_DBA_ADDSERVER_FOR_MONITOR_SQL_LS]	@P_SERVER='LAPTOP-ISGUKEUC\SQLEXPRESS',	@P_DESC='LAPTOP-ISGUKEUC\SQLEXPRESS',	@P_VERSION='SQL2014',	@P_USERNAME='SA',	@P_PWD='G0d$peed@123',	@P_category='Non-Prod',	@P_location='India',	@P_edition='Express Edition (64-bit)',	@P_svr_status='Running',	@P_login_mode='Windows'

-- Add non SQL based linked server (Other source)
EXEC [USP_DBA_ADDSERVER_FOR_MONITOR_Other_LS]	@P_LINK_SERVER='DBA_LAPTOP-ISGUKEUC\MUTHU',@P_SERVER='LAPTOP-ISGUKEUC\MUTHU',	@P_DESC='LAPTOP-ISGUKEUC\MUTHU',	@P_VERSION='SQL2014',	@P_USERNAME='SA',	@P_PWD='SApassword',	@P_category='Non-Prod',	@P_location='India',	@P_edition='Enterprise Edition: Core-based Licensing (64-bit)',	@P_svr_status='Running',	@P_login_mode='Windwos'

select * from DBA_All_servers

-- Drop SQL based linked server
EXEC [USP_DBA_DROPSERVER_FOR_MONITOR_SQL_LS_SQL_LS]	'LAPTOP-ISGUKEUC\MUTHU',	'SQL2014',	'LAPTOP-ISGUKEUC\MUTHU'
-- Drop non SQL based linked server (Other source)
EXEC [USP_DBA_DROPSERVER_FOR_MONITOR_Other_LS]	'DBA_LAPTOP-ISGUKEUC\MUTHU',	'DBA_LAPTOP-ISGUKEUC\MUTHU',	'SQL2014',	'LAPTOP-ISGUKEUC\MUTHU'


select Added_date,* FROM DBADATA.DBO.DBA_ALL_SERVERS where Description like '%ServerName.FQDN%'

-- Run 1_0_1_CMS.sql on target and collect data and paste over it

SELECT create_date FROM sys.server_principals WHERE sid = 0x010100000000000512000000
--=============================== Replace the server name

select* from DBA_All_servers where Description like '%ServerName.domain%'
 

--- insert other tables -- replace the ip 3 places

select * from tbl_SQL_inventory_AppownerTable

 INSERT INTO DBADATA.DBO.tbl_SQL_inventory_AppownerTable (SQL_full_name,comments,environment,Applications,Business_owner,Location) 
 VALUES ('ServerName.domain', 'Working','Production','App Name','Owner Name','Location')

 select * from tbl_SQL_ESXI_Host_Details where Host like '%vsphere17%'

 INSERT INTO DBADATA.DBO.tbl_SQL_ESXI_Host_Details (Server_name,base_location,SQL_VM,ip,Datacenter,Cluster,Host,VcenterName,svr_status) 
 VALUES ('ServerName.domain','Broker','Virtual','IP_Address','vSphere','SQL Cluster','Esxi host name','vcenter Name','running')
 
 select * from tbl_Backup_Calender

 INSERT INTO DBADATA.DBO.tbl_Backup_Calender (computer_name,Server_name,Server_type,ip,backup_tool_name,appAware,server_backup,backup_SQL,[backup],Comments_Consolidated,svr_status) 
 VALUES ('ServerName.domain','ServerName.domain','Virtual','IP_Address','BackupExec','Physical-DB backup','yes-tlog','Log_shipping','yes','WSFC with Log_shipping primary','Running')

 select * from tbl_Patch_OS_EOL -- where server_name like '%server%'

 INSERT INTO DBADATA.DBO.tbl_Patch_OS_EOL (Server_name,ip,Product,CAU,comments,WSUS_Patch,svr_status) 
 VALUES ('ServerName.domain','IP_Address','Windows Server 2016 Standard','Use CAU','Stand-Alone','OS Cluster','Running')



   -- Update columns where is needed and possible 
 select * FROM DBADATA.DBO.DBA_ALL_SERVERS WHERE Description LIKE 'ServerName.domain' 
 --UPDATE DBADATA.DBO.DBA_ALL_SERVERS SET location='Location' WHERE Description LIKE 'ServerName.domain' 
 --UPDATE DBADATA.DBO.DBA_ALL_SERVERS SET domain='Domain name' WHERE Description LIKE 'ServerName.domain' 
 --UPDATE DBADATA.DBO.DBA_ALL_SERVERS SET Severity='Severity 3' WHERE Description LIKE 'ServerName.domain'  
 --UPDATE DBADATA.DBO.DBA_ALL_SERVERS SET Critical_Service_Level='Low' where Description LIKE 'ServerName.domain' 
 UPDATE DBADATA.DBO.DBA_ALL_SERVERS SET HA='SQLcluster' WHERE Description LIKE 'ServerName.domain' 
 UPDATE DBADATA.DBO.DBA_ALL_SERVERS SET Comments='SQLcluster with Logshipping standby' WHERE Description LIKE 'ServerName.domain' 
 		
update DBA_ALL_SERVERS set is_Appaware='Added' where description like 'ServerName.domain' 
update DBA_ALL_SERVERS set is_full_machine='BackupExec' where description like 'ServerName.domain' 
update DBA_ALL_SERVERS set is_SolwarWinds='Added' where description like 'ServerName.domain' 
update DBA_ALL_SERVERS set is_Splunk='Yes' where description like 'ServerName.domain' 
select EOL,SP_E_EOL,MS_Patch,Patch_compliance,* FROM DBADATA.DBO.DBA_ALL_SERVERS WHERE Version like'SQL2017' -- check version and update
select OS_EOL,OS_version,* FROM DBADATA.DBO.DBA_ALL_SERVERS WHERE OS_version like'%2016%' -- check version and update

update DBA_ALL_SERVERS set EOL='2022-11-10 00:00:00.000' where description like 'ServerName.domain' 
update DBA_ALL_SERVERS set SP_E_EOL='2027-12-10 00:00:00.000' where description like 'ServerName.domain' 
update DBA_ALL_SERVERS set MS_Patch='14.0.3294.2' where description like 'ServerName.domain' 
update DBA_ALL_SERVERS set Patch_compliance='Yes' where description like 'ServerName.domain' 

update DBA_ALL_SERVERS set OS_EOL='2027-01-12 00:00:00.000' where description like 'ServerName.domain' 
update DBA_ALL_SERVERS set OS_version='Windows Server 2016 Standard' where description like 'ServerName.domain' 
update DBA_ALL_SERVERS set computer_name='ServerName.domain' where description like 'ServerName.domain' 
update DBA_ALL_SERVERS set OS_bit='NT x64' where description like 'ServerName.domain' 
update DBA_ALL_SERVERS set SQL_bit='64-bit' where description like 'ServerName.domain' 
update DBA_ALL_SERVERS set is_vm='Virtual' where description like 'ServerName.domain' 

 --UPDATE DBADATA.DBO.DBA_ALL_SERVERS SET Description='ServerName.domain' WHERE Description LIKE 'ServerName.domain' 
  select * FROM DBADATA.DBO.DBA_ALL_SERVERS WHERE Description LIKE 'ServerName.domain' 

  
 --update DBADATA.DBO.tbl_SQL_inventory_AppownerTable set Comments= 'Working'WHERE SQL_full_name LIKE 'ServerName.domain%' -- 41

 -- Run Sps and load to get new data
 --1 Inventory
exec DBADATA.DBO.[Usp_load_OS_Info]
exec DBADATA.DBO.[Usp_Load_cpu_ram_Inventory_load]
exec DBADATA.DBO.[Usp_load_settings]


 SELECT * FROM DBADATA.DBO.tbl_load_inventory_settings WHERE server_name LIKE 'ServerName.domain%'-- 41 
 SELECT * FROM DBADATA.DBO.tbl_load_Inventory_CPU_RAM_count  WHERE Servername LIKE 'ServerName.domain%'-- 41  
 SELECT * FROM DBADATA.DBO.tbl_SQL_inventory_AppownerTable  WHERE SQL_full_name LIKE 'ServerName.domain%'-- 41  

 SELECT * FROM  tbl_OS_version WHERE Servername LIKE 'ServerName.domain%' -- 41
 SELECT * FROM  tbl_SQL_ESXI_Host_Details WHERE Server_name LIKE 'ServerName.domain%' -- 41
 SELECT * FROM  tbl_OS_version WHERE Servername LIKE 'ServerName.domain%' -- 41
 SELECT * FROM  tbl_Patch_OS_EOL WHERE Server_name LIKE 'ServerName.domain%' -- 41
