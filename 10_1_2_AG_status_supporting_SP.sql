USE [DBAdata]
GO

/****** Object:  StoredProcedure [dbo].[usp_SpServerDiagnostics]    Script Date: 15-04-2017 14:29:31 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*

CREATE TABLE [dbo].[SpServerDiagnostics](
	[create_time] [datetime] NULL,
	[component_type] [sysname] NOT NULL,
	[component_name] [sysname] NOT NULL,
	[state] [int] NULL,
	[state_desc] [sysname] NOT NULL,
	[data] [nvarchar](max) NULL
) 

*/

--DROP PROC [dbo].[usp_SpServerDiagnostics]
alter proc [dbo].[usp_SpServerDiagnostics]
--with Encryption
as
begin

	  DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @text varchar(8000)
      DECLARE @minrow int
      DECLARE @maxrow int

--TRUNCATE TABLE SpServerDiagnostics


declare @Diagnostics table (id int  primary key identity, 
servername varchar(100),Description varchar(100)) 
 
insert into @Diagnostics

select Servername , Description   from dbadata.dbo.dba_all_servers 
-- usp_SpServerDiagnostics Object created only target server
WHERE Description in(
'sss'

)


 -- select *  from dbadata.dbo.dba_all_servers where ha like 'a%'
SELECT @minrow = MIN(id)FROM   @Diagnostics
SELECT @maxrow  = MAX(id) FROM   @Diagnostics
 
 while (@minrow <=@maxrow)
 begin

 BEGIN TRY
 
 select @Server_name=Servername ,
 @Desc=Description   from @Diagnostics where ID = @minrow 
 
 
EXEC('Exec ['+@Server_name+'].MASTER.DBO.usp_SpServerDiagnostics')

end try

BEGIN CATCH
SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'AlwaysON_DIAGNOSTICS',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()


END CATCH
 
set @minrow =@minrow +1 
end

END



GO


