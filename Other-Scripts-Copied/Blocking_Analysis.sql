use DBAUtil

select bt.blocktime,b.spid,b.blocked,b.cmd,s.EventInfo last_SQL_statement, waittype,waittime,lastwaittype,
waitresource,db_name(dbid) as DBname,uid,cpu,physical_io,memusage,login_time,last_batch,ecid,open_tran,status,sid,
hostname,program_name,hostprocess,cmd,nt_domain,nt_username,net_address,net_library,loginame,context_info,
sql_handle,stmt_start,stmt_end

from blocktime bt 
inner join blocks b  on bt.BlockID=b.blockid
inner join sqlstatements s on s.BlockID=b.blockid

--where bt.blocktime >=''

order by BlockTime


--select top 100 AuditOn from dbo.AuditLog with (nolock) order by AuditOn desc