USE [DBAUtil]
GO

/****** Object:  StoredProcedure [dbo].[USP_Repl_Column_Count]    Script Date: 2/2/2024 4:15:30 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[USP_Repl_Column_Count]
as
begin

-- select * from TBL_Repl_Column_Count_Email_Alert
-- select * from tempTransReplication_Col_Count

truncate table TBL_Repl_Column_Count_Email_Alert
truncate table tempTransReplication_Col_Count

/*
IF OBJECT_ID('tempdb..tempTransReplication_Col_Count') IS NOT NULL 
 DROP TABLE tempTransReplication_Col_Count

CREATE TABLE tempTransReplication_Col_Count
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
 Col_count_publisher INT,
 Col_count_subscriber INT,
 Col_count_diff INT
 )

 */

INSERT INTO tempTransReplication_Col_Count

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

 ISNULL(a.source_owner,'dbo') as source_owner,
 a.source_object,
  --ISNULL(a.destination_owner, a.source_owner), -- if NULL, schema name remains same at subscriber side
  case
 when a.destination_owner is null then 'dbo' END 'destination_owner',
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
 and p.publication <>'HDXDB-DR'
 
 -- SELECT  * FROM    tempTransReplication_Col_Count



--------------------------------------------------------------------
-- STEP 2: Gather Columncount at Publisher side
--------------------------------------------------------------------

IF OBJECT_ID('tempdb..#tempPublishedArticles_Col') IS NOT NULL 
 DROP TABLE #tempPublishedArticles_Col

