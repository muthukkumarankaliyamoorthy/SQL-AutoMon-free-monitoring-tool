
/*

use DBAdata
-- select * from DBAdata.dbo.tbl_ServicesServiceStatus
select L_server_name, count (*) from DBAdata.dbo.tbl_ServicesServiceStatus group by L_server_name

select * from DBAdata.dbo.tbl_ServicesServiceStatus --where servername =''

select serviceName from DBAdata.dbo.tbl_ServicesServiceStatus group by serviceName
select serviceStatus from DBAdata.dbo.tbl_ServicesServiceStatus group by serviceStatus

select * from DBAdata.dbo.tbl_ServicesServiceStatus where serviceName ='Analysis Services' and serviceStatus ='Running.'
select * from DBAdata.dbo.tbl_ServicesServiceStatus where serviceStatus like 's%.'

drop table tbl_ServicesServiceStatus

CREATE TABLE tbl_ServicesServiceStatus
(
RowID INT ,ServerName NVARCHAR(128),ServiceName NVARCHAR(128),
ServiceStatus VARCHAR(128),StatusDateTime DATETIME DEFAULT (GETDATE()),
PhysicalSrverName NVARCHAR(128), L_server_name varchar (200)

)

 select 7*121 -- 847

*/
-- select * from tbl_ServicesServiceStatus
use [DBAdata]
go
--DROP PROC [[USP_DBA_GETservice_status]]
alter PROCEDURE [dbo].[USP_DBA_GETservice_status]
/*
Summary:     [USP_DBA_GETservice_status]
Contact:     Muthukkumaran Kaliyamoorhty SQL DBA


ChangeLog:
Date         Coder							Description
2013-jan-21	 Muthukkumaran Kaliyamoorhty     Updated the 2012 functionality                   


*/
--WITH ENCRYPTION
AS
BEGIN
SET nocount ON

--inserting the drive space
TRUNCATE TABLE DBADATA.DBO.tbl_ServicesServiceStatus
TRUNCATE TABLE master.dbo.ServicesServiceStatus

--CREATE TABLE TEMPSPACE_service
--(
--RowID INT ,ServerName NVARCHAR(128),ServiceName NVARCHAR(128),
--ServiceStatus VARCHAR(128),StatusDateTime DATETIME DEFAULT (GETDATE()),
--PhysicalSrverName NVARCHAR(128)
--)
      DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @sql1 varchar(8000)
      DECLARE @minrow int
      DECLARE @maxrow int

---------------------------------------------------
--Put the local server first
---------------------------------------------------
  
 
 declare @Service_info table (id int  primary key identity, 
 servername varchar(100),Description varchar(100)) 
 
 insert into @Service_info

 select Servername , Description   from dbadata.dbo.dba_all_servers 
 WHERE Version <>'SQL2000' -- and edition  not in ('Express')
 AND svr_status ='running' 

 --select *  from dbadata.dbo.dba_all_servers
SELECT @minrow = MIN(id)FROM   @Service_info
SELECT @maxrow  = MAX(id) FROM   @Service_info
 
 while (@minrow <=@maxrow)
 begin
 BEGIN TRY
 select @Server_name=Servername ,
 @Desc=Description   from @Service_info where ID = @minrow 
 
 exec ('exec ['+@server_name+'].master.dbo.Usp_service_Installed')
 
----------------------------------------------------------------
--insert the value to table
-----------------------------------------------------------------

set @sql1=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''  Select *,'''''''''+@Desc+''''''''' from    MASTER.DBO.ServicesServiceStatus      
'''')'')
      '


insert into dbadata.dbo.tbl_ServicesServiceStatus
exec(@sql1)
--print @sql1

end try

BEGIN CATCH
SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;

insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'Service_installed_new',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

--PRINT 'SERVER ['+@SERVER_NAME+']is not COMPLETED.'
END CATCH
 
set @minrow =@minrow +1 
END
 
 
END



