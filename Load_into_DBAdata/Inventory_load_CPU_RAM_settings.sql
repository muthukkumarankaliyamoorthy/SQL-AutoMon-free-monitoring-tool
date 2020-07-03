USE [DBAdata]

GO
/*

USE [DBAdata]
GO
drop table tbl_load_Inventory_CPU_RAM_count
go
CREATE TABLE [dbo].[tbl_load_Inventory_CPU_RAM_count](

	servername varchar(200) not null primary key,
	[Number_of_Logical_CPU] [int] NOT NULL,
	[hyperthread_ratio] [int] NOT NULL,
	[Number_of_Physical_CPU] [int] NULL,
	[Total_Physical_Memory_KB] [bigint] NOT NULL,
	[SQL_Version] [sql_variant] NULL
)
GO

--ALTER TABLE [tbl_load_Inventory_CPU_RAM_count] ALTER COLUMN [servername] varchar(100) NOT NULL
--alter table tbl_load_Inventory_CPU_RAM_count add primary key (servername)

-- load the missing servers
select * from dba_all_servers where description not in (select servername from [tbl_load_Inventory_CPU_RAM_count] )and SVR_status='running' order by description desc


select * from [tbl_load_Inventory_CPU_RAM_count] 
select * from dba_all_servers where svr_status ='running'


select Number_of_Logical_CPU/hyperthread_ratio,Number_of_Physical_CPU,* from [tbl_load_Inventory_CPU_RAM_count] where Number_of_Physical_CPU = 0

select * from [tbl_load_Inventory_CPU_RAM_count]  where Number_of_Physical_CPU = 0
select * from [tbl_load_Inventory_CPU_RAM_count]  where Number_of_Physical_CPU is null

*/


-- select * from dba_all_servers where  svr_status ='running' and Description not in (select servername from [tbl_load_Inventory_CPU_RAM_count]) 

use DBAdata
go

create PROCEDURE [dbo].[Usp_Load_cpu_ram_Inventory_load]
/*
Summary:        Usp_Load_cpu_ram_Inventory_load
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
Truncate table dbadata.dbo.tbl_load_Inventory_CPU_RAM_count


      DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @sql varchar(8000)
	  DECLARE @sql1 varchar(8000)
	   DECLARE @VER SYSNAME
      DECLARE @minrow int
      DECLARE @maxrow int

---------------------------------------------------
--Put the local server first
---------------------------------------------------
 /*insert into tbl_load_Inventory_CPU_RAM_count

SELECT 'server',
 cpu_count AS [Number of Logical CPU]
,hyperthread_ratio
,cpu_count/hyperthread_ratio AS [Number of Physical CPU]
,physical_memory_kb AS [Total Physical Memory IN MB],serverproperty('ProductVersion') as SQL_Version 
FROM sys.dm_os_sys_info OPTION (RECOMPILE);

select  cpu_count 
,hyperthread_ratio
,cpu_count/hyperthread_ratio as phy,physical_memory_in_bytes/1024, serverproperty('ProductVersion') 
FROM sys.dm_os_sys_info OPTION (RECOMPILE);

 select  cpu_count ,hyperthread_ratio
,cpu_count/hyperthread_ratio ,physical_memory_kb, serverproperty('ProductVersion')
FROM sys.dm_os_sys_info OPTION (RECOMPILE);
*/

 declare @CPU_count table (id int  primary key identity,  servername varchar(200),Description varchar(100), version varchar(50)) 
 
 insert into @CPU_count
 select Servername , Description,version   from dbadata.dbo.dba_all_servers 
 where svr_status ='running' 
 
SELECT @minrow = MIN(id)FROM   @CPU_count
SELECT @maxrow  = MAX(id) FROM   @CPU_count
 
 while (@minrow <=@maxrow)
 begin
 begin try
 select @Server_name=Servername ,
 @Desc=Description,@VER=VERSION  from @CPU_count where ID = @minrow 
 
 ----------------------------------------------------------------
--insert the value to table
--select * from dbadata.dbo.tbl_get_logfiles_size where freespace <5000 and log_size >5000
-----------------------------------------------------------------


 IF (@VER<'SQL2012')
 BEGIN
 set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''
 select '''''''''+@Desc+''''''''', cpu_count 
,hyperthread_ratio
,cpu_count/hyperthread_ratio ,physical_memory_in_bytes/1024 as physical_memory_kb, serverproperty(''''''''ProductVersion'''''''') 
FROM sys.dm_os_sys_info OPTION (RECOMPILE);
        
'''')'')
      '

insert into dbadata.dbo.tbl_load_Inventory_CPU_RAM_count
EXEC (@sql)
--PRINT @sql1
END

ELSE

BEGIN
set @sql1=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''
 select '''''''''+@Desc+''''''''', cpu_count ,hyperthread_ratio
,cpu_count/hyperthread_ratio ,physical_memory_kb, serverproperty(''''''''ProductVersion'''''''')
FROM sys.dm_os_sys_info OPTION (RECOMPILE);
        
'''')'')
      '
     
insert into dbadata.dbo.tbl_load_Inventory_CPU_RAM_count
EXEC (@sql1)

--PRINT @sql
END

 --print ' sever'+@server_name+'completed.'
 end try
 BEGIN CATCH
--SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'cpu_ram_count',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

PRINT 'SERVER ['+@SERVER_NAME+']is not COMPLETED.'
END CATCH
 set @minrow =@minrow +1 
 end

END


