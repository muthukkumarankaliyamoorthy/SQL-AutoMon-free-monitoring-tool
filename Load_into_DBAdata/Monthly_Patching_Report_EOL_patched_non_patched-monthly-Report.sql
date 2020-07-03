/*

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
drop table tbl_SWG_patch_compliance
create table tbl_SWG_patch_compliance (SP_count varchar(20), CU_count varchar(20), site_name varchar(20))
*/
truncate table tbl_SWG_patch_compliance



-- Above 2016 only CU
insert into tbl_SWG_patch_compliance (CU_count,site_name)
select count(*), 'Site1 CU' as site_name

/*
P.servername as [Server Name],Namelevel [SQL Version], SPlevel,SPtarget,buildlevel,BuildTarget,
CUlevel,CUTarget,'Site1'[Site Name], 
	case 
	WHEN convert(VARCHAR(30),D.E_EOL) >getdate()-1 and CUlevel = CUTarget THEN 'Upto Date CU'
	WHEN convert(VARCHAR(30),D.E_EOL) >getdate()-1 and CUlevel is null THEN 'Need a CU Update-'+CUTarget
	WHEN convert(VARCHAR(30),D.E_EOL) >getdate()-1 and CUlevel <> CUTarget THEN 'Need a CU Update-'+CUTarget
	--ELSE 'EOL- No Patch' 
	END  AS  [Comments],
	case when  buildlevel >BuildTarget  THEN 'EOL or Patch compliance'
	ELSE 'Apply -'+CUTarget
	END  AS  [Patching], 
'CU' [SP_or_CU],D.HA,PM.Environment,PM.Applications,PM.Business_Owner,S.Server_type,D.Domain,D.E_EOL,D.OS_EOL,V.OS_Version, D.OS_bit, D.SQL_bit
*/
FROM SQLPatch_EOL P
join DBADATA.DBO.DBA_ALL_SERVERS D on P.servername=D.Description
join DBADATA.DBO.tbl_SQL_inventory_AppOwners PM on D.Description=PM.Server_Name
join DBADATA.DBO.tbl_load_inventory_settings S on PM.Server_Name=S.server_name
JOIN DBADATA.DBO.tbl_OS_version V on S.server_name=V.Servername
where Namelevel >'2016'
and buildlevel <BuildTarget -- need a patching
and D.E_EOL >getdate()-1
--and CUlevel <>CUTarget -- Null is making some data missmatch, update the null to use this condition
--group by p.servername,Namelevel,SupportedUntil, CUlevel,CUTarget ,SPlevel,SPtarget,buildlevel,BuildTarget,PM.Environment,PM.Applications,PM.Business_Owner,S.Server_type,D.Domain,D.E_EOL,D.OS_EOL


-- Below 2017 only SP
insert into tbl_SWG_patch_compliance (SP_count,site_name)
select count(*), 'Site1 SP' as site_name

/*P.servername as [Server Name],Namelevel [SQL Version],SPlevel,SPtarget,buildlevel,BuildTarget,
CUlevel,CUTarget,'Site1'[Site Name], 
	case 
	WHEN convert(VARCHAR(30),D.E_EOL) >getdate()-1 and SPlevel = SPTarget THEN 'Upto Date SP'
	WHEN convert(VARCHAR(30),D.E_EOL) >getdate()-1 and SPlevel <> SPTarget THEN 'Need a SP Update-'+SPTarget
	ELSE 'EOL- No Patch' 
	END  AS  [Comments],
	case when  buildlevel >BuildTarget  THEN 'EOL or Patch compliance'
	ELSE 'Apply -'+SPTarget
	END  AS  [Patching], 
'SP' [SP_or_CU],D.HA,PM.Environment,PM.Applications,PM.Business_Owner,S.Server_type,D.Domain,D.E_EOL,D.OS_EOL,V.OS_Version, D.OS_bit, D.SQL_bit
*/
FROM SQLPatch_EOL P
join DBADATA.DBO.DBA_ALL_SERVERS D on P.servername=D.Description
join DBADATA.DBO.tbl_SQL_inventory_AppOwners PM on D.Description=PM.Server_Name
join DBADATA.DBO.tbl_load_inventory_settings S on PM.Server_Name=S.server_name
JOIN DBADATA.DBO.tbl_OS_version V on S.server_name=V.Servername
where Namelevel <'2017'
and splevel<>sptarget
and D.E_EOL > '2020-06-05'
--and buildlevel >=BuildTarget
--group by p.servername,Namelevel,SupportedUntil, CUlevel,CUTarget ,SPlevel,SPtarget,buildlevel,BuildTarget,PM.Environment,PM.Applications,PM.Business_Owner,S.Server_type,D.Domain,D.E_EOL,D.OS_EOL


select 
SP_count as [SP count],CU_count as [CU count], site_name as [Site Name]

from tbl_SWG_patch_compliance
