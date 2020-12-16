
-- To find the ObjectName,CounterName,InstanceName
select ObjectName,CounterName,InstanceName from CounterDetails   
JOIN CounterData ON CounterData.CounterID = CounterDetails.CounterID  JOIN DisplayToID ON DisplayToID.GUID = CounterData.GUID
where ObjectName like '%Buffer%'
group by ObjectName,CounterName,InstanceName

SELECT MachineName,CounterName,
   CONVERT(DATETIME, CONVERT(VARCHAR(16), CounterDateTime)) as [Date],
   AVG(CounterValue) as Average,
   MIN(CounterValue) as Minimum,
   MAX(CounterValue) as Maximum
FROM CounterDetails
   JOIN CounterData ON CounterData.CounterID = CounterDetails.CounterID
   JOIN DisplayToID ON DisplayToID.GUID = CounterData.GUID
WHERE ObjectName like '%Physical%'
GROUP BY MachineName,CounterName,
   CONVERT(DATETIME, CONVERT(VARCHAR(16), CounterDateTime)) 


   SELECT  MachineName ,
        CounterName ,
        InstanceName ,
        CounterValue ,
        CounterDateTime ,
        DisplayString
FROM    dbo.CounterDetails cdt
        INNER JOIN dbo.CounterData cd ON cdt.CounterID = cd.CounterID
        INNER JOIN DisplayToID d ON d.GUID = cd.GUID
WHERE   MachineName like '%K%'
AND ObjectName like '%buffer%' AND cdt.CounterName like '%Page life expectancy%'  --AND cdt.InstanceName like '%_Total%'
ORDER BY CounterDateTime

----------------------Aggregate
SELECT  MachineName ,
        CounterName ,
        InstanceName ,
        MIN(CounterValue) AS minValue ,
        MAX(CounterValue) AS maxValue ,
        AVG(CounterValue) AS avgValue ,
        DisplayString
FROM    dbo.CounterDetails cdt
        INNER JOIN dbo.CounterData cd ON cdt.CounterID = cd.CounterID
        INNER JOIN dbo.DisplayToID d ON d.GUID = cd.GUID
WHERE    MachineName like '%K%'
AND ObjectName like '%buffer%' AND cdt.CounterName like '%Page life expectancy%'  --AND cdt.InstanceName like '%_Total%'
and CounterDateTime between '2017-07-12 00:00:03.923' and '2017-07-12 23:59:03.923'
GROUP BY MachineName ,CounterName ,InstanceName , DisplayString--, CounterDateTime


--select getdate()

