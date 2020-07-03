
-- drop table tbl_server_processes



USE [DBA_Processes]

GO
/*

USE [DBA_Processes]
GO

drop table [tbl_server_processes]

CREATE TABLE [dbo].[tbl_server_processes](
	[SERVER_Name] varchar (100),
	[NAME] [sysname] NOT NULL,
	[login_time] [datetime] NULL,
	[last_batch] [datetime] NULL,
	[DATE] [datetime] NOT NULL,
	[STATUS] [nchar](30) NULL,
	[hostname] [nchar](128) NULL,
	[program_name] [nchar](128) NULL,
	[nt_username] [nchar](128) NULL,
	[loginame] [nchar](128) NULL
)

select * from tbl_server_processes

*/
use DBA_Processes
go

--drop proc [Usp_load_sys_processes]
alter PROCEDURE [dbo].[Usp_load_sys_processes]
/*
Summary:        [Usp_load_sys_processes]
Contact:        Muthukkumaran Kaliyamoorhty SQL DBA

ChangeLog:
Date                          Coder                                                    Description
2012-06-04                 Muthukkumaran Kaliyamoorhty               created
 
*******************All the SQL keywords should be written in upper case********************
*/
WITH ENCRYPTION
AS
BEGIN
SET nocount ON

--inserting the drive space
--Truncate table DBA_Processes.dbo.[tbl_server_processes]


      DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @sql varchar(8000)
      DECLARE @minrow int
      DECLARE @maxrow int

---------------------------------------------------
--Put the local server first
---------------------------------------------------
 --insert into tbl_server_processes
--select 'FINSQLVM01.FORTIS-UK.FORTIS.COM',* from master.dbo.sysdatabases


 declare @Load_sys_processes table (id int  primary key identity, 
 servername varchar(100),Description varchar(100)) 
 
 insert into @Load_sys_processes
 select Servername , Description   from DBAdata.dbo.dba_all_servers 
 where svr_status ='running' 
 
 
SELECT @minrow = MIN(id)FROM   @Load_sys_processes
SELECT @maxrow  = MAX(id) FROM   @Load_sys_processes
 
 while (@minrow <=@maxrow)
 begin
 begin try
 select @Server_name=Servername ,
 @Desc=Description   from @Load_sys_processes where ID = @minrow 

 
 -- select *  from sys.databases
 set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''
 
 SELECT  '''''''''+@Desc+''''''''', NAME
 ,login_time
 ,last_batch
 ,getdate() AS DATE
 ,sp.STATUS
 ,hostname
 ,program_name
 ,nt_username
 ,loginame 
FROM master.dbo.sysdatabases d
LEFT JOIN master.dbo.sysprocesses sp ON d.dbid = sp.dbid
WHERE d.dbid NOT BETWEEN 0
  AND 4
 AND loginame IS NOT NULL

'''')'')
      '

 insert into DBA_Processes.dbo.tbl_server_processes
 exec(@sql)

 --print ' sever'+@server_name+'completed.'
 end try
 BEGIN CATCH
--SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into dbadata.dbo.tbl_Error_handling
 
SELECT @SERVER_NAME,'tbl_server_processes',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

PRINT 'SERVER ['+@SERVER_NAME+']is not COMPLETED.'
END CATCH
 set @minrow =@minrow +1 
 end
 

END


