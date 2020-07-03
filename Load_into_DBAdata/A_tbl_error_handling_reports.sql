use DBAdata
/* select svr_status,* FROM DBADATA.DBO.DBA_ALL_SERVERS where svr_status ='running'
select svr_status,Added_date,maintenance_date,* FROM DBADATA.DBO.DBA_ALL_SERVERS where description like '%%'
select svr_status,Added_date,maintenance_date,* FROM DBADATA.DBO.DBA_ALL_SERVERS where ip like '%%'
*/
select svr_status,* FROM DBADATA.DBO.DBA_ALL_SERVERS where svr_status ='not ping_U'
update DBADATA.DBO.DBA_ALL_SERVERS set svr_status ='Running' where svr_status ='not ping_U'
select svr_status,maintenance_date as md,* FROM DBADATA.DBO.DBA_ALL_SERVERS where svr_status ='decom' order by maintenance_date desc
--select getdate()
SELECT * FROM [dbo].[DBA_All_Server_Space_percentage] WHERE Precentage_free <10 ORDER BY FREE_SPACE_IN_MB
 go
Exec [Usp_agent_status]
 
select Error_Message,count(*) from tbl_Error_handling group by Error_Message 
select Error_Message,Server_name,Module_name from tbl_Error_handling group by Error_Message,Server_name,Module_name
TRUNCATE TABLE tbl_Error_handling


/*
select Added_date as Install, * FROM DBADATA.DBO.DBA_ALL_SERVERS order by Added_date desc
select maintenance_date as Decom,SVR_status as state, * FROM DBADATA.DBO.DBA_ALL_SERVERS where SVR_status<>'running' order by maintenance_date desc

select Added_date as Install, * FROM Server.DBADATA.DBO.DBA_ALL_SERVERS order by Added_date desc
select maintenance_date as Decom,SVR_status as state, * FROM Server.DBADATA.DBO.DBA_ALL_SERVERS where SVR_status<>'running' order by maintenance_date desc

-- Decom
update DBADATA.DBO.DBA_ALL_SERVERS set SVR_status='decom' where Description like '%Server%'
update DBADATA.DBO.DBA_ALL_SERVERS set maintenance_date='2020-05-31 13:26:04.560' where Description like '%Server%'
update tbl_SQL_inventory_PeteM set Comments='decom' where SQL_full_name like 'Server'
update tbl_Patch_OS_EOL set svr_status='decom' where Server_name like 'Server'
update tbl_SQL_ESXI_Host_Details set svr_status='decom' where Server_name like 'Server'
update DBA_ALL_SERVERS set CR_Decom_build='Decom moved' where Description like 'Server'

*/


-- oracle

--select * from tbl_oracle_Legacy_Inventory

 
 ------=========
  ------=========


select * FROM DBADATA.DBO.tbl_Error_handling where ERROR_MESSAGE like '%login%'

select Module_name from tbl_Error_handling group by Module_name
select Error_Message,Server_name,Module_name from tbl_Error_handling group by Error_Message,Server_name,Module_name

select * FROM DBADATA.DBO.DBA_ALL_SERVERS order by Description
-- w32tm /resync
select Server_name,ERROR_MESSAGE from tbl_Error_handling  where ERROR_MESSAGE   like '%find%' group by Server_name,ERROR_MESSAGE
-- TRUNCATE TABLE tbl_Error_handling
select Error_Message from tbl_Error_handling group by Error_Message

select Server_name,count(*) from tbl_Error_handling group by Server_name order by count(*) desc

select Error_Message,Server_name,Module_name,count(*) from tbl_Error_handling group by Error_Message,Server_name,Module_name order by Module_name desc

--select * from tbl_dm_server_services where server_name like '%server%'

-- ===== server consolidation
/*

select * from tbl_server_Migration_list


insert into tbl_server_Migration_list 

select * from tbl_server_upgrade_list


select * from tbl_server_Decommission_list

insert into tbl_server_Decommission_list 



select * from tbl_server_Installation_list


insert into tbl_server_Installation_list 


*/