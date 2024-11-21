
-- AG DB task only for R/W DBs

Exec sp_MSforeachdb
'USE [?];
IF (DB_ID(''?'')<>2 and databasepropertyex(''?'',''updateability'') =''Read_Write'')

begin
select db_name();
Exec sp_updatestats;

end'

-- Run somethig for all DB

Exec sp_MSforeachdb
'USE [?];
select ''?'' AS DB, name from sysobjects
';