--https://sqlconjuror.com/sql-server-re-initializing-single-article-transaction-replication/

-- 1.  Turn off @allow_anonymous and @immediate_sync on the publication.

use [Muthu_2]
go
EXEC sp_changepublication
@publication = 'Pub_Muthu_2',
@property = N'allow_anonymous',
@value = 'false'
GO
               
EXEC sp_changepublication
@publication = 'Pub_Muthu_2',
@property = N'immediate_sync',
@value = 'false'
GO
--The reason we have to disable @immediate_sync is that everytime you add a new article, and if @immediate_sync is enabled, it will cause the entire snapshot to be applied. Our objective is to only apply a particular article.

--2.  Add new article and invalidate snapshot.
--select * from [Person].[Person]
EXEC sp_addarticle
@publication = 'Pub_Muthu_2',
@article = 'T9',
@source_object = 'T9',
--@source_owner ='Person',
@force_invalidate_snapshot = 1


--3.  Refresh the subscription

EXEC sp_refreshsubscriptions @publication = 'Pub_Muthu_2'
GO
--4.  Check the current snapshot agent history.

use distribution
go
select * from dbo.MSsnapshot_history order by start_time desc
--5.  Start Snapshot agent.

use Muthu_2
EXEC sp_startpublication_snapshot @publication = 'Pub_Muthu_2';
GO


DECLARE @publication AS sysname;
DECLARE @subscriber AS sysname;
DECLARE @subscriptionDB AS sysname;
SET @publication = N'Pub_Muthu_2';
SET @subscriber = N'Node2';
SET @subscriptionDB = N'Muthu_2';

--Add a push subscription to a transactional publication.
USE [Muthu_2]
EXEC sp_addsubscription 
  @publication = @publication, 
  @subscriber = @subscriber, 
  @destination_db = @subscriptionDB, 
  @subscription_type = N'push',
   @sync_type = 'automatic',
  @update_mode = 'read only';

  -- connect the publisher again
use Muthu_2
EXEC sp_startpublication_snapshot @publication = 'Pub_Muthu_2';
GO

--6.  Check the Snapshot Agent history again. You should see a snapshot generated only for the newly added article/s.

--7.  Turn ON @allow_anonymous and @immediate_sync on the publication.

use Muthu_2
go

EXEC sp_changepublication
@publication = 'Pub_Muthu_2',
@property = N'immediate_sync',
@value = 'true'
GO


EXEC sp_changepublication
@publication = 'Pub_Muthu_2',
@property = N'allow_anonymous',
@value = 'true'
GO
