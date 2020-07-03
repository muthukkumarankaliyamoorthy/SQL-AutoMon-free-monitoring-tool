
USE [DBA_Report_Code]
GO

alter procedure [dbo].[Usp_CPU_Trends]
(@Server varchar(100))
as
begin
declare @param1 varchar(100)
set @param1 = '%'+@Server+'%'

select Servername,SQL_CPU_utilization,Idel,other_process
,cast(c.Upload_date as date) as Date

from DBAdata_Archive.[dbo].[tbl_CPU_usgae] c
where SERVERNAME like ''+@param1+''

and Upload_date >= getdate ()-180
group by servername,SQL_CPU_utilization,Idel,other_process,cast(c.Upload_date as date)
order by cast(c.Upload_date as date) asc;

end

-- exec [Usp_CPU_Trends] 'server'
--select * from DBAdata_Archive.[dbo].[tbl_CPU_usgae]
/*

select Servername,SQL_CPU_utilization,Idel,other_process
,cast(c.Upload_date as date) as Date

from DBAdata_Archive.[dbo].[tbl_CPU_usgae] C 
where SERVERNAME like '%server%'

and Upload_date >= getdate ()-60
group by servername,SQL_CPU_utilization,Idel,other_process,cast(c.Upload_date as date)
order by cast(c.Upload_date as date) asc;

*/
