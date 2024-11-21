USE [DBAUtil]
GO

/****** Object:  StoredProcedure [dbo].[USP_Rep_agent_Histroy_Daily]    Script Date: 2/2/2024 4:16:34 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*

USE [DBAUtil]
GO
USP_Rep_agent_Histroy_Daily
select * from DBAUtil.dbo.tbl_Repl_MON_Daily where [time] > getdate ()-1 order by time desc


USE [DBAUtil]
GO
drop table [tbl_Repl_MON_Daily]
go
CREATE TABLE [dbo].[tbl_Repl_MON_Daily](
	[publication] [sysname] NOT NULL,
	[subscriber_db] [sysname] NULL,
	[start_time] [datetime] NOT NULL,
	[time] [datetime] NOT NULL,
	[duration] [int] NOT NULL,
	[comments] [nvarchar](max) NOT NULL,
	--[xact_seqno] [varbinary](16) NULL,
	[delivered_transactions] [int] NOT NULL,
	[delivered_commands] [int] NOT NULL,
	[delivery_latency] [int] NOT NULL,
	[Catagory] sysname
) 


USE [DBAUtil]
GO
drop table [tbl_replication_monitor_data]
go
CREATE TABLE [dbo].[tbl_replication_monitor_data](
	[publication] [sysname] NOT NULL,
	[subscriber_db] [sysname] NULL,
	[start_time] [datetime] NOT NULL,
	[time] [datetime] NOT NULL,
	[duration] [int] NOT NULL,
	[comments] [nvarchar](max) NOT NULL,
	--[xact_seqno] [varbinary](16) NULL,
	[delivered_transactions] [int] NOT NULL,
	[delivered_commands] [int] NOT NULL,
	[delivery_latency] [int] NOT NULL,
	[Catagory] sysname
) 

go
drop table [tbl_MSsnapshot_history]
go

CREATE TABLE [dbo].[tbl_MSsnapshot_history](
	[publication] [sysname] NOT NULL,
	[subscriber_db] [sysname] NULL,
	--[agent_id] [int] NOT NULL,
	--[runstatus] [int] NOT NULL,
	[start_time] [datetime] NOT NULL,
	[time] [datetime] NOT NULL,
	[duration] [int] NOT NULL,
	[comments] [nvarchar](1000) NOT NULL,
	[delivered_transactions] [int] NOT NULL,
	[delivered_commands] [int] NOT NULL,
	--[delivery_rate] [float] NOT NULL,
	--[error_id] [int] NOT NULL,
	--[timestamp] [timestamp] NOT NULL
	[delivery_latency] [int] NOT NULL,
	[Catagory] sysname
)

go
drop table [tbl_MSlogreader_history]
go


CREATE TABLE [dbo].[tbl_MSlogreader_history](
	[publication] [sysname] NOT NULL,
	[subscriber_db] [sysname] NULL,
	--[agent_id] [int] NOT NULL,
	--[runstatus] [int] NOT NULL,
	[start_time] [datetime] NOT NULL,
	[time] [datetime] NOT NULL,
	[duration] [int] NOT NULL,
	[comments] [nvarchar](4000) NOT NULL,
	--[xact_seqno] [varbinary](16) NULL,
	--[delivery_time] [int] NOT NULL,
	[delivered_transactions] [int] NOT NULL,
	[delivered_commands] [int] NOT NULL,
	--[average_commands] [int] NOT NULL,
	--[delivery_rate] [float] NOT NULL,
	[delivery_latency] [int] NOT NULL,
	--[error_id] [int] NOT NULL,
	--[timestamp] [timestamp] NOT NULL,
	--[updateable_row] [bit] NOT NULL,
	[Catagory] sysname
)

go
drop table [tbl_MSdistribution_history]
go


CREATE TABLE [dbo].[tbl_MSdistribution_history](
	[publication] [sysname] NOT NULL,
	[subscriber_db] [sysname] NULL,
	--[agent_id] [int] NOT NULL,
	--[runstatus] [int] NOT NULL,
	[start_time] [datetime] NOT NULL,
	[time] [datetime] NOT NULL,
	[duration] [int] NOT NULL,
	[comments] [nvarchar](max) NOT NULL,
	--[xact_seqno] [varbinary](16) NULL,
	--[current_delivery_rate] [float] NOT NULL,
	--[current_delivery_latency] [int] NOT NULL,
	[delivered_transactions] [int] NOT NULL,
	[delivered_commands] [int] NOT NULL,
	--[average_commands] [int] NOT NULL,
	--[delivery_rate] [float] NOT NULL,
	[delivery_latency] [int] NOT NULL,
	--[total_delivered_commands] [bigint] NOT NULL,
	--[error_id] [int] NOT NULL,
	--[updateable_row] [bit] NOT NULL,
	--[timestamp] [timestamp] NOT NULL,
	[Catagory] sysname
)


*/

CREATE proc [dbo].[USP_Rep_agent_Histroy_Daily]
as

set nocount on

begin

