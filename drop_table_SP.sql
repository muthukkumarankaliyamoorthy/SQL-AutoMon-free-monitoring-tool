
select * from sysobjects where type ='p'

select 'drop table ['+name+']' from sysobjects where type ='u'

select 'drop proc ['+name+']' from sysobjects where type ='p'

