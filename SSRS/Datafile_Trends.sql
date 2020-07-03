
USE [DBA_Report_Code]
GO

alter procedure [dbo].[Usp_DataFile_Trends]
(@Server varchar(100), @DB_name varchar(100), @Data_File varchar(100))
as
begin

select Servername,DBname,Filename,avg(data_size) as File_SizeIn_MB,Drive_letter
,[Date]  = CONVERT(CHAR(7),DATEADD(mm,DATEDIFF(mm,0,[Upload_date]),0),23)

from DBAdata_Archive.[dbo].[tbl_get_datafiles_size] t 
where SERVERNAME like @Server
and dbname=@DB_name
and filename=@Data_File
--and drive_letter ='k'
and Upload_date >= getdate ()-365
group by servername,dbname,filename ,Drive_letter,DATEDIFF(mm,0,[Upload_date])
order by [Date] asc;



end

-- exec [Usp_DataFile_Trends] 'Server','',''

/*
select Servername,DBname,Filename,avg(data_size) as File_SizeIn_MB,Drive_letter
,[Date]  = CONVERT(CHAR(7),DATEADD(mm,DATEDIFF(mm,0,[Upload_date]),0),23)

from DBAdata_Archive.[dbo].[tbl_get_datafiles_size] t 
where SERVERNAME= 'Server'
and dbname=''
and filename=''
--and drive_letter ='k'
and Upload_date >= getdate ()-460
group by servername,dbname,filename ,Drive_letter,DATEDIFF(mm,0,[Upload_date])
order by [Date] asc;

*/
