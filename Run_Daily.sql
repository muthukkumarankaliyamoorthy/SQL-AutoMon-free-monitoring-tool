-- truncate table tbl_Error_handling

use DBAData
select Server_name,Module_name, left([error_message],25) AS error
from DBAData..tbl_Error_handling 
where Upload_Date>=DATEADD(Day,-1,getdate())
and Module_name <>'Perfmon'
group by Server_name,Module_name,[error_message]
having count(*)>=1




/*
Keep this column updated
SELECT SERVERNAME as[Linked_ServerName],[DESCRIPTION] as [Server_Name],HA,Category, version,login_mode FROM DBADATA.DBO.DBA_ALL_SERVERS

*/

/*

truncate table DBAdata_Archive.dbo.tbl_get_datafiles_size_express_edition


use DBAdata_Archive
go
select 'truncate table[' +name+']' from sys.objects where type='u'

*/
