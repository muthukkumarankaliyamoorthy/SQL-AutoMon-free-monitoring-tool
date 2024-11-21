/*
https://www.youtube.com/watch?v=wAP_tykTHdY

Pre request:

You need to drop the tables in subscripber since backup and restore will take whole DB. Remove tables, 
if any filter n column and rows make sure to remove that 

For existing Connect to the Publisher and remove the subscription
For new replication create the publication with out snapshot both option

Trun on Allow initialized from backup - true

*/

/*
USE muthu
GO

EXEC sp_replicationdboption
	@dbname = N'muthu', 
	@optname = N'publish', 
	@value = N'true'
GO

*/
--T-SQL: To enable this publication option we need execute the "sp_changepublication" stored procedure at the Publisher on the publication database.
  EXEC sp_changepublication 
  @publication = 'muthu_Replica', 
  @property = 'allow_initialize_from_backup', 
  @value = 'True'
  GO 

--When immediate sync is on, all changes in the log are tracked immediately after the initial snapshot is generated even if there are no subscriptions. 
  EXEC sp_changepublication 
  @publication = 'muthu_Replica', 
  @property = 'immediate_sync', 
  @value = 'True'
  GO 

  backup database [muthu] to disk ='\\NODE2\LS_Copy_Logfile\muthu_Replica_full.bak'
  backup database [muthu] to disk ='\\NODE2\LS_Copy_Logfile\muthu_Replica_diff.bak' with differential

  Go to subscriber

  use master
alter database [muthu_Replica] set single_user with rollback immediate
  restore database [muthu_Replica] from disk ='\\NODE2\LS_Copy_Logfile\muthu_Replica_full.bak' with replace,norecovery
  restore database [muthu_Replica] from disk ='\\NODE2\LS_Copy_Logfile\muthu_Replica_diff.bak' with recovery

  
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
SET @publication = N'muthu_Replica';
SET @subscriber = N'Node2';
SET @subscriptionDB = N'muthu_Replica';

--Add a push subscription to a transactional publication.
USE [muthu_Replica]
EXEC sp_addsubscription 
  @publication = @publication, 
  @subscriber = @subscriber, 
  @destination_db = @subscriptionDB, 
  @subscription_type = N'push',
  @sync_type = 'initialize with backup',
  @backupdevicetype = 'Disk',
  @backupdevicename = '\\NODE2\LS_Copy_Logfile\muthu_Replica_diff.bak',
  @update_mode = N'read only';

-- You will get this error - This database is not enabled for publication.. This can be ignored

Go to subscription property and make sure to have correct distribution agent account. 
MUTHU\Svc_repl_distributer -- G0d$peed

Verify the replication status
Do some DML
Add one more new article and see all working as expected

