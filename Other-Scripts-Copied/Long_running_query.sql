-- Long running process based on last login time
select db_name(dbid) as DBName , Cmd, Status as [Run_Status],datediff(minute,login_time,getdate()) as [Runtime_minute]
,spid,blocked,lastwaittype,waittime,hostname,program_name,loginame,login_time from sysprocesses
where spid > 51 and status not in ('background','sleeping')
and datediff(minute,login_time,getdate()) >5 -- more than 5 minutes
--and cmd not in ('waitfor','awaiting command')
--and not in dbid (1,2,3,4)
group by dbid,Cmd, Status ,login_time,spid,blocked,lastwaittype,waittime,hostname,program_name,loginame,login_time