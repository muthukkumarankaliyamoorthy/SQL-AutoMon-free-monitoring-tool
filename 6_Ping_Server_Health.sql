/*

use dbadata
go
create table dbadata.dbo.dba_PingServers   
(  
server varchar(255),  
uptime datetime ,  
status varchar(255) 
--,loadtime datetime
) 

use dbadata_archive
go
create table dbadata_archive.dbo.dba_PingServers   
(  
server varchar(255),  
uptime datetime ,  
status varchar(255) , 
loadtime datetime
) 

*/

USE [DBAData]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select * from dbo.dba_PingServers  
 
-- Exec  [DBAData].[dbo].[usp_prdServerPing_1]
create proc [dbo].[usp_prdServerPing_1]
/*

Summary:     Ping server health status
Contact:     Muthukkumaran Kaliyamoorthy SQL DBA
Description: Ping server health status alert

ChangeLog:
Date         Coder							Description
2013-jan-21	 Muthukkumaran Kaliyamoorthy     Updated the 2012 functionality                   


*/  
--WITH ENCRYPTION   

as begin  
  
Declare @servername varchar(255)  
Declare @description varchar(255)  
Declare @uptime datetime  
/*  
declare @PingServers table  
(  
server varchar(255),  
uptime datetime ,  
status varchar(255)  
) 



 

*/

delete from dba_PingServers

Declare @cmd varchar(255)  
  
Declare cur_serv cursor for   

select servername,description from   
dbo.DBA_All_servers  where SVR_status in('running')--and version  in ('sql2000')

open cur_serv  
Fetch next from  cur_serv into @servername,@description  
  
while @@fetch_status=0  
begin   
set @cmd= 'select top 1 '''+@description+''',convert(datetime,getdate(),103)-cast(login_time as DATETIME),null from ['+@servername+'].master.dbo.sysprocesses where spid=1'  
begin try   
  
insert into dba_PingServers  
exec (@cmd)  
  
--print @cmd  
  
end try   
  
begin catch  
--print error_message()  
insert into tbl_Error_handling
 
SELECT @description,'Ping',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()

insert into dba_PingServers values (@description,null,'Cannot Ping')  

select * from tbl_Error_handling where Module_name='ping' and  Upload_Date>=DATEADD(HH,-1,getdate())
-- by Upload_Date desc
select getdate(),DATEADD(HH,-1,getdate())
end catch  
  
Fetch next from  cur_serv into @servername,@description  
end   
close cur_serv  
deallocate cur_serv  
  
update dba_PingServers set status ='Server running for past '+
cast(datediff(day,'1900-01-01 00:00:00.00',uptime) as varchar)+' days '+
cast(datepart(Hour,uptime)  as varchar)+' hrs and '+cast(datepart(minute,uptime) as varchar)+' minutes '  
 

-- select * from dba_PingServers  
-- select * from dbadata_archive.dbo.dba_PingServers
if exists (select 1 from dba_PingServers where uptime is null)
begin

DECLARE @SERVER VARCHAR(200)    
  
DECLARE pingCUR CURSOR FOR   
 
SELECT SERVER FROM dba_PingServers where uptime is null   
    
OPEN pingCUR    
    
FETCH NEXT FROM pingCUR    
INTO @SERVER  

DECLARE @BODY1 VARCHAR(max)    
SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>Followings are the servers not connecting:</b> </font>    
<P>     
 <font size=1 color=#FF00FF  face=''verdana''>    
<Table border=0 width=450 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">      
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold">     
 <td width=600 color=white>SERVER</td>     
 </tr>'    
WHILE @@FETCH_STATUS=0    
BEGIN    
SET @BODY1= @BODY1 +'<tr>    
<td>'+ISNULL(@SERVER,'&nbsp;')+'</td>'  
  
    
FETCH NEXT FROM pingCUR
INTO @SERVER  

END
SET @BODY1=@BODY1+'</Table> </p>
<p>
<font style="color:#7E2217;font-face:verdana;font-size:9px;"> Generated on '
+convert(varchar(30),getdate(),100)+'. </BR>
This is an auto generated mail by DBA Team. If you receive this email by mistake please contact us. 
 </br>
© Property of DBA Team.
 </font>'

CLOSE pingCUR
DEALLOCATE pingCUR
DECLARE @EMAILIDS VARCHAR(500)

SELECT @EMAILIDS=
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS  
FROM DBADATA.dbo.DBA_ALL_OPERATORS WHERE name ='muthu' and STATUS =1
    
    
 DECLARE @EMAILIDS1 VARCHAR(500)

--SELECT @EMAILIDS1= 'abcd@xyz.com'


EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@SUBJECT = 'DBA: Ping drops server hung Status',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,
@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';
--select @BODY1

end 

insert into dbadata_archive.dbo.dba_PingServers  
select *,getdate() from dba_PingServers

--*/ 
end  

