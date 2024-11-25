
-- On pub node1
drop database Muthu
drop database Muthu_Replica

create database Muthu
--create database Muthu_Local
create database Muthu_Replica

use Muthu
create table Repl_Tbl1 (N int primary key, N1 varchar(100))
insert into Repl_Tbl1 values (1,'A')
create table Repl_Tbl2 (N int primary key, N1 varchar(100))
insert into Repl_Tbl1 values (2,'A')
create table Repl_Tbl3 (N int primary key, N1 varchar(100))
create table Repl_Tbl4 (N int primary key, N1 varchar(100))


-- On sub node2
Drop database Muthu_DR
Drop database Muthu_Replica
Drop database [Muthu-BI]
go

create database Muthu_DR
create database Muthu_Replica
create database [Muthu-BI]

create table Repl_Tbl5 (N int primary key, N1 varchar(100))