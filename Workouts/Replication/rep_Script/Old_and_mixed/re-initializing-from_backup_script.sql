
--T-SQL: To enable this publication option we need execute the "sp_changepublication" stored procedure at the Publisher on the publication database.
  EXEC sp_changepublication 
  @publication = 'AW_Remote_Dist', 
  @property = 'allow_initialize_from_backup', 
  @value = 'True'
  GO 

--When immediate sync is on, all changes in the log are tracked immediately after the initial snapshot is generated even if there are no subscriptions. 
  EXEC sp_changepublication 
  @publication = 'AW_Remote_Dist', 
  @property = 'immediate_sync', 
  @value = 'True'
  GO 

  backup database [AdventureWorks2019] to disk ='\\NODE2\LS_Copy_Logfile\AdventureWorks2019_full.bak'
  backup database [AdventureWorks2019] to disk ='\\NODE2\LS_Copy_Logfile\AdventureWorks2019_diff.bak' with differential

  Go to subscriber

  
  restore database [AdventureWorks2019] from disk ='\\NODE2\LS_Copy_Logfile\AdventureWorks2019_full.bak' with replace,norecovery
  restore database [AdventureWorks2019] from disk ='\\NODE2\LS_Copy_Logfile\AdventureWorks2019_diff.bak' with recovery

  
/*
Execute the stored procedure sp_addsubscription at the Publisher on the publication database, 
 Specify the following parameter:
 @sync_type = 'initialize with backup',
   @backupdevicetype = 'Disk',
 @backupdevicename = 'Backup Path'
 */

DECLARE @publication AS sysname;
DECLARE @subscriber AS sysname;
DECLARE @subscriptionDB AS sysname;
SET @publication = N'AW_Remote_Dist';
SET @subscriber = N'Node2';
SET @subscriptionDB = N'AdventureWorks2019';

--Add a push subscription to a transactional publication.
USE [AdventureWorks2019]
EXEC sp_addsubscription 
  @publication = @publication, 
  @subscriber = @subscriber, 
  @destination_db = @subscriptionDB, 
  @subscription_type = N'push',
  @sync_type = 'initialize with backup',
  @backupdevicetype = 'Disk',
  @backupdevicename = '\\NODE2\LS_Copy_Logfile\AdventureWorks2019_diff.bak',
  @update_mode = N'read only';

