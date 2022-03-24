SELECT top 1 b.database_name, f.physical_device_name,datediff (hour,b.backup_start_date,b.backup_finish_date) as minutess,
b.backup_start_date,b.backup_finish_date,b.backup_size /1024/1024 AS size_MB,b.type
--b.has_bulk_logged_data,b.is_copy_only,f.mirror--,compressed_backup_size/1024/1024 AS C_size_MB
FROM MSDB.DBO.BACKUPMEDIAFAMILY F
JOIN MSDB.DBO.BACKUPSET B
ON (f.media_set_id=b.media_set_id)
WHERE b.backup_finish_date >'2017-01-07 03:09:20.000'
and f.physical_device_name like '\\%'
ORDER BY b.backup_size /1024/1024 DESC

--2017-05-06 23:25:34.000	2017-05-07 03:28:52.000