create table tbl_svr (Server varchar(200) primary key)
insert into tbl_svr values ('Server1')
insert into tbl_svr values ('Server2')
insert into tbl_svr values ('Server3')
insert into tbl_svr values ('Server4')
insert into tbl_svr values ('Server5')

Create table tbl_dbs_list (Server varchar(200), dbname varchar(200))
insert into tbl_dbs_list values ('Server1','db1')
insert into tbl_dbs_list values ('Server1','db2')
insert into tbl_dbs_list values ('Server1','db3')
insert into tbl_dbs_list values ('Server1','db4')
insert into tbl_dbs_list values ('Server1','db5')
insert into tbl_dbs_list values ('Server2','db1')
insert into tbl_dbs_list values ('Server2','db2')
insert into tbl_dbs_list values ('Server3','db1')
insert into tbl_dbs_list values ('Server4','db2')
insert into tbl_dbs_list values ('Server5','db1')


select d.dbname [DB_name],count(*) as Count
 from tbl_svr A join  tbl_dbs_list D on (a.Server=d.Server)
 group by d.dbname
 having count(*)>1

-- If I pass db name that will work, But I want to do as  having count(*)>1
select a.Server,d.dbname [DB_name]
 from tbl_svr A join  tbl_dbs_list D on (a.Server=d.Server)
 where d.dbname in ('db1','db2')

-- Errors out
select a.Server,d.dbname [DB_name]
 from tbl_svr A join  tbl_dbs_list D on (a.Server=d.Server)
 --where d.dbname in ('db1','db2','db3','db4','db5')
  having count(*)>1

--sloution
WITH Server_Databases AS
(
    select a.Server,d.dbname [DB_name], COUNT(d.dbname) OVER(PARTITION BY dbname) AS cnt
      from tbl_svr A join  tbl_dbs_list D on (a.Server=d.Server)
     --where d.dbname in ('db1','db2')
)
SELECT sd.Server, sd.[DB_name]
FROM Server_Databases AS sd
WHERE sd.cnt > 1
order by server