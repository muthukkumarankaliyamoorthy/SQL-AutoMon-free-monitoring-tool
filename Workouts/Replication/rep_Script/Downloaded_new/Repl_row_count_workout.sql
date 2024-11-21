/*
USE [DBAUtil]
GO

drop table [Tbl_Repl_Rowcount]
go
CREATE TABLE [dbo].[Tbl_Repl_Rowcount](
	[PublisherName] [varchar](200) NOT NULL,
	[Table_name] [varchar](400) NOT NULL,
	[Row_Count] [int] NULL
) 

select * from Tbl_Repl_Rowcount

*/

USE [DBAUtil]
GO
alter proc USP_Repl_row_count
as
begin

truncate table Tbl_Repl_Rowcount

Declare @SQL_cmd varchar (max)
Declare @SQL_txt varchar (max)
DECLARE @Pub_NAME VARCHAR(2000)
DECLARE @Tbl_name VARCHAR(2000)


DECLARE Repl_cur CURSOR
FOR

select top 10
sp.name as PublisherName 
, sa.name as TableName 
, 'select count(*) as [Row_Count] from HDXDB.dbo.['+sa.name+'] with (nolock)' as count_cmd

from hdxdb.dbo.syspublications sp  
join hdxdb.dbo.sysarticles sa on sp.pubid = sa.pubid 
join hdxdb.dbo.syssubscriptions s on sa.artid = s.artid 
join master.dbo.sysservers srv on s.srvid = srv.srvid 
where sp.name ='HDXDB-DR' 
order by sa.name


OPEN Repl_cur
FETCH NEXT FROM Repl_cur INTO @Pub_NAME,@Tbl_name,@SQL_cmd

WHILE @@FETCH_STATUS=0  
BEGIN
BEGIN TRY


set @SQL_txt = 
'SELECT '''+@Pub_NAME+''','''+@Tbl_name+''','''+@SQL_cmd+''' from hdxdb.dbo.syspublications sp  
join hdxdb.dbo.sysarticles sa on sp.pubid = sa.pubid 
join hdxdb.dbo.syssubscriptions s on sa.artid = s.artid 
join master.dbo.sysservers srv on s.srvid = srv.srvid
where sp.name =''HDXDB-DR''
'

print @SQL_txt

end try
BEGIN CATCH
--SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
 
SELECT 'Repl_row_count',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()


END CATCH

FETCH NEXT FROM Repl_cur INTO @Pub_NAME,@Tbl_name,@SQL_cmd
END
CLOSE Repl_cur
DEALLOCATE Repl_cur

/*
select @SQL_cmd='insert into [DBAUtil].dbo.[Tbl_Repl_Rowcount] select '''+sp.name+''' as [PublisherName],'''+sa.name+''' as [Table_name], count(*) as [Row_Count] from ['+sa.name+'] with (nolock)'

from hdxdb.dbo.syspublications sp  
join hdxdb.dbo.sysarticles sa on sp.pubid = sa.pubid 
join hdxdb.dbo.syssubscriptions s on sa.artid = s.artid 
join master.dbo.sysservers srv on s.srvid = srv.srvid

where sp.name ='HDXDB-DR' 
order by sa.name

print (@SQL_cmd)
*/
end
