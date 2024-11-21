
--https://www.sqlservercentral.com/scripts/find-all-published-tables-with-row-counts-and-table-size

-- create table with only the names of databases that are published
SELECT name as [DatabaseName]
INTO #tmpPubDatabases
FROM sys.databases
WHERE database_id > 4
AND is_published = 1; 


-- create table to hold the table info (name, schema,row count, space used)
CREATE TABLE #tmpTableSizes(
DBName VARCHAR(256),
SchemaName VARCHAR(256),
TableName VARCHAR(256),
RowCounts INT,
TotalSpaceMB DECIMAL(18,2)
);


DECLARE @command VARCHAR(MAX);


-- run this in all the databases that have publications 
SET @command = '
USE [HDXDB]

IF DB_NAME() IN (SELECT DatabaseName FROM #tmpPubDatabases)
BEGIN
INSERT #tmpTableSizes
SELECT 
db_Name(),
s.Name AS SchemaName,
t.NAME AS TableName,
p.rows AS RowCounts,
(SUM(a.total_pages) * 8)/1024.0 AS TotalSpaceMB
FROM 
sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE 
t.NAME NOT LIKE ''dt%'' 
AND t.is_ms_shipped = 0
AND i.OBJECT_ID > 255
--AND t.Name IN ()
GROUP BY 
t.Name, s.Name, p.Rows
ORDER BY 
t.Name
END';

-- run for all affected databases
EXEC sp_MSforeachdb @command


-- this will match the publications to the tables and give the you row count and sizes
-- run this in the distribution database

SELECT
     P.[publication]   AS [PublicationName]
    ,A.[publisher_db]  AS [DatabaseName]
    ,A.[article]       AS [ArticleName]
    ,A.[source_owner]  AS [Schema]
    ,A.[source_object] AS [Table]
,T.RowCounts
,T.TotalSpaceMB
FROM
    [distribution].[dbo].[MSarticles] AS A
    INNER JOIN [distribution].[dbo].[MSpublications] AS P ON (A.[publication_id] = P.[publication_id])
LEFT JOIN #tmpTableSizes T ON A.[publisher_db] = T.DBName AND A.[source_owner] = T.SchemaName AND A.[source_object] = T.TableName
where P.[publication] ='HDXDB-DR'
ORDER BY
    P.[publication], A.[article];


-- clean up
DROP TABLE #tmpTableSizes;
DROP TABLE #tmpPubDatabases;
