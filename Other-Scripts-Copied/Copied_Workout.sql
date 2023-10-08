-- Group BY PARTITION BY CTE to make more seperation
WITH Server_Databases AS
(
    select a.Server,d.dbname [DB_name], COUNT(d.dbname) OVER(PARTITION BY dbname) AS cnt
      from tbl_servers A join  tbl_sys_databases D on (a.Server=d.Server)
     --where d.dbname in ('db1','db2')
)
SELECT sd.Server, sd.[DB_name]
FROM Server_Databases AS sd
WHERE sd.cnt > 1
order by server

-- Script to convert columns to rows
STRING_AGG(QUOTENAME(COLUMN_NAME, ''''), ',')

---
select 
'bcp "select '+STRING_AGG(COLUMN_NAME,',')+' from [db].dbo.'+name+'" queryout "G:\Test-Bak\Data\db'+'_Load\'+name+'.txt" -S"server" -U"sa" -P"password" -n -c -t^| -T -o"G:\Test-Bak\Log\db\'+name+'_log.txt"' 
table_name--,name,COLUMN_NAME
from tbl_column_length C left join sysobjects  S on C.TABLE_NAME=S.name
where type='u' 
and length <100
--and name in('table1')
group by name