USE [DBAdata]
GO

/****** Object:  StoredProcedure [dbo].[usp_SpServerDiagnostics_new]    Script Date: 15-04-2017 14:29:39 ******/
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
alter proc [dbo].[usp_SpServerDiagnostics_new]
(@Server_name varchar(50))
--with Encryption
as
begin

 
EXEC('Exec ['+@Server_name+'].MASTER.DBO.usp_SpServerDiagnostics')



END



GO


