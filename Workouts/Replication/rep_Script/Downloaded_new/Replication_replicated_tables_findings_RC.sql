--SELECT * FROM sys.tables WHERE is_replicated = 1

/*
HDXDB_Replica
HDXDB-BI
HDXDB-DR
HOMESQL01_Local
*/

use hdxdb;
select  
db_name() PublisherDB 
, sp.name as PublisherName 
, sa.name as TableName 
, UPPER(srv.srvname) as SubscriberServerName 
from dbo.syspublications sp  
join dbo.sysarticles sa on sp.pubid = sa.pubid 
join dbo.syssubscriptions s on sa.artid = s.artid 
join master.dbo.sysservers srv on s.srvid = srv.srvid 
where sp.name ='HDXDB-DR' 



-- count of tables for publication
/*
USE [DBAUtil]
GO

drop table [Tbl_Repl_Rowcount]
go
CREATE TABLE [dbo].[Tbl_Repl_Rowcount](
	[PublisherName] [varchar](200) NOT NULL,
	[Table_name] [varchar](400) NOT NULL
	,[Row_Count] [int] NULL
) 

*/

use hdxdb;
select  
db_name() PublisherDB 
, sp.name as PublisherName 
, sa.name as TableName 
, 'insert into DBAUtil.dbo.[Tbl_Repl_Rowcount] select '''+sp.name+''' as [PublisherName],'''+sa.name+''' as [Table_name], count(*) as [Row_Count] from ['+sa.name+'] with (nolock)' as count_cmd
, UPPER(srv.srvname) as SubscriberServerName 
from dbo.syspublications sp  
join dbo.sysarticles sa on sp.pubid = sa.pubid 
join dbo.syssubscriptions s on sa.artid = s.artid 
join master.dbo.sysservers srv on s.srvid = srv.srvid 
where sp.name ='HDXDB-DR' --and sa.name not in ('Dynamix Art$Purchase Prepayment %','Dynamix Art$Sales Prepayment %') -- just replace space _ to space %
order by sa.name

-- select * from sys.objects where name like 'Dynamix Art$Purchase Prepayment%' and type ='u'
select * from DBAUtil.dbo.[Tbl_Repl_Rowcount] order by Table_name 


-- run on subscriber
select 'insert into DBAUtil.dbo.[Tbl_Repl_Rowcount] select @@Servername,'''+name+''',count (*) from ['+name+'] with (nolock)' from sys.objects where name in 
(
'pass the notepad data'
)

select * from DBAUtil.dbo.[Tbl_Repl_Rowcount] order by Table_name 