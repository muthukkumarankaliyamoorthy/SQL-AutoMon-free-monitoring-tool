/*
--drop table Backup_filer_space_check
--drop table Backup_filer_space_check_final

use dbadata
go
drop table Backup_filers_name
CREATE TABLE [dbo].[Backup_filers_name](
	[filer_no] [int] IDENTITY(1,1) NOT NULL,
	[filer_name] [varchar](100) NOT NULL,
	[filer_name_original] [varchar](100) NULL,
	[filer_Satus] [varchar](20) NULL,
	[access_from_local] [varchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[filer_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
)

drop table Backup_filer_space_check
create table Backup_filer_space_check
(Filer_name varchar(500),output varchar(1000),date datetime)

use DBAdata_Archive
go
drop table Backup_filer_space_check_final
create table Backup_filer_space_check_final
(Filer_name varchar(500),Free_space_GB varchar (1000),date datetime)

*/

/*
update Backup_filers_name set filer_satus = 'Not in use' where filer_name 
in(
'\\share\spbackup\',

)
*/

use dbadata
go

alter  PROCEDURE [dbo].[USP_DBA_GET_FILER_SPACE]
/*
Summary:     File share Space Utilization findings
Contact:     Muthukkumaran Kaliyamoorhty SQL DBA
Description: FILER Space Utilization findings

ChangeLog:
Date         Coder							Description
2013-FEB-17	 Muthukkumaran Kaliyamoorhty     Updated the 2012 functionality                   


*/
WITH ENCRYPTION
AS 
BEGIN

declare @minid int
declare @maxid int
declare @fname varchar(500)

truncate table Backup_filer_space_check
truncate table Backup_filer_space_check_final

create table #Backup_filer
(output varchar(1000))


declare @backup_share_info table (id int  primary key identity, 
filer_name varchar(100),filer_satus varchar(100),access_from_local varchar(20) ) 

insert into @backup_share_info
select filer_name,filer_satus,access_from_local from Backup_filers_name where filer_satus ='running'
and  access_from_local='accessed'

SELECT @minid = MIN(id)FROM   @backup_share_info
SELECT @maxid  = MAX(id) FROM   @backup_share_info

while (@minid<=@maxid)
begin
select @fname=filer_name from @backup_share_info where id=@minid and  access_from_local='accessed'
--select @fname

BEGIN TRY

insert into #Backup_filer
--exec xp_cmdshell 'dir ''''['+ @fname +']'''''
EXEC ('exec xp_cmdshell ''dir '+@fname+'''')
--select * from #Backup_filer
--select @fname

insert into Backup_filer_space_check
select @fname,ltrim(output),getdate() from #Backup_filer
where ltrim(output) like '%Dir(s)%'
--select @fname,ltrim(output),getdate() from #Backup_filer
--where ltrim(output) like '%bytes free%'
truncate table #Backup_filer
END TRY

BEGIN CATCH

--select * from tbl_Error_handling
insert into tbl_Error_handling
 
SELECT @fname,'Bak_Share',[Error_Line] = ERROR_LINE(),[Error_Number] = ERROR_NUMBER(),
[Error_Severity] = ERROR_SEVERITY(),[Error_State] = ERROR_STATE(),
[Error_Message] = ERROR_MESSAGE(),GETDATE()


SELECT @fname,ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;

END CATCH

set @minid=@minid+1

end
drop table #Backup_filer

insert into Backup_filer_space_check_final

select filer_name
,cast(replace(replace (replace (substring(LTrim(output),11,100),',',''),' ',''),'bytesfree','')as bigint)/1024/1024/1024 
As GB_filer
,date
from Backup_filer_space_check where output like '%Dir(s)%'






-- select * from Backup_filer_space_check
-- select * from Backup_filer_space_check_final
-- select * from Backup_filers_name
----------------------------------------------------
-- May be its time to send the report to my DBA


DECLARE @filer_name VARCHAR(200)
DECLARE @Free_space VARCHAR(200)

if exists 
(
select 1
from Backup_filer_space_check_final 
--where Free_space_GB <500

)
BEGIN

DECLARE Filer_cursor CURSOR FOR

select filer_name,Free_space_GB
from Backup_filer_space_check_final 
--where Free_space_GB <500 order by Free_space_GB desc

OPEN Filer_cursor

FETCH NEXT FROM Filer_cursor
INTO @filer_name,@Free_space

DECLARE @BODY1 VARCHAR(max)
SET @BODY1=  '<font size=2 color=#C35817  face=''verdana''><B>FOLLOWINGS ARE FILER SPACE INFO FOR SQL SERVERS:</b> </font>
<P> 
 <font size=1 color=#FF00FF  face=''verdana''>
<Table border=0 width=1000 bgcolor=#ECE5B6 cellpadding=1  style="color:#7E2217;font-face:verdana;font-size:12px;">  
 <b>  <tr bgcolor=#8A4117 align=center style="color:#FFFFFF;font-weight:bold"> 
 <td width=600 color=white>Filer Name </td> 
 <td width=200 color=white>Free Space GB</td>  
</b>  
</tr>'
WHILE @@FETCH_STATUS=0
BEGIN
SET @BODY1= @BODY1 +'<tr>
<td>'+ISNULL(@filer_name,'&nbsp')+'</td>'+
'<td align=center>'+ISNULL(@Free_space,'&nbsp')+'</td>'

FETCH NEXT FROM Filer_cursor
INTO @filer_name,@Free_space

END

SET @BODY1=@BODY1+'</Table> </p>
<p>
<font style="color:#7E2217;font-face:verdana;font-size:9px;"> Generated on '
+convert(varchar(30),getdate(),100)+'. </BR>
This is an auto generated mail by DBA Team. If you receive this email by mistake please contact us. 
 </br>
© Property of DBA Team.
 </font>'

CLOSE Filer_cursor
DEALLOCATE Filer_cursor
DECLARE @EMAILIDS VARCHAR(500)

SELECT @EMAILIDS=
COALESCE(@EMAILIDS+';','')+EMAIL_ADDRESS  FROM DBAdata.DBO.DBA_ALL_OPERATORS
WHERE STATUS =1


DECLARE @EMAILIDS1 VARCHAR(500)


EXEC MSDB.DBO.SP_SEND_DBMAIL @RECIPIENTS=@EMAILIDS,
@SUBJECT = 'DBA: Filler Share Space Usage',
@BODY = @BODY1,
@copy_recipients=@EMAILIDS1,
@BODY_FORMAT = 'HTML' ,@PROFILE_NAME='muthu';
--select @BODY1

-------------------------------------------------------
end

--select * from DBAdata_Archive.dbo.Backup_filer_space_check_final
insert into DBAdata_Archive.dbo.Backup_filer_space_check_final
select * from Backup_filer_space_check_final

END