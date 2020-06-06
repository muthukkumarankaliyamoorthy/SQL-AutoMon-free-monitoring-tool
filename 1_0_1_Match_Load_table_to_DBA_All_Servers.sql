/*
select * from tbl_SQL_AutoMON
select * from DBA_All_servers

select A.* 	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description


*/

update D set D.Computer_Name=A.ComputerNamePhysicalNetBIOS	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.Instance=A.Instance	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.Login_mode=A.Login_mode	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.Edition=A.Edition	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.ProductBuild=A.ProductBuild	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.ProductBuildType=A.ProductBuildType	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.SP=A.ProductLevel	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.ProductMajorVersion=A.ProductMajorVersion	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.ProductMinorVersion=A.ProductMinorVersion	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.ProductUpdateLevel=A.ProductUpdateLevel	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.ProductUpdateReference=A.ProductUpdateReference	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.Version=A.Version	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description

update D set D.ResourceLastUpdateDateTime=A.ResourceLastUpdateDateTime	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.ResourceVersion=A.ResourceVersion	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.MachineName=A.MachineName	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.IsClustered=A.IsClustered	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.IsFullTextInstalled=A.IsFullTextInstalled	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.IsHadrEnabled=A.IsHadrEnabled	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.IsLocalDB=A.IsLocalDB	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.IsPolyBaseInstalled=A.IsPolyBaseInstalled	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.IsSingleUser=A.IsSingleUser	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.IsXTPSupported=A.IsXTPSupported	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.LCID=A.LCID	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.LicenseType=A.LicenseType	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description

update D set D.NumLicenses=A.NumLicenses	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.ProcessID=A.ProcessID	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.SqlCharSet=A.SqlCharSet	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.SqlCharSetName=A.SqlCharSetName	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.SqlSortOrder=A.SqlSortOrder	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.SqlSortOrderName=A.SqlSortOrderName	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.FilestreamShareName=A.FilestreamShareName	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.FilestreamConfiguredLevel=A.FilestreamConfiguredLevel	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.FilestreamEffectiveLevel=A.FilestreamEffectiveLevel	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.CollationID=A.CollationID	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.ComparisonStyle=A.ComparisonStyle	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.EditionID=A.EditionID	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.EngineEdition=A.EngineEdition	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.HadrManagerStatus=A.HadrManagerStatus	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.InstanceDefaultDataPath=A.InstanceDefaultDataPath	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.InstanceDefaultLogPath=A.InstanceDefaultLogPath	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.IsAdvancedAnalyticsInstalled=A.IsAdvancedAnalyticsInstalled	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.net_transport=A.net_transport	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.protocol_type=A.protocol_type	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.auth_scheme=A.auth_scheme	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.IP=A.IP	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description

update D set D.local_tcp_port=A.local_tcp_port	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.client_net_address=A.client_net_address	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.HA=A.HA	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.Domain=A.Domain	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.OS=A.OS	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.SQL_bit=A.server_type	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.OS_bit=A.No_of_logical_cpu	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.Is_VM=A.hyperthread_ratio	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.No_of_logical_cpu=A.No_of_physical_cpu	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.hyperthread_ratio=A.physical_memory_kb	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.No_of_physical_cpu=A.No_of_physical_cpu	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description
update D set D.physical_memory_kb=A.physical_memory_kb	from tbl_SQL_AutoMON A join DBA_All_servers D on A.ServerName=D.Description

-- Need manual update

/*
update D set D.Category=
update D set D.Location=
update D set D.Applications=
update D set D.Business_owner=
update D set D.Critical_service_level=
update D set D.Severity=
update D set D.MS_Patch=
update D set D.EOL=
update D set D.E_EOL=
update D set D.OS_EOL=
update D set D.Esxi_mapping=
update D set D.Esxi_hostName=
update D set D.Patch_compliance=
update D set D.is_win_A_path=
update D set D.Is_SQL_Auto_Path=
update D set D.Patch_Software=
update D set D.Is_server_backup=
update D set D.Is_DB_level_Backup=
update D set D.Is_monitoring=
update D set D.License_Detalis=
update D set D.CR_new_Build=
update D set D.CR_Decom_build=
update D set D.Install_date=
update D set D.comments_1=
update D set D.comments_2=
update D set D.Added_date=
update D set D.Maintenance_date=
*/

