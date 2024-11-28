
/*

use [DBAdata]
--drop table tbl_agent_Status
go
CREATE TABLE [dbo].[tbl_agent_Status](
	[servername] varchar(200) not null,
	instance_name varchar(200),
	Edition varchar (50),
	Status varchar (50),
	Date datetime,
	
)


*/
-- select * from tbl_agent_Status
use [DBAdata]
go
-- Exec [DBAdata].[dbo].[Usp_Agent_Status]
--DROP PROC [Usp_Agent_Status]
create PROCEDURE [dbo].[Usp_Agent_Status]
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

-- select * from dbadata.dbo.tbl_agent_Status

Truncate table dbadata.dbo.tbl_agent_Status

      DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @sql varchar(8000)
      DECLARE @minrow int
      DECLARE @maxrow int

---------------------------------------------------
--Put the local server first
---------------------------------------------------
 

IF EXISTS (  SELECT 1 
             FROM master.dbo.sysprocesses 
             WHERE program_name = N'SQLAgent - Generic Refresher')



BEGIN
insert into tbl_agent_Status
    SELECT @@SERVERNAME as server , convert ( varchar(max),SERVERPROPERTY('servername')) AS InstanceName,
	convert (varchar(max),SERVERPROPERTY('edition'))as edition,	'Running' AS SQLServerAgent_Status, getdate() as today_date
	
END

ELSE 
BEGIN
insert into tbl_agent_Status
     SELECT @@SERVERNAME as server , convert ( varchar(max),SERVERPROPERTY('servername')) AS InstanceName,
	convert (varchar(max),SERVERPROPERTY('edition'))as edition,	'Running' AS SQLServerAgent_Status, getdate() as today_date
	
	
END

  

 

 declare @agent_status table (id int  primary key identity, 
 servername varchar(100),Description varchar(100)) 
 
 insert into @agent_status
 select Servername , Description   from dbadata.dbo.dba_all_servers 
 WHERE svr_status ='running'

 --select *  from dbadata.dbo.dba_all_servers
SELECT @minrow = MIN(id)FROM   @agent_status
SELECT @maxrow  = MAX(id) FROM   @agent_status
 
 while (@minrow <=@maxrow)
 begin
 BEGIN TRY
 select @Server_name=Servername ,
 @Desc=Description   from @agent_status where ID = @minrow 
 
----------------------------------------------------------------
--insert the value to table
-----------------------------------------------------------------
set @sql=
'EXEC(''SELECT * from OPENQUERY(['+@server_name+'],

''''

IF EXISTS (  SELECT 1 
             FROM master.dbo.sysprocesses 
             WHERE program_name = N''''''''SQLAgent - Generic Refresher'''''''')



BEGIN

    SELECT '''''''''+@desc+''''''''' as server , convert ( varchar(max),SERVERPROPERTY(''''''''servername'''''''')) AS InstanceName,
convert (varchar(max),SERVERPROPERTY(''''''''edition''''''''))as edition,	''''''''Running'''''''' AS SQLServerAgent_Status, getdate() as today_date
	
END

ELSE 
BEGIN

     SELECT '''''''''+@desc+''''''''' as server , convert ( varchar(max),SERVERPROPERTY(''''''''servername'''''''')) AS InstanceName,
convert (varchar(max),SERVERPROPERTY(''''''''edition''''''''))as edition,	''''''''Running'''''''' AS SQLServerAgent_Status, getdate() as today_date
	
	
END

	  
'''')'')
      '
 
 insert into dbadata.dbo.tbl_agent_Status
 exec(@sql)

end try
BEGIN CATCH
SELECT @SERVER_NAME,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
insert into tbl_Error_handling
 
SELECT @SERVER_NAME,'Agent Status',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

--PRINT 'SERVER ['+@SERVER_NAME+']is not COMPLETED.'
END CATCH
 
set @minrow =@minrow +1 
 end
 
 
  
----------------------------------------------------------------
--Send an email to DBA team
-----------------------------------------------------------------
      DECLARE @minid INT
      DECLARE @maxid INT
      DECLARE @servername varchar(100)
      DECLARE @edition varchar(100)
      DECLARE @status varchar(100)
      
      
-- select * from dbadata.dbo.tbl_agent_Status 
if exists (

select 1 from dbadata.dbo.tbl_agent_Status where status <>'running' and Edition not like '%express%' 
)

begin

DECLARE Agent_CUR CURSOR FOR

SELECT servername,Edition, status
FROM tbl_agent_Status 
where status <>'running' and Edition not like '%express%' 

OPEN Agent_CUR

FETCH NEXT FROM Agent_CUR
INTO @servername,@edition,@Status


DECLARE @BODY1 VARCHAR(max)
SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>SQL agent Service Status:</b> </font>
<P> 
 <font size=1 color=#FF00FF  face=''verdana''>
<Table border=5 width=1000 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">  
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold"> 
 <td width=600 color=white>SERVER</td> 
 <td width=600 color=white>Edition</td> 
   <td width=600 color=white>Status</td>  
  </b>  

 </tr>'
WHILE @@FETCH_STATUS=0
BEGIN
SET @BODY1= @BODY1 +'<tr>
<td>'+ISNULL(@SERVERNAME,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@edition,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@status,'&nbsp')+'</td>'


FETCH NEXT FROM Agent_CUR
INTO @servername,@edition,@Status

END
SET @BODY1=@BODY1+'</Table> </p>
<p>
<font style="color:#7E2217;font-face:verdana;font-size:9px;"> Generated on '
+convert(varchar(30),getdate(),100)+'. </BR>
This is an auto generated mail by DBA team. If you receive this email by mistake please contact us. 
 </br>
© Property of DBA Team.
 </font>'

CLOSE Agent_CUR
DEALLOCATE Agent_CUR
DECLARE @EMAILIDS VARCHAR(500)

SELECT @EMAILIDS=
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS  FROM dbo.DBA_ALL_OPERATORS
WHERE STATUS=1


DECLARE @EMAILIDS1 VARCHAR(500)
--SELECT @EMAILIDS1= 'abc@xxx.com;xyz@xxx.com'
SELECT @EMAILIDS1= 'dbateam@xxx.com'



EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@SUBJECT = 'DBA: Agent Service Status',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,

@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';
--select @BODY1

-------------------------------------------------------

end

END



