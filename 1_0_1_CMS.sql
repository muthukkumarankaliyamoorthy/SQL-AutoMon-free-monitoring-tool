
select @@SERVERNAME as server,isnull(serverproperty ('InstanceName'),'Default')as Instance,
serverproperty ('Edition')as edition,serverproperty('ProductVersion') as SQL_Version,serverproperty('ProductVersion') as SQL_full_version,
serverproperty ('ProductLevel')as SP,
case when serverproperty ('IsIntegratedSecurityOnly')=0 then 'SQL' else 'Windows'end as login_mode,
'update HA' as [HA],case when serverproperty ('IsClustered')=0 then 'Stand alone' else 'Clustered'end as IsClustered ,
serverproperty ('Collation') as Collation,
serverproperty ('BuildClrVersion') as  BuildClrVersion,
'update Domain' as [Domain],'update OS' as [OS],

--serverproperty ('LicenseType') as LicenseType ,

--CONNECTIONPROPERTY('net_transport') AS net_transport,
--CONNECTIONPROPERTY('protocol_type') AS protocol_type,
--CONNECTIONPROPERTY('auth_scheme') AS auth_scheme,
CONNECTIONPROPERTY('local_net_address') AS IP,
--CONNECTIONPROPERTY('local_tcp_port') AS local_tcp_port,
--CONNECTIONPROPERTY('client_net_address') AS client_net_address,
--sysinfo.virtual_machine_type_desc,
server_type = case 
when sysinfo.virtual_machine_type =1 then 'Virtual' else 'Physical' end,
cpu_count as [No_of_logical_cpu],
hyperthread_ratio,
cpu_count/hyperthread_ratio as [No_of_physical_cpu],
physical_memory_kb,
'Prod' as Category,
'update location' as Location,
'update Applications' as Applications,
'update Business_owner' as Business_owner,
'update Critical_service_level' as Critical_service_level,
'update Severity' as Severity,
'Running' as server_status,
'Update Windows patch' as is_win_A_path,
'Update SQL patch' as Is_SQL_Auto_Path,
 'Update Backup details' as Is_backup,
 'Update Monitoring Details' as Is_monitoring,
 'Update License Detalis ' as License_Detalis,
'update comments_1' as comments_1,
'update comments_2' as comments_2,
getdate() as Added_date,
getdate() as Maintenance_date

from sys.dm_os_sys_info sysinfo



EXEC master.dbo.xp_regread 
'HKEY_LOCAL_MACHINE',
'Software\Microsoft\Windows NT\CurrentVersion',
'productname'
