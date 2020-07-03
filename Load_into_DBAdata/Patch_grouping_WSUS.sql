
create table tbl_Patch_OS_EOL ()

--Site1

select * from tbl_Patch_OS_EOL
select wsus_patch,count(*) from DBADATA.DBO.tbl_Patch_OS_EOL group by wsus_patch
select CAU,count(*) from DBADATA.DBO.tbl_Patch_OS_EOL group by CAU

select Category, count(*) from DBADATA.DBO.DBA_ALL_SERVERS d  where D.Svr_status ='running' group by Category
select domain, count(*) from DBADATA.DBO.DBA_ALL_SERVERS d where D.Svr_status ='running' group by domain


select Server_Name,D.IP,Schedule_time as W_Schedule_time,WSUS_GPO_Schedule,WSUS_Patch,cau,HA,Category,D.Svr_status,D.OS_version,OS_EOL,domain,version,SP_E_EOL,'Site1' Site
from DBADATA.DBO.tbl_Patch_OS_EOL OE join DBADATA.DBO.DBA_ALL_SERVERS D on (OE.Server_name =D.Description)
where D.Svr_status ='running'
--and Category in ('Development','Test','UAT') and domain not in ('domain','domain') -- 23
--and Category in ('Production') and domain not in ('domain','domain')
--and domain  in ('domain') -- 4 -- 3 prod & 1 test
--and domain  in ('domain') -- 3 tesco -- 2 test & 1 prod

-- Site2
select wsus_patch,count(*) from Server..DBADATA.DBO.tbl_Patch_OS_EOL group by wsus_patch
select CAU,count(*) from Server..DBADATA.DBO.tbl_Patch_OS_EOL group by CAU

select * from Server..DBADATA.DBO.tbl_Patch_OS_EOL where wsus_patch ='not added' 

select Server_Name,D.IP,Schedule_time as W_Schedule_time,WSUS_GPO_Schedule,WSUS_Patch,cau,HA,Category,D.Svr_status,D.OS_version,OS_EOL,domain,version,SP_E_EOL,'Site2' Site
from Server..DBADATA.DBO.tbl_Patch_OS_EOL OE join Server..DBADATA.DBO.DBA_ALL_SERVERS D on (OE.Server_name =D.Description)
where D.Svr_status ='running'

/* 
--update WSUS grouping except non HA servers



--update WSUS grouping except non HA servers

select HA, count(*) from DBADATA.DBO.DBA_ALL_SERVERS d  where D.Svr_status ='running' group by HA

-- update site dmz prod
select Server_Name,D.IP,Schedule_time as W_Schedule_time,WSUS_GPO_Schedule,WSUS_Patch,cau,HA,Category,D.Svr_status,D.OS_version,OS_EOL,domain,version,SP_E_EOL
from DBADATA.DBO.tbl_Patch_OS_EOL OE join DBADATA.DBO.DBA_ALL_SERVERS D on (OE.Server_name =D.Description)
where D.Svr_status ='running' and d.HA in ('no ha', 'replication')
and Category in ('Production') and domain in ('domain')
--and domain  in ('domain') -- 4 -- 3 prod & 1 test
--and domain  in ('domain') -- 3 tesco -- 2 test & 1 prod

-- update site dmz prod
update OE
set oe.WSUS_Patch ='Tier 9 - DMZ - SQL Prod Group'
from DBADATA.DBO.tbl_Patch_OS_EOL OE join DBADATA.DBO.DBA_ALL_SERVERS D on (OE.Server_name =D.Description)
where D.Svr_status ='running' and d.HA in ('no ha', 'replication')
and Category in ('Production') and domain in ('domain')
--and domain  in ('domain') -- 4 -- 3 prod & 1 test
--and domain  in ('domain') -- 3 tesco -- 2 test & 1 prod

-- update site dmz non prod

select Server_Name,D.IP,Schedule_time as W_Schedule_time,WSUS_GPO_Schedule,WSUS_Patch,cau,HA,Category,D.Svr_status,D.OS_version,OS_EOL,domain,version,SP_E_EOL
from DBADATA.DBO.tbl_Patch_OS_EOL OE join DBADATA.DBO.DBA_ALL_SERVERS D on (OE.Server_name =D.Description)
where D.Svr_status ='running' and d.HA in ('no ha', 'replication')
and Category not in ('Production') and domain in ('domain')
--and domain  in ('domain') -- 4 -- 3 prod & 1 test
--and domain  in ('domain') -- 3 tesco -- 2 test & 1 prod

update OE
set oe.WSUS_Patch ='Tier 8 - DMZ - SQL UAT Group'
from DBADATA.DBO.tbl_Patch_OS_EOL OE join DBADATA.DBO.DBA_ALL_SERVERS D on (OE.Server_name =D.Description)
where D.Svr_status ='running' and d.HA in ('no ha', 'replication')
and Category not in ('Production') and domain in ('domain')
--and domain  in ('domain') -- 4 -- 3 prod & 1 test
--and domain  in ('domain') -- 3 tesco -- 2 test & 1 prod


/*non DMZ*/


