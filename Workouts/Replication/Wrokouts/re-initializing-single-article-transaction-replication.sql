--https://sqlconjuror.com/sql-server-re-initializing-single-article-transaction-replication/

-- 1.  Turn off @allow_anonymous and @immediate_sync on the publication.

-- Drop article from existing replication
use muthu
go
EXEC sys.sp_dropsubscription
@publication = 'muthu_Replica',
@article = 'Repl_Tbl5', 
@subscriber = 'Node2', 
@destination_db = 'muthu_Replica'

EXEC sys.sp_droparticle @publication = 'muthu_Replica',
@article = 'Repl_Tbl5',
@force_invalidate_snapshot = 0



/*
muthu_DR --Node2
muthu_DR --Node3
muthu_DR --Node2
muthu_DR--Node1

*/

use [muthu]
go
EXEC sp_changepublication
@publication = 'muthu_Replica',
@property = N'allow_anonymous',
@value = 'false'
GO
               
EXEC sp_changepublication
@publication = 'muthu_Replica',
@property = N'immediate_sync',
@value = 'false'
GO
--The reason we have to disable @immediate_sync is that everytime you add a new article, and if @immediate_sync is enabled, it will cause the entire snapshot to be applied. Our objective is to only apply a particular article.

--2.  Add new article and invalidate snapshot.
--select * from [Person].[Person]

EXEC sp_addarticle
@publication = 'muthu_Replica',
@article = 'Repl_Tbl5',
@source_object = 'Repl_Tbl5',
--@source_owner ='Person',
@force_invalidate_snapshot = 1


--3.  Refresh the subscription

EXEC sp_refreshsubscriptions @publication = 'muthu_Replica'
GO
--4.  Check the current snapshot agent history.

use distribution
go
select * from dbo.MSsnapshot_history order by start_time desc
--5.  Start Snapshot agent.

--use muthu
--EXEC sp_startpublication_snapshot @publication = 'muthu_Replica';
--GO

/*
muthu_DR --Node2
muthu_DR --Node3
muthu_DR --Node2
muthu_DR--Node1
*/

DECLARE @publication AS sysname;
DECLARE @subscriber AS sysname;
DECLARE @subscriptionDB AS sysname;
SET @publication = N'muthu_Replica';
SET @subscriber = N'Node2'; -- change
SET @subscriptionDB = N'muthu_Replica'; --chnage

--Add a push subscription to a transactional publication.
USE [muthu]
EXEC sp_addsubscription 
  @publication = @publication, 
  @subscriber = @subscriber, 
  @destination_db = @subscriptionDB, 
  @subscription_type = N'push',
   @sync_type = 'automatic',
  @update_mode = 'read only',
  @reserved='Internal';

  -- connect the publisher again
use muthu
EXEC sp_startpublication_snapshot @publication = 'muthu_Replica';
GO

--6.  Check the Snapshot Agent history again. You should see a snapshot generated only for the newly added article/s.
use distribution
go
select * from dbo.MSsnapshot_history order by start_time desc

select A.publication,H.* from dbo.MSsnapshot_history H join MSsnapshot_agents A on h.agent_id =A.ID order by start_time desc
where comments like '%Snapshot of%' order by start_time desc

--7.  Turn ON @allow_anonymous and @immediate_sync on the publication.

use muthu
go

EXEC sp_changepublication
@publication = 'muthu_Replica',
@property = N'immediate_sync',
@value = 'true'
GO


EXEC sp_changepublication
@publication = 'muthu_Replica',
@property = N'allow_anonymous',
@value = 'true'
GO
