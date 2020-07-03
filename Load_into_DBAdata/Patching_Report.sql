 /*Patch

-- Run this PS on both site -- -- \\Server\SQLDBA\ -- EOL_Patch_SQL_PS
-- Above 2016 only CU
-- Below 2017 only Sp
-- EOL no Patch and CU


CREATE TABLE [dbo].[SQLPatch_EOL](
	[ServerName] [nvarchar](max) NULL,
	[SqlInstance] [nvarchar](max) NULL,
	[Build] [nvarchar](max) NULL,
	[NameLevel] [nvarchar](max) NULL,
	[SPLevel] [nvarchar](max) NULL,
	[CULevel] [nvarchar](max) NULL,
	[KBLevel] [nvarchar](max) NULL,
	[BuildLevel] [nvarchar](max) NULL,
	[SupportedUntil] [datetime2](7) NULL,
	[MatchType] [nvarchar](max) NULL,
	[Warning] [nvarchar](max) NULL,
	[Compliant] [bit] NULL,
	[MinimumBuild] [nvarchar](max) NULL,
	[MaxBehind] [nvarchar](max) NULL,
	[SPTarget] [nvarchar](max) NULL,
	[CUTarget] [nvarchar](max) NULL,
	[BuildTarget] [nvarchar](max) NULL
) 

*/
-- join table of 64 bit 32 bit of SQL & OS and PS version
-- Run first monthly and PS script to get a latest report \\Server\SQLDBA\ -- EOL_Patch_SQL_PS
select * FROM SQLPatch_EOL where Build >'14.0'
select * FROM SQLPatch_EOL where Build like'13.0.5%'
/*
select * FROM  DBADATA.DBO.DBA_ALL_SERVERS where SVR_status ='running'  order by Description
select * from SQLPatch_EOL order by ServerName
select * FROM DBADATA.DBO.tbl_load_inventory_settings order by server_name
select * FROM DBADATA.DBO.tbl_SQL_inventory_PeteM where Comments='Working' order by SQL_full_name
select * FROM tbl_OS_version order by Servername
select * FROM DBADATA.DBO.tbl_Patch_OS_EOL  where svr_status ='running' order by Server_name

*/

select count (*) FROM  DBADATA.DBO.DBA_ALL_SERVERS where SVR_status ='running' -- 114
select count(*) from SQLPatch_EOL
select count (*) FROM DBADATA.DBO.tbl_load_inventory_settings --
select count (*) FROM DBADATA.DBO.tbl_SQL_inventory_PeteM where Comments='Working'--

select count (*) FROM tbl_OS_version --
select count (*) FROM DBADATA.DBO.tbl_Patch_OS_EOL  where svr_status ='running'--

-- Broker
-- Above 2016 only CU
select P.servername as [Server Name],Namelevel [SQL Version], SPlevel,SPtarget,buildlevel,BuildTarget,
CUlevel,CUTarget,KBLevel,'Broker'[Site Name], 
	case 
	WHEN convert(VARCHAR(30),D.SP_E_EOL) >getdate()-1 and CUlevel = CUTarget THEN 'Upto Date CU'
	WHEN convert(VARCHAR(30),D.SP_E_EOL) >getdate()-1 and CUlevel is null THEN 'Need a CU Update-'+CUTarget
	WHEN convert(VARCHAR(30),D.SP_E_EOL) >getdate()-1 and CUlevel <> CUTarget THEN 'Need a CU Update-'+CUTarget
	--ELSE 'EOL- No Patch' 
	END  AS  [Comments],
	case when  buildlevel >=BuildTarget  THEN 'EOL or Patch compliance'
	ELSE 'Apply -'+CUTarget
	END  AS  [Patching], 
'CU' [SP_or_CU],OE.WSUS_Patch,D.HA,D.Category,PM.Applications,PM.Business_Owner,S.Server_type,D.Domain,D.SP_E_EOL,D.OS_EOL,V.OS_Version, D.OS_bit, D.SQL_bit

FROM SQLPatch_EOL P
join DBADATA.DBO.DBA_ALL_SERVERS D on P.servername=D.Description
join DBADATA.DBO.tbl_SQL_inventory_PeteM PM on D.Description=PM.SQL_full_name
join DBADATA.DBO.tbl_load_inventory_settings S on PM.SQL_full_name=S.server_name
JOIN DBADATA.DBO.tbl_OS_version V on S.server_name=V.Servername
JOIN DBADATA.DBO.tbl_Patch_OS_EOL OE on OE.server_name=V.Servername
where Namelevel >'2016'
and buildlevel <BuildTarget -- need a patching
and D.SP_E_EOL >getdate()-1
--and CUlevel <>CUTarget -- Null is making some data missmatch, update the null to use this condition
--group by p.servername,Namelevel,SupportedUntil, CUlevel,CUTarget ,SPlevel,SPtarget,buildlevel,BuildTarget,PM.Environment,PM.Applications,PM.Business_Owner,S.Server_type,D.Domain,D.SP_E_EOL,D.OS_EOL
order by D.SP_E_EOL


