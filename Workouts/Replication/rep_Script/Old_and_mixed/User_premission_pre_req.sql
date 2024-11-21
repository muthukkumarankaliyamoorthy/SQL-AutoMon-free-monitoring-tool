USE [distribution]
GO
CREATE USER [MUTHU\Svc_repl_snapshot] FOR LOGIN [MUTHU\Svc_repl_snapshot]
GO
USE [distribution]
GO
ALTER ROLE [db_owner] ADD MEMBER [MUTHU\Svc_repl_snapshot]
GO

USE [distribution]
GO
CREATE USER [MUTHU\Svc_repl_logreader] FOR LOGIN [MUTHU\Svc_repl_logreader]
GO
USE [distribution]
GO
ALTER ROLE [db_owner] ADD MEMBER [MUTHU\Svc_repl_logreader]
GO


USE [distribution]
GO
CREATE USER [MUTHU\Svc_repl_distributer] FOR LOGIN [MUTHU\Svc_repl_distributer]
GO
USE [distribution]
GO
ALTER ROLE [db_owner] ADD MEMBER [MUTHU\Svc_repl_distributer]
GO

--============ on pub & sub

--USE [AdventureWorks2019]
--GO
--CREATE USER [MUTHU\Svc_repl_snapshot] FOR LOGIN [MUTHU\Svc_repl_snapshot]
--GO
USE [AdventureWorks2019]
GO
ALTER ROLE [db_owner] ADD MEMBER [MUTHU\Svc_repl_snapshot]
GO

--USE [AdventureWorks2019]
--GO
--CREATE USER [MUTHU\Svc_repl_logreader] FOR LOGIN [MUTHU\Svc_repl_logreader]
--GO
USE [AdventureWorks2019]
GO
ALTER ROLE [db_owner] ADD MEMBER [MUTHU\Svc_repl_logreader]
GO


--USE [AdventureWorks2019]
--GO
--CREATE USER [MUTHU\Svc_repl_distributer] FOR LOGIN [MUTHU\Svc_repl_distributer]
--GO
USE [AdventureWorks2019]
GO
ALTER ROLE [db_owner] ADD MEMBER [MUTHU\Svc_repl_distributer]
GO

