/*

CREATE TABLE [dbo].[TBL_Repl_Row_Count_Email_Alert](
	[publisher_srv] [varchar](255) NULL,
	[publisher_db] [varchar](255) NULL,
	[subscriber_srv] [varchar](255) NULL,
	[subscriber_db] [varchar](255) NULL,
	[publication] [varchar](255) NULL,
	[object_type] [varchar](255) NULL,
	[source_objectname] [varchar](511) NULL,
	[destination_objectname] [varchar](511) NULL,
	[rowcount_diff] [int] NULL
)



-- Pub
select 'select count(*) from ['+publisher_db+'].[dbo].['+replace (source_objectname,'DBO.','')+'] with (nolock)' from TBL_Repl_Row_Count_Email_Alert

-- Sub
select 'select count(*) from  ['+subscriber_srv+'].['+subscriber_db+'].[dbo].['+replace (destination_objectname,'DBO.','')+'] with (nolock)' from TBL_Repl_Row_Count_Email_Alert

--select * from sys.objects where name like '%Home Dynamix, LLC_$Sales Line%' and type ='u'

*/

use DBAUtil
go
alter proc USP_Repl_Row_Count
as
begin

truncate table TBL_Repl_Row_Count_Email_Alert
truncate table tempTransReplication

/*
IF OBJECT_ID('tempdb..tempTransReplication') IS NOT NULL 
 DROP TABLE tempTransReplication

CREATE TABLE tempTransReplication
 (
 publisher_id INT,
 publisher_srv VARCHAR(255),
 publisher_db VARCHAR(255),
 publication VARCHAR(255),
 subscriber_id INT,
 subscriber_srv VARCHAR(255),
 subscriber_db VARCHAR(255),
 object_type VARCHAR(255),
 source_owner VARCHAR(255),
 source_object VARCHAR(255),
 destination_owner VARCHAR(255),
 destination_object VARCHAR(255),
 rowcount_publisher INT,
 rowcount_subscriber INT,
 rowcount_diff INT
 )
 */
INSERT INTO tempTransReplication
 SELECT s.publisher_id,
 ss2.data_source,
 a.publisher_db,
 p.publication,
 s.subscriber_id,
 --ss.data_source,
 CASE 
when p.publication ='HDXDB-BI' then UPPER ('REPL_hdx-dr-sql01') 
when p.publication ='HDXDB_Replica' then UPPER ('REPL_hdx-dr-sql01') 
when p.publication ='HDXDB-DR' then UPPER ('REPL_hdx-dr-sql02') 
when p.publication ='HOMESQL01_Local' then UPPER ('REPL_HOMESQL01') 
ELSE UPPER ('Find out') END 'Subscriber' -- pass subscriber name

 ,s.subscriber_db,
 NULL,
 a.source_owner,
 a.source_object,
 ISNULL(a.destination_owner, a.source_owner), -- if NULL, schema name remains same at subscriber side
 a.destination_object,
 NULL,
 NULL,
 NULL
 FROM distribution.dbo.MSarticles AS a
 INNER JOIN distribution.dbo.MSsubscriptions AS s 
ON a.publication_id = s.publication_id
 AND a.article_id = s.article_id
 INNER JOIN [master].sys.servers AS ss 
ON s.subscriber_id = ss.server_id
 INNER JOIN distribution.dbo.MSpublications AS p 
ON s.publication_id = p.publication_id
 LEFT OUTER JOIN [master].sys.servers AS ss2 
ON p.publisher_id = ss2.server_id
 WHERE s.subscriber_db <> 'virtual'
 
 --SELECT  *
--FROM    tempTransReplication



--------------------------------------------------------------------
-- STEP 2: Gather rowcount at Publisher side
--------------------------------------------------------------------

IF OBJECT_ID('tempdb..#tempPublishedArticles') IS NOT NULL 
 DROP TABLE #tempPublishedArticles

CREATE TABLE #tempPublishedArticles
 (
 publisher_db VARCHAR(255),
 source_owner VARCHAR(255),
 source_object VARCHAR(255),
 object_type VARCHAR(255),
 rowcount_publisher INT
 )

DECLARE @pub_db VARCHAR(255),
 @strSQL_P VARCHAR(4000)

DECLARE db_cursor_p CURSOR
 FOR SELECT DISTINCT
 publisher_db
 FROM distribution.dbo.MSpublications

OPEN db_cursor_p 
FETCH NEXT FROM db_cursor_p INTO @pub_db

