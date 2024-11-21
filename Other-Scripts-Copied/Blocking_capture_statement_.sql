
/*
create table sqlstatements (BlockID int null, spid int null, EventType nvarchar(200), Parameters nvarchar(400),EventInfo nvarchar(4000))

alter table sqlstatements with check add constraint [FK_sqlstatements_Blocktime] foreign key (BlockID) references blocktime (BlockID)
alter table sqlstatements check  constraint [FK_sqlstatements_Blocktime]

create table sqlstatements_fn_get_sql (BlockID int null, spid int null, sqltext varchar(7000))

alter table sqlstatements_fn_get_sql with check add constraint [FK_sqlstatements_fn_get_sql_Blocktime] foreign key (BlockID) references blocktime (BlockID)
alter table sqlstatements_fn_get_sql check  constraint [FK_sqlstatements_fn_get_sql_Blocktime]

*/

alter procedure usp_get_sql_statement
(@BlockID int, @spid varchar(6), @use_fn_get_SQL bit =0)
as
declare @SQLText varchar(8000)
Declare @handle binary(20)

create table #sqlstatements (EventType nvarchar(200), Parameters nvarchar(400),EventInfo nvarchar(4000))

IF Exists (select spid from master..sysprocesses where spid =@spid)

begin
	Declare @sql nvarchar(200)
	set @sql =N'DBCC INPUTBUFFER ('+ @spid+ ')'
	insert #sqlstatements Exec sp_executesql @sql
	insert into sqlstatements (BlockID,spid,EventType,Parameters,EventInfo) 
	select @BlockID, @spid, EventType,Parameters, cast (EventInfo as nvarchar(3000)) from #sqlstatements
end

Else

Begin
	
	insert into sqlstatements (BlockID,spid,EventType,Parameters,EventInfo) values (@BlockID, @SPID,'No Spid',0, 'Spid was gone by the time query ran')
	
end

IF @use_fn_get_SQL =1 
begin

select @handle =sql_handle from sysprocesses where spid =@spid
select @SQLText = text from ::fn_get_sql(@handle)

insert into  [dbo].[sqlstatements_fn_get_sql] values (@BlockID,@SPID,@SQLText)


END


