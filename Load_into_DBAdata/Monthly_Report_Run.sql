/*
*/

-- Site1
--1 Inventory
exec DBADATA.DBO.[Usp_load_OS_Info] --tbl_OS_version
exec DBADATA.DBO.[Usp_Load_cpu_ram_Inventory_load] --tbl_load_Inventory_CPU_RAM_count
exec DBADATA.DBO.[Usp_load_settings] -- tbl_load_inventory_settings

--1 insert lower version
--insert into tbl_load_inventory_settings (server_name,Instance,SQL_Version,SP,login_mode,edition,IsClustered,Collation,BuildClrVersion,local_net_address,virtual_machine_type_desc,Server_type,uploaddate)
 
 -- update win 2003
--select * from  tbl_OS_version where os_version like '%2003%'
-- select * from tbl_load_inventory_settings where convert(VARCHAR(30),SQL_Version) like '13.0.52%'


--update tbl_load_inventory_settings set local_net_address='ip' where server_name='server'

-- update version
UPDATE t1
  SET t1.Version = convert(VARCHAR(30),t2.SQL_Version)
  FROM dbo.DBA_ALL_SERVERS AS t1
  INNER JOIN dbo.tbl_load_inventory_settings AS t2
  ON t1.Description = t2.server_name
--  WHERE t1.BatchNo = '110';


---------
update DBA_ALL_SERVERS set Version   ='SQL2000' where Version like '8%'
update DBA_ALL_SERVERS set Version   ='SQL2005' where Version like '9%'
update DBA_ALL_SERVERS set Version   ='SQL2008' where Version like '10.0%'
update DBA_ALL_SERVERS set Version   ='SQL2008R2' where Version like '10.5%'
update DBA_ALL_SERVERS set Version   ='SQL2012' where Version like '11%'
update DBA_ALL_SERVERS set Version   ='SQL2014' where Version like '12%'
update DBA_ALL_SERVERS set Version   ='SQL2016' where Version like '13%'
update DBA_ALL_SERVERS set Version   ='SQL2017' where Version like '14%'
update DBA_ALL_SERVERS set Version   ='SQL2019' where Version like '15%'

-- update SP level

UPDATE t1
  SET t1.SP = convert(VARCHAR(30),t2.sp)
  FROM dbo.DBA_ALL_SERVERS AS t1
  INNER JOIN dbo.tbl_load_inventory_settings AS t2
  ON t1.Description = t2.server_name
--  WHERE t1.BatchNo = '110';

-- update login mode

UPDATE t1
  SET t1.Login_mode = convert(VARCHAR(30),t2.login_mode)
  FROM dbo.DBA_ALL_SERVERS AS t1
  INNER JOIN dbo.tbl_load_inventory_settings AS t2
  ON t1.Description = t2.server_name
--  WHERE t1.BatchNo = '110';

-- update edition

UPDATE t1
  SET t1.Edition = convert(VARCHAR(30),t2.edition)
  FROM dbo.DBA_ALL_SERVERS AS t1
  INNER JOIN dbo.tbl_load_inventory_settings AS t2
  ON t1.Description = t2.server_name
--  WHERE t1.BatchNo = '110';


-- update IP

UPDATE t1
  SET t1.ip = convert(VARCHAR(30),t2.local_net_address)
  FROM dbo.DBA_ALL_SERVERS AS t1
  INNER JOIN dbo.tbl_load_inventory_settings AS t2
  ON t1.Description = t2.server_name
--  WHERE t1.BatchNo = '110';


-- update server type

UPDATE t1
  SET t1.Is_VM = convert(VARCHAR(30),t2.Server_type)
  FROM dbo.DBA_ALL_SERVERS AS t1
  INNER JOIN dbo.tbl_load_inventory_settings AS t2
  ON t1.Description = t2.server_name
--  WHERE t1.BatchNo = '110';

-- update version number

UPDATE t1
  SET t1.Version = convert(VARCHAR(30),t2.SQL_Version)
  FROM dbo.DBA_ALL_SERVERS AS t1
  INNER JOIN dbo.tbl_load_inventory_settings AS t2
  ON t1.Description = t2.server_name
