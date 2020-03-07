
alter procedure USP_DBA_ErrorHandling_Report
/*
Summary:     Send a error report of script
Contact:     Muthukkumaran Kaliyamoorthy SQL DBA
Description: Send a error report of script

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
      DECLARE @Module_name varchar(100)
	  DECLARE @error varchar(100)
      
-- select * from dbadata.dbo.tbl_get_datafiles_size 
if exists (
select 1
from tbl_Error_handling 
where Upload_Date>=DATEADD(Day,-1,getdate())
and Module_name <>'Perfmon'
group by Server_name,Module_name,[error_message]
having count(*)>=1
)

begin

DECLARE Svr_error_CUR CURSOR FOR

select Server_name,Module_name, left([error_message],25) AS error
from tbl_Error_handling 
where Upload_Date>=DATEADD(Day,-1,getdate())
and Module_name <>'Perfmon'
group by Server_name,Module_name,[error_message]
having count(*)>=1

OPEN Svr_error_CUR

FETCH NEXT FROM Svr_error_CUR
INTO @servername,@Module_name,@error

DECLARE @BODY1 VARCHAR(max)
SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>DBA: Error server report:</b> </font>
<P> 
 <font size=1 color=#FF00FF  face=''verdana''>
<Table border=5 width=1000 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">  
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold"> 
 <td width=600 color=white>SERVER</td> 
 <td width=600 color=white>Module</td> 
   <td width=600 color=white>Error</td>  
  </b>  

 </tr>'
WHILE @@FETCH_STATUS=0
BEGIN
SET @BODY1= @BODY1 +'<tr>
<td>'+ISNULL(@SERVERNAME,'&nbsp')+'</td>'+
'<td>'+ISNULL(@Module_name,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@error,'&nbsp')+'</td>'


FETCH NEXT FROM Svr_error_CUR
INTO @servername,@Module_name,@error
END
SET @BODY1=@BODY1+'</Table> </p>
<p>
<font style="color:#7E2217;font-face:verdana;font-size:9px;"> Generated on '
+convert(varchar(30),getdate(),100)+'. </BR>
This is an auto generated mail by DBA team. If you receive this email by mistake please contact us. 
 </br>
© Property of DBA Team.
 </font>'

CLOSE Svr_error_CUR
DEALLOCATE Svr_error_CUR
DECLARE @EMAILIDS VARCHAR(500)

SELECT @EMAILIDS=
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS  FROM dbo.DBA_ALL_OPERATORS
WHERE STATUS=1
DECLARE @EMAILIDS1 VARCHAR(500)
SELECT @EMAILIDS1=
COALESCE(@EMAILIDS1+';','')+EMAIL_ADDRESS  FROM DBAdata.DBO.DBA_ALL_OPERATORS
WHERE STATUS =1 and Mail_copy='CC'

EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@SUBJECT = 'DBA: Error server report',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,
--@blind_copy_recipients='HCL_NOC@sandisk.com',
@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';
end
END