WHILE @@FETCH_STATUS = 0 
    BEGIN


 SET @strSQL_P = 'SELECT ' + '''' + @pub_db + ''''
            + ' AS publisher_db, s.name AS source_owner, o.name AS source_object, o.Type_Desc AS object_type, i.rows AS rowcount_publisher 
 FROM [' + @pub_db + '].sys.objects AS o 
 INNER JOIN [' + @pub_db + '].sys.schemas AS s 
on o.schema_id = s.schema_id 
 LEFT OUTER JOIN [' + @pub_db + '].sys.partitions AS i 
on o.object_id = i.object_id 
 WHERE ' + '''' + @pub_db + '''' + ' + ' + '''' + '.' + '''' + ' + s.name' + ' + ' + '''' + '.' + '''' + ' + o.name COLLATE DATABASE_DEFAULT' + ' 
 IN (SELECT publisher_db + ' + '''' + '.' + ''''+ ' + source_owner + ' + '''' + '.' + ''''+ ' + source_object FROM tempTransReplication) 
 and o.type_desc = ''USER_TABLE''
 AND i.index_id IN ( 0, 1 )
 ORDER BY i.rows DESC'


-- heap (indid=0); clustered index (indix=1)
INSERT INTO #tempPublishedArticles
 EXEC ( @strSQL_P
 )
 
 FETCH NEXT FROM db_cursor_p INTO @pub_db 
 END
CLOSE db_cursor_p 
DEALLOCATE db_cursor_p

--SELECT  *
--FROM    #tempPublishedArticles
/*

SELECT  * FROM    tempTransReplication
SELECT  publication,subscriber_srv FROM    tempTransReplication group by publication,subscriber_srv
SELECT  * FROM    #tempPublishedArticles

*/

--------------------------------------------------------------------
-- STEP 3: Gather rowcount at Subscriber(s) side
--------------------------------------------------------------------

IF OBJECT_ID('tempdb..#tempSubscribedArticles') IS NOT NULL 
 DROP TABLE #tempSubscribedArticles

CREATE TABLE #tempSubscribedArticles
 (
 subscriber_srv VARCHAR(255),
 subscriber_db VARCHAR(255),
 destination_owner VARCHAR(255),
 destination_object VARCHAR(255),
 object_type VARCHAR(255),
 rowcount_subscriber INT
 )

DECLARE @sub_srv VARCHAR(255),
 @sub_db VARCHAR(255),
 @strSQL_S VARCHAR(4000)

DECLARE db_cursor_s CURSOR
 FOR SELECT DISTINCT
 subscriber_srv,
 subscriber_db
 FROM tempTransReplication  where subscriber_srv not like '%HDX-DR-SQL02%'-- excluded

OPEN db_cursor_s
FETCH NEXT FROM db_cursor_s INTO @sub_srv, @sub_db

WHILE @@FETCH_STATUS = 0 
 BEGIN


SET @strSQL_S = 'SELECT ' + '''' + @sub_srv + '''' + ' AS subscriber_srv, ' + '''' + @sub_db + '''' + ' AS subscriber_db, ' + 's.name AS destination_owner, o.name AS destination_object, o.Type_Desc AS object_type, i.rows AS rowcount_subscriber 
FROM [' + @sub_srv + '].[' + @sub_db + '].sys.objects AS o 
INNER JOIN [' + @sub_srv + '].[' + @sub_db + '].sys.schemas AS s on o.schema_id = s.schema_id
LEFT OUTER JOIN [' + @sub_srv + '].[' + @sub_db + '].sys.partitions AS i on o.object_id = i.object_id

WHERE ' + '''' + @sub_srv + '.' + @sub_db + '''' 
+ ' + ' + '''' + '.' + ''''
 + ' + s.name' + ' + ' + '''' + '.' + '''' + ' + o.name'
 + ' IN (SELECT subscriber_srv + ' + '''' + '.' + ''''
 + ' + subscriber_db + ' + '''' + '.' + ''''
 + ' + destination_owner + ' + '''' + '.' + ''''
 + ' + destination_object FROM tempTransReplication) 
 
and o.type_desc = ''USER_TABLE''
 AND i.index_id IN ( 0, 1 )
 ORDER BY i.rows DESC'


-- heap (indid=0); clustered index (indix=1)
INSERT INTO #tempSubscribedArticles
 EXEC (@strSQL_S)
 --print @strSQL_S

 FETCH NEXT FROM db_cursor_s INTO @sub_srv, @sub_db
 END 
CLOSE db_cursor_s
DEALLOCATE db_cursor_s

--SELECT  *
--FROM    #tempSubscribedArticles



