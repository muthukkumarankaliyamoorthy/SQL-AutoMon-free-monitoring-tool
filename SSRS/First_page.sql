
use DBA_Report_Code
go

--drop proc [usp_RS_dba_PingServers]

-- Exec [usp_RS_dba_PingServers]

alter proc [usp_RS_dba_PingServers]
as 
select Server [Server Name], status [Status] from DBAdata.[dbo].[dba_PingServers]
order by uptime