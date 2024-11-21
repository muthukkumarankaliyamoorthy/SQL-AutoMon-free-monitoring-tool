--For example, you could get the number of commands replicated per day per publisher database with this query:
--https://dba.stackexchange.com/questions/299471/ms-sql-transactional-replication-how-to-figure-out-how-much-data-is-being-push

use distribution
go
select t.publisher_database_id,convert(date,entry_time) as entry_date, SUM(DATALENGTH(c.command))/1024[total size of the commands KB]
,count(*) as nb_commands 
from MSrepl_transactions t
    INNER JOIN MSrepl_commands c ON t.publisher_database_id=c.publisher_database_id and t.xact_seqno=c.xact_seqno
GROUP BY t.publisher_database_id,convert(date,entry_time) 
