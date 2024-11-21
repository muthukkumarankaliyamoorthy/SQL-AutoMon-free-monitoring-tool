

Use DBAutil
go

/*

select * from alwayson_delay

create table alwayson_delay (Primary_replica varchar(256) not null, database_name varchar(128) not null, time_recorded datetime not null,
secondary_replica varchar(256) not null, Sync_Lag_Mins int not null, Availability_group sysname not null, constraint [uIX_alwayson_delay] unique clustered
(time_recorded asc,primary_replica asc, secondary_replica asc,database_name asc)
)
*/

alter proc usp_check_alwayson_lag
as
set nocount , xact_abort on
begin
-- if ag enabled
--IF dbo.fn_get_ag_enabled ('ag_server_active') =0 return
--if version above 2012
-- IF dbo.fn_return_sql_version ('major') <11 return

;with
ag_stats as
(
select ar.replica_server_name,hars.role_desc,db_name(DRS.database_id)[DBName],DRS.last_commit_time,Groups.name
from sys.dm_Hadr_database_replica_states DRS
join sys.availability_replicas AR on DRS.replica_id=AR.replica_id
join sys.dm_hadr_availability_replica_states HARS on AR.group_id=HARS.group_id
join sys.availability_groups Groups on Groups.group_id=HARS.group_id
and AR.replica_id=HARS.replica_id
),
Pri_commitTime AS
(
select replica_server_name, DBName, Name, Last_commit_time from AG_Stats where role_desc='Primary'
),
Sec_CommitTime AS
(
select replica_server_name, DBName,name, Last_commit_time from AG_Stats where role_desc='Secondary'
)

insert into alwayson_delay

select p.replica_server_name [Primary Replica],P.DBName [DB Name], Getdate() Time_Recorded,
s.replica_server_name [Secondary Replica], isnull(datediff(mi,s.last_commit_time,p.last_commit_time),0) as [Syn_Lag_Mins],p.[name]

from Pri_commitTime P left join Sec_CommitTime S on s.DBName=P.DBName

end