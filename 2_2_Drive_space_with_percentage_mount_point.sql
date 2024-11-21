/*

use DBAdata
-- select * from DBAdata.dbo.DBA_All_Server_Space_percentage_MP --where server_name like '%08%'
drop table DBA_All_Server_Space_percentage_MP
CREATE TABLE [dbo].[DBA_All_Server_Space_percentage_MP](
Volume_mount_point NVARCHAR(512),
Available_GB BIGINT,
Total_GB BIGINT,
PercentFree BIGINT,
[SERVER_NAME] [varchar](50) NULL
)

/*=====================================*/
-- select * from DBAdata_Archive.dbo.DBA_All_Server_Space_percentage_MP
use [DBAdata_Archive]
drop table DBA_All_Server_Space_percentage_MP
CREATE TABLE [dbo].[DBA_All_Server_Space_percentage_MP](
Volume_mount_point NVARCHAR(512),
Available_GB BIGINT,
Total_GB BIGINT,
PercentFree BIGINT,
[SERVER_NAME] [varchar](50) NULL,
[Upload_date] [datetime] NULL
) 


*/

--DROP PROC [USP_DBA_GETSERVERSPACE_percentage]
-- Exec DBAdata.[dbo].[USP_DBA_GETSERVERSPACE_percentage] @P_Precentage_free= 11 -- less than 10 % alert
USE DBAdata
GO
alter PROCEDURE [dbo].USP_drivespace_mount_point_All
/*
Summary:     Percentage of Space Utilization findings
Contact:     Muthukkumaran Kaliyamoorthy SQL DBA
Description: Percentage of Space Utilization findings
This will enable &amp; disable Ole Automation Procedures, make sure, if you have system to be always enabled Ole Automation Procedures, comment the script

ChangeLog:
Date         Coder							Description
2013-jan-21	 Muthukkumaran Kaliyamoorthy     Updated the 2012 functionality                   


*/
--(@P_Precentage_free int)
--WITH ENCRYPTION
AS 
BEGIN
-- select * from DBADATA.DBO.DBA_All_Server_Space_percentage_MP



TRUNCATE TABLE DBADATA.DBO.DBA_All_Server_Space_percentage_MP


CREATE TABLE #tbl_driveinfo_mount_point
(
volume_mount_point NVARCHAR(512),
available_bytes BIGINT,
total_bytes BIGINT,
PercentFree DECIMAL(20,2)
)

DECLARE @SERVER_NAME VARCHAR(200)
DECLARE @DESC VARCHAR(200)
--** PUT LOCAL SERVER FIRST.

-- Ole Automation need to be checked in the system by default this is been disabled
-- Check before enable and disable, if the system needs this should be enabled all the time, make adjustment

DECLARE ALLSERVER_percentage CURSOR
FOR

SELECT SERVERNAME,	[DESCRIPTION] FROM DBADATA.DBO.DBA_ALL_SERVERS
WHERE  svr_status ='running'
and Version not in ('SQL2000','SQL2005')
--and Version  in ('SQL2019')

OPEN ALLSERVER_percentage
FETCH NEXT FROM ALLSERVER_percentage INTO @SERVER_NAME,@DESC

WHILE @@FETCH_STATUS=0  
BEGIN
BEGIN TRY

TRUNCATE TABLE #tbl_driveinfo_mount_point

--INSERT INTO DBA_All_Server_Space_percentage_MP -- (DRIVE,Lable_NAME,FREE_SPACE_IN_MB,used_SPACE_IN_MB,Total_SPACE_IN_MB,Precentage_free)


EXEC ('EXEC [' + @SERVER_NAME+'].MASTER.DBO.USP_drivespace_mount_point')
EXEC ('INSERT INTO  #tbl_driveinfo_mount_point SELECT * FROM [' + @SERVER_NAME+'].MASTER.DBO.tbl_driveinfo_mount_point')

INSERT INTO DBA_All_Server_Space_percentage_MP
SELECT *,@DESC AS SERVERNAME FROM #tbl_driveinfo_mount_point


--PRINT 'SERVER ' +@SERVER_NAME+' COMPLETED.'
END TRY

BEGIN CATCH
--SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'Drive_percentage_MP',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

--PRINT 'SERVER ['+@SERVER_NAME+']is not COMPLETED.'
END CATCH

FETCH NEXT FROM ALLSERVER_percentage INTO @SERVER_NAME,@DESC
END
CLOSE ALLSERVER_percentage
DEALLOCATE ALLSERVER_percentage
DROP TABLE #tbl_driveinfo_mount_point

