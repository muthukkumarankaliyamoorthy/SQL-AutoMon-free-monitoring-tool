/*
use DBAdata
drop table DBA_All_Server_Space
CREATE TABLE [dbo].[DBA_All_Server_Space](
	[DRIVE] [char](1) NULL,
	[FREE_SPACE_IN_MB] [int] NULL,
	[SERVER_NAME] [varchar](50) NULL
)
/*=====================================*/
CREATE TABLE [dbo].[tbl_Error_handling](
	[Server_name] [varchar](50) NULL,
	[Module_name] [varchar](50) NULL,
	[Error_Line] [int] NULL,
	[Error_Number] [bigint] NULL,
	[Error_Severity] [int] NULL,
	[Error_State] [int] NULL,
	[Error_Message] [varchar](1000) NULL,
	[Upload_Date] [datetime] NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[DBA_ALL_OPERATORS](
	[NAME] [varchar](25) NULL,
	[EMAIL_ADDRESS] [nvarchar](100) NULL,
	[STATUS] [int] NULL,
	[Mail_copy] [varchar](5) NULL
) ON [PRIMARY]

select * from DBA_ALL_OPERATORS
insert into DBA_ALL_OPERATORS values ('Muthu','muthukkumaran.kaliyamoorthy@abcd.com',1,'CC')
/*=====================================*/

use [DBAdata_Archive]
CREATE TABLE [dbo].[DBA_All_Server_Space](
	[DRIVE] [char](1) NULL,
	[FREE_SPACE_IN_MB] [int] NULL,
	[SERVER_NAME] [varchar](50) NULL,
	[Upload_date] [datetime] NULL
) 

*/

-- DROP PROC [USP_DBA_GETSERVERSPACE]
-- Exec DBAdata.[dbo].[USP_DBA_GETSERVERSPACE] @Free_Space_threshold = 25 -- less than 25600 MB alert
USE DBAdata
GO
alter PROCEDURE [dbo].[USP_DBA_GETSERVERSPACE]
/*
Summary:     Space Utilization findings
Contact:     Muthukkumaran Kaliyamoorthy SQL DBA
Description: Space Utilization findings, alert for low space threshold

ChangeLog:
Date         Coder							Description
2013-jan-21	 Muthukkumaran Kaliyamoorthy     Updated the 2012 functionality                   


*/
--WITH ENCRYPTION
(@Free_Space_threshold int)
AS 


BEGIN
-- select * from DBADATA.DBO.DBA_ALL_SERVER_SPACE
TRUNCATE TABLE DBADATA.DBO.DBA_ALL_SERVER_SPACE

CREATE TABLE #TEMPSPACE
(
DRIVE VARCHAR(20),
SPACE INT
)

DECLARE @SERVER_NAME VARCHAR(200)
DECLARE @DESC VARCHAR(200)
--** PUT LOCAL SERVER FIRST.
INSERT INTO DBA_ALL_SERVER_SPACE
SELECT null,Null,null

INSERT INTO #TEMPSPACE
EXEC XP_FIXEDDRIVES

INSERT INTO DBA_ALL_SERVER_SPACE
SELECT *,@@servername AS SERVERNAME FROM #TEMPSPACE

--PRINT @@SERVERNAME +' COMPLETED.'


DECLARE ALLSERVER CURSOR
FOR

SELECT SERVERNAME,	[DESCRIPTION] FROM DBADATA.DBO.DBA_ALL_SERVERS
WHERE  svr_status ='running'


OPEN ALLSERVER
FETCH NEXT FROM ALLSERVER INTO @SERVER_NAME,@DESC

WHILE @@FETCH_STATUS=0  
BEGIN
BEGIN TRY

TRUNCATE TABLE #TEMPSPACE

INSERT INTO DBA_ALL_SERVER_SPACE
SELECT null,Null,null

EXEC ('EXEC [' + @SERVER_NAME+'].MASTER.DBO.USP_TEMPSPACE_POP')
EXEC ('INSERT INTO  #TEMPSPACE SELECT * FROM [' + @SERVER_NAME+'].MASTER.DBO.tempSpace')

INSERT INTO DBA_ALL_SERVER_SPACE
SELECT *,@DESC AS SERVERNAME FROM #TEMPSPACE

--PRINT 'SERVER ' +@SERVER_NAME+' COMPLETED.'
END TRY

BEGIN CATCH
--SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'Drive',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

--PRINT 'SERVER ['+@SERVER_NAME+']is not COMPLETED.'
END CATCH

FETCH NEXT FROM ALLSERVER INTO @SERVER_NAME,@DESC
END
CLOSE ALLSERVER
DEALLOCATE ALLSERVER
DROP TABLE #TEMPSPACE
----------------------------------------------------
-- May be its time to send the report to my DBA

DECLARE @SERVERNAME VARCHAR(500)
DECLARE @DRIVE VARCHAR(200)
DECLARE @SPACE VARCHAR(200)

if exists 
(
select 1 from dbadata.dbo.DBA_ALL_SERVER_SPACE 
where ( 
  (FREE_SPACE_IN_MB<@Free_Space_threshold AND DRIVE NOT IN ('Q','P'))
)

)
begin

DECLARE SPACECUR CURSOR FOR

SELECT SERVER_NAME,DRIVE, FREE_SPACE_IN_MB FROM [DBA_ALL_SERVER_SPACE]
where ( 
  (FREE_SPACE_IN_MB<@Free_Space_threshold AND DRIVE NOT IN ('Q','P'))
)
--and ((SERVER_NAME  not IN ('abcd','aa','bb','cc') and DRIVE ='c' and FREE_SPACE_IN_MB<4000))
order by SERVER_NAME

OPEN SPACECUR

FETCH NEXT FROM SPACECUR
INTO @SERVERNAME,@DRIVE,@SPACE

DECLARE @BODY1 VARCHAR(max)
SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>FOLLOWINGS ARE LOW DISK SPACE INFO FOR PROD SERVERS:</b> </font>
<P> 
 <font size=1 color=#FF00FF  face=''verdana''>
<Table border=0 width=500 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">  
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold"> 
 <td width=350 color=white>SERVER</td> 
 <td width=150 color=white>DRIVE</td>  
<td width=150 color=white>SPACE MB</td>  </b>  

 </tr>'
WHILE @@FETCH_STATUS=0
BEGIN
SET @BODY1= @BODY1 +'<tr>
<td>'+ISNULL(@SERVERNAME,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@DRIVE+':','&nbsp')+'</td>'
+
case when @SPACE< 1024 then '<td align=center style="color:#FF0000;font-weight:bold">'+ISNULL(@SPACE,'&nbsp')+'</td>'
else '<td align=center >'+ISNULL(@SPACE,'&nbsp')+'</td>' end


FETCH NEXT FROM SPACECUR
INTO @SERVERNAME,@DRIVE,@SPACE
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
SELECT @EMAILIDS1=
COALESCE(@EMAILIDS1+';','')+EMAIL_ADDRESS  FROM DBAdata.DBO.DBA_ALL_OPERATORS
WHERE STATUS =1 and Mail_copy='CC'

EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@SUBJECT = 'DBA: DISK SPACE INFO',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,
@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';
--select @BODY1

-------------------------------------------------------
end
--select * from DBAdata_Archive.dbo.DBA_ALL_SERVER_SPACE
insert into DBAdata_Archive.dbo.DBA_ALL_SERVER_SPACE
select *,GETDATE() from DBA_ALL_SERVER_SPACE

END

