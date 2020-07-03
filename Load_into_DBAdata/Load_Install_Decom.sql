
-- drop table [tbl_server_Decommission_list]

create table [tbl_server_Decommission_list]
(
Application_name varchar(max),	Computer_Name  varchar(max),IP  varchar(max),Owner  varchar(max),
SQL_Servername  varchar(max),	Databases varchar(max), Type_of_Decom  varchar(max),
DB_Count  varchar(max),	Site  varchar(max),Edition	 varchar(max), Machine_Type	 varchar(max),
OS_Version	 varchar(max), SQL_Version  varchar(max),	Change_Request  varchar(max),	Date  datetime,	Comments  varchar(max))

BULK INSERT [tbl_server_Decommission_list]   FROM 'D:\Source\.txt'WITH (FIELDTERMINATOR = '<>',ROWTERMINATOR = '\n')
select * from [tbl_server_Decommission_list] where site like 'd%' and type_of_decom <>'Database' order by ip

select CR_New_build from DBADATA.DBO.DBA_ALL_SERVERS group by CR_New_build
update  DBADATA.DBO.DBA_ALL_SERVERS set CR_New_build ='Support Taken'
select CR_Decom_build from DBADATA.DBO.DBA_ALL_SERVERS group by CR_Decom_build
update  DBADATA.DBO.DBA_ALL_SERVERS set CR_Decom_build ='Support Taken'
update  DBADATA.DBO.DBA_ALL_SERVERS set CR_Decom_build ='Decom approved'where SVR_status='decom' and CR_Decom_build='Support Taken'

select D.* from [tbl_server_Decommission_list] D join DBADATA.DBO.DBA_ALL_SERVERS A on A.ip=D.ip where D.type_of_decom <>'Database' order by ip
select D.* from [tbl_server_Decommission_list] D join Server.DBADATA.DBO.DBA_ALL_SERVERS A on A.ip=D.ip where D.type_of_decom <>'Database' order by ip

update A set A.CR_Decom_build = D.change_request
from [tbl_server_Decommission_list] D join DBADATA.DBO.DBA_ALL_SERVERS A on A.ip=D.ip where D.type_of_decom <>'Database'

update A set A.CR_Decom_build = D.change_request
from [tbl_server_Decommission_list] D join Server.DBADATA.DBO.DBA_ALL_SERVERS A on A.ip=D.ip
where D.type_of_decom <>'Database'

select CR_New_build,CR_Decom_build,* from DBADATA.DBO.DBA_ALL_SERVERs where Description like '%server%'
update DBADATA.DBO.DBA_ALL_SERVERs set CR_Decom_build ='cr no' where Description like '%server%'
update Server.DBADATA.DBO.DBA_ALL_SERVERs set CR_Decom_build ='cr no' where Description like '%server%'
update DBADATA.DBO.DBA_ALL_SERVERs set CR_Decom_build ='cr no' where Description like '%server%'
 

select * from [tbl_server_Decommission_list] where Computer_Name like '%server%'
select * from [tbl_server_Decommission_list] where ip like '%ip%'
select * from tbl_server_Installation_list where Computer_Name like '%server%'
select * from [tbl_server_Decommission_list] where ip like '%ip%'
-- ============= install
-- server install date can be found t-sql
SELECT create_date FROM sys.server_principals WHERE sid = 0x010100000000000512000000

--drop table tbl_server_Installation_list


create table tbl_server_Installation_list
(
Application_name varchar(max),	Computer_Name  varchar(max),IP  varchar(max),Owner  varchar(max),
SQL_Servername  varchar(max),	Databases varchar(max), 
DB_Count  varchar(max),	Site  varchar(max),Edition	 varchar(max), Machine_Type	 varchar(max),
OS_Version	 varchar(max), SQL_Version  varchar(max),	Change_Request  varchar(max),	Date  datetime,	Comments  varchar(max),
Category varchar(max),Location varchar(max),	Domain varchar(max))

BULK INSERT tbl_server_Installation_list   FROM 'D:\Source\Install_list_inflight.txt'WITH (FIELDTERMINATOR = '<>',ROWTERMINATOR = '\n')

select * from tbl_server_Installation_list where site like 'd%' order by ip

select D.change_request,D.* from tbl_server_Installation_list D join DBADATA.DBO.DBA_ALL_SERVERS A on A.ip=D.ip  order by ip
select D.change_request,D.* from tbl_server_Installation_list D join Server.DBADATA.DBO.DBA_ALL_SERVERS A on A.ip=D.ip  order by ip

update A set A.CR_new_build = D.change_request
from tbl_server_Installation_list D join DBADATA.DBO.DBA_ALL_SERVERS A on A.ip=D.ip 

update A set A.CR_new_build = D.change_request
from tbl_server_Installation_list D join Server.DBADATA.DBO.DBA_ALL_SERVERS A on A.ip=D.ip


select * from tbl_server_install_date order by install_date desc
