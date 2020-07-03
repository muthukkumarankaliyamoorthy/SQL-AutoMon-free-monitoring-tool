USE [DBAdata]

GO
/*

drop table [tbl_db_count]

CREATE TABLE [dbo].[tbl_db_count](
servername varchar (200) not null primary key,
db_count int null
)

select * from tbl_db_count
-- load from cms 

*/
use DBAdata
go

-- exec [Usp_load_db_count] '2020-06-30 23:59:26.680'

create PROCEDURE [dbo].[Usp_load_db_count]
(@P_DB_create_date sysname)
/*
Summary:        Laod database details
Contact:        Muthukkumaran Kaliyamoorhty SQL DBA

ChangeLog:
Date                          Coder                                                    Description
2012-06-04                 Muthukkumaran Kaliyamoorhty               created
 

*/
--WITH ENCRYPTION
AS
BEGIN
SET nocount ON


--inserting the drive space
Truncate table dbadata.dbo.[tbl_db_count]

declare @DB_create_date sysname
      DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @sql varchar(8000)
      DECLARE @minrow int
      DECLARE @maxrow int

--set @DB_create_date=@P_DB_create_date
---------------------------------------------------
--Put the local server first
---------------------------------------------------
 --insert into tbl_db_count



 declare @Load_db_count table (id int  primary key identity, 
 servername varchar(100),Description varchar(100),crdate datetime) 
 
 insert into @Load_db_count
 select Servername , Description,@P_DB_create_date   from dbadata.dbo.dba_all_servers 
 where svr_status ='running' 
 
 
SELECT @minrow = MIN(id)FROM   @Load_db_count
SELECT @maxrow  = MAX(id) FROM   @Load_db_count
 
 while (@minrow <=@maxrow)
 begin
 begin try
 select @Server_name=Servername ,
 @Desc=Description ,@DB_create_date =convert (datetime,crdate,5) from @Load_db_count where ID = @minrow 
 
 ----------------------------------------------------------------
--insert the value to table
--select * from dbadata.dbo.tbl_get_logfiles_size where freespace <5000 and log_size >5000
-----------------------------------------------------------------
/*
set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''SELECT @@servername as server_name, count(*) as DB_count  from master..sysdatabases 
where dbid not in (1,2,3,4) and name not in (''''''''ReportServer'''''''',''''''''ReportServerTempDB'''''''')
               
'''')'')
      '

 insert into dbadata.dbo.tbl_db_count
 exec(@sql)
 --print @sql
 */
 --select count(*)as database_count from master.dbo.sysdatabases where dbid not in (1,2,3,4)
 set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''
 select '''''''''+@Desc+''''''''', count(*)as database_count from master.dbo.sysdatabases where dbid not in (2) and crdate <='''''''''+@DB_create_date+'''''''''
 
 
'''')'')
'
--print (@sql)
 insert into dbadata.dbo.tbl_db_count
 exec(@sql)

 --print ' sever'+@server_name+'completed.'
 end try
 BEGIN CATCH
--SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'db_count',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

PRINT 'SERVER ['+@SERVER_NAME+']is not COMPLETED.'
END CATCH
 set @minrow =@minrow +1 
 end
 
 

END


