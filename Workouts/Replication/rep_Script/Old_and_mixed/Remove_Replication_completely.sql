/*
https://jonathancrozier.com/blog/sql-server-replication-how-to-completely-remove-replication

1) The script below is designed to remove ALL replication objects from your server. 
Please make sure that you only execute this script if you are 100% sure that you want to completely wipe your entire replication setup.

2) In most cases, the publisher and distributor are installed on the same server, simplifying the replication setup. 
If you happen to have your distributor set up on a different server to the publisher, 
then you’ll need to execute the distributor scripts on the distribution server.

3) The stored procedures used in the script apply to all types of SQL Server Replication (Snapshot, Transactional, Merge).
However, some of the stored procedures have arguments that can control how they affect specific types of replication setups
e.g. for the sp_removedbreplication stored procedure you can specify the value of the @type argument as ‘merge’ to 
only remove Merge Replication objects from the database.

*/
-- Declare and set variables.

/*
 use [master]
exec sp_dropdistributor @no_checks = 1
GO
*/

 Manually remove subscriber in publication

-- Remove all replication objects from the publication database.
USE [Muthu_1] -- CHANGE THIS TO THE PUBLICATION DATABASE NAME.
EXEC sp_removedbreplication N'Muthu_2';
 



 --Connect distribution server
-- Remove the publisher registration at the distributor.

USE master
EXEC sp_dropdistpublisher @publisher = 'NODE1'; -- pass pblisher server name
 
-- Delete the distribution database.
EXEC sp_dropdistributiondb  N'distribution';
 
-- Uninstall the local server as a distributor.
EXEC sp_dropdistributor;


-- Delete all folders and files in the share patch
\\NODE2\Repl_Snap_files
