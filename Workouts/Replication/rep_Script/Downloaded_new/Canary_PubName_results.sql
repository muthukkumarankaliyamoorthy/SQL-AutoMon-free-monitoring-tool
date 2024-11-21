

--HOMESQL01_Local

SELECT @@servername AS [ServerName] ,
'HOMESQL01_Local' [Pulisher Name],
'homesql01\homesql01'[Subscriber Server],
'HDXDB_Replica'[Subscriber DB],
GETDATE() AS [CurrentTime] ,
Currenttime AS [ReplicationTime] ,
CONVERT (VARCHAR(10), DATEDIFF(mi, currenttime, getdate()) / 1440)
+ ':' + CONVERT (VARCHAR(10), ( DATEDIFF(mi, currenttime, getdate())
% 1440 ) / 60) + ':'
+ CONVERT (VARCHAR(10), ( DATEDIFF(mi, currenttime, getdate()) % 60 )) AS [LAG DD:HH:MM]
FROM [HDXDB_Replica].DBO.Canary_PubName

--HDXDB-BI
SELECT @@servername AS [ServerName] ,
'HDXDB-BI' [Pulisher Name],
'hdx-dr-sql01'[Subscriber Server],
'HDXDB-BI'[Subscriber DB],
GETDATE() AS [CurrentTime] ,
[Currenttime] AS [ReplicationTime] ,
CONVERT (VARCHAR(10), DATEDIFF(mi, Currenttime, getdate()) / 1440)+ ':' + CONVERT (VARCHAR(10), ( DATEDIFF(mi, Currenttime, getdate())% 1440 ) / 60) + ':'+ CONVERT (VARCHAR(10), ( DATEDIFF(mi, Currenttime, getdate()) % 60 )) AS [LAG DD:HH:MM]
FROM [repl_hdx-dr-sql01].[hdxdb-bi].dbo.Canary_PubName

--HDXDB_Replica
SELECT @@servername AS [ServerName] ,
'HDXDB_Replica' [Pulisher Name],
'hdx-dr-sql01'[Subscriber Server],
'HDXDB_Replica'[Subscriber DB],
GETDATE() AS [CurrentTime] ,
Currenttime AS [ReplicationTime] ,
CONVERT (VARCHAR(10), DATEDIFF(mi, Currenttime, getdate()) / 1440)+ ':' + CONVERT (VARCHAR(10), ( DATEDIFF(mi, Currenttime, getdate())% 1440 ) / 60) + ':'+ CONVERT (VARCHAR(10), ( DATEDIFF(mi, Currenttime, getdate()) % 60 )) AS [LAG DD:HH:MM]
FROM [REPL_hdx-dr-sql01].[HDXDB_Replica].DBO.Canary_PubName


/*

SELECT @@servername AS [ServerName] ,
'HDXDB-DR' [Pulisher Name],
'hdx-dr-sql02'[Subscriber Server],
'HDXDB'[Subscriber DB],
GETDATE() AS [CurrentTime] ,
Currenttime AS [ReplicationTime] ,
CONVERT (VARCHAR(10), DATEDIFF(mi, currenttime, getdate()) / 1440)
+ ':' + CONVERT (VARCHAR(10), ( DATEDIFF(mi, currenttime, getdate())
% 1440 ) / 60) + ':'
+ CONVERT (VARCHAR(10), ( DATEDIFF(mi, currenttime, getdate()) % 60 )) AS [LAG DD:HH:MM]
FROM [REPL_hdx-dr-sql02].[HDXDB].DBO.Canary_PubName

*/


/*

*/