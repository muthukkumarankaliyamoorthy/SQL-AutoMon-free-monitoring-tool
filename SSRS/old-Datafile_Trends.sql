
USE [DBA_Report_Code]
GO

alter procedure [dbo].[Usp_DataFile_Trends]
(@Server varchar(100), @DB_name varchar(100), @Data_File varchar(100))
as
begin


select Servername,DBname,Filename,avg(data_size) as File_SizeIn_MB,Drive_letter
,cast(t.Upload_date as date) as Date

from DBAdata_Archive.[dbo].[tbl_get_datafiles_size] t 
where SERVERNAME like @Server
and dbname=@DB_name
and filename=@Data_File
and Upload_date >= getdate ()-180
group by servername,dbname,filename,data_size ,Drive_letter,cast(t.Upload_date as date)
order by cast(t.Upload_date as date) asc;

end

-- exec [Usp_DataFile_Trends] 'server','tempdb','tempdev'

/*

select Servername,DBname,Filename,avg(data_size) as File_SizeIn_MB,Drive_letter
,cast(t.Upload_date as date) as Date

from DBAdata_Archive.[dbo].[tbl_get_datafiles_size] t 
where SERVERNAME= 'server'
--and drive_letter ='k'
and Upload_date >= getdate ()-60
group by servername,dbname,filename,data_size ,Drive_letter,cast(t.Upload_date as date)
order by cast(t.Upload_date as date) asc;

*/
