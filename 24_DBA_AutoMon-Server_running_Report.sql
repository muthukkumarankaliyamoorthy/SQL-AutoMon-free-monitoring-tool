
alter procedure USP_DBA_AutoMon_server_Report
/*
Summary:     Send a server which are not monitored by tool
Contact:     Muthukkumaran Kaliyamoorthy SQL DBA
Description: Send a server which are not monitored by tool

ChangeLog:
Date         Coder							Description
2013-jan-21	 Muthukkumaran Kaliyamoorhty     Updated the 2012 functionality                   


*/
--WITH ENCRYPTION
AS
BEGIN
SET nocount ON

--Send an email to DBA team
-----------------------------------------------------------------
      DECLARE @minid INT
      DECLARE @maxid INT
      DECLARE @servername varchar(100)
      DECLARE @SVR_status varchar(100)
      
-- select * from dbadata.dbo.tbl_get_datafiles_size 
if exists (select Description,SVR_status from dbadata.dbo.DBA_All_servers where SVR_status<>'running')

begin

DECLARE Svr_running_CUR CURSOR FOR

select Description,SVR_status from dbadata.dbo.DBA_All_servers where SVR_status<>'running'

OPEN Svr_running_CUR

FETCH NEXT FROM Svr_running_CUR
INTO @servername,@SVR_status

DECLARE @BODY1 VARCHAR(max)
SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>AutoMON DBA maintenance server report:</b> </font>
<P> 
 <font size=1 color=#FF00FF  face=''verdana''>
<Table border=5 width=1000 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">  
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold"> 
 <td width=600 color=white>SERVER</td> 
   <td width=600 color=white>Status</td>  
  </b>  

 </tr>'
WHILE @@FETCH_STATUS=0
BEGIN
SET @BODY1= @BODY1 +'<tr>
<td>'+ISNULL(@SERVERNAME,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@SVR_status,'&nbsp')+'</td>'


FETCH NEXT FROM Svr_running_CUR
INTO @servername,@SVR_status
END
SET @BODY1=@BODY1+'</Table> </p>
<p>
<font style="color:#7E2217;font-face:verdana;font-size:9px;"> Generated on '
+convert(varchar(30),getdate(),100)+'. </BR>
This is an auto generated mail by DBA team. If you receive this email by mistake please contact us. 
 </br>
© Property of DBA Team.
 </font>'

CLOSE Svr_running_CUR
DEALLOCATE Svr_running_CUR
DECLARE @EMAILIDS VARCHAR(500)

SELECT @EMAILIDS=
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS  FROM dbo.DBA_ALL_OPERATORS
WHERE STATUS=1
DECLARE @EMAILIDS1 VARCHAR(500)
SELECT @EMAILIDS1=
COALESCE(@EMAILIDS1+';','')+EMAIL_ADDRESS  FROM DBAdata.DBO.DBA_ALL_OPERATORS
WHERE STATUS =1 and Mail_copy='CC'

EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@SUBJECT = 'DBA: AutoMON maintenance server report',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,
--@blind_copy_recipients='HCL_NOC@sandisk.com',
@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';
end
END