/*
----------------------------------------------------
-- May be its time to send the report to my DBA

DECLARE @SERVERNAME VARCHAR(500)
DECLARE @DRIVE VARCHAR(200)

DECLARE @FREE_SPACE_IN_GB  VARCHAR(200)
DECLARE @Total_SPACE_IN_GB  VARCHAR(200)
DECLARE @Precentage_free  VARCHAR(200)


-- select * from dbadata.dbo.DBA_All_Server_Space_percentage_MP 
if exists 
(

SELECT * FROM [DBA_All_Server_Space_percentage_MP]
where len(Volume_mount_point )>3
--where Precentage_free&lt;@P_Precentage_free AND DRIVE NOT IN (&#039;Q&#039;,&#039;P&#039;)
--where Precentage_free&lt;11 AND DRIVE NOT IN (&#039;Q&#039;,&#039;P&#039;)

--and (server_name  not in (&#039;abcd&#039;,&#039;aa&#039;,&#039;bb\SDSS&#039;))
--and (server_name  'xx' and drive 'Z')

)
begin

DECLARE SPACECUR_mp CURSOR FOR

SELECT server_name,Volume_mount_point,Available_GB,Total_GB,PercentFree FROM [DBA_All_Server_Space_percentage_MP]
where len(Volume_mount_point )>3
--where Precentage_free&lt;@P_Precentage_free AND DRIVE NOT IN (&#039;Q&#039;,&#039;P&#039;)
--where Precentage_free&lt;11 AND DRIVE NOT IN (&#039;Q&#039;,&#039;P&#039;)

--and (server_name  not in (&#039;abcd&#039;,&#039;aa&#039;,&#039;bb\SDSS&#039;))
--and (server_name  'xx' and drive 'Z')
order by server_name

OPEN SPACECUR_mp

FETCH NEXT FROM SPACECUR_mp
INTO @SERVERNAME,@DRIVE,@FREE_SPACE_IN_GB,@Total_SPACE_IN_GB,@Precentage_free

---
DECLARE @BODY1 VARCHAR(max)
SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>FOLLOWINGS ARE LOW MOUNT POINT VOLUME SPACE PERCENTAGE INFO:</b> </font>
<P> 
 <font size=1 color=#FF00FF  face=''verdana''>
<Table border=0 width=1000 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">  
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold"> 
 <td width=550 color=white>Server Name</td> 
 <td width=150 color=white>Drive</td>  
<td width=550 color=white>Free Space GB</td> 
<td width=550 color=white>Total Space GB</td> 
<td width=350 color=white>% Free</td> 

</b>  

 </tr>'
WHILE @@FETCH_STATUS=0
BEGIN
SET @BODY1= @BODY1 +'<tr>
<td>'+ISNULL(@SERVERNAME,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@DRIVE+':','&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@FREE_SPACE_IN_GB,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@Total_SPACE_IN_GB,'&nbsp')+'</td>'+
case when @Precentage_free< 10 then '<td align=center style="color:#FF0000;font-weight:bold">'+ISNULL(@Precentage_free,'&nbsp')+'</td>'
else '<td align=center >'+ISNULL(@Precentage_free,'&nbsp')+'</td>' end


FETCH NEXT FROM SPACECUR
INTO @SERVERNAME,@DRIVE,@FREE_SPACE_IN_GB,@Total_SPACE_IN_GB,@Precentage_free
END
SET @BODY1=@BODY1+'</Table> </p>
<p>
<font style="color:#7E2217;font-face:verdana;font-size:9px;"> Generated on '
+convert(varchar(30),getdate(),100)+'. </BR>
This is an auto generated mail by DBA TEAM. If you receive this email by mistake please contact us. 
</br>
© Property of DBA Team.
</font>'

---

CLOSE SPACECUR_mp
DEALLOCATE SPACECUR_mp

DECLARE @EMAILIDS VARCHAR(500)

SELECT @EMAILIDS=
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS  FROM DBAdata.DBO.DBA_ALL_OPERATORS
WHERE STATUS =1


DECLARE @EMAILIDS1 VARCHAR(500)
--SELECT @EMAILIDS1= 'abc@xxx.com;xyz@xxx.com'

EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@SUBJECT = 'DBA: Mount Point Volume PERCENTAGE INFO',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,
@BODY_FORMAT = 'HTML' ,@PROFILE_NAME=@@servername;
--select @BODY1

-------------------------------------------------------
end
--select * from DBAdata_Archive.dbo.DBA_All_Server_Space_percentage_MP
insert into DBAdata_Archive.dbo.DBA_All_Server_Space_percentage_MP
select *,GETDATE() from DBA_All_Server_Space_percentage_MP -- where server_name like '%19%'

*/

END