-- select * FROM SQLPatch_EOL

-- Below 2017 only SP
select P.servername as [Server Name],Namelevel [SQL Version],SPlevel,SPtarget,buildlevel,BuildTarget,
CUlevel,CUTarget,KBLevel,'Broker'[Site Name], 
	case 
	WHEN convert(VARCHAR(30),D.SP_E_EOL) >getdate()-1 and SPlevel = SPTarget THEN 'Upto Date SP'
	WHEN convert(VARCHAR(30),D.SP_E_EOL) >getdate()-1 and SPlevel <> SPTarget THEN 'Need a SP Update-'+SPTarget
	ELSE 'EOL- No Patch' 
	END  AS  [Comments],
	case when  buildlevel >=BuildTarget  THEN 'EOL or Patch compliance'
	ELSE 'Apply -'+SPTarget
	END  AS  [Patching], 
'SP' [SP_or_CU],OE.WSUS_Patch,D.HA,D.Category,PM.Applications,PM.Business_Owner,S.Server_type,D.Domain,D.SP_E_EOL,D.OS_EOL,V.OS_Version, D.OS_bit, D.SQL_bit

FROM SQLPatch_EOL P
join DBADATA.DBO.DBA_ALL_SERVERS D on P.servername=D.Description
join DBADATA.DBO.tbl_SQL_inventory_PeteM PM on D.Description=PM.SQL_full_name
join DBADATA.DBO.tbl_load_inventory_settings S on PM.SQL_full_name=S.server_name
JOIN DBADATA.DBO.tbl_OS_version V on S.server_name=V.Servername
JOIN DBADATA.DBO.tbl_Patch_OS_EOL OE on OE.server_name=V.Servername
where Namelevel <'2017'
and splevel<>sptarget
and D.SP_E_EOL > '2020-04-21'
--and buildlevel >=BuildTarget
--group by p.servername,Namelevel,SupportedUntil, CUlevel,CUTarget ,SPlevel,SPtarget,buildlevel,BuildTarget,PM.Environment,PM.Applications,PM.Business_Owner,S.Server_type,D.Domain,D.SP_E_EOL,D.OS_EOL
order by D.SP_E_EOL

--=============================

select count(*) fromServer.DBADATA.DBO.SQLPatch_EOL
select count (*) FROM Server.DBADATA.DBO.tbl_load_inventory_settings --
select count (*) FROMServer. DBADATA.DBO.tbl_SQL_inventory_PeteC where Comments='Working'--
select count (*) FROM  Server.DBADATA.DBO.DBA_ALL_SERVERS where SVR_status ='running' -- 114
select count (*) FROM Server.DBADATA.DBO.tbl_OS_version --
select count (*) FROM Server.DBADATA.DBO.tbl_Patch_OS_EOL  where svr_status ='running'

--update Server.DBADATA.DBO.tbl_Patch_OS_EOL set svr_status ='running' where Server_name ='BMT-VW-NICESENT'

-- D&P
-- Above 2016 only CU

select P.servername as [Server Name],Namelevel [SQL Version], SPlevel,SPtarget,buildlevel,BuildTarget,
CUlevel,CUTarget,KBLevel,'D&P'[Site Name], 
case 
	WHEN convert(VARCHAR(30),D.SP_E_EOL) >getdate()-1 and CUlevel = CUTarget THEN 'Upto Date CU'
	WHEN convert(VARCHAR(30),D.SP_E_EOL) >getdate()-1 and CUlevel is null THEN 'Need a CU Update-'+CUTarget
	WHEN convert(VARCHAR(30),D.SP_E_EOL) >getdate()-1 and CUlevel <> CUTarget THEN 'Need a CU Update-'+CUTarget
	--ELSE 'EOL- No Patch' 
	END  AS  [Comments],
	case when  buildlevel >=BuildTarget  THEN 'EOL or Patch compliance'
	ELSE 'Apply -'+CUTarget
	END  AS  [Patching], 
