USE [DBAdata]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*

USE [DBAdata]
GO
--drop table tbl_recovery_model_non_Prod
			
CREATE TABLE [dbo].[tbl_recovery_model_non_Prod](
	[SERVER_NAME] [sysname] NOT NULL,
	[DB_NAME] [sysname] NOT NULL,
	[Recovery] [varchar](100) NULL
	
	)

USE [DBAdata_archive]
GO
	CREATE TABLE [dbo].[tbl_recovery_model_non_Prod](
	[SERVER_NAME] [sysname] NOT NULL,
	[DB_NAME] [sysname] NOT NULL,
	[Recovery] [varchar](100) NULL,
	[CREATE_DATE] [datetime] NULL

	)

select * from tbl_Error_handling order by Upload_Date  desc

select * from tbl_recovery_model_non_Prod
and name not in (''''''''ReportServer'''''''',''''''''ReportServerTempDB'''''''')
*/



create proc [dbo].[USP_recovery_model_Non_prod]
/*
Summary:     Check the recovery mode for non prod
Contact:     Muthukkumaran Kaliyamoorthy SQL DBA
Description: Check the recovery mode for non prod

ChangeLog:
Date         Coder							Description
2013-jan-21	 Muthukkumaran Kaliyamoorhty     Updated the 2012 functionality                   


*/
--with Encryption
as
begin

	  DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @sql varchar(max)
      DECLARE @minrow int
      DECLARE @maxrow int

TRUNCATE TABLE tbl_recovery_model_non_Prod

declare @Recovery table (id int  primary key identity, 
servername varchar(100),Description varchar(100)) 
 
insert into @Recovery

select Servername , Description   from dbadata.dbo.dba_all_servers 
--WHERE Description  not LIKE '%ip%' and Description  not LIKE '%KIL%'
WHERE Category  not in ('LIVE','PROD') and SVR_status ='running' and version <>'SQL2000'

 -- select Category  from dbadata.dbo.dba_all_servers group by Category
 -- select *  from dbadata.dbo.dba_all_servers where Category not in ('PROD','live')


 --select *  from dbadata.dbo.dba_all_servers
SELECT @minrow = MIN(id)FROM   @Recovery
SELECT @maxrow  = MAX(id) FROM   @Recovery
 
 while (@minrow <=@maxrow)
 begin
 BEGIN TRY
 
 select @Server_name=Servername ,
 @Desc=Description   from @Recovery where ID = @minrow 

set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''select '''''''''+@DESC+''''''''',name,recovery_model_desc from sys.databases 
where recovery_model_desc <>''''''''simple'''''''' and  database_id not in (1,2,3,4) 
'''')'')
'
insert into dbadata.dbo.tbl_recovery_model_non_Prod
exec(@sql)
--SELECT @sql
end try
BEGIN CATCH
SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'Recovery',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()


END CATCH
 
set @minrow =@minrow +1 
end

insert into DBAdata_Archive.dbo.tbl_recovery_model_non_Prod
select *,getdate() from tbl_recovery_model_non_Prod


END


