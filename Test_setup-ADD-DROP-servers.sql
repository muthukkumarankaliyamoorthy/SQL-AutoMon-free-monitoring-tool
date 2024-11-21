select 'EXEC USP_DBA_ADDSERVER_FOR_MONITOR','''DBA_'+ServerName+''',',''''+ServerName+''',',
''''+Version+''',',''''+ServerName+''',','''SA'',','''G0d$peed'',',
''''+Category+''',','''India'',',''''+Edition+''',','''Running'',',''''+Login_Mode+''''
from dbo.tbl_SQL_AutoMON where svr_Status <>'Server Not running'

-- SQL:
-- EXEC USP_DBA_DROPSERVER_FOR_MONITOR		'laptop-isgukeuc',	'SQL2014',	'laptop-isgukeuc'
EXEC USP_DBA_DROPSERVER_FOR_MONITOR		'LAPTOP-ISGUKEUC\MUTHU',	'SQL2014',	'LAPTOP-ISGUKEUC\MUTHU'

-- EXEC USP_DBA_ADDSERVER_FOR_MONITOR	'laptop-isgukeuc',	'SQL2014',	'laptop-isgukeuc',	'SA',	'G0d$peed',	'Non-Prod',	'India',	'Enterprise Edition: Core-based Licensing (64-bit)',	'Running',	'SQL'
EXEC USP_DBA_ADDSERVER_FOR_MONITOR		'LAPTOP-ISGUKEUC\MUTHU',	'SQL2014',	'LAPTOP-ISGUKEUC\MUTHU',	'SA',	'G0d$peed',	'Non-Prod',	'India',	'Enterprise Edition: Core-based Licensing (64-bit)',	'Running',	'SQL'

select 'EXEC USP_DBA_DROPSERVER_FOR_MONITOR','''DBA_'+ServerName+''',',''''+ServerName+''',',
''''+Version+''',',''''+ServerName+''''
from dbo.tbl_SQL_AutoMON --where servername like '%ii%'


-- other source:

EXEC USP_DBA_ADDSERVER_FOR_MONITOR	'DBA_laptop-isgukeuc','laptop-isgukeuc',	'SQL2014',	'laptop-isgukeuc',	'SA',	'G0d$peed',	'Non-Prod',	'India',	'Enterprise Edition: Core-based Licensing (64-bit)',	'Running',	'SQL'
EXEC USP_DBA_ADDSERVER_FOR_MONITOR		'DBA_LAPTOP-ISGUKEUC\MUTHU','LAPTOP-ISGUKEUC\MUTHU',	'SQL2014',	'LAPTOP-ISGUKEUC\MUTHU',	'SA',	'G0d$peed',	'Non-Prod',	'India',	'Enterprise Edition: Core-based Licensing (64-bit)',	'Running',	'SQL'

EXEC USP_DBA_DROPSERVER_FOR_MONITOR	'DBA_laptop-isgukeuc',	'laptop-isgukeuc',	'SQL2014',	'laptop-isgukeuc'
EXEC USP_DBA_DROPSERVER_FOR_MONITOR	'DBA_LAPTOP-ISGUKEUC\MUTHU',	'LAPTOP-ISGUKEUC\MUTHU',	'SQL2014',	'LAPTOP-ISGUKEUC\MUTHU'

