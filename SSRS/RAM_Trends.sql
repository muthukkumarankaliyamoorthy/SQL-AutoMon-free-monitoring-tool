
USE [DBA_Report_Code]
GO

alter procedure [dbo].[Usp_RAM_Trends]
(@Server varchar(100))
as
begin


select  Servername,Physical_RAM_mB,Physical_RAM_Available_mB,Physical_RAM_Use_mB,Locked_page_RAM_mB,Max_RAM,Min_RAM,PLE
,cast(c.Upload_date as date) as Date

from DBAdata_Archive.[dbo].tbl_memory_usgae_2012_New c
where SERVERNAME like @Server

and Upload_date >= getdate ()-120
group by Servername,Physical_RAM_mB,Physical_RAM_Available_mB,Physical_RAM_Use_mB,Locked_page_RAM_mB,Max_RAM,Min_RAM,PLE,cast(c.Upload_date as date)
order by cast(c.Upload_date as date) asc;

end

-- exec [Usp_RAM_Trends] 'Server'
-- select * from DBAdata_Archive.[dbo].[tbl_memory_usgae_2012_New]
--/*

select Servername,Physical_RAM_mB,Physical_RAM_Available_mB,Physical_RAM_Use_mB,Locked_page_RAM_mB,Max_RAM,Min_RAM,PLE
,cast(c.Upload_date as date) as Date

from DBAdata_Archive.[dbo].tbl_memory_usgae_2012_New C 
where SERVERNAME= 'Server'

and Upload_date >= getdate ()-60
group by Servername,Physical_RAM_mB,Physical_RAM_Available_mB,Physical_RAM_Use_mB,Locked_page_RAM_mB,Max_RAM,Min_RAM,PLE,cast(c.Upload_date as date)
order by cast(c.Upload_date as date) asc;

--*/