-- update site non dmz prod
select Server_Name,D.IP,Schedule_time as W_Schedule_time,WSUS_GPO_Schedule,WSUS_Patch,cau,HA,Category,D.Svr_status,D.OS_version,OS_EOL,domain,version,SP_E_EOL
from DBADATA.DBO.tbl_Patch_OS_EOL OE join DBADATA.DBO.DBA_ALL_SERVERS D on (OE.Server_name =D.Description)
where D.Svr_status ='running' and d.HA in ('no ha', 'replication')
and Category in ('Production') and domain not in ('domain','domain')
--and domain  in ('domain') -- 4 -- 3 prod & 1 test
--and domain  in ('domain') -- 3 tesco -- 2 test & 1 prod

-- update site non dmz prod
update OE
set oe.WSUS_Patch ='Tier 7 - SQL - Production Group'
from DBADATA.DBO.tbl_Patch_OS_EOL OE join DBADATA.DBO.DBA_ALL_SERVERS D on (OE.Server_name =D.Description)
where D.Svr_status ='running' and d.HA in ('no ha', 'replication')
and Category in ('Production') and domain not in ('domain','domain')
--and domain  in ('domain') -- 4 -- 3 prod & 1 test
--and domain  in ('domain') -- 3 tesco -- 2 test & 1 prod

-- update site non dmz non prod

select Server_Name,D.IP,Schedule_time as W_Schedule_time,WSUS_GPO_Schedule,WSUS_Patch,cau,HA,Category,D.Svr_status,D.OS_version,OS_EOL,domain,version,SP_E_EOL
from DBADATA.DBO.tbl_Patch_OS_EOL OE join DBADATA.DBO.DBA_ALL_SERVERS D on (OE.Server_name =D.Description)
where D.Svr_status ='running' and d.HA in ('no ha', 'replication')
and Category not in ('Production') and domain not in ('domain','domain')
--and domain  in ('domain') -- 4 -- 3 prod & 1 test
--and domain  in ('domain') -- 3 tesco -- 2 test & 1 prod

update OE
set oe.WSUS_Patch ='Tier 6 - SQL - UAT Group'
from DBADATA.DBO.tbl_Patch_OS_EOL OE join DBADATA.DBO.DBA_ALL_SERVERS D on (OE.Server_name =D.Description)
where D.Svr_status ='running' and d.HA in ('no ha', 'replication')
and Category not in ('Production') and domain not in ('domain','domain')
--and domain  in ('domain') -- 4 -- 3 prod & 1 test
--and domain  in ('domain') -- 3 tesco -- 2 test & 1 prod


-- site3

select Server_Name,D.IP,Schedule_time as W_Schedule_time,WSUS_GPO_Schedule,WSUS_Patch,cau,HA,Category,D.Svr_status,D.OS_version,OS_EOL,domain,version,SP_E_EOL
from DBADATA.DBO.tbl_Patch_OS_EOL OE join DBADATA.DBO.DBA_ALL_SERVERS D on (OE.Server_name =D.Description)
where D.Svr_status ='running' and d.HA in ('no ha', 'replication')
and domain  in ('domain') -- 3 tesco -- 2 test & 1 prod

update OE
set oe.WSUS_Patch =''
from DBADATA.DBO.tbl_Patch_OS_EOL OE join DBADATA.DBO.DBA_ALL_SERVERS D on (OE.Server_name =D.Description)
where D.Svr_status ='running' and d.HA in ('no ha', 'replication')
and domain  in ('domain') -- 3 tesco -- 2 test & 1 prod


update OE
set wsus_patch ='OS Cluster'
from DBADATA.DBO.tbl_Patch_OS_EOL OE join DBADATA.DBO.DBA_ALL_SERVERS D on (OE.Server_name =D.Description)
where D.Svr_status ='running'
and WSUS_Patch is null
--and Category in ('Development','Test','UAT') and domain not in ('domain','domain') -- 23
--and Category in ('Production') and domain not in ('domain','domain')
--and domain  in ('domain') -- 4 -- 3 prod & 1 test
and domain  not in ('domain') -- 3 tesco -- 2 test & 1 prod

-- Site2
update Server..DBADATA.DBO.tbl_Patch_OS_EOL  set wsus_patch ='OS Cluster' where cau ='No-Wrokgroup'

*/

