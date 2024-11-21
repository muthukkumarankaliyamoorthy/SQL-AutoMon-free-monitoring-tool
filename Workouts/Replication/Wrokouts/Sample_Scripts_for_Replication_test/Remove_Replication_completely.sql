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

 --Manually remove subscriber
 --Manually remove publication
 
--Run this for all replicated Dbs


--other method
--====================

--https://jonathancrozier.com/blog/sql-server-replication-how-to-completely-remove-replication

--/*
--on sub
-- Remove replication objects from the subscription database on MYSUB.
DECLARE @subscriptionDB AS sysname
SET @subscriptionDB = N'Muthu_Replica'

-- Remove replication objects from a subscription database (if necessary).
USE master
EXEC sp_removedbreplication @subscriptionDB
GO


--*/ on pub

-- Declare and set variables.
DECLARE @distributionDB SYSNAME;
DECLARE @publisher      SYSNAME;
DECLARE @publicationDB  SYSNAME;
 
SET @distributionDB = N'distribution';   -- CHANGE THIS TO THE DISTRIBUTION DATABASE NAME.
SET @publisher      = N'node1';   -- CHANGE THIS TO THE PUBLISHER NAME.
SET @publicationDB  = N'muthu'; -- CHANGE THIS TO THE PUBLICATION DATABASE NAME.
 
-- Remove all replication objects from the publication database.
USE muthu -- CHANGE THIS TO THE PUBLICATION DATABASE NAME.
EXEC sp_removedbreplication @publicationDB;
 
-- Remove the publisher registration at the distributor.
USE master
EXEC sp_dropdistpublisher @publisher;
 
-- Delete the distribution database.
EXEC sp_dropdistributiondb @distributionDB;
 
-- Uninstall the local server as a distributor.
EXEC sp_dropdistributor;

use muthu
select 'Drop view ['+name+']',* from sys.objects where name like 'sync%'

 use [master]
exec sp_dropdistributor @no_checks = 1


-- Delete all folders and files in the share patch
\\NODE2\Repl_Snap_files

-- on node2
/*
Drop database [HDXDB_DR]
Drop database [HDXDB-BI]
Drop database [HDXDB_Replica]
go
create database [HDXDB_DR]
create database [HDXDB-BI]
create database [HDXDB_Replica]

*/


SELECT  HOST_NAME() AS 'host_name()',
@@servername AS 'ServerName\InstanceName',
SERVERPROPERTY('servername') AS 'ServerName',
SERVERPROPERTY('machinename') AS 'Windows_Name',
SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS 'NetBIOS_Name',
SERVERPROPERTY('instanceName') AS 'InstanceName',
SERVERPROPERTY('IsClustered') AS 'IsClustered'

/*
EXEC sp_DROPSERVER 'NODE2'
go
EXEC sp_ADDSERVER 'NODE2', 'local'
*/


USE [HDXDB] -- CHANGE THIS TO THE PUBLICATION DATABASE NAME.
EXEC sp_removedbreplication N'[HDXDB]';
 
--remove LS
-- Remove all replication objects from the publication database.



---------------- Remove LS manually
--- Important if the above did not work
use master
go
alter database [HDXDB] set single_user with rollback immediate
go
Drop database [HDXDB]

Drop database [HDXDB_DR]
Drop database [HDXDB-BI]
Drop database [HDXDB_Replica]
go
create database [HDXDB_DR]
create database [HDXDB-BI]
create database [HDXDB_Replica]