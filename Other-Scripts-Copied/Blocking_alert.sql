select @@servername [SERVER],sp.spid,sp.blocked, (CONVERT(DATETIME,CAST(sp.last_batch AS CHAR(8)),101))  as last_batch,sp.waittime,sp.waitresource,sp.lastwaittype,sp.cmd, sp.dbid,
sp.loginame,sp.hostname,sp.cpu 
from master.dbo.sysprocesses sp
where sp.spid>50 and sp.spid<>sp.blocked and sp.blocked<>0 
and waittime>10000 -- milli seconnds
--and datediff(Second,last_batch,GETDATE())>30
