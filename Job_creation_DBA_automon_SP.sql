
-- DBA_AutoMon_Blocking_Log_running_job_alert Every 30 Minutes
EXEC [DBAdata].[dbo].[USP_DBA_GET_Blocking_running_Details]
EXEC [DBAdata].[dbo].[USP_DBA_GET_Long_running_Details]

--DBA_AutoMon_AG_job_alert
EXEC [DBAdata].[dbo].[Usp_Alwayson_Quorum]
EXEC [DBAdata].[dbo].[Usp_Alwayson_Monitoring]
EXEC [DBAdata].[dbo].[usp_check_alwayson_lag]


-- DBA_AutoMon_Database_File_job_alert Every 1 hours
EXEC [DBAdata].[dbo].[Usp_dba_send_logfiles_size] @disk_low_threshold =5000, @Log_growth_threshold =10000
EXEC [DBAdata].[dbo].[Usp_dba_send_DATAfiles_size] @disk_free_threshold = 5000 -- alert less than 5 gb drive free
Exec [DBAdata].[dbo].[Usp_dba_send_logfiles_huge] @Log_Big_threshold = 500000,@drivefreespace=100000 -- alert big log file
EXEC [DBAdata].[dbo].[Usp_dba_send_DATAfiles_size_Express_limit_check]
EXEC [DBAdata].[dbo].[USP_recovery_model_Non_prod]
EXEC [DBAdata].[dbo].[USP_recovery_model_pord]
EXEC [DBAdata].[dbo].[USP_Large_logfile_sync_with_recovery_model_check] @P_log_size = 50000, @P_freespace =50000

-- DBA_AutoMon_Disk_Space_job_alert Every 1 hours
EXEC [DBAdata].[dbo].[USP_DBA_GETSERVERSPACE_Plain] @Free_Space_threshold = 5000
EXEC [DBAdata].[dbo].[USP_DBA_GETSERVERSPACE] @Free_Space_threshold_percentage= 10, @P_FREE_SPACE_IN_MB=80000
--EXEC [DBAdata].[dbo].USP_drivespace_mount_point_All
--EXEC [DBAdata].[dbo].USP_drivespace_mount_point_All_New


-- DBA_AutoMon_Morning_job_alert @ 6 AM every day
update DBADATA.DBO.DBA_ALL_SERVERS set svr_status ='Running' where svr_status ='not ping_U' 
EXEC [DBAdata].[dbo].[usp_ping_server_morethan_5_fail_status_change]
EXEC [DBAdata].[dbo].[USP_DBA_No_full_backup]
EXEC [DBAdata].[dbo].[USP_DBA_GETNEW_DB_AND_LOGIN]
EXEC [DBAdata].[dbo].[Usp_agent_status]
Exec [DBAdata].[dbo].[USP_DBA_AutoMon_server_Report]
Exec [DBAdata].[dbo].[USP_DBA_GETSERVERSPACE_percentage] @P_Precentage_free= 10 -- less than 10 % alert
Exec [DBAdata].[dbo].[USP_DBA_ErrorHandling_Report]
Exec [DBAdata].[dbo].[Usp_Automon_job_status]
Exec [DBAdata].[dbo].[USP_DBA_GETFAILEDJOBS_last_one_day_new]
Exec [DBAdata].[dbo].[Usp_Linked_server_Status_Check]
--EXEC [DBAdata].dbo.[USP_DBA_GET_FILER_SPACE]
Exec [DBAdata].[dbo].[Usp_load_sys_databases]
Exec [DBAdata].[dbo].[Usp_load_sys_processes]
Exec [DBAdata].[dbo].[Usp_last_run_date_with_duration]

--DBA_AutoMon_Resource_CPU_RAM_job_alert Every 4 Hours or 8 Hours
Exec DBAdata.[dbo].[Usp_CPU_alert] @SQL_CPU_utilization = 90, @other_process = 90
Exec DBAdata.[dbo].[Usp_Memory_alert_2012_New] @P_PLE = 300 -- alert low PLE


-- DBA_AutoMon_Server_DB_online_job_alert - Every 2 Minute
EXEC [DBAdata].[dbo].[usp_prdServerPing_1]
EXEC [DBAdata].[dbo].[Usp_DB_Online_status]
--EXEC [DBAdata].[dbo].[Usp_DB_Mirror_Monitoring]
Exec [DBAdata].[dbo].[Usp_Linked_server_Status_Check]
EXEC [DBAdata].[dbo].[usp_ping_server_morethan_5_fail_status_change]


