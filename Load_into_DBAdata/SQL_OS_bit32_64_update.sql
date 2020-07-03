
alter table DBA_ALL_SERVERS add OS_bit varchar (20)
alter table DBA_ALL_SERVERS add SQL_bit varchar (20)


select Platform,* from tbl_Server_perporty_ServiceAccounts
select OS_bit,SQL_bit, * from DBA_ALL_SERVERS where SVR_status ='running' and os_bit is null
select OS_bit,SQL_bit, * from DBA_ALL_SERVERS where SVR_status ='running' and os_bit not in ('NT x64','NT AMD64')

select OS_bit,SQL_bit, * from DBA_ALL_SERVERS where SVR_status ='running' and sql_bit is null

select * from tbl_Server_perporty_ServiceAccounts PS 
join DBA_ALL_SERVERS D on PS.server_name =D.Description
where D.SVR_status ='running'

update D set D.OS_bit = PS.Platform
from tbl_Server_perporty_ServiceAccounts PS 
join DBA_ALL_SERVERS D on PS.server_name =D.Description
where D.SVR_status ='running'

select SQL_bit,Edition, * from DBA_ALL_SERVERS where SVR_status ='running' and Edition like '%64%'
update DBA_ALL_SERVERS set SQL_bit ='64-bit' where SVR_status ='running' and Edition like '%64%'


select SQL_bit,Edition, * from DBA_ALL_SERVERS where SVR_status ='running' and Edition not like '%64%'
update DBA_ALL_SERVERS set SQL_bit ='32-bit' where SVR_status ='running' and Edition not like '%64%'

update DBA_ALL_SERVERS set os_bit ='NT INTEL X86' where SVR_status ='running' and servername like '10.10.10.108\ADK,1433'
update DBA_ALL_SERVERS set os_bit ='NT x64' where SVR_status ='running' and os_bit is null