--Transaction Replication Last Status: This one is my favorite, no clicking through replication monitor.
truncate table DBAUtil.dbo.tbl_Repl_MON_Daily

truncate table DBAUtil.dbo.tbl_replication_monitor_data

insert into DBAUtil.dbo.tbl_replication_monitor_data

SELECT
agt.publication
,agt.subscriber_db
,DH.start_time
,DH.time
,DH.duration
,DH.comments
--,DH.xact_seqno
,DH.delivered_transactions
,DH.delivered_commands
,0
,'All_Repl_Monitor'
--into DBAUtil.dbo.tbl_replication_monitor_data
FROM

distribution.dbo.msdistribution_agents agt
INNER JOIN distribution.[dbo].[MSdistribution_history] DH
ON DH.agent_id = agt.id
INNER JOIN (SELECT agent_id, max(time) htime FROM distribution.[dbo].[MSdistribution_history] GROUP BY agent_id) dhm ON dh.agent_id = dhm.agent_id AND dh.time = dhm.htime

WHERE 
subscriber_db <> 'virtual'
--AND comments NOT LIKE 
and start_time >getdate() -1
ORDER BY time DESC



truncate table DBAUtil.dbo.tbl_MSsnapshot_history
insert into DBAUtil.dbo.tbl_MSsnapshot_history

SELECT 
publication,
'N/A',
start_time,
time,
duration,
comments,
delivered_transactions,
delivered_commands,
0,
'Snapshot_history'

FROM distribution.dbo.MSsnapshot_history SH join distribution..MSsnapshot_agents SA on SH.agent_id =SA.ID
WHERE comments NOT LIKE '<stats%'
and time >getdate()-1
ORDER BY Time desc

/*
--where comments like '%Snapshot of%' order by start_time desc

--select *  from dbo.MSsnapshot_history H join MSsnapshot_agents A on h.agent_id =A.ID order by start_time desc

drop table TBL_DBA_MSsnapshot_history

USE [DBAUtil]
GO

CREATE TABLE [dbo].[TBL_DBA_MSsnapshot_history](
	[publication] [sysname] NOT NULL,
	[agent_id] [int] NOT NULL,
	[runstatus] [int] NOT NULL,
	[start_time] [datetime] NOT NULL,
	[time] [datetime] NOT NULL,
	[duration] [int] NOT NULL,
	[comments] [nvarchar](1000) NOT NULL,
	[delivered_transactions] [int] NOT NULL,
	[delivered_commands] [int] NOT NULL,
	[delivery_rate] [float] NOT NULL,
	[error_id] [int] NOT NULL,
	[timestamp] varchar(500) NOT NULL
)

--load data
insert into DBAUtil.DBO.TBL_DBA_MSsnapshot_history
select A.publication,H.* from distribution.dbo.MSsnapshot_history H join distribution..MSsnapshot_agents A on h.agent_id =A.ID order by start_time desc


-- delete unwanted data
delete from DBAUtil.DBO.TBL_DBA_MSsnapshot_history where comments like '%Updating statistics on index%'

--
select * from DBAUtil.DBO.TBL_DBA_MSsnapshot_history where start_time >getdate()-5

--make alert based on what do you need
*/

--2--MSlogreader_history

truncate table DBAUtil.dbo.tbl_MSlogreader_history
insert into DBAUtil.dbo.tbl_MSlogreader_history

SELECT 
publication
,'N/A'
,start_time
,time
,duration
,comments
,delivered_transactions
,delivered_commands
,delivery_latency
,'Logreader_history'

FROM distribution.dbo.MSlogreader_history LH join distribution..MSlogreader_agents LA on LH.agent_id =LA.ID
WHERE comments NOT LIKE '<stats%'
and comments NOT LIKE 'Approximately%'
--Approximately 10000000 log records have been scanned in pass # 4, 0 of which were marked for replication.
and time >getdate()-1
ORDER BY Time desc

--3--MSdistribution_history

truncate table DBAUtil.dbo.tbl_MSdistribution_history
insert into DBAUtil.dbo.tbl_MSdistribution_history


SELECT 
publication
,subscriber_db
,start_time
,time
,duration
,comments
,delivered_transactions
,delivered_commands
,delivery_latency
,'Distribution_history'

FROM distribution.dbo.MSdistribution_history DH join distribution..MSdistribution_agents DA on DH.agent_id =DA.ID
where DA.subscriber_db <>'virtual'
and comments NOT LIKE '<stats%'
and time >getdate()-1
ORDER BY Time desc

-- Final Load
insert into DBAUtil.dbo.tbl_Repl_MON_Daily select * from tbl_replication_monitor_data
insert into DBAUtil.dbo.tbl_Repl_MON_Daily select * from tbl_MSsnapshot_history
insert into DBAUtil.dbo.tbl_Repl_MON_Daily select * from tbl_MSlogreader_history
insert into DBAUtil.dbo.tbl_Repl_MON_Daily select * from tbl_MSdistribution_history

select * from DBAUtil.dbo.tbl_Repl_MON_Daily where [time] > getdate ()-1

End
GO


