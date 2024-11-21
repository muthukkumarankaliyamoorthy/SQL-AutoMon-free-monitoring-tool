
/*

use [DBAdata]
--drop table tbl_Linked_Server_Status
go
CREATE TABLE [dbo].[tbl_Linked_Server_Status](
	[servername] varchar(200),
	error_no bigint,
	errors varchar(2000),
	Date datetime
	
)


*/
-- select * from tbl_Linked_Server_Status
use [DBAdata]
go
-- Exec [DBAdata].[dbo].[Usp_Linked_server_Status_Check]
--DROP PROC [Usp_Linked_server_Status_Check]
create PROCEDURE [dbo].[Usp_Linked_server_Status_Check]
/*
Summary:     Check the SQL agent stats
Contact:     Muthukkumaran Kaliyamoorhty SQL DBA
Description: Check the SQL agent stats

ChangeLog:
Date         Coder							Description
2013-jan-21	 Muthukkumaran Kaliyamoorhty     Updated the 2012 functionality                   



*/
--WITH ENCRYPTION

AS
BEGIN
SET nocount ON

-- select * from dbadata.dbo.tbl_Linked_Server_Status

Truncate table dbadata.dbo.tbl_Linked_Server_Status

      DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      --DECLARE @sql varchar(8000)
      DECLARE @minrow int
      DECLARE @maxrow int

 declare @Linked_status table (id int  primary key identity,  servername varchar(100),Description varchar(100)) 
 
 insert into @Linked_status
 select Servername , Description   from dbadata.dbo.dba_all_servers  WHERE svr_status ='running'

 --select *  from dbadata.dbo.dba_all_servers
SELECT @minrow = MIN(id)FROM   @Linked_status
SELECT @maxrow  = MAX(id) FROM   @Linked_status
 
 while (@minrow <=@maxrow)
 begin
 BEGIN TRY
 select @Server_name=Servername   from @Linked_status where ID = @minrow 
  Exec sp_testlinkedserver @server_name;
 end try
BEGIN CATCH


insert into tbl_linked_server_status
select @server_name,ERROR_NUMBER(), ERROR_MESSAGE(), Getdate();


END CATCH
 
set @minrow =@minrow +1 
 end
 
 
  
----------------------------------------------------------------
--Send an email to DBA team
-----------------------------------------------------------------
      DECLARE @minid INT
      DECLARE @maxid INT
      DECLARE @servername varchar(100)
      DECLARE @error_no varchar(100)
	  DECLARE @errors varchar(100)
	  DECLARE @date varchar(100)
      
      
-- select * from dbadata.dbo.tbl_Linked_Server_Status 
if exists (

select 1 from dbadata.dbo.tbl_Linked_Server_Status
)

begin

DECLARE Linked_CUR CURSOR FOR

SELECT *
FROM tbl_Linked_Server_Status 


OPEN Linked_CUR

FETCH NEXT FROM Linked_CUR
INTO @servername,@error_no,@errors,@date


DECLARE @BODY1 VARCHAR(max)
SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>AutoMon Linked server Status:</b> </font>
<P> 
 <font size=1 color=#FF00FF  face=''verdana''>
<Table border=5 width=1000 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">  
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold"> 
 <td width=600 color=white>SERVER</td> 
 <td width=600 color=white>Error Number</td> 
 <td width=600 color=white>Error</td> 
   <td width=600 color=white>Date</td>  
  </b>  

 </tr>'
WHILE @@FETCH_STATUS=0
BEGIN
SET @BODY1= @BODY1 +'<tr>
<td>'+ISNULL(@SERVERNAME,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@error_no,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@errors,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@date,'&nbsp')+'</td>'


FETCH NEXT FROM Linked_CUR
INTO @servername,@error_no,@errors,@date

END
SET @BODY1=@BODY1+'</Table> </p>
<p>
<font style="color:#7E2217;font-face:verdana;font-size:9px;"> Generated on '
+convert(varchar(30),getdate(),100)+'. </BR>
This is an auto generated mail by DBA team. If you receive this email by mistake please contact us. 
 </br>
© Property of DBA Team.
 </font>'

CLOSE Linked_CUR
DEALLOCATE Linked_CUR
DECLARE @EMAILIDS VARCHAR(500)

SELECT @EMAILIDS=
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS  FROM dbo.DBA_ALL_OPERATORS
WHERE STATUS=1


DECLARE @EMAILIDS1 VARCHAR(500)
--SELECT @EMAILIDS1= 'abc@xxx.com;xyz@xxx.com'
SELECT @EMAILIDS1= 'dbateam@xxx.com'



EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@SUBJECT = 'DBA: AutoMon Linked server Status',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,

@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';
--select @BODY1

-------------------------------------------------------

end

END



