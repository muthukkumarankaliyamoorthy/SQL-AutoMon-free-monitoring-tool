
/*
Easy way to get table created is, use insert into table name --into tbl_A_temp
Get script outed and change not null to null
insert that into tbl_SQL_AutoMON
--
*/

--insert into [tbl_A_temp]
--insert into [tbl_SQL_AutoMON]

select @@SERVERNAME as servername,
convert (varchar(max), SERVERPROPERTY('ComputerNamePhysicalNetBIOS')) AS [ComputerNamePhysicalNetBIOS],
convert (varchar(max), isnull(serverproperty ('InstanceName'),'Default'))as Instance, 
case when convert (varchar(max), serverproperty ('IsIntegratedSecurityOnly'))=0 then 'SQL' else 'Windows'end as Login_mode,
convert (varchar(max),SERVERPROPERTY('Edition')) AS [Edition], 
convert (varchar(max),SERVERPROPERTY('ProductBuild')) AS [ProductBuild], 
convert (varchar(max),SERVERPROPERTY('ProductBuildType')) AS [ProductBuildType], 
convert (varchar(max),SERVERPROPERTY('ProductLevel')) AS [ProductLevel], 
--convert (varchar(max),SERVERPROPERTY('ProductMajorVersion')) AS [ProductMajorVersion], 
--convert (varchar(max),SERVERPROPERTY('ProductMinorVersion')) AS [ProductMinorVersion], 
convert (varchar(max),SERVERPROPERTY('ProductUpdateLevel')) AS [ProductUpdateLevel], 
convert (varchar(max),SERVERPROPERTY('ProductUpdateReference')) AS [ProductUpdateReference], 
--convert (varchar(max),SERVERPROPERTY('ProductVersion')) AS [ProductVersion], 
convert (varchar(max),SERVERPROPERTY('ProductVersion')) AS [Version], 
convert (varchar(max),SERVERPROPERTY('ResourceLastUpdateDateTime')) AS [ResourceLastUpdateDateTime], 
convert (varchar(max),SERVERPROPERTY('ResourceVersion')) AS [ResourceVersion], 

convert (varchar(max),SERVERPROPERTY('MachineName')) AS [MachineName], 
case when convert (varchar(max), serverproperty ('IsClustered'))=0 then 'Stand alone' else 'Clustered'end as IsClustered ,
convert (varchar(max),SERVERPROPERTY('IsFullTextInstalled')) AS [IsFullTextInstalled], 
convert (varchar(max),SERVERPROPERTY('IsHadrEnabled')) AS [IsHadrEnabled], 


convert (varchar(max),SERVERPROPERTY('IsLocalDB')) AS [IsLocalDB], 
convert (varchar(max),SERVERPROPERTY('IsPolyBaseInstalled')) AS [IsPolyBaseInstalled], 
convert (varchar(max),SERVERPROPERTY('IsSingleUser')) AS [IsSingleUser], 
convert (varchar(max),SERVERPROPERTY('IsXTPSupported')) AS [IsXTPSupported], 
convert (varchar(max),SERVERPROPERTY('LCID')) AS [LCID], 
convert (varchar(max),SERVERPROPERTY('LicenseType')) AS [LicenseType], 

convert (varchar(max),SERVERPROPERTY('NumLicenses')) AS [NumLicenses], 
convert (varchar(max),SERVERPROPERTY('ProcessID')) AS [ProcessID], 
convert (varchar(max),SERVERPROPERTY('SqlCharSet')) AS [SqlCharSet], 
convert (varchar(max),SERVERPROPERTY('SqlCharSetName')) AS [SqlCharSetName], 
convert (varchar(max),SERVERPROPERTY('SqlSortOrder')) AS [SqlSortOrder], 
convert (varchar(max),SERVERPROPERTY('SqlSortOrderName')) AS [SqlSortOrderName], 
convert (varchar(max),SERVERPROPERTY('FilestreamShareName')) AS [FilestreamShareName], 
convert (varchar(max),SERVERPROPERTY('FilestreamConfiguredLevel')) AS [FilestreamConfiguredLevel], 
convert (varchar(max),SERVERPROPERTY('FilestreamEffectiveLevel')) AS [FilestreamEffectiveLevel],
convert (varchar(max),SERVERPROPERTY('CollationID')) AS [CollationID], 
convert (varchar(max),SERVERPROPERTY('ComparisonStyle')) AS [ComparisonStyle],
convert (varchar(max),SERVERPROPERTY('EditionID')) AS [EditionID], 
convert (varchar(max),SERVERPROPERTY('EngineEdition')) AS [EngineEdition], 
convert (varchar(max),SERVERPROPERTY('HadrManagerStatus')) AS [HadrManagerStatus], 
convert (varchar(max),SERVERPROPERTY('InstanceDefaultDataPath')) AS [InstanceDefaultDataPath], 
convert (varchar(max),SERVERPROPERTY('InstanceDefaultLogPath')) AS [InstanceDefaultLogPath],
convert (varchar(max),SERVERPROPERTY('IsAdvancedAnalyticsInstalled')) AS [IsAdvancedAnalyticsInstalled],
convert (varchar(max),CONNECTIONPROPERTY('net_transport')) AS net_transport,
convert (varchar(max),CONNECTIONPROPERTY('protocol_type')) AS protocol_type,
convert (varchar(max),CONNECTIONPROPERTY('auth_scheme')) AS auth_scheme,
convert (varchar(max),CONNECTIONPROPERTY('local_net_address')) AS IP,
convert (varchar(max),CONNECTIONPROPERTY('local_tcp_port')) AS local_tcp_port,
convert (varchar(max),CONNECTIONPROPERTY('client_net_address')) AS client_net_address,
--sysinfo.virtual_machine_type_desc,
'update HA' as [HA],
DEFAULT_DOMAIN() as [Domain],'update OS' as [OS],
server_type = case 
when sysinfo.virtual_machine_type =1 then 'Virtual' else 'Physical' end,
'Update cloud' as[is_cloud],
cpu_count as [No_of_logical_cpu],
hyperthread_ratio,
cpu_count/hyperthread_ratio as [No_of_physical_cpu],
physical_memory_kb,
'update Category - prod/dev' as Category,
'update location' as Location,
'update Applications' as Applications,
'update Business_owner' as Business_owner,
'update Critical_service_level' as Critical_service_level,
'update Severity' as Severity,
'Running' as server_status,
'Update Windows patch' as is_win_A_patch,
'Update SQL patch' as Is_SQL_Auto_Patch,
'Update Backup details' as Is_backup,
'Update Monitoring Details' as Is_monitoring,
'Update License Detalis ' as License_Detalis,
'Update comments_1' as comments_1,
'Update comments_2' as comments_2,
getdate() as Added_date,
getdate() as Maintenance_date --into tbl_A_temp

from sys.dm_os_sys_info sysinfo



EXEC master.dbo.xp_regread  'HKEY_LOCAL_MACHINE','Software\Microsoft\Windows NT\CurrentVersion','productname'



exec master..sp_configure 'show advanced options', 1
RECONFIGURE; 
exec master..sp_configure 'Ole Automation Procedures'
