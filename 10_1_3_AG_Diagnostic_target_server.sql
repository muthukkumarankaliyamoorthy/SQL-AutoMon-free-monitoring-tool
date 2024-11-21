
use master
go
CREATE TABLE SpServerDiagnosticsResult  
(  
      create_time DateTime,  
      component_type sysname,  
      component_name sysname,  
      state int,  
      state_desc sysname,  
      data nvarchar(max)  
);  
go
-- select * from SpServerDiagnosticsResult

create proc usp_SpServerDiagnostics
as 
begin
--truncate table SpServerDiagnosticsResult

INSERT INTO SpServerDiagnosticsResult 
EXEC master.dbo.sp_server_diagnostics

delete  from SpServerDiagnosticsResult where create_time > getdate()-10
end