
-- exec  usp_RS_Get_server_space 'server'

use DBA_Report_Code
go


alter proc usp_RS_Get_server_space

(@servername varchar(50))
as

begin


select top 25  Drive,FREE_SPACE_IN_MB,Upload_date from [DBAdata_Archive]..[DBA_All_Server_Space]
where SERVER_NAME like @servername-- ='Server'
order by Upload_date desc

end
