-- Load sql hosts
drop table tbl_SQL_ESXI_Host_Details
go

create table tbl_SQL_ESXI_Host_Details
(
--ID int identity,
Server_name varchar (max), SQL_VM varchar (200),
Base_location varchar (200),Location varchar (max),	VM	varchar (max),
DNS_Name varchar (max),	IP varchar (max),
TYPE varchar (max),	Datacenter varchar (max),	
Cluster varchar (max),	 Host varchar (max),	VcenterName varchar (max),
svr_status varchar(20))



BULK INSERT tbl_SQL_ESXI_Host_Details  FROM 'D:\Source\Esxi_SQL_mapping.txt'WITH (FIELDTERMINATOR = '<>',ROWTERMINATOR = '\n')

select * from tbl_SQL_ESXI_Host_Details where SQL_vm like 'v%'
select * from tbl_SQL_ESXI_Host_Details where Location like 's%'
select Location from tbl_SQL_ESXI_Host_Details group by Location 

-- join table
select E.* from tbl_SQL_ESXI_Host_Details E join
DBA_ALL_SERVERS D on E.IP=D.IP
where D.SVR_status ='running'
order by Server_name


select * from tbl_SQL_ESXI_Host_Details E join
DBA_ALL_SERVERS D on E.Server_name=D.Description
where D.SVR_status ='running'


UPDATE DBA_ALL_SERVERS SET location = E.Location
FROM DBA_ALL_SERVERS D
  OUTER APPLY
   (
        SELECT TOP 1 *
        FROM tbl_SQL_ESXI_Host_Details E
        WHERE D.IP = E.IP 
    ) E

where d.SVR_status ='running'
and D.location not like '%dmz%'


SELECT 
*
FROM 
    DBA_ALL_SERVERS D
    OUTER APPLY
    (
        SELECT TOP 1 *
        FROM tbl_SQL_ESXI_Host_Details E
        WHERE D.IP = E.IP 
    ) E

where d.SVR_status ='running'
and D.location not like '%dmz%'








/*
drop table tbl_Windows_ESXI_Host_Details
create table tbl_Windows_ESXI_Host_Details
(

Location varchar (max),	VM	varchar (max),
DNS_Name varchar (max),	IP varchar (max),
TYPE varchar (max),	Datacenter varchar (max),	
Cluster varchar (max),	 Host varchar (max),	VcenterName varchar (max))



BULK INSERT tbl_Windows_ESXI_Host_Details  FROM 'D:\Source\ESXI_host.txt'WITH (FIELDTERMINATOR = '<<>>',ROWTERMINATOR = '\n')

select * from tbl_Windows_ESXI_Host_Details


select * from tbl_Windows_ESXI_Host_Details

select  al.Description,al.is_vm as SQL_VM,eh.* from DBA_All_servers AL left join tbl_Windows_ESXI_Host_Details EH
on (AL.ip=EH.ip)
where SVR_status ='running'and Is_VM like 'v%'
order by Description


select  al.Description,al.is_vm as SQL_VM,eh.*  from [server].DBADATA.DBO.DBA_All_servers AL left join tbl_Windows_ESXI_Host_Details EH
on (AL.ip=EH.ip)
where SVR_status ='running' and Is_VM like 'V%' order by Description

select is_vm FROM DBADATA.DBO.DBA_ALL_SERVERS where svr_status ='Running' group by is_vm

select count(*) FROM DBADATA.DBO.DBA_ALL_SERVERS where svr_status ='Running' and  is_vm like 'v%'
select count(*) FROM [server].DBADATA.DBO.DBA_ALL_SERVERS where svr_status ='Running' and  is_vm like 'v%'

*/