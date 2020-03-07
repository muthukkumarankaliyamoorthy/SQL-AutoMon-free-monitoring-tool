/*
--drop table tbl_alwayson_monitoring

select * from tbl_alwayson_monitoring
use DBAdata
go
CREATE TABLE [dbo].[tbl_alwayson_monitoring](
	[replica_server_name] [nvarchar](256) NOT NULL,
	[Group_name] [nvarchar](256) NOT NULL,
	[role_desc] [nvarchar](60) NULL,
	[operational_state_desc] [nvarchar](60) NULL,
	[recovery_health_desc] [nvarchar](60) NULL,
	[synchronization_health_desc] [nvarchar](60) NULL,
	Upload_date datetime
) 

use DBAdata_archive
go
CREATE TABLE [dbo].[tbl_alwayson_monitoring](
	[replica_server_name] [nvarchar](256) NOT NULL,
	[Group_name] [nvarchar](256) NOT NULL,
	[role_desc] [nvarchar](60) NULL,
	[operational_state_desc] [nvarchar](60) NULL,
	[recovery_health_desc] [nvarchar](60) NULL,
	[synchronization_health_desc] [nvarchar](60) NULL,
	Upload_date datetime
) 

*/ /*=======================[usp_SpServerDiagnostics] & [usp_SpServerDiagnostics_new] both sp needed */
-- 
use DBAdata
go
-- DROP PROC [Usp_Alwayson_Monitoring]
alter proc [dbo].Usp_Alwayson_Monitoring
/*
Summary:     Alwayson status
Contact:     Muthukkumaran Kaliyamoorthy SQL DBA
Description: Alwayson status run sp_server_diagnostics on target server


ChangeLog:
Date         Coder							Description
2013-jan-21	 Muthukkumaran Kaliyamoorthy     Updated the 2012 functionality                   


*/

--with Encryption
as
begin

	  DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @sql varchar(8000)
      DECLARE @minrow int
      DECLARE @maxrow int

TRUNCATE TABLE tbl_alwayson_monitoring


declare @spaceinfo table (id int  primary key identity, 
servername varchar(100),Description varchar(100)) 
 
insert into @spaceinfo
select Servername , Description   from dbadata.dbo.dba_all_servers 
WHERE ha ='alwayson'
and VERSION  NOT IN('SQL2000','SQL2005','SQL2008','SQL2008R2')
and SVR_status='running'
 --select *  from dbadata.dbo.dba_all_servers
SELECT @minrow = MIN(id)FROM   @spaceinfo
SELECT @maxrow  = MAX(id) FROM   @spaceinfo
 
 while (@minrow <=@maxrow)
 begin
 BEGIN TRY
 
 select @Server_name=Servername ,
 @Desc=Description   from @spaceinfo where ID = @minrow 

set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],
''''select '''''''''+@server_name+''''''''',name,role_desc,operational_state_desc,recovery_health_desc,
synchronization_health_desc,getdate()
from sys.dm_hadr_availability_replica_cluster_states a join 
sys.dm_hadr_availability_replica_states b on a.group_id =b.group_id 
join sys.availability_groups_cluster c on b.group_id =c.group_id 
where b.synchronization_health_desc<>''''''''HEALTHY''''''''
'''')'')
'
insert into dbadata.dbo.tbl_alwayson_monitoring
exec(@sql)
--SELECT @sql
end try
BEGIN CATCH
SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'AlwaysON',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()


END CATCH
 
set @minrow =@minrow +1 
end

----------------------------------------------------------------
--Send an email to DBA team
-----------------------------------------------------------------
      
      DECLARE @servername varchar(100)
	  DECLARE @Replica_servername varchar(100)
      DECLARE @group_name varchar(100)
	  DECLARE @health_Status varchar(100)
      DECLARE @Role varchar(100)
     
      
      
--SELECT * FROM dbadata.dbo.tbl_alwayson_monitoring
IF EXISTS (
SELECT 1 FROM dbadata.dbo.tbl_alwayson_monitoring
where synchronization_health_desc<>'HEALTHY'
) 
begin

--DECLARE @Replica_servername varchar(100)

SELECT @Replica_servername=replica_server_name FROM DBAdata_Archive.dbo.tbl_alwayson_monitoring
where synchronization_health_desc<>'HEALTHY'


set @Replica_servername=@Replica_servername

--select @Replica_servername

exec usp_SpServerDiagnostics_new @Replica_servername

DECLARE HADR_CuR CURSOR FOR

SELECT [Group_name],replica_server_name,synchronization_health_desc,role_desc
FROM dbadata.dbo.tbl_alwayson_monitoring 
where synchronization_health_desc<>'HEALTHY'

OPEN HADR_CuR
FETCH NEXT FROM HADR_CuR
INTO @group_name,@servername,@health_Status, @Role

DECLARE @BODY1 VARCHAR(max)
SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>Followings are AlwaysON Status:</b> </font>
<P> 
<font size=1 color=#FF00FF  face=''verdana''>
<Table border=5 width=1000 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">  
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold"> 
 <td width=600 color=white>Group Name</td>
 <td width=600 color=white>Server Name</td> 
 <td width=600 color=white>Health State</td> 
 <td width=600 color=white>Server Role</td> 
 </b>  

 </tr>'
WHILE @@FETCH_STATUS=0
BEGIN
SET @BODY1= @BODY1 +'<tr>
<td>'+ISNULL(@group_name,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@servername,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@health_Status,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@Role,'&nbsp')+'</td>'

FETCH NEXT FROM HADR_CuR
INTO @group_name,@servername,@health_Status, @Role

END
SET @BODY1=@BODY1+'</Table> </p>
<p>
<font style="color:#7E2217;font-face:verdana;font-size:9px;"> Generated on '
+convert(varchar(30),getdate(),100)+'. </BR>
This is an auto generated mail by DBA Team. If you receive this email by mistake please contact us. 
 </br>
© Property of DBA Team.
 </font>'

CLOSE HADR_CuR
DEALLOCATE HADR_CuR
DECLARE @EMAILIDS VARCHAR(500)

SELECT @EMAILIDS=
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS 
FROM DBADATA.dbo.DBA_ALL_OPERATORS WHERE name ='muthu' and STATUS =1

DECLARE @EMAILIDS1 VARCHAR(500)

SELECT @EMAILIDS1= 'dba@abcd.com'


EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@SUBJECT = 'DBA: AlwaysOn Staus',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,
@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';
--select @BODY1

-------------------------------------------------------

end  

insert into DBAdata_Archive.dbo.tbl_alwayson_monitoring
select * from tbl_alwayson_monitoring

END


--select * from DBAdata_Archive.dbo.tbl_alwayson_monitoring