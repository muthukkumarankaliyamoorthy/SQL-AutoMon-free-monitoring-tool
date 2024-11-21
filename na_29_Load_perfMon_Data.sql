-- set up sp from cms
-- truncate table on target
-- run the sp
-- load the data to cmss
-- Archive the load
/*
drop proc Usp_PerfMon_Data_collection
drop table OSPerfCounters
drop table OSPerfCountersLast
*/

alter proc usp_PerfMon_collector_CMS
as
begin

DECLARE @SERVER_NAME VARCHAR(200)
DECLARE @DESC VARCHAR(200)
DECLARE @Trun VARCHAR(2000)
DECLARE @Ins VARCHAR(2000)

CREATE TABLE #OSPerfCounters(
	ServerName varchar(100) NOT NULL 
    , DateAdded datetime NOT NULL
    , Batch_Requests_Sec int NOT NULL
    , Cache_Hit_Ratio float NOT NULL
    , Free_Memory_KB int   NULL
    , Lazy_Writes_Sec int NOT NULL
    , Memory_Grants_Pending int NOT NULL
    , Deadlocks int NOT NULL
    , Page_Life_Exp int NOT NULL
    , Page_Lookups_Sec int NOT NULL
    , Page_Reads_Sec int NOT NULL
    , Page_Writes_Sec int NOT NULL
    , SQL_Compilations_Sec int NOT NULL
    , SQL_Recompilations_Sec int NOT NULL
    , ServerMemoryTarget_KB int NOT NULL
    , ServerMemoryTotal_KB int NOT NULL
    , Transactions_Sec int NOT NULL
	, LogFlushWaitsSec int NOT NULL
	, UserConnections int NOT NULL
	, FreeListStallsSec int NOT NULL
	, StolenServerMemoryKB int  NULL
	, ForwardedRecordsSec int NOT NULL
	, FullScanssec int NOT NULL
	, IndexSearchessec int NOT NULL
	)

-- truncate data
TRUNCATE TABLE OSPerfCounters
-- local server
exec dbadata.dbo.Usp_PerfMon_Data_collection


DECLARE CMS_PerfMon CURSOR
FOR

SELECT SERVERNAME,	[DESCRIPTION]FROM DBADATA.DBO.DBA_ALL_SERVERS
WHERE  svr_status ='running'
and Version  not in ('sql2000')
AND ([DESCRIPTION] not   IN ('HUGVSQLPROD01.hug.hardygroup.co.uk\VIRTUALCENTRE'))


OPEN CMS_PerfMon
FETCH NEXT FROM CMS_PerfMon INTO @SERVER_NAME,@DESC

WHILE @@FETCH_STATUS=0  
BEGIN
BEGIN TRY

EXEC ('EXEC ['+@SERVER_NAME+'].MASTER.DBO.Usp_PerfMon_Data_collection')

set @Ins ='SELECT * FROM [' + @SERVER_NAME+'].MASTER.DBO.OSPerfCounters'
--print (@Ins) 
INSERT INTO OSPerfCounters
exec (@Ins) 


--EXEC ('INSERT INTO  #OSPerfCounters SELECT * FROM [' + @SERVER_NAME+'].MASTER.DBO.OSPerfCounters')

--SELECT * FROM #OSPerfCounters

--INSERT INTO OSPerfCounters SELECT *  FROM #OSPerfCounters

PRINT 'SERVER ' +@SERVER_NAME+' COMPLETED.'
END TRY

BEGIN CATCH
-- SELECT * from tbl_Error_handling where module_name like '%perf%'
-- delete tbl_Error_handling where module_name like '%perf%'
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'Perfmon',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

PRINT 'SERVER ['+@SERVER_NAME+']is not COMPLETED.'
END CATCH

FETCH NEXT FROM CMS_PerfMon INTO @SERVER_NAME,@DESC
END
CLOSE CMS_PerfMon
DEALLOCATE CMS_PerfMon


DROP TABLE #OSPerfCounters

-- select *,GETDATE() from OSPerfCounters
-- select *,GETDATE() from dbadata_archive..OSPerfCounters
 insert into DBAdata_Archive.dbo.OSPerfCounters select *,GETDATE() from OSPerfCounters


end

