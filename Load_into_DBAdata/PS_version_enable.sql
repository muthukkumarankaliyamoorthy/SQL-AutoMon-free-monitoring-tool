
drop table tbl_PS_version_enable

create table tbl_PS_version_enable
(server_name varchar (200), version_no varchar(100),PS_Remoting varchar(100), site_name varchar (20))

BULK INSERT tbl_PS_version_enable  FROM 'D:\Source\PS_version_RS.txt'WITH (FIELDTERMINATOR = '<>',ROWTERMINATOR = '\n')

select * from tbl_PS_version_enable

--alter table tbl_PS_version_enable add PS_Remoting varchar(100)
--alter table tbl_PS_version_enable add OS_bit varchar(100)

select D.computer_name,D.version,D.OS_version,ps.version_no,Ps.PS_Remoting,count (d.Description) [count]
from tbl_PS_version_enable PS right join DBADATA.DBO.DBA_ALL_SERVERS D
on PS.server_name =D.computer_name where d.SVR_status ='running'
group by D.computer_name,D.version,D.OS_version,ps.version_no,Ps.PS_Remoting
order by computer_name


-- 
select D.computer_name,D.version,D.OS_version,ps.version_no,Ps.PS_Remoting
from tbl_PS_version_enable PS right join DBADATA.DBO.DBA_ALL_SERVERS D
on PS.server_name =D.computer_name where d.SVR_status ='running'
and PS.site_name like 'b%'
and version_no <3
and D.Version >='SQL2012' 