'CU' [SP_or_CU],OE.WSUS_Patch,D.HA,D.Category,PM.system,PM.Business_Contact,S.Server_type,D.Domain,D.SP_E_EOL,D.OS_EOL,V.OS_Version, D.OS_bit, D.SQL_bit
FROM  Server.DBADATA.DBO.SQLPatch_EOL P
join Server.DBADATA.DBO.DBA_ALL_SERVERS D on P.servername=D.Description
join Server.DBADATA.DBO.tbl_SQL_inventory_PeteC PM on D.Description=PM.Servername
join Server.DBADATA.DBO.tbl_load_inventory_settings S on PM.Servername=S.server_name
JOIN Server.DBADATA.DBO.tbl_OS_version V on S.server_name=V.Servername
JOIN Server.DBADATA.DBO.tbl_Patch_OS_EOL OE on OE.server_name=V.Servername
where Namelevel >'2016'
and buildlevel <BuildTarget -- need a patching
and D.SP_E_EOL >getdate()-1
--group by p.servername,Namelevel,SupportedUntil, CUlevel,CUTarget ,SPlevel,SPtarget,buildlevel,BuildTarget,PM.Environment,PM.Applications,PM.Business_Owner,S.Server_type,D.Domain,D.SP_E_EOL,D.OS_EOL
order by D.SP_E_EOL


-- select * FROM Server.DBADATA.DBO.SQLPatch_EOL where servername like '%door%'

-- Below 2017 only SP
select P.servername as [Server Name],Namelevel [SQL Version], SPlevel,SPtarget,buildlevel,BuildTarget,
CUlevel,CUTarget,KBLevel,'D&P'[Site Name], 
case 
	WHEN convert(VARCHAR(30),D.SP_E_EOL) >getdate()-1 and SPlevel = SPTarget THEN 'Upto Date SP'
	WHEN convert(VARCHAR(30),D.SP_E_EOL) >getdate()-1 and SPlevel <> SPTarget THEN 'Need a SP Update-'+SPTarget
	ELSE 'EOL- No Patch' 
	END  AS  [Comments],
	case when  buildlevel >=BuildTarget  THEN 'EOL or Patch compliance'
	ELSE 'Apply -'+SPTarget
	END  AS  [Patching],
'SP' [SP_or_CU],OE.WSUS_Patch,D.HA,D.Category,PM.system,PM.Business_Contact,S.Server_type,D.Domain,D.SP_E_EOL,D.OS_EOL,V.OS_Version, D.OS_bit, D.SQL_bit
FROM Server.DBADATA.DBO.SQLPatch_EOL P
join Server.DBADATA.DBO.DBA_ALL_SERVERS D on P.servername=D.Description
join Server.DBADATA.DBO.tbl_SQL_inventory_PeteC PM on D.Description=PM.Servername
join Server.DBADATA.DBO.tbl_load_inventory_settings S on PM.Servername=S.server_name
JOIN Server.DBADATA.DBO.tbl_OS_version V on S.server_name=V.Servername
JOIN Server.DBADATA.DBO.tbl_Patch_OS_EOL OE on OE.server_name=V.Servername
where Namelevel <'2017'
and splevel<>sptarget
--and D.SP_E_EOL >getdate()-1
--and buildlevel >=BuildTarget
--group by p.servername,Namelevel,SupportedUntil, CUlevel,CUTarget ,SPlevel,SPtarget,buildlevel,BuildTarget,PM.Environment,PM.Applications,PM.Business_Owner,S.Server_type,D.Domain,D.SP_E_EOL,D.OS_EOL
order by D.SP_E_EOL

-- DB mapping: App owers
select * from tbl_DB_Mapping_application_Owners
where Server_Name in (
'Server'
)

/*
select P.servername as [Server Name]
--,Namelevel [SQL Version],SPlevel,SPtarget,buildlevel,BuildTarget,
--CUlevel,CUTarget,'Broker'[Site Name], case WHEN convert(VARCHAR(30),D.SP_E_EOL) >getdate()-1 THEN 'Need to Patch'
--ELSE 'EOL- No Patch' 
--END  AS  [Comments],
--case when  buildlevel >BuildTarget  THEN 'EOL or Patch compliance'
--ELSE 'Need Patch' 
--END  AS  [Patching], 'SP' [SP_or_CU],D.HA,
--PM.Environment,PM.Applications,PM.Business_Owner,S.Server_type,D.Domain,D.SP_E_EOL,D.OS_EOL,V.OS_Version
FROM SQLPatch_EOL P
join DBADATA.DBO.DBA_ALL_SERVERS D on P.servername=D.Description
join DBADATA.DBO.tbl_SQL_inventory_PeteM PM on D.Description=PM.SQL_full_name
join DBADATA.DBO.tbl_load_inventory_settings S on PM.SQL_full_name=S.server_name
JOIN DBADATA.DBO.tbl_OS_version V on S.server_name=V.Servername
where Namelevel <'2017'
and splevel<>sptarget
and D.SP_E_EOL > '2020-04-21'
and Environment not in ('Production','Live') and Domain not in ('')
and Namelevel like '%2016%' -- version
order by D.SP_E_EOL
*/