/*
select min(counterDateTime),max(counterDateTime) from [dbo].[CounterData] with (nolock)

select top 10 * From counterdata
*/
use DBA_Perfmon
go
--select @@servername
SELECT top 10
counterdetails.machinename,
       counterdetails.objectname,
       counterdetails.countername,
       --counterdetails.countertype,
       counterdetails.instancename,
       Datediff(minute, st.starttime, Cast(LEFT(counterdata.counterdatetime, Len(counterdata.counterdatetime) - 8) AS DATETIME)) AS interval,
       Avg(counterdata.countervalue) AS Avg_countervalue
	   --Avg(counterdata.countervalue) /1024/1024 AS counterValues_GB
	   --counterdata.countervalue AS counterValues
	   ,Cast(LEFT(counterdata.counterdatetime, Len(counterdata.counterdatetime) - 8)AS DATETIME) as Load_Time
FROM   counterdata
INNER JOIN counterdetails ON counterdata.counterid = counterdetails.counterid,
(
SELECT counterdetails.machinename,
Min(Cast(LEFT(counterdata.counterdatetime, Len(counterdata.counterdatetime) - 8)AS DATETIME))AS startTime
FROM   counterdata
INNER JOIN counterdetails ON counterdata.counterid = counterdetails.counterid
GROUP  BY machinename
) AS st

-------================================
WHERE  st.machinename = counterdetails.machinename
--AND counterdata.counterdatetime >'2017-11-01 14:56:00.000'
-------================================ OBJECTNAME
--and objectname in ('PhysicalDisk')
AND CounterName in ('Avg. Disk sec/Transfer')
--AND CounterName in ('Disk Bytes/sec', 'Avg. Disk sec/Transfer','IO Data Bytes/sec')
--and counterdata.counterdatetime between '2017-11-20'and'2017-11-21'
/*
and Datediff(minute, st.starttime, Cast(LEFT(counterdata.counterdatetime, Len(counterdata.counterdatetime) - 8) AS DATETIME))  in(
'187082',
'186657',
'186657',
'186652',
'186652'

)
*/
--and InstanceName in ('J','N','E','L')
--and InstanceName not in ('J','N','E','L')

--and objectname in ('memory')
--AND CounterName in ('Available MBytes')
/*
AND objectname in ('Paging File','Processor','Process(sqlservr) Process(msmdsrv)'
,'System','PhysicalDisk','Memory','SQLServer:Memory Manager','SQLServer:Buffer Manager'
,'SQLServer:Databases','SQLServer:General Statistics','SQLServer:SQL Statistics'
,'SQLServer:Access Methods','LogicalDisk')
*/
/************************************************************ COUNTER ******************/

-------================================ CPU
--AND CounterName in ('Processor Queue Length','% Usage','% Processor Time','% Privilege Time','Context Switches/sec') -- CPU

-------================================ Disk
--2017-11-07 00:20:00.000 & 2017-11-06 23:15:00.000

--and 

--AND CounterName in ('Avg ms/read','Avg ms/write','Avg. Disk sec/Read','Avg. Disk sec/Write','Avg. Disk Queue Length')
--,'Disk Read Bytes/sec','Disk Write Bytes/sec') -- Disk
-------================================ general filter
--AND CounterName in( 'Free Pages/sec' , 'Free List Stalls/sec' ) -- general filter
-------================================ RAM
/*
AND CounterName in ('Available MBytes','Memory Grants Pending','Total Server Memory (KB)','Target Server Memory (KB)'
,'Free Memory (KB)','Stolen Server Memory (KB)','Stolen Pages/sec','Lazy writes/sec'
,'Page life expectancy','Lazy writes/sec','Page reads/sec','Page writes/sec','Buffer cache hit ratio'
,'Free Pages/sec' , 'Free List Stalls/sec','Pages/sec'
)-- RAM
*/
/*
-------================================ Transaction
AND CounterName in ('Log Flush Waits/sec','User Connections','Batch Requests/Sec','SQL Server: SQL Statistics','SQL Re-Compilations/sec'
,'Forwarded Records/sec','Full Scans/sec','Index Searches/sec'
) -- Transaction
*/
-------================================ Date
--and Cast(LEFT(counterdata.counterdatetime, Len(counterdata.counterdatetime) - 8)AS DATETIME) between '2017-08-07' and '2017-08-09'

GROUP  BY counterdetails.machinename,
          counterdetails.objectname,
          counterdetails.countername,
          counterdetails.countertype,
          counterdetails.instancename,
          Datediff(minute, st.starttime, Cast(LEFT(counterdata.counterdatetime, Len(counterdata.counterdatetime) - 8) AS DATETIME))
		  ,counterdata.countervalue 
 ,Cast(LEFT(counterdata.counterdatetime, Len(counterdata.counterdatetime) - 8)AS DATETIME)

having counterdata.countervalue>0.01
--having counterdata.countervalue/1024/1024<50
order by Cast(LEFT(counterdata.counterdatetime, Len(counterdata.counterdatetime) - 8)AS DATETIME) desc
--order by CounterValue 

--Avg(counterdata.countervalue)/1024/1024


--==================================
 -- get the counter name for object/ counter
 /*
 
 use [DBA_Perfmon]

 -- object
 select CounterName ,objectname from counterdetails  where objectname like '%user%'  
 group by CounterName,objectname

 -- counter
 select CounterName ,objectname from counterdetails  where countername like '%user%'  
 group by CounterName,objectname


 select CounterName ,objectname from counterdetails 
 group by CounterName,objectname

 select instancename,count(*) from counterdetails group by instancename
 select * from counterdetails where instancename is null


 */