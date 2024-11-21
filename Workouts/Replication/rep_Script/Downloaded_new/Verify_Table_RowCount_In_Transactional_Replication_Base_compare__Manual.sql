select * from DBAUtil.dbo.TBL_Repl_Row_Count_Email_Alert where rowcount_diff >100

select count(*) from HDXDB.dbo.[Home Dynamix, LLC_$Sales Header] -- 11591
select count(*) from [REPL_HDX-DR-SQL01].[HDXDB-BI].dbo.[Home Dynamix, LLC_$Sales Header] --11591


select publisher_srv,publisher_db,source_objectname into tbl_Pub_rowCount_HOMESQL01_Local from DBAUtil.dbo.TBL_Repl_Row_Count_Email_Alert where rowcount_diff >100

select subscriber_srv,subscriber_db,destination_objectname into tbl_Sub_rowCount_HOMESQL01_Local from DBAUtil.dbo.TBL_Repl_Row_Count_Email_Alert where rowcount_diff >100

--drop table tbl_Sub_rowCount_HOMESQL01_Local

select * from tbl_Pub_rowCount_HOMESQL01_Local

select 'insert into tbl_Pub_rowCount_HOMESQL01_Local_join select '''+publisher_srv+'''[subscriber_srv],'''+publisher_db+'''[subscriber_db],'''+source_objectname+'''[destination_objectname],
count(*) [Count] from['+publisher_srv+'].['+publisher_db+'].dbo.['+replace(source_objectname,'dbo.','')+']' from tbl_Pub_rowCount_HOMESQL01_Local


select 'insert into tbl_Sub_rowCount_HOMESQL01_Local_join select '''+subscriber_srv+'''[subscriber_srv],'''+subscriber_db+'''[subscriber_db],'''+destination_objectname+'''[destination_objectname],
count(*) [Count] from['+subscriber_srv+'].['+subscriber_db+'].dbo.['+replace(destination_objectname,'dbo.','')+']' from tbl_Sub_rowCount_HOMESQL01_Local



-- compare row count

SELECT source_objectname,count FROM tbl_Pub_rowCount_HOMESQL01_Local_join
EXCEPT
SELECT [destination_objectname],count FROM tbl_Sub_rowCount_HOMESQL01_Local_join