--------------------------------------------------------------------
-- STEP 4: Update table tempTransReplication with rowcount
--------------------------------------------------------------------
--select top 10 * FROM tempTransReplication AS t
--select  top 10  * from #tempPublishedArticles 



UPDATE t
SET rowcount_publisher = p.rowcount_publisher,
 object_type = p.object_type
FROM tempTransReplication AS t
 INNER JOIN #tempPublishedArticles AS p ON t.publisher_db = p.publisher_db
 AND t.source_owner = p.source_owner
 AND t.source_object = p.source_object

--select top 10 * FROM #tempSubscribedArticles AS t
--select  top 10  * from #tempSubscribedArticles 


UPDATE t
SET rowcount_subscriber = s.rowcount_subscriber
FROM tempTransReplication AS t
 INNER JOIN #tempSubscribedArticles AS s ON t.subscriber_srv = s.subscriber_srv
 AND t.subscriber_db = s.subscriber_db
 AND t.destination_owner = s.destination_owner
 AND t.destination_object = s.destination_object

UPDATE tempTransReplication
SET rowcount_diff = ABS(rowcount_publisher - rowcount_subscriber)

--SELECT  *
--FROM    tempTransReplication

/*

Since I am only interested in the replicated tables that fall behind, therefore I filter the object_type to be 'USER_TABLE' and the rowcount_diff to be greater than 0.
The first result displays the sum of rowcount_diff by database. Second result shows the sum of rowcount_diff by publication. 
The last result displays the sum of rowcount_diff by table.

If all three results happen to return nothing, that means there are no difference in rowcount between Publisher and Subscriber(s). 
This also means your transactional replication is totally synced up in term of rowcount.

*/

--------------------------------------------------------------------
-- STEP 5: Display final results
--------------------------------------------------------------------

-- rowcount result by replicated database
/*

SELECT publisher_srv,
 publisher_db,
 subscriber_srv,
 subscriber_db,
 sum(rowcount_diff) AS rowcount_diff
FROM tempTransReplication
WHERE object_type = 'USER_TABLE' -- tables only
GROUP BY publisher_srv,
 publisher_db,
 subscriber_srv,
 subscriber_db
HAVING sum(rowcount_diff) > 0 -- only show those databases which fall behind
ORDER BY rowcount_diff DESC

*/
/*

-- rowcount result by publication
SELECT publisher_srv,
 publisher_db,
 publication,
 subscriber_srv,
 subscriber_db,
 sum(rowcount_diff) AS rowcount_diff
FROM tempTransReplication
WHERE object_type = 'USER_TABLE' -- tables only
GROUP BY publisher_srv,
 publisher_db,
 publication,
 subscriber_srv,
 subscriber_db
HAVING sum(rowcount_diff) > 0 -- only show those publications which fall behind
ORDER BY rowcount_diff DESC

*/

-- rowcount result by table
--select * from DBAUtil.dbo.TBL_Repl_Row_Count_Email_Alert

insert into DBAUtil.dbo.TBL_Repl_Row_Count_Email_Alert

SELECT publisher_srv,
 publisher_db,
 subscriber_srv,
 subscriber_db,
 publication,
 object_type,
 ( source_owner + '.' + source_object ) AS source_objectname,
 ( destination_owner + '.' + destination_object ) AS destination_objectname,
 rowcount_diff AS rowcount_diff  
FROM tempTransReplication
WHERE object_type = 'USER_TABLE' -- tables only 
AND rowcount_diff > 0 -- only show those tables which fall behind
ORDER BY rowcount_diff DESC


/*
SUMMARY
I have shown how to use T-SQL to access system tables from both master and distribution databases to obtain information about your current transaction replication. 
I have also demonstrated how to use system tables from each replicated database to obtain the rowcount for each replicated table,
and then verify results between Publisher and Subscriber(s) to make sure these replicated tables are indeed synced-up. 
As mentioned in the beginning of this article, this script also provides a complete view of your current transactional replication setup. 
The query below will give you just that!


*/
--------------------------------------------------------------------
-- information about current transactional replication setup
--------------------------------------------------------------------
/*

SELECT  publisher_srv,
        publisher_db,
        subscriber_srv,
        subscriber_db,
        publication,
        object_type,
        ( source_owner + '.' + source_object ) AS source_objectname,
        ( destination_owner + '.' + destination_object ) AS destination_objectname,
        rowcount_publisher 
FROM    tempTransReplication
ORDER BY publisher_srv,
        publisher_db,
        subscriber_srv,
        subscriber_db,
        publication,
        object_type,
        source_objectname,
        rowcount_publisher
*/

/********************************************************************
END OF SCRIPT
*********************************************************************/

End


