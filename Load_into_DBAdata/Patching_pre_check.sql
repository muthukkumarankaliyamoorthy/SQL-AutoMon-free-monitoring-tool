
-- check the c drive space
SELECT * FROM [dbo].[DBA_All_Server_Space_percentage] 
where drive ='c' and server_name in(
'server name'

)

order by Precentage_free

-- collect the database names and change the cr Date


Exec [Usp_load_sys_databases] -- 1054

go

select SD.ServerName as [Server Name],SD.name as [Database Name],SD.crdate [Create Date],
CASE   
		 WHEN convert(VARCHAR(30),SD.name) like 'master' THEN 'System DB'
		 WHEN convert(VARCHAR(30),SD.name) like 'model' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like 'msdb' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like 'tempdb' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like '%ReportServer%' THEN 'SSRS Portal'  
		 ELSE AO.[Application_Name]
END  AS [Application Name],  

 CASE   
		 WHEN convert(VARCHAR(30),SD.name) like 'master' THEN 'System DB'
		 WHEN convert(VARCHAR(30),SD.name) like 'model' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like 'msdb' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like 'tempdb' THEN 'System DB'  
		 WHEN convert(VARCHAR(30),SD.name) like '%ReportServer%' THEN 'SSRS Portal'  
		 ELSE AO.Business_Owner
END  AS [Business Owner],

'Broker' [Site Name]


from tbl_sys_databases SD left join tbl_DB_Mapping_application_Owners AO
on SD.ServerName=AO.Server_Name
and sd.name=ao.Database_Name
where SD.Name not in ('master','model','msdb','tempdb','DBAUtil') and
SD.ServerName in (
'Server Name'
)
order by SD.ServerName 


