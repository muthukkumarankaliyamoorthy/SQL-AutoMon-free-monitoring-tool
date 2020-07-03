

create table tbl_xp_cmdshell (

Server_Name varchar (200),name	varchar (200), minimum int,	maximum	int, config_value int,	run_value int
)

BULK INSERT tbl_xp_cmdshell  FROM 'D:\SQLDBA\Temp\CMDShell_Enabled.txt'WITH (FIELDTERMINATOR = '<>',ROWTERMINATOR = '\n')


select * from tbl_xp_cmdshell where run_value =1

drop table tbl_Server_perporty_ServiceAccounts
go
CREATE TABLE tbl_Server_perporty_ServiceAccounts(
	server_name varchar(200),
    [Domain] [nvarchar](64) NULL,
    [SQLServerName] [varchar](64) NULL,
    [InstanceName] [nvarchar](128) NULL,
    [ComputerNamePhysicalNetBIOS] [nvarchar](128) NULL,
    [IsClustered] [varchar](13) NULL,
    [ClusterNodes] [nvarchar](32) NULL,
    [ActiveNode] [nvarchar](128) NULL,
    [HostIPAddress] [nvarchar](16) NULL,
    [PortNumber] [varchar](80) NULL,
    [IsIntegratedSecurityOnly] [varchar](64) NULL,
    [AuditLevel] [varchar](38) NOT NULL,
    [ProductVersion] [varchar](100) NULL,
    [ProductLevel] [varchar](100) NULL,
    [ResourceVersion] [varchar](100) NULL,
    [ResourceLastUpdateDateTime] [varchar](100) NOT NULL,
    [EngineEdition] [varchar](64) NULL,
    [BuildClrVersion] [varchar](100) NOT NULL,
    [Collation] [varchar](100) NULL,
    [CollationID] [varchar](100) NULL,
    [ComparisonStyle] [varchar](100) NULL,
    [IsFullTextInstalled] [varchar](26) NULL,
    [SQLCharset] [varchar](100) NOT NULL,
    [SQLCharsetName] [varchar](100) NOT NULL,
    [SQLSortOrderID] [varchar](100) NOT NULL,
    [SQLSortOrderName] [varchar](100) NOT NULL,
    [Platform] [varchar](128) NULL,
    [FileDescription] [varchar](128) NULL,
    [WindowsVersion] [varchar](128) NULL,
    [ProcessorCount] [float] NULL,
    [ProcessorType] [varchar](128) NULL,
    [PhysicalMemory] [float] NULL,
    [ServerPageFile] [varchar](124) NULL,
    [SQLInstallationLocation] [nvarchar](512) NULL,
    [BinariesPath] [nvarchar](128) NULL,
    [ErrorLogsLocation] [nvarchar](128) NULL,
    [MSSQLServerServiceStartupUser] [varchar](64) NULL,
    [MSSQLAgentServiceStartupUser] [varchar](64) NULL,
    [MSSQLServerServiceStartupType] [char](12) NULL,
    [MSSQLAgentServiceStartupType] [char](12) NULL,
    [InstanceLastStartDate] [datetime] NULL,
    loaddate [datetime])


truncate table tbl_Server_perporty_ServiceAccounts

BULK INSERT tbl_Server_perporty_ServiceAccounts  FROM 'D:\SQLDBA\Temp\Server_Perporty_service_accounts.txt'WITH (FIELDTERMINATOR = '<>',ROWTERMINATOR = '\n')

select * from tbl_Server_perporty_ServiceAccounts where [MSSQLAgentServiceStartupType] like 'Automatic%'

