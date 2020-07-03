USE [DBA_Report_Code]
GO
/****** Object:  StoredProcedure [dbo].[Usp_RAM_Trends]    Script Date: 23/12/2019 14:01:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter procedure [dbo].[Usp_RAM_Trends_percentage]
(@Server varchar(100))
as
begin
declare @param1 varchar(100)
set @param1 = '%'+@Server+'%'

select  Servername,Physical_RAM_mB,Physical_RAM_Available_mB,Physical_RAM_Use_mB,((CONVERT(NUMERIC(9,0),Physical_RAM_Use_mB) / CONVERT(NUMERIC(9,0),Physical_RAM_mB)) * 100) AS [Percentage Usage],
Locked_page_RAM_mB,Max_RAM,Min_RAM,PLE
,cast(c.Upload_date as date) as Date

from DBAdata_Archive.[dbo].tbl_memory_usgae_2012_New c
where SERVERNAME like ''+@param1+''

and Upload_date >= getdate ()-180
group by Servername,Physical_RAM_mB,Physical_RAM_Available_mB,Physical_RAM_Use_mB,Locked_page_RAM_mB,Max_RAM,Min_RAM,PLE,cast(c.Upload_date as date)
--order by cast(c.Upload_date as date) asc;
order by [Percentage Usage] desc

end

/* 
exec [Usp_RAM_Trends_percentage] 'server'

select  Servername,Physical_RAM_mB,Physical_RAM_Available_mB,Physical_RAM_Use_mB,((CONVERT(NUMERIC(9,0),Physical_RAM_Use_mB) / CONVERT(NUMERIC(9,0),Physical_RAM_mB)) * 100) AS [Percentage usage],
Locked_page_RAM_mB,Max_RAM,Min_RAM,PLE
from DBAdata_Archive.[dbo].tbl_memory_usgae_2012_New c
where ((CONVERT(NUMERIC(9,0),Physical_RAM_Use_mB) / CONVERT(NUMERIC(9,0),Physical_RAM_mB)) * 100) > 95
order by [Percentage usage] desc

select  Servername,count(*)
from DBAdata_Archive.[dbo].tbl_memory_usgae_2012_New c
where ((CONVERT(NUMERIC(9,0),Physical_RAM_Use_mB) / CONVERT(NUMERIC(9,0),Physical_RAM_mB)) * 100) > 95
group by Servername order by 2 desc
*/