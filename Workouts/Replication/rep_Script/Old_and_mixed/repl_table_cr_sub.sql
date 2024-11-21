use Muthu_2
go
select * from T9
go
select * from T10

use master
go
alter database Muthu_2 set single_user with rollback immediate

drop database Muthu_2
create database Muthu_2