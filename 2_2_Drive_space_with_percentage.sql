/*
use DBAdata
-- select * from DBAdata.dbo.DBA_All_Server_Space_percentage
drop table DBA_All_Server_Space_percentage
CREATE TABLE [dbo].[DBA_All_Server_Space_percentage](
	[DRIVE] [char](1) NULL,
	[Lable_NAME] [varchar](50) NULL,
	[FREE_SPACE_IN_MB] [int] NULL,
	[used_SPACE_IN_MB] [int] NULL,
	[Total_SPACE_IN_MB] [int] NULL,
	[Precentage_free] NUMERIC(9,0) NULL,
	[SERVER_NAME] [varchar](50) NULL
)

/*=====================================*/
-- select * from DBAdata_Archive.dbo.DBA_All_Server_Space_percentage
use [DBAdata_Archive]
drop table DBA_All_Server_Space_percentage
CREATE TABLE [dbo].[DBA_All_Server_Space_percentage](
	[DRIVE] [char](1) NULL,
	[Lable_NAME] [varchar](50) NULL,
	[FREE_SPACE_IN_MB] [int] NULL,
	[used_SPACE_IN_MB] [int] NULL,
	[Total_SPACE_IN_MB] [int] NULL,
	[Precentage_free] NUMERIC(9,0) NULL,
	[SERVER_NAME] [varchar](50) NULL,
	[Upload_date] [datetime] NULL
) 

*/

WARNING: It needs Ole Automation Procedures, enable and disable (OR) permanently enable if it already enabled or needed to be enabled for any applications.

If you are using SQL 2000, you will get an error for enabling Ole Automation Procedures. But as long as it installed it will work. Just the table if it is installed or not 
-- SELECT * FROM master.dbo.sysobjects WHERE name LIKE '%sp_OA%' AND xtype = 'X'

Server: Msg 15123, Level 16, State 1, Procedure sp_configure, Line 78
The configuration option 'Ole Automation Procedures' does not exist, or it may be an advanced option.


--DROP PROC [USP_DBA_GETSERVERSPACE_percentage]
-- Exec DBAdata.[dbo].[USP_DBA_GETSERVERSPACE_percentage] @P_Precentage_free= 10 -- less than 10 % alert
USE DBAdata
GO
alter PROCEDURE [dbo].[USP_DBA_GETSERVERSPACE_percentage]
/*
Summary:     Percentage of Space Utilization findings
Contact:     Muthukkumaran Kaliyamoorthy SQL DBA
Description: Percentage of Space Utilization findings
This will enable & disable Ole Automation Procedures, make sure, if you have system to be always enabled Ole Automation Procedures, comment the script

ChangeLog:
Date         Coder							Description
2013-jan-21	 Muthukkumaran Kaliyamoorthy     Updated the 2012 functionality                   


*/
(@P_Precentage_free int)
--WITH ENCRYPTION
AS 
BEGIN
-- select * from DBADATA.DBO.DBA_All_Server_Space_percentage
TRUNCATE TABLE DBADATA.DBO.DBA_All_Server_Space_percentage


CREATE TABLE #TEMPSPACE_percentage
(
	[DRIVE] [char](1) NULL,
	[Lable_NAME] [varchar](50) NULL,
	[FREE_SPACE_IN_MB] [int] NULL,
	[used_SPACE_IN_MB] [int] NULL,
	[Total_SPACE_IN_MB] [int] NULL,
	[Precentage_free] NUMERIC(9,0) NULL,
)
DECLARE @SERVER_NAME VARCHAR(200)
DECLARE @DESC VARCHAR(200)
--** PUT LOCAL SERVER FIRST.

-- Ole Automation need to be checked in the system by default this is been disabled
-- Check before enable and disable, if the system needs this should be enabled all the time, make adjustment

/*
exec master..sp_configure 'show advanced options', 1 
RECONFIGURE; 
exec master..sp_configure 'Ole Automation Procedures', 1 
RECONFIGURE;
*/



SET NOCOUNT ON


IF EXISTS (SELECT name FROM tempdb..sysobjects WHERE name = '##_DriveSpace')
	DROP TABLE ##_DriveSpace

IF EXISTS (SELECT name FROM tempdb..sysobjects WHERE name = '##_DriveInfo')
	DROP TABLE ##_DriveInfo


DECLARE @Result INT
	, @objFSO INT
	, @Drv INT 
	, @cDrive VARCHAR(13) 
	, @Size VARCHAR(50) 
	, @Free VARCHAR(50)
	, @Label varchar(10)

CREATE TABLE ##_DriveSpace 
	(
	 DriveLetter CHAR(1) not null
	, FreeSpace VARCHAR(10) not null

	 )

CREATE TABLE ##_DriveInfo
	(
	DriveLetter CHAR(1)
	, TotalSpace bigint
	, FreeSpace bigint
	, Label varchar(10)
	)

INSERT INTO ##_DriveSpace 
	EXEC master.dbo.xp_fixeddrives


-- Iterate through drive letters.
DECLARE curDriveLetters CURSOR
	FOR SELECT driveletter FROM ##_DriveSpace

DECLARE @DriveLetter char(1)
	OPEN curDriveLetters

FETCH NEXT FROM curDriveLetters INTO @DriveLetter
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN

		 SET @cDrive = 'GetDrive("' + @DriveLetter + '")' 

			EXEC @Result = sp_OACreate 'Scripting.FileSystemObject', @objFSO OUTPUT 

				IF @Result = 0 

					EXEC @Result = sp_OAMethod @objFSO, @cDrive, @Drv OUTPUT 

				IF @Result = 0 

					EXEC @Result = sp_OAGetProperty @Drv,'TotalSize', @Size OUTPUT 

				IF @Result = 0 

					EXEC @Result = sp_OAGetProperty @Drv,'FreeSpace', @Free OUTPUT 

				IF @Result = 0 

					EXEC @Result = sp_OAGetProperty @Drv,'VolumeName', @Label OUTPUT 

				IF @Result <> 0 
 
					EXEC sp_OADestroy @Drv 
					EXEC sp_OADestroy @objFSO 

			SET @Size = (CONVERT(BIGINT,@Size) / 1048576 )

			SET @Free = (CONVERT(BIGINT,@Free) / 1048576 )

			INSERT INTO ##_DriveInfo
				VALUES (@DriveLetter, @Size, @Free, @Label)

	END
	FETCH NEXT FROM curDriveLetters INTO @DriveLetter
END

CLOSE curDriveLetters
DEALLOCATE curDriveLetters


INSERT INTO dbadata.dbo.DBA_All_Server_Space_percentage
SELECT DriveLetter
	, Label
	, FreeSpace AS [FreeSpace MB]
	, (TotalSpace - FreeSpace) AS [UsedSpace MB]
	, TotalSpace AS [TotalSpace MB]
	, ((CONVERT(NUMERIC(9,0),FreeSpace) / CONVERT(NUMERIC(9,0),TotalSpace)) * 100) AS [Percentage Free]
	,@@SERVERNAME
FROM ##_DriveInfo
ORDER BY [DriveLetter] ASC	

--SELECT *,'abcd' AS SERVERNAME FROM ##_DriveInfo ORDER BY FreeSpace desc	

DROP TABLE ##_DriveSpace
DROP TABLE ##_DriveInfo

/*
exec master..sp_configure 'Ole Automation Procedures', 0 
RECONFIGURE; 
exec master..sp_configure 'show advanced options', 0
RECONFIGURE;
*/
--PRINT @@SERVERNAME +' COMPLETED.'


DECLARE ALLSERVER_percentage CURSOR
FOR

SELECT SERVERNAME,	[DESCRIPTION] FROM DBADATA.DBO.DBA_ALL_SERVERS
WHERE  svr_status ='running'
and Version not in ('SQL2000')

OPEN ALLSERVER_percentage
FETCH NEXT FROM ALLSERVER_percentage INTO @SERVER_NAME,@DESC

WHILE @@FETCH_STATUS=0  
BEGIN
BEGIN TRY

TRUNCATE TABLE #TEMPSPACE_percentage

INSERT INTO DBA_All_Server_Space_percentage -- (DRIVE,Lable_NAME,FREE_SPACE_IN_MB,used_SPACE_IN_MB,Total_SPACE_IN_MB,Precentage_free)
SELECT null,Null,null,null,null,null,null

EXEC ('EXEC [' + @SERVER_NAME+'].MASTER.DBO.USP_TEMPSPACE_POP_percentage')
EXEC ('INSERT INTO  #TEMPSPACE_percentage SELECT * FROM [' + @SERVER_NAME+'].MASTER.DBO.TEMPSPACE_percentage')

INSERT INTO DBA_All_Server_Space_percentage
SELECT *,@DESC AS SERVERNAME FROM #TEMPSPACE_percentage

--PRINT 'SERVER ' +@SERVER_NAME+' COMPLETED.'
END TRY

BEGIN CATCH
--SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'Drive_percentage',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

--PRINT 'SERVER ['+@SERVER_NAME+']is not COMPLETED.'
END CATCH

FETCH NEXT FROM ALLSERVER_percentage INTO @SERVER_NAME,@DESC
END
CLOSE ALLSERVER_percentage
DEALLOCATE ALLSERVER_percentage
DROP TABLE #TEMPSPACE_percentage


----------------------------------------------------
-- May be its time to send the report to my DBA

DECLARE @SERVERNAME VARCHAR(500)
DECLARE @DRIVE VARCHAR(200)
DECLARE @Lable_NAME  VARCHAR(200)
DECLARE @FREE_SPACE_IN_MB  VARCHAR(200)
DECLARE @used_SPACE_IN_MB  VARCHAR(200)
DECLARE @Total_SPACE_IN_MB  VARCHAR(200)
DECLARE @Precentage_free  VARCHAR(200)


-- select * from dbadata.dbo.DBA_All_Server_Space_percentage 
if exists 
(
select 1 from dbadata.dbo.DBA_All_Server_Space_percentage 
where Precentage_free<@P_Precentage_free AND DRIVE NOT IN ('Q','P')
and (server_name  not in ('abcd','aa','bb\SDSS'))
and (server_name  <>'xx' and drive <>'Z')
)
begin

DECLARE SPACECUR CURSOR FOR

SELECT SERVER_NAME,DRIVE, Lable_name,Total_SPACE_IN_MB,used_SPACE_IN_MB,FREE_SPACE_IN_MB,
Precentage_free FROM [DBA_All_Server_Space_percentage]
where Precentage_free<@P_Precentage_free AND DRIVE NOT IN ('Q','P')
and (server_name  not in ('abcd','aa','bb\SDSS'))
and (server_name  <>'xx' and drive <>'Z')
order by server_name

OPEN SPACECUR

FETCH NEXT FROM SPACECUR
INTO @SERVERNAME,@DRIVE,@Lable_NAME,@Total_SPACE_IN_MB,@used_SPACE_IN_MB,@FREE_SPACE_IN_MB,@Precentage_free

DECLARE @BODY1 VARCHAR(max)
SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>FOLLOWINGS ARE LOW DISK SPACE PERCENTAGE INFO:</b> </font>
<P> 
 <font size=1 color=#FF00FF  face=''verdana''>
<Table border=0 width=1000 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">  
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold"> 
 <td width=550 color=white>Server Name</td> 
 <td width=150 color=white>Drive</td>  
<td width=150 color=white>Lable</td> 
<td width=550 color=white>Total Space MB</td> 
<td width=550 color=white>Used Space MB</td> 
<td width=550 color=white>Free Space MB</td> 
<td width=350 color=white>% Free</td> 

</b>  

 </tr>'
WHILE @@FETCH_STATUS=0
BEGIN
SET @BODY1= @BODY1 +'<tr>
<td>'+ISNULL(@SERVERNAME,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@DRIVE+':','&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@Lable_NAME,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@Total_SPACE_IN_MB,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@used_SPACE_IN_MB,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@FREE_SPACE_IN_MB,'&nbsp')+'</td>'+
case when @Precentage_free< 10 then '<td align=center style="color:#FF0000;font-weight:bold">'+ISNULL(@Precentage_free,'&nbsp')+'</td>'
else '<td align=center >'+ISNULL(@Precentage_free,'&nbsp')+'</td>' end


FETCH NEXT FROM SPACECUR
INTO @SERVERNAME,@DRIVE,@Lable_NAME,@Total_SPACE_IN_MB,@used_SPACE_IN_MB,@FREE_SPACE_IN_MB,@Precentage_free
END
SET @BODY1=@BODY1+'</Table> </p>
<p>
<font style="color:#7E2217;font-face:verdana;font-size:9px;"> Generated on '
+convert(varchar(30),getdate(),100)+'. </BR>
This is an auto generated mail by DBA TEAM. If you receive this email by mistake please contact us. 
</br>
© Property of DBA Team.
</font>'

CLOSE SPACECUR
DEALLOCATE SPACECUR

DECLARE @EMAILIDS VARCHAR(500)

SELECT @EMAILIDS=
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS  FROM DBAdata.DBO.DBA_ALL_OPERATORS
WHERE STATUS =1

DECLARE @EMAILIDS1 VARCHAR(500)
--SELECT @EMAILIDS1= 'abc@xxx.com;xyz@xxx.com'
SELECT @EMAILIDS1= 'dbateam@abcd.com'



EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@SUBJECT = 'DBA: DISK SPACE PERCENTAGE INFO',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,
@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';
--select @BODY1

-------------------------------------------------------
end
--select * from DBAdata_Archive.dbo.DBA_All_Server_Space_percentage
insert into DBAdata_Archive.dbo.DBA_All_Server_Space_percentage
select *,GETDATE() from DBA_All_Server_Space_percentage



END

