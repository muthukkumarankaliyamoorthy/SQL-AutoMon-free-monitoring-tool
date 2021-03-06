USE DBA_REPORT_CODE
GO


-- EXEC USP_RS_PERFMON_INSTANCENAME 'Server','LOGICALDISK','AVG. DISK SEC/TRANSFER','H:','2016-11-21 07:15:00.000'

ALTER PROC USP_RS_PERFMON_INSTANCENAME
(@SERVERNAME VARCHAR(100),@OBJECTNAME VARCHAR (100), @COUNTERNAME VARCHAR(100), @INSTANCENAME VARCHAR(100)=NULL,
@UPLOAD_DATE VARCHAR(100)=NULL)
AS
BEGIN
SELECT DBA_PERFMON..COUNTERDETAILS.MACHINENAME,
       DBA_PERFMON..COUNTERDETAILS.OBJECTNAME,
       DBA_PERFMON..COUNTERDETAILS.COUNTERNAME,
       DBA_PERFMON..COUNTERDETAILS.INSTANCENAME,
       DATEDIFF(MINUTE, ST.STARTTIME, CAST(LEFT(DBA_PERFMON..COUNTERDATA.COUNTERDATETIME, LEN(DBA_PERFMON..COUNTERDATA.COUNTERDATETIME) - 8) AS DATETIME)) AS INTERVAL,
       AVG(DBA_PERFMON..COUNTERDATA.COUNTERVALUE) AS COUNTERVALUE
	   ,CAST(LEFT(DBA_PERFMON..COUNTERDATA.COUNTERDATETIME, LEN(DBA_PERFMON..COUNTERDATA.COUNTERDATETIME) - 8)AS DATETIME) AS LOAD_TIME
FROM   DBA_PERFMON..COUNTERDATA
INNER JOIN DBA_PERFMON..COUNTERDETAILS ON DBA_PERFMON..COUNTERDATA.COUNTERID = DBA_PERFMON..COUNTERDETAILS.COUNTERID,
(
SELECT DBA_PERFMON..COUNTERDETAILS.MACHINENAME,
MIN(CAST(LEFT(DBA_PERFMON..COUNTERDATA.COUNTERDATETIME, LEN(DBA_PERFMON..COUNTERDATA.COUNTERDATETIME) - 8)AS DATETIME))AS STARTTIME
FROM   DBA_PERFMON..COUNTERDATA
INNER JOIN DBA_PERFMON..COUNTERDETAILS ON DBA_PERFMON..COUNTERDATA.COUNTERID = DBA_PERFMON..COUNTERDETAILS.COUNTERID
GROUP  BY MACHINENAME
) AS ST

-------================================
WHERE  ST.MACHINENAME = DBA_PERFMON..COUNTERDETAILS.MACHINENAME

-------================================ OBJECTNAME
AND DBA_PERFMON..COUNTERDETAILS.MACHINENAME= @SERVERNAME
AND OBJECTNAME = @OBJECTNAME
AND COUNTERNAME = @COUNTERNAME
AND INSTANCENAME=@INSTANCENAME
AND DBA_PERFMON..COUNTERDATA.COUNTERDATETIME>=@UPLOAD_DATE

GROUP  BY DBA_PERFMON..COUNTERDETAILS.MACHINENAME,
          DBA_PERFMON..COUNTERDETAILS.OBJECTNAME,
          DBA_PERFMON..COUNTERDETAILS.COUNTERNAME,
          DBA_PERFMON..COUNTERDETAILS.COUNTERTYPE,
          DBA_PERFMON..COUNTERDETAILS.INSTANCENAME,
          DATEDIFF(MINUTE, ST.STARTTIME, CAST(LEFT(DBA_PERFMON..COUNTERDATA.COUNTERDATETIME, LEN(DBA_PERFMON..COUNTERDATA.COUNTERDATETIME) - 8) AS DATETIME))
		  ,DBA_PERFMON..COUNTERDATA.COUNTERVALUE 
 ,CAST(LEFT(DBA_PERFMON..COUNTERDATA.COUNTERDATETIME, LEN(DBA_PERFMON..COUNTERDATA.COUNTERDATETIME) - 8)AS DATETIME)

--HAVING DBA_PERFMON..COUNTERDATA.COUNTERVALUE>0.1
--HAVING DBA_PERFMON..COUNTERDATA.COUNTERVALUE/1024/1024<50
ORDER BY CAST(LEFT(DBA_PERFMON..COUNTERDATA.COUNTERDATETIME, LEN(DBA_PERFMON..COUNTERDATA.COUNTERDATETIME) - 8)AS DATETIME) DESC

END