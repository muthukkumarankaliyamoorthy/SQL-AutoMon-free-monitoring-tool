USE [DBAUtil]
GO


GO
/*
USE [DBAUtil]
GO

drop table [Tbl_Repl_Rowcount]
go
CREATE TABLE [dbo].[Tbl_Repl_Rowcount](
	[PublisherName] [varchar](200) NOT NULL,
	[Table_name] [varchar](400) NOT NULL
	,[Row_Count] [int] NULL
) 

select * from Tbl_Repl_Rowcount

*/
use DBAUtil
go

alter PROCEDURE [dbo].[USP_Repl_row_count_loop]


AS
BEGIN
SET nocount ON


-- select * from DBAUtil.dbo.Tbl_Repl_Rowcount
Truncate table DBAUtil.dbo.Tbl_Repl_Rowcount




      DECLARE @Pub_name SYSNAME
      DECLARE @Tbl_name SYSNAME
      DECLARE @sql varchar(8000)
	  DECLARE @sql_cmd varchar(8000)
      DECLARE @minrow int
      DECLARE @maxrow int

 
 declare @repl_info table (id int  primary key identity, 
 PublisherName varchar(500),TableName varchar(500)) 
 
 insert into @repl_info

select top 10
sp.name as PublisherName 
, sa.name as TableName 
--, 'select count(*) as [Row_Count] from HDXDB.dbo.['+sa.name+'] with (nolock)' as count_cmd

from hdxdb.dbo.syspublications sp  
join hdxdb.dbo.sysarticles sa on sp.pubid = sa.pubid 
join hdxdb.dbo.syssubscriptions s on sa.artid = s.artid 
join master.dbo.sysservers srv on s.srvid = srv.srvid 
where sp.name ='XX' 
order by sa.name

 
 
SELECT @minrow = MIN(id)FROM   @repl_info
SELECT @maxrow  = MAX(id) FROM   @repl_info
 
 while (@minrow <=@maxrow)
 begin
 begin try

 select @Pub_name=PublisherName ,
 @tbl_name=TableName   
 
 from @repl_info where ID = @minrow 
 

set @sql=
'EXEC(''DECLARE @sql_cmd varchar(8000);
select @SQL_cmd=''''''''select top 1 '''''+@Pub_name+''''' as [PublisherName],'''''+@tbl_name+''''' as [Table_name]
,count(*) as [Row_Count]

from hdxdb.dbo.syspublications sp  
join hdxdb.dbo.sysarticles sa on sp.pubid = sa.pubid
join hdxdb.dbo.syssubscriptions s on sa.artid = s.artid 
join master.dbo.sysservers srv on s.srvid = srv.srvid

where sp.name =''''XXX''''
'')'

 insert into dbautil.dbo.Tbl_Repl_Rowcount
 exec(@sql)
 --print @SQL

 
 end try
 BEGIN CATCH


 
SELECT 'Rpl_Row_count',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()


END CATCH
 set @minrow =@minrow +1 
 end
 
 

END


