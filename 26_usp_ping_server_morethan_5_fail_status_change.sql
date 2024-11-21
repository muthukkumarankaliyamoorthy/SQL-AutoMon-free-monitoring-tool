-- exec usp_ping_server_morethan_5_fail_status_change
--  select * from DBA_All_servers where SVR_status<>'running'
-- select * from tbl_Error_handling where Module_name='ping'
create proc usp_ping_server_morethan_5_fail_status_change
/*
Summary:     Auto maintenance after 5 ping fails
Contact:     Muthukkumaran Kaliyamoorthy SQL DBA
Description: Auto maintenance after 5 ping fails

ChangeLog:
Date         Coder							Description
2013-jan-21	 Muthukkumaran Kaliyamoorhty     Updated the 2012 functionality                   


*/
as
BEGIN
declare @count_s int


select @count_s=count(*) from tbl_Error_handling E
join DBA_All_servers A on (e.Server_name=a.Description)
where Module_name='ping' and  Upload_Date>=DATEADD(HH,-1,getdate())
--and a.SVR_status='running'
group by Server_name
having count(*)>=5
--select @count_s

if (@count_s>=5)
begin


 DECLARE @server_name SYSNAME
      DECLARE @DESC SYSNAME
      DECLARE @sql varchar(8000)
      DECLARE @minrow int
      DECLARE @maxrow int

 declare @ping_u table (id int  primary key identity, 
 servername varchar(100),count_R varchar(100)) 
 
insert into @ping_u

select Server_name,count(*) from tbl_Error_handling 
where Module_name='ping' and  Upload_Date>=DATEADD(HH,-1,getdate())
group by Server_name
having count(*)>=5
 
SELECT @minrow = MIN(id)FROM   @ping_u
SELECT @maxrow  = MAX(id) FROM   @ping_u
 
 while (@minrow <=@maxrow)
 begin
 
 select @Server_name=Servername  from @ping_u where ID = @minrow 
 
 --select @minrow,@maxrow

print @Server_name


update DBA_All_servers set SVR_status='not ping_U' where Description=@Server_name
update DBA_All_servers set maintenance_date= getdate() where Description=@Server_name
--select Description,SVR_status from DBA_All_servers where Description=@Server_name

 set @minrow =@minrow +1 
 end

end

END
