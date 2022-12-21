declare @svrName varchar(255)
declare @sql varchar(400)
--/*by default it will take the current server name, we can the set the server name as well*/
set @svrName = @@ServerName

set @sql='powershell.exe -c "gwmi win32_volume -computername ' + QUOTENAME(@svrName,'''') +' -Filter ''DriveType = 3'' | select Name, capacity, FreeSpace | foreach{$_.name+''|''+$_.capacity/1048576+''%''+$_.freespace/1048576+''*''}"'
--EXEC xp_cmdshell @SQL
--creating a temporary table
CREATE TABLE #DriveSpace
(line varchar(255))
--inserting disk name, total space and free space value in to temporary table
insert #DriveSpace
EXEC xp_cmdshell @sql
/*
----script to retrieve the values in MB from PS Script output
select rtrim(ltrim(SUBSTRING(line,1,CHARINDEX('|',line) -1))) as [Drive Name]
 ,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('|',line)+1,
 (CHARINDEX('%',line) -1)-CHARINDEX('|',line)) )) as Float),0) as 'Capacity (MB)'
 ,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('%',line)+1,
 (CHARINDEX('*',line) -1)-CHARINDEX('%',line)) )) as Float),0) as 'Freespace (MB)'
from #DriveSpace
where line like '[A-Z][:]%'
--and rtrim(ltrim(SUBSTRING(line,1,CHARINDEX('|',line) -1))) not in ('C:\','D:\')
order by [Drive name]
*/
--script to retrieve the values in GB from PS Script output
select Serverproperty('ServerName') [Server_Name],
rtrim(ltrim(SUBSTRING(line,1,CHARINDEX('|',line) -1))) as [Drive_Name]
 ,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('|',line)+1,
 (CHARINDEX('%',line) -1)-CHARINDEX('|',line)) )) as Float)/1024,1) as 'Total_GB'
 ,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('%',line)+1,
 (CHARINDEX('*',line) -1)-CHARINDEX('%',line)) )) as Float) /1024,1)as 'Free_Space_GB',
 round((round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('%',line)+1,
 (CHARINDEX('*',line) -1)-CHARINDEX('%',line)) )) as Float) /1024,1) /
 round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('|',line)+1,
 (CHARINDEX('%',line) -1)-CHARINDEX('|',line)) )) as Float)/1024,1))*100,2) as 'Free_%'
from #DriveSpace
where line like '[A-Z][:]%'
--and rtrim(ltrim(SUBSTRING(line,1,CHARINDEX('|',line) -1))) not in ('C:\','D:\')
order by [Drive Name]
--script to drop the temporary table
drop table #DriveSpace
--select * from #output
