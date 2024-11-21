

use DBAutil
go

/*

create table default_trace_events_recorded (EventID smallint not null, Event_Description nvarchar(128) null)
--https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-trace-setevent-transact-sql?view=sql-server-ver16
insert into default_trace_events_recorded values (104,'Audit AddLogin Event')
insert into default_trace_events_recorded values (105,'Audit Login GDR Event')
insert into default_trace_events_recorded values (106,'Audit Login Change Property Event')
insert into default_trace_events_recorded values (107,'Audit Login Change Password Event')
insert into default_trace_events_recorded values (108,'Audit Add Login to Server Role Event')
insert into default_trace_events_recorded values (109,'Audit Add DB User Event')
insert into default_trace_events_recorded values (110,'Audit Add Member to DB Role Event')
insert into default_trace_events_recorded values (111,'Audit Add Role Event')
insert into default_trace_events_recorded values (152,'Audit Change Database Owner')
insert into default_trace_events_recorded values (153,'Audit Schema Object Take Ownership Event')


drop table event_trace
create table event_trace
(EventName nvarchar(256) not null, subclass_name nvarchar(256) not null,DatabaseName nvarchar(512) not null,NTdomainname nvarchar(512) null,
ApplicationName nvarchar(512) null, LoginName nvarchar(512) null, SPID int not null, StartTime datetime not null, RoleName nvarchar(512) null,
TargetUserName nvarchar(512) null, TargetLoginName nvarchar(512) null, SessionLoginName varchar(512) null, Processed_Time Datetime null
)
alter table event_trace add default ('2000-01-01') for Processed_Time

select * from event_trace
*/
alter proc usp_Trace_events_collection
@i_debug int =0
as

declare @v_path nvarchar(1000)
declare @nv_sql_text nvarchar(72)

SET XACT_ABORT,NOCOUNT ON

BEGIN TRAN

select @v_path = REVERSE(substring(reverse([path]),charindex(char(92), reverse([path])),260))+N'log.trc'
from master.sys.traces where is_default=1

--select @v_path
BEGIN

insert into event_trace
select te.name as [EventName], v.subclass_name,t.DatabaseName,t.NTDomainName,t.ApplicationName,t.LoginName,t.SPID,t.StartTime,t.RoleName,
t.TargetUserName,t.TargetLoginName,t.SessionLoginName,'2000-01-01'
from sys.fn_trace_gettable (@v_path, default)t
join sys.trace_events te on t.EventClass=te.trace_event_id
join sys.trace_subclass_values v on v.trace_event_id=te.trace_event_id
where EventClass in  (select eventid from DBAutil..default_trace_events_recorded)
and starttime > (select isnull(max(starttime),'2000-01-01') from event_trace)
and v.subclass_value=t.EventSubClass
END

Commit tran

/*
select te.name as [EventName], v.subclass_name,t.DatabaseName,t.NTDomainName,t.ApplicationName,t.LoginName,t.SPID,t.StartTime,t.RoleName,
t.TargetUserName,t.TargetLoginName,t.SessionLoginName,'2000-01-01'
from sys.fn_trace_gettable (@v_path, default)t
join sys.trace_events te on t.EventClass=te.trace_event_id
join sys.trace_subclass_values v on v.trace_event_id=te.trace_event_id
where EventClass in  (104,105,106,107,108,109,110,111,152,153)
and v.subclass_value=t.EventSubClass
*/