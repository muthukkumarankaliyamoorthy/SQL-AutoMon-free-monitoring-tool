USE [DBAdata]

GO
/*

drop table [tbl_sys_configurations]

CREATE TABLE [dbo].[tbl_sys_configurations](
servername varchar (200) not null,
	[configuration_id] [int] NOT NULL,
	[name] [nvarchar](35) NOT NULL,
	[value] [sql_variant] NULL,
	[minimum] [sql_variant] NULL,
	[maximum] [sql_variant] NULL,
	[value_in_use] [sql_variant] NULL,
	[description] [nvarchar](255) NOT NULL,
	[is_dynamic] [bit] NOT NULL,
	[is_advanced] [bit] NOT NULL
)

select * from tbl_sys_configurations

insert into tbl_sys_configurations
select servername FROM tbl_sys_configurations group by servername
-- load from cms 


select ServerName FROM tbl_sys_configurations group by ServerName

select * from dbadata.dbo.dba_all_servers where svr_status in ('Running','NU') -- 115

select svr_status,count(*) FROM dba_all_servers group by svr_status



*/
use DBAdata
go

alter PROCEDURE [dbo].[Usp_load_sys_config]
/*
Summary:        [Usp_load_sys_config]
Contact:        Muthukkumaran Kaliyamoorhty SQL DBA

ChangeLog:
Date                          Coder                                                    Description
2012-06-04                 Muthukkumaran Kaliyamoorhty               created
 
*******************All the SQL keywords should be written in upper case********************
*/
--WITH ENCRYPTION
AS
BEGIN
SET nocount ON

--inserting the drive space
Truncate table dbadata.dbo.[tbl_sys_configurations]


      DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @sql varchar(8000)
      DECLARE @minrow int
      DECLARE @maxrow int

---------------------------------------------------
--Put the local server first
---------------------------------------------------
 --insert into tbl_sys_configurations
--select @@servername,* FROM sys.configurations ORDER BY name ;


 declare @Load_config table (id int  primary key identity, 
 servername varchar(100),Description varchar(100)) 
 
 insert into @Load_config
 select Servername , Description   from dbadata.dbo.dba_all_servers 
 where svr_status ='running' 
 
 
SELECT @minrow = MIN(id)FROM   @Load_config
SELECT @maxrow  = MAX(id) FROM   @Load_config
 
 while (@minrow <=@maxrow)
 begin
 begin try
 select @Server_name=Servername ,
 @Desc=Description   from @Load_config where ID = @minrow 
 
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

 set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''
 select '''''''''+@Desc+''''''''', * FROM sys.configurations ORDER BY name           
'''')'')
      '

 insert into dbadata.dbo.tbl_sys_configurations
 exec(@sql)

 --print ' sever'+@server_name+'completed.'
 end try
 BEGIN CATCH
--SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'sysconfig',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

PRINT 'SERVER ['+@SERVER_NAME+']is not COMPLETED.'
END CATCH
 set @minrow =@minrow +1 
 end
 

END


