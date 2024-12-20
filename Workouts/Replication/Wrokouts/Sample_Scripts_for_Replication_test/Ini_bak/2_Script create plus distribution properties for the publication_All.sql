

use master
exec sp_adddistributor @distributor = N'Node1', @password = N'G0d$peed'
GO

-- Adding the agent profiles
-- Updating the agent profile defaults
exec sp_MSupdate_agenttype_default @profile_id = 1
GO
exec sp_MSupdate_agenttype_default @profile_id = 2
GO
exec sp_MSupdate_agenttype_default @profile_id = 6
GO
exec sp_MSupdate_agenttype_default @profile_id = 11
GO
exec sp_MSupdate_agenttype_default @profile_id = 14
GO


-- Adding the distribution databases
use master
exec sp_adddistributiondb @database = N'distribution', @data_folder = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA', @data_file = N'distribution.MDF', @data_file_size = 57161, @log_folder = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA', @log_file = N'distribution.LDF', @log_file_size = 176, @min_distretention = 0, @max_distretention = 120, @history_retention = 120, @security_mode = 1
GO

-- Adding the distribution publishers
exec sp_adddistpublisher @publisher = N'Node1', @distribution_db = N'distribution', @security_mode = 0, @login = N'11-834', @password = N'G0d$peed', @working_directory = N'\\NODE1\Repl_Snap_files', @trusted = N'false', @thirdparty_flag = 0, @publisher_type = N'MSSQLSERVER'
GO

/*
exec sp_addsubscriber @subscriber = N'Node2', @type = 0, @description = N''
GO
exec sp_addsubscriber @subscriber = N'Node3', @type = 0, @description = N''
GO
exec sp_addsubscriber @subscriber = N'Node1', @type = 0, @description = N''
GO
exec sp_addsubscriber @subscriber = N'Node1', @type = 0, @description = N''
GO
*/

/****** End: Script to be run at Publisher ******/


-- Enabling the replication database
use master
exec sp_replicationdboption @dbname = N'muthu', @optname = N'publish', @value = N'true'
GO

exec [muthu].sys.sp_addlogreader_agent @job_login = N'muthu\Svc_repl_logreader', @job_password = 'G0d$peed', @publisher_security_mode = 0, @publisher_login = N'tncreplicator2', @publisher_password = N'G0d$peed'
GO
--exec [muthu].sys.sp_addqreader_agent @job_login = null, @job_password = 'G0d$peed', @frompublisher = 1

---==============================================
---==============================================
--1
GO
-- Adding the transactional publication
use [muthu]
exec sp_addpublication @publication = N'muthu_Replica', @description = N'Transactional publication of database ''muthu'' from Publisher ''Node1''.', @sync_method = N'concurrent', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'false', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'continuous', @status = N'active', @independent_agent = N'true', @immediate_sync = N'false', @allow_sync_tran = N'false', @autogen_sync_procs = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1, @allow_initialize_from_backup = N'false', @enabled_for_p2p = N'false', @enabled_for_het_sub = N'false'
GO
exec sp_addpublication_snapshot @publication = N'muthu_Replica', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = N'muthu\Svc_repl_snapshot', @job_password = 'G0d$peed', @publisher_security_mode = 0, @publisher_login = N'tncreplicator1', @publisher_password = N'G0d$peed'

/*
exec sp_grant_publication_access @publication = N'muthu_Replica', @login = N'tncreplicator1'
GO
*/
-- Adding the transactional articles
use [muthu]
exec sp_addarticle @publication = N'muthu_Replica', @article = N'Repl_Tbl1', @source_owner = N'dbo', @source_object = N'Repl_Tbl1', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x0000000000030073, @identityrangemanagementoption = N'none', @destination_table = N'Repl_Tbl1', @destination_owner = N'dbo', @status = 16, @vertical_partition = N'false', @ins_cmd = N'CALL [dbo].[sp_MSins_dboRepl_Tbl1]', @del_cmd = N'CALL [dbo].[sp_MSdel_dboRepl_Tbl1]', @upd_cmd = N'SCALL [dbo].[sp_MSupd_dboRepl_Tbl1]'
GO
use [muthu]
exec sp_addarticle @publication = N'muthu_Replica', @article = N'Repl_Tbl2', @source_owner = N'dbo', @source_object = N'Repl_Tbl2', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'none', @destination_table = N'Repl_Tbl2', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'true', @ins_cmd = N'CALL [sp_MSins_dboRepl_Tbl2]', @del_cmd = N'CALL [sp_MSdel_dboRepl_Tbl2]', @upd_cmd = N'SCALL [sp_MSupd_dboRepl_Tbl2]'