--  WHERE t1.BatchNo = '110';

/*
-- Site2
 
exec Server.DBADATA.DBO.[Usp_load_OS_Info]
exec Server.DBADATA.DBO.[Usp_Load_cpu_ram_Inventory_load]
exec Server.DBADATA.DBO.[Usp_load_settings]


-- update version
UPDATE t1
  SET t1.Version = convert(VARCHAR(30),t2.SQL_Version)
  FROM Server.DBADATA.DBO.DBA_ALL_SERVERS AS t1
  INNER JOIN Server.DBADATA.DBO.tbl_load_inventory_settings AS t2
  ON t1.Description = t2.server_name
--  WHERE t1.BatchNo = '110';


---------
update Server.DBADATA.DBO.DBA_ALL_SERVERS set Version   ='SQL2000' where Version like '8%'
update Server.DBADATA.DBO.DBA_ALL_SERVERS set Version   ='SQL2005' where Version like '9%'
update Server.DBADATA.DBO.DBA_ALL_SERVERS set Version   ='SQL2008' where Version like '10.0%'
update Server.DBADATA.DBO.DBA_ALL_SERVERS set Version   ='SQL2008R2' where Version like '10.5%'
update Server.DBADATA.DBO.DBA_ALL_SERVERS set Version   ='SQL2012' where Version like '11%'
update Server.DBADATA.DBO.DBA_ALL_SERVERS set Version   ='SQL2014' where Version like '12%'
update Server.DBADATA.DBO.DBA_ALL_SERVERS set Version   ='SQL2016' where Version like '13%'
update Server.DBADATA.DBO.DBA_ALL_SERVERS set Version   ='SQL2017' where Version like '14%'
update Server.DBADATA.DBO.DBA_ALL_SERVERS set Version   ='SQL2019' where Version like '15%'

-- update SP level

UPDATE t1
  SET t1.SP = convert(VARCHAR(30),t2.sp)
  FROM Server.DBADATA.DBO.DBA_ALL_SERVERS AS t1
  INNER JOIN Server.DBADATA.DBO.tbl_load_inventory_settings AS t2
  ON t1.Description = t2.server_name
--  WHERE t1.BatchNo = '110';

-- update login mode

UPDATE t1
  SET t1.Login_mode = convert(VARCHAR(30),t2.login_mode)
  FROM Server.DBADATA.DBO.DBA_ALL_SERVERS AS t1
  INNER JOIN Server.DBADATA.DBO.tbl_load_inventory_settings AS t2
  ON t1.Description = t2.server_name
--  WHERE t1.BatchNo = '110';

-- update edition

UPDATE t1
  SET t1.Edition = convert(VARCHAR(30),t2.edition)
  FROM Server.DBADATA.DBO.DBA_ALL_SERVERS AS t1
  INNER JOIN Server.DBADATA.DBO.tbl_load_inventory_settings AS t2
  ON t1.Description = t2.server_name
--  WHERE t1.BatchNo = '110';


-- update IP

UPDATE t1
  SET t1.ip = convert(VARCHAR(30),t2.local_net_address)
  FROM Server.DBADATA.DBO.DBA_ALL_SERVERS AS t1
  INNER JOIN Server.DBADATA.DBO.tbl_load_inventory_settings AS t2
  ON t1.Description = t2.server_name
--  WHERE t1.BatchNo = '110';


-- update server type

UPDATE t1
  SET t1.Is_VM = convert(VARCHAR(30),t2.Server_type)
  FROM Server.DBADATA.DBO.DBA_ALL_SERVERS AS t1
  INNER JOIN Server.DBADATA.DBO.tbl_load_inventory_settings AS t2
  ON t1.Description = t2.server_name
--  WHERE t1.BatchNo = '110';

-- update version number

UPDATE t1
  SET t1.Version = convert(VARCHAR(30),t2.SQL_Version)
  FROM Server.DBADATA.DBO.DBA_ALL_SERVERS AS t1
  INNER JOIN Server.DBADATA.DBO.tbl_load_inventory_settings AS t2
  ON t1.Description = t2.server_name
--  WHERE t1.BatchNo = '110';

*/