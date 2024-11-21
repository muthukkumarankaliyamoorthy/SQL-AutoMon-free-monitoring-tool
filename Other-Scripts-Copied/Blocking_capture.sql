
/*

drop table Blocks
drop table sqlstatements
drop table sqlstatements_fn_get_sql
drop table BlockTime

create table BlockTime (BlockID int identity (1,1) not null primary key, blocktime datetime not null default getdate(),
Blockstatus bit not null default (0))

--

CREATE TABLE [dbo].[Blocks](
	[BlockId] [int] NOT NULL,
	[spid] [smallint] NOT NULL,
	[kpid] [smallint] NOT NULL,
	[blocked] [smallint] NOT NULL,
	[waittype] [binary](2) NOT NULL,
	[waittime] [bigint] NOT NULL,
	[lastwaittype] [nchar](32) NOT NULL,
	[waitresource] [nchar](256) NOT NULL,
	[dbid] [smallint] NOT NULL,
	[uid] [smallint] NULL,
	[cpu] [int] NOT NULL,
	[physical_io] [bigint] NOT NULL,
	[memusage] [int] NOT NULL,
	[login_time] [datetime] NOT NULL,
	[last_batch] [datetime] NOT NULL,
	[ecid] [smallint] NOT NULL,
	[open_tran] [smallint] NOT NULL,
	[status] [nchar](30) NOT NULL,
	[sid] [binary](86) NOT NULL,
	[hostname] [nchar](128) NOT NULL,
	[program_name] [nchar](128) NOT NULL,
	[hostprocess] [nchar](10) NOT NULL,
	[cmd] [nchar](16) NOT NULL,
	[nt_domain] [nchar](128) NOT NULL,
	[nt_username] [nchar](128) NOT NULL,
	[net_address] [nchar](12) NOT NULL,
	[net_library] [nchar](12) NOT NULL,
	[loginame] [nchar](128) NOT NULL,
	[context_info] [binary](128) NOT NULL,
	[sql_handle] [binary](20) NOT NULL,
	[stmt_start] [int] NOT NULL,
	[stmt_end] [int] NOT NULL
	
)

--

--
alter table  blocks with check add constraint [FK_Blocks_BlockTime] foreign key (BlockId)
references blocktime (BlockId)
alter table  blocks check constraint [FK_Blocks_BlockTime]



--
create table sqlstatements (BlockID int null, spid int null, EventType nvarchar(200), Parameters nvarchar(400),EventInfo nvarchar(4000))

alter table sqlstatements with check add constraint [FK_sqlstatements_Blocktime] foreign key (BlockID) references blocktime (BlockID)
alter table sqlstatements check  constraint [FK_sqlstatements_Blocktime]

--
create table sqlstatements_fn_get_sql (BlockID int null, spid int null, sqltext varchar(7000))

alter table sqlstatements_fn_get_sql with check add constraint [FK_sqlstatements_fn_get_sql_Blocktime] foreign key (BlockID) references blocktime (BlockID)
alter table sqlstatements_fn_get_sql check  constraint [FK_sqlstatements_fn_get_sql_Blocktime]

*/

alter proc usp_check_Blockng
(@wait_threshold smallint =3000, @wait_threshold_lb int=60000, @blk_threshold tinyint =5)
as

-- variable
Declare @i_valid_blocks int
Declare @blk_cnt smallint, @blockid INT, @inputbuffer_spid smallint, @lr_blk_cnt tinyint

-- table
declare @current_blocks_table table
(
spid smallint not null,kpid smallint not null,blocked smallint not null,waittype binary (2) not null, waittime bigint not null,
lastwaittype nchar(32) NOT NULL,waitresource nchar(256) NOT NULL,dbid smallint NOT NULL,uid smallint NULL,cpu int NOT NULL,
physical_io bigint NOT NULL,	memusage int NOT NULL,	login_time datetime NOT NULL,	last_batch datetime NOT NULL,	ecid smallint NOT NULL,
open_tran smallint NOT NULL,	status nchar(30) NOT NULL,	sid binary(86) NOT NULL,	hostname nchar(128) NOT NULL,	program_name nchar(128) NOT NULL,
hostprocess nchar(10) NOT NULL,	cmd nchar(26) NOT NULL,	nt_domain nchar(128) NOT NULL,	nt_username nchar(128) NOT NULL,	
net_address nchar(12) NOT NULL,	net_library nchar(12) NOT NULL,	loginame nchar(128) NOT NULL,	context_info binary(128) NOT NULL,
sql_handle binary(20) NOT NULL,	stmt_start int NOT NULL,	stmt_end int NOT NULL
)
Declare @affected_spid table (spid smallint not null, blocked smallint not null)
declare @blocked_spids table (spid smallint)
declare @blks_snapshot_tbl table (spid smallint not null, waittime bigint, dbid int not null)

-- insert into tables
insert into @blks_snapshot_tbl 
select spid,waittime, dbid from master.dbo.sysprocesses where blocked <>0 and waittime >@wait_threshold

select @lr_blk_cnt = count (*) from @blks_snapshot_tbl where waittime >@wait_threshold_lb
select @blk_cnt = count (*) from @blks_snapshot_tbl where waittime >@wait_threshold

select @i_valid_blocks = count (*) from @blks_snapshot_tbl

--print @blk_cnt

IF (@lr_blk_cnt>0 OR @blk_cnt >@blk_threshold)
BEGIN

-- get all proccess
insert into @current_blocks_table 
select spid,kpid,blocked,waittype,waittime,lastwaittype,waitresource,dbid,uid,cpu,physical_io,memusage,login_time,
last_batch,ecid,open_tran,status,sid,hostname,program_name,hostprocess,cmd,nt_domain,nt_username,net_address,
net_library,loginame,context_info,sql_handle,stmt_start,stmt_end from master.dbo.sysprocesses

-- get affected processes
insert into @blocked_spids select blocked from @current_blocks_table where blocked <>0

insert into @affected_spid (spid,blocked)
select distinct spid, blocked from @current_blocks_table where blocked <>0 
union all
select distinct spid, blocked from @current_blocks_table where spid in (select spid from @blocked_spids)

insert into blocktime (Blockstatus) values (1)
select @blockid = @@identity

insert into DBAutil.dbo.Blocks
select @blockid,spid,kpid,blocked,waittype,waittime,lastwaittype,waitresource,dbid,uid,cpu,physical_io,memusage,login_time,
last_batch,ecid,open_tran,status,sid,hostname,program_name,hostprocess,cmd,nt_domain,nt_username,net_address,
net_library,loginame,context_info,sql_handle,stmt_start,stmt_end from @current_blocks_table where spid in (select spid from @affected_spid)

--select spid from @affected_spid

--/*
declare ibuffer cursor  fast_forward for select spid from @affected_spid
open ibuffer
fetch next from ibuffer into @inputbuffer_spid

while (@@FETCH_STATUS != -1)
	begin
	exec DBAUtil..usp_get_sql_statement @BlockId, @inputbuffer_spid
	fetch next from ibuffer into @inputbuffer_spid
	end

	close ibuffer
	deallocate ibuffer
--*/
END