CREATE TABLE #tempPublishedArticles_Col
 (
 publisher_db VARCHAR(255),
 source_owner VARCHAR(255),
 source_object VARCHAR(255),
 object_type VARCHAR(255),
 Col_count_publisher INT
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
            + ' AS publisher_db, s.name AS source_owner, o.name AS source_object, o.Type_Desc AS object_type, COUNT(*) AS Colcount_publisher
 FROM [' + @pub_db + '].sys.columns AS c
 INNER JOIN [' + @pub_db + '].sys.objects AS o
on c.object_id = o.object_id
 INNER JOIN [' + @pub_db + '].sys.schemas AS s 
on o.schema_id = s.schema_id
 WHERE ' + '''' + @pub_db + '''' + ' + ' + '''' + '.' + '''' + ' + s.name' + ' + ' + '''' + '.' + '''' + ' + o.name COLLATE DATABASE_DEFAULT' + ' 
 IN (SELECT publisher_db + ' + '''' + '.' + ''''+ ' + source_owner + ' + '''' + '.' + ''''+ ' + source_object FROM tempTransReplication_Col_Count) 
 and o.type_desc = ''USER_TABLE''
 --AND i.index_id IN ( 0, 1 )
 GROUP BY o.name, s.name, o.type_desc
 ORDER BY COUNT(*) DESC'


-- heap (indid=0); clustered index (indix=1)
INSERT INTO #tempPublishedArticles_Col
 EXEC ( @strSQL_P)
 --print @strSQL_P
 FETCH NEXT FROM db_cursor_p INTO @pub_db 
 END
CLOSE db_cursor_p 
DEALLOCATE db_cursor_p

--SELECT  *
--FROM    #tempPublishedArticles_Col
/*

SELECT  * FROM    tempTransReplication_Col_Count
SELECT  publication,subscriber_srv FROM    tempTransReplication_Col_Count group by publication,subscriber_srv
SELECT  * FROM    #tempPublishedArticles_Col

*/

--/*
--------------------------------------------------------------------
-- STEP 3: Gather Columncount at Subscriber(s) side
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
 Col_count_subscriber INT
 )

DECLARE @sub_srv VARCHAR(255),
 @sub_db VARCHAR(255),
 @strSQL_S VARCHAR(4000)

DECLARE db_cursor_s CURSOR
 FOR SELECT DISTINCT
 subscriber_srv,
 subscriber_db
 FROM tempTransReplication_Col_Count  where subscriber_srv not like '%HDX-DR-SQL02%'-- excluded

OPEN db_cursor_s
FETCH NEXT FROM db_cursor_s INTO @sub_srv, @sub_db

WHILE @@FETCH_STATUS = 0 
 BEGIN



SET @strSQL_S = 'SELECT ' + '''' + @sub_srv + '''' + ' AS subscriber_srv, ' + '''' + @sub_db + '''' + ' AS subscriber_db, ' + 's.name AS destination_owner, o.name AS destination_object, o.Type_Desc AS object_type,  COUNT(*) AS Col_count_subscriber 
FROM [' + @sub_srv + '].[' + @sub_db + '].sys.columns AS c 
INNER JOIN [' + @sub_srv + '].[' + @sub_db + '].sys.objects AS o 
on c.object_id = o.object_id
INNER JOIN [' + @sub_srv + '].[' + @sub_db + '].sys.schemas AS s 
on o.schema_id = s.schema_id

WHERE ' + '''' + @sub_srv + '.' + @sub_db + '''' 
+ ' + ' + '''' + '.' + ''''
 + ' + s.name' + ' + ' + '''' + '.' + '''' + ' + o.name'
 + ' IN (SELECT subscriber_srv + ' + '''' + '.' + ''''
 + ' + subscriber_db + ' + '''' + '.' + ''''
 + ' + destination_owner + ' + '''' + '.' + ''''
 + ' + destination_object FROM tempTransReplication_Col_Count) 
 
and o.type_desc = ''USER_TABLE''
 --AND i.index_id IN ( 0, 1 )
 GROUP BY o.name, s.name, o.type_desc
 ORDER BY COUNT(*) DESC'


-- heap (indid=0); clustered index (indix=1)
INSERT INTO #tempSubscribedArticles
 EXEC (@strSQL_S)
 --print @strSQL_S

 FETCH NEXT FROM db_cursor_s INTO @sub_srv, @sub_db
 END 
CLOSE db_cursor_s
DEALLOCATE db_cursor_s

--SELECT  * FROM    #tempSubscribedArticles



--------------------------------------------------------------------
-- STEP 4: Update table tempTransReplication_Col_Count with Columncount
--------------------------------------------------------------------
--select top 10 * FROM tempTransReplication_Col_Count AS t
--select  top 10  * from #tempPublishedArticles_Col 



UPDATE t
SET Col_count_publisher = p.Col_count_publisher,
 object_type = p.object_type
FROM tempTransReplication_Col_Count AS t
 INNER JOIN #tempPublishedArticles_Col AS p ON t.publisher_db = p.publisher_db
 AND t.source_owner = p.source_owner
 AND t.source_object = p.source_object

--select top 10 * FROM #tempSubscribedArticles AS t
--select  top 10  * from #tempSubscribedArticles 


UPDATE t
SET Col_count_subscriber = s.Col_count_subscriber
FROM tempTransReplication_Col_Count AS t
 INNER JOIN #tempSubscribedArticles AS s ON t.subscriber_srv = s.subscriber_srv
 AND t.subscriber_db = s.subscriber_db
 AND t.destination_owner = s.destination_owner
 AND t.destination_object = s.destination_object

UPDATE tempTransReplication_Col_Count
SET Col_count_diff = ABS(Col_count_publisher - Col_count_subscriber)

--SELECT  *
--FROM    tempTransReplication_Col_Count

/*

Since I am only interested in the replicated tables that fall behind, therefore I filter the object_type to be 'USER_TABLE' and the Col_count_diff to be greater than 0.
The first result displays the sum of Col_count_diff by database. Second result shows the sum of Col_count_diff by publication. 
The last result displays the sum of Col_count_diff by table.

If all three results happen to return nothing, that means there are no difference in Columncount between Publisher and Subscriber(s). 
This also means your transactional replication is totally synced up in term of Columncount.

*/

--------------------------------------------------------------------
-- STEP 5: Display final results
--------------------------------------------------------------------

-- Columncount result by replicated database
/*

SELECT publisher_srv,
 publisher_db,
 subscriber_srv,
 subscriber_db,
 sum(Col_count_diff) AS Col_count_diff
FROM tempTransReplication_Col_Count
WHERE object_type = 'USER_TABLE' -- tables only
GROUP BY publisher_srv,
 publisher_db,
 subscriber_srv,
 subscriber_db
HAVING sum(Col_count_diff) > 0 -- only show those databases which fall behind
ORDER BY Col_count_diff DESC

*/
/*

-- Columncount result by publication
SELECT publisher_srv,
 publisher_db,
 publication,
 subscriber_srv,
 subscriber_db,
 sum(Col_count_diff) AS Col_count_diff
FROM tempTransReplication_Col_Count
WHERE object_type = 'USER_TABLE' -- tables only
GROUP BY publisher_srv,
 publisher_db,
 publication,
 subscriber_srv,
 subscriber_db
HAVING sum(Col_count_diff) > 0 -- only show those publications which fall behind
ORDER BY Col_count_diff DESC

*/

-- Columncount result by table
--select * from DBAUtil.dbo.TBL_Repl_Column_Count_Email_Alert

insert into DBAUtil.dbo.TBL_Repl_Column_Count_Email_Alert

SELECT publisher_srv,
 publisher_db,
 subscriber_srv,
 subscriber_db,
 publication,
 object_type,
 ( source_owner + '.' + source_object ) AS source_objectname,
 ( destination_owner + '.' + destination_object ) AS destination_objectname,
 Col_count_diff AS Col_count_diff  
FROM tempTransReplication_Col_Count
WHERE object_type = 'USER_TABLE' -- tables only 
AND Col_count_diff > 0 -- only show those tables which fall behind
ORDER BY Col_count_diff DESC


/*
SUMMARY
I have shown how to use T-SQL to access system tables from both master and distribution databases to obtain information about your current transaction replication. 
I have also demonstrated how to use system tables from each replicated database to obtain the Columncount for each replicated table,
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
        Col_count_publisher 
FROM    tempTransReplication_Col_Count
ORDER BY publisher_srv,
        publisher_db,
        subscriber_srv,
        subscriber_db,
        publication,
        object_type,
        source_objectname,
        Col_count_publisher
*/

/********************************************************************
END OF SCRIPT
*********************************************************************/
--*/

End


GO


