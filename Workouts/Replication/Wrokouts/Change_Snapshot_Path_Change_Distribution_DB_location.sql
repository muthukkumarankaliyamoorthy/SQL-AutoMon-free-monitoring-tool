
--https://www.mssqltips.com/sqlservertip/2785/changing-sql-servers-default-snapshot-folder-for-replication/

/*
You can change the snapshot location without having to perform a re-initialization. 
The only caveat to this is you do need to generate a new snapshot. This snapshot will not be applied to your subscribers, 
but has to go through the generation process. I recommend doing this at night or weekends
to minimize the impact of the snapshot agent locking tables and contention on the publisher database.
*/


-- change snapshot location for all publication
/*Channge path will generate new snapshot BCP file in the new location but this will not apply into subscription*/
USE distribution    
exec sp_changedistpublisher 
    @publisher = 'Node1', 
    @property = 'working_directory', 
    @value = '\\NODE1\New_Repl_Snap_1'



--Move [distribution] DB -- Very smooth change

--------------------------------- note the existing details with logical name

sp_helpdb 'distribution'

distribution	1	C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\distribution.MDF	PRIMARY	58532864 KB	Unlimited	65536 KB	data only
distribution_log	2	C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\distribution.LDF	NULL	180224 KB	2147483648 KB	65536 KB	log only

--Step 2
-- change to new location for both mdf & ldf OR only LDF
-- If you have more MDF and LDF for a single database, you have to do it for each

use master
ALTER DATABASE distribution
MODIFY FILE (NAME = distribution, FILENAME = 'C:\Dist_DB\distribution.mdf');
ALTER DATABASE distribution
MODIFY FILE (NAME = distribution_log, FILENAME = 'C:\Dist_DB\distribution.ldf');


--Step 3
-- single user
ALTER DATABASE distribution SET single_user with rollback immediate
ALTER DATABASE distribution SET OFFLINE
--Step 4

--You can offline (OR) -- stop SQL agent or even SQL service

-- copy & paste the MDF & LDF files
--Step 5
ALTER DATABASE distribution SET ONLINE
ALTER DATABASE distribution SET multi_user
--Step 6
sp_helpdb 'distribution'

-- Once all fine remove the old MDF & LDF
