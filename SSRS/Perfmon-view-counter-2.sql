--Here are some queries that I've found useful:

--Get all computers that have cosunter data logged:

SELECT DISTINCT MachineName 
FROM CounterDetails 
ORDER BY MachineName
--Get available object names for a particular computer:

SELECT DISTINCT ObjectName 
FROM CounterDetails 
WHERE MachineName = '\\KW3L1P41' 
ORDER BY ObjectName
--Get counter names for a particular computer and object:

SELECT DISTINCT CounterName 
FROM CounterDetails 
WHERE MachineName = '\\KW3L1P41' 
AND ObjectName = 'Processor' 
ORDER BY CounterName
--Get instance names for a particular computer, object and counter:

SELECT DISTINCT InstanceName 
FROM CounterDetails 
WHERE MachineName = '\\KW3L1P41' 
AND ObjectName = 'Processor' 
AND CounterName = '% Processor Time' 
ORDER BY InstanceName
--Get counter values for a particular computer, object, counter and instance. Name the column appropriately:

SELECT 
    CAST(LEFT(CounterDateTime, 16) as smalldatetime) AS CounterDateTime, 
    REPLACE(CounterDetails.MachineName,'\\','') AS ComputerName, 
    CounterDetails.ObjectName + ISNULL('(' + CounterDetails.InstanceName + ')','') + '\' + CounterDetails.CounterName AS [Counter], 
    CounterData.CounterValue 
FROM CounterData 
    INNER JOIN CounterDetails ON CounterData.CounterID = CounterDetails.CounterID 
    INNER JOIN DisplayToID ON CounterData.GUID = DisplayToID.GUID 
WHERE CounterDetails.ObjectName = 'Processor' 
    AND    CounterDetails.CounterName = '% Processor Time' 
    AND    CounterDetails.MachineName = '\\KW3L1P41' 
    AND CounterDetails.InstanceName = '_Total' 
ORDER BY CounterData.CounterDateTime