-- Adding the article's partition column(s)
exec sp_articlecolumn @publication = N'muthu_Replica', @article = N'Repl_Tbl2', @column = N'N', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'muthu_Replica', @article = N'Repl_Tbl2', @column = N'N1', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1

-- Adding the article synchronization object
--exec sp_articleview @publication = N'muthu_Replica', @article = N'Home Dynamix, LLC_$Vendor Receipt', @view_name = N'syncobj_0x3934464243413435', @filter_clause = N'', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
GO

-- Adding the transactional subscriptions
use [muthu]
exec sp_addsubscription @publication = N'muthu_Replica', @subscriber = N'Node2', @destination_db = N'muthu_Replica', @subscription_type = N'Push', @sync_type = N'automatic', @article = N'all', @update_mode = N'read only', @subscriber_type = 0
exec sp_addpushsubscription_agent @publication = N'muthu_Replica', @subscriber = N'Node2', @subscriber_db = N'muthu_Replica', @job_login = N'muthu\Svc_repl_distributer', @job_password = 'G0d$peed', @subscriber_security_mode = 0, @subscriber_login = N'tncreplicator1', @subscriber_password = 'G0d$peed', @frequency_type = 64, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, @frequency_subday = 4, @frequency_subday_interval = 5, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @dts_package_location = N'Distributor'
GO

-- BI
--2
-- Adding the transactional publication
use [muthu]
exec sp_addpublication @publication = N'muthu-BI', @description = N'Transactional publication of database ''muthu'' from Publisher ''Node1''.', @sync_method = N'concurrent', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'false', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'continuous', @status = N'active', @independent_agent = N'true', @immediate_sync = N'false', @allow_sync_tran = N'false', @autogen_sync_procs = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1, @allow_initialize_from_backup = N'false', @enabled_for_p2p = N'false', @enabled_for_het_sub = N'false'
GO
exec sp_addpublication_snapshot @publication = N'muthu-BI', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = N'muthu\Svc_repl_snapshot', @job_password = 'G0d$peed', @publisher_security_mode = 0, @publisher_login = N'tncreplicator1', @publisher_password = N'G0d$peed'

/*

exec sp_grant_publication_access @publication = N'muthu-BI', @login = N'tncreplicator1'
GO
*/

-- Adding the transactional articles
use [muthu]
exec sp_addarticle @publication = N'muthu-BI', @article = N'Repl_Tbl1', @source_owner = N'dbo', @source_object = N'Repl_Tbl1', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x0000000000030073, @identityrangemanagementoption = N'none', @destination_table = N'Repl_Tbl1', @destination_owner = N'dbo', @status = 16, @vertical_partition = N'false', @ins_cmd = N'CALL [dbo].[sp_MSins_dboRepl_Tbl1]', @del_cmd = N'CALL [dbo].[sp_MSdel_dboRepl_Tbl1]', @upd_cmd = N'SCALL [dbo].[sp_MSupd_dboRepl_Tbl1]'
GO
use [muthu]
exec sp_addarticle @publication = N'muthu-BI', @article = N'Repl_Tbl2', @source_owner = N'dbo', @source_object = N'Repl_Tbl2', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'none', @destination_table = N'Repl_Tbl2', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'true', @ins_cmd = N'CALL [sp_MSins_dboRepl_Tbl2]', @del_cmd = N'CALL [sp_MSdel_dboRepl_Tbl2]', @upd_cmd = N'SCALL [sp_MSupd_dboRepl_Tbl2]'

-- Adding the article's partition column(s)
exec sp_articlecolumn @publication = N'muthu-BI', @article = N'Repl_Tbl2', @column = N'N', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'muthu-BI', @article = N'Repl_Tbl2', @column = N'N1', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1


-- Adding the transactional subscriptions
use [muthu]
exec sp_addsubscription @publication = N'muthu-BI', @subscriber = N'Node2', @destination_db = N'muthu-BI', @subscription_type = N'Push', @sync_type = N'automatic', @article = N'all', @update_mode = N'read only', @subscriber_type = 0
exec sp_addpushsubscription_agent @publication = N'muthu-BI', @subscriber = N'Node2', @subscriber_db = N'muthu-BI', @job_login = N'muthu\Svc_repl_distributer', @job_password = 'G0d$peed', @subscriber_security_mode = 0, @subscriber_login = N'tncreplicator1', @subscriber_password = 'G0d$peed', @frequency_type = 64, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, @frequency_subday = 4, @frequency_subday_interval = 5, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @dts_package_location = N'Distributor'
GO

--3
----------------DR_Start


-- Adding the transactional publication
use [muthu]
exec sp_addpublication @publication = N'muthu-DR', @description = N'Transactional publication of database ''muthu'' from Publisher ''Node1''.', @sync_method = N'concurrent', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'false', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'continuous', @status = N'active', @independent_agent = N'true', @immediate_sync = N'false', @allow_sync_tran = N'false', @autogen_sync_procs = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1, @allow_initialize_from_backup = N'false', @enabled_for_p2p = N'false', @enabled_for_het_sub = N'false'
GO
exec sp_addpublication_snapshot @publication = N'muthu-DR', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = N'muthu\Svc_repl_snapshot', @job_password = 'G0d$peed', @publisher_security_mode = 0, @publisher_login = N'tncreplicator2', @publisher_password = N'G0d$peed'

/*
exec sp_grant_publication_access @publication = N'muthu-DR', @login = N'tncreplicator2'
GO
*/
-- Adding the transactional articles
use [muthu]
exec sp_addarticle @publication = N'muthu-DR', @article = N'Repl_Tbl1', @source_owner = N'dbo', @source_object = N'Repl_Tbl1', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x0000000000030073, @identityrangemanagementoption = N'none', @destination_table = N'Repl_Tbl1', @destination_owner = N'dbo', @status = 16, @vertical_partition = N'false', @ins_cmd = N'CALL [dbo].[sp_MSins_dboRepl_Tbl1]', @del_cmd = N'CALL [dbo].[sp_MSdel_dboRepl_Tbl1]', @upd_cmd = N'SCALL [dbo].[sp_MSupd_dboRepl_Tbl1]'
GO
use [muthu]
exec sp_addarticle @publication = N'muthu-DR', @article = N'Repl_Tbl2', @source_owner = N'dbo', @source_object = N'Repl_Tbl2', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'none', @destination_table = N'Repl_Tbl2', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'true', @ins_cmd = N'CALL [sp_MSins_dboRepl_Tbl2]', @del_cmd = N'CALL [sp_MSdel_dboRepl_Tbl2]', @upd_cmd = N'SCALL [sp_MSupd_dboRepl_Tbl2]'

-- Adding the article's partition column(s)
exec sp_articlecolumn @publication = N'muthu-DR', @article = N'Repl_Tbl2', @column = N'N', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'muthu-DR', @article = N'Repl_Tbl2', @column = N'N1', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1


-- Adding the article synchronization object
--exec sp_articleview @publication = N'muthu-DR', @article = N'Home Dynamix, LLC_$Posted Vendor Performance Line', @view_name = N'syncobj_0x3545333336373337', @filter_clause = N'', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
GO

-- Adding the transactional subscriptions
use [muthu]
--exec sp_addsubscription @publication = N'muthu-DR', @subscriber = N'Node3', @destination_db = N'muthu', @subscription_type = N'Push', @sync_type = N'replication support only', @article = N'all', @update_mode = N'read only', @subscriber_type = 0
exec sp_addsubscription @publication = N'muthu-DR', @subscriber = N'Node2', @destination_db = N'muthu_DR', @subscription_type = N'Push', @sync_type = N'automatic', @article = N'all', @update_mode = N'read only', @subscriber_type = 0
exec sp_addpushsubscription_agent @publication = N'muthu-DR', @subscriber = N'Node2', @subscriber_db = N'muthu_DR', @job_login = N'muthu\Svc_repl_distributer', @job_password = 'G0d$peed', @subscriber_security_mode = 0, @subscriber_login = N'tncreplicator2', @subscriber_password = 'G0d$peed', @frequency_type = 64, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, @frequency_subday = 4, @frequency_subday_interval = 5, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @dts_package_location = N'Distributor'
GO



----------------DR_END
--==============
--4
--local
-- Adding the transactional publication
use [muthu]
exec sp_addpublication @publication = N'HOMESQL01_Local', @description = N'Transactional publication of database ''muthu'' from Publisher ''Node1''.', @sync_method = N'concurrent', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'false', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'continuous', @status = N'active', @independent_agent = N'true', @immediate_sync = N'false', @allow_sync_tran = N'false', @autogen_sync_procs = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1, @allow_initialize_from_backup = N'false', @enabled_for_p2p = N'false', @enabled_for_het_sub = N'false'
GO
exec sp_addpublication_snapshot @publication = N'HOMESQL01_Local', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = 'muthu\Svc_repl_snapshot', @job_password = 'G0d$peed', @publisher_security_mode = 1

/*
exec sp_grant_publication_access @publication = N'HOMESQL01_Local', @login = N'HOMEDYNAMIX\preddy'
GO
*/
-- Adding the transactional articles
use [muthu]
exec sp_addarticle @publication = N'HOMESQL01_Local', @article = N'Repl_Tbl1', @source_owner = N'dbo', @source_object = N'Repl_Tbl1', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x0000000000030073, @identityrangemanagementoption = N'none', @destination_table = N'Repl_Tbl1', @destination_owner = N'dbo', @status = 16, @vertical_partition = N'false', @ins_cmd = N'CALL [dbo].[sp_MSins_dboRepl_Tbl1]', @del_cmd = N'CALL [dbo].[sp_MSdel_dboRepl_Tbl1]', @upd_cmd = N'SCALL [dbo].[sp_MSupd_dboRepl_Tbl1]'
GO
use [muthu]
exec sp_addarticle @publication = N'HOMESQL01_Local', @article = N'Repl_Tbl2', @source_owner = N'dbo', @source_object = N'Repl_Tbl2', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'none', @destination_table = N'Repl_Tbl2', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'true', @ins_cmd = N'CALL [sp_MSins_dboRepl_Tbl2]', @del_cmd = N'CALL [sp_MSdel_dboRepl_Tbl2]', @upd_cmd = N'SCALL [sp_MSupd_dboRepl_Tbl2]'

-- Adding the article's partition column(s)
exec sp_articlecolumn @publication = N'HOMESQL01_Local', @article = N'Repl_Tbl2', @column = N'N', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'HOMESQL01_Local', @article = N'Repl_Tbl2', @column = N'N1', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1


-- Adding the transactional subscriptions
use [muthu]
exec sp_addsubscription @publication = N'HOMESQL01_Local', @subscriber = N'Node1', @destination_db = N'muthu_Replica', @subscription_type = N'Push', @sync_type = N'automatic', @article = N'all', @update_mode = N'read only', @subscriber_type = 0
exec sp_addpushsubscription_agent @publication = N'HOMESQL01_Local', @subscriber = N'Node1', @subscriber_db = N'muthu_Replica',				@job_login = 'muthu\Svc_repl_distributer', @job_password = 'G0d$peed', @subscriber_security_mode = 0,@subscriber_login = N'tncreplicator1',			@subscriber_password = 'G0d$peed', @frequency_type = 64, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, @frequency_subday = 4, @frequency_subday_interval = 5, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @dts_package_location = N'Distributor'

GO



