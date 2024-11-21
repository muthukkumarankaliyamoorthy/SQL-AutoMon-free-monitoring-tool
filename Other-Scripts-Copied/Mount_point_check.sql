--https://stackoverflow.com/questions/489181/finding-available-drive-space-of-databases-stored-on-a-lun

DECLARE @dsize VARCHAR(20)
DECLARE @SQL NVARCHAR(500)

SET @sql = 'xp_cmdshell ''fsutil volume diskfree ' --+'D:'''+''

CREATE TABLE #Dletter (
    Drive VARCHAR(50),
    )

CREATE TABLE #Size (Sinfo VARCHAR(250))

CREATE TABLE #DriveInfo (
    Drive VARCHAR(30),
    TotalSize REAL,
    Freesize REAL
    )

--set @x='xp_cmdshell''wmic volume get capacity,caption,freespace'''
INSERT INTO #Dletter
EXEC xp_cmdshell 'wmic volume where drivetype="3" get caption'

SET ROWCOUNT 1

DELETE
FROM #Dletter

SET ROWCOUNT 0

DELETE
FROM #Dletter
WHERE drive IS NULL
    OR len(drive) < 4

UPDATE #dletter
SET drive = replace(drive, ' ', '')

--delete from #Dletter where Drive like'R:\%'
--delete from #Capacity where Dcapacity is null or len(Dcapacity)<15 
--delete from #dletter where
-- convert(int,substring(drive,len(drive)-1,len(drive)))=5
--SELECT Row_Number() OVER (order by Drive asc) as RowNumber,drive from #Dletter
DECLARE @dv VARCHAR(30)

DECLARE dx CURSOR
FOR
SELECT *
FROM #dletter

OPEN dx

FETCH NEXT
FROM dx
INTO @dv

WHILE @@fetch_status = 0
BEGIN
    SET @sql = @sql + @dv + ''''

    --  print @sql
    INSERT INTO #Size
    EXEC sp_executesql @sql

    DELETE
    FROM #size
    WHERE sinfo IS NULL
        OR sinfo LIKE 'Total # of avail free bytes  :%'

    --select Drive from #dletter
    --insert into #DriveInfo(Drive,TotalSize,Freesize)
    SELECT @dv AS Drive,
        convert(REAL, substring(sinfo, isnull(charindex(':', sinfo), 0) + 2, len(isnull(sinfo, 0)))) / 1024 / 1024 / 1024 AS Size
    INTO #rama
    FROM #size
    ORDER BY 2 ASC

    DECLARE @d VARCHAR(30)
    DECLARE @s REAL
    DECLARE @cntr INT

    SET @cntr = 1

    DECLARE x CURSOR
    FOR
    SELECT *
    FROM #rama
    ORDER BY 2 DESC

    OPEN x

    FETCH NEXT
    FROM x
    INTO @d,
        @s

    WHILE @@fetch_status = 0
    BEGIN
        IF @cntr = 1
        BEGIN
            INSERT INTO #Driveinfo (
                Drive,
                Totalsize
                )
            VALUES (
                @d,
                @s
                )
                --print convert(char,@cntr)+' '+convert(varchar,@d)+'TotalSize:'+convert(varchar, @s)
        END

        IF @cntr = 2
        BEGIN
            UPDATE #DriveInfo
            SET Freesize = @s
            WHERE drive = @d
                --print convert(char,@cntr)+' '+convert(varchar,@d)+'FreeSize:'+convert(varchar, @s)
        END

        FETCH NEXT
        FROM x
        INTO @d,
            @s

        SET @cntr = @cntr + 1
    END

    CLOSE x

    DEALLOCATE x

    DROP TABLE #rama

    DELETE
    FROM #size

    SET @Cntr = 1

    FETCH NEXT
    FROM dx
    INTO @dv

    --print @sql
    SET @sql = 'xp_cmdshell ''fsutil volume diskfree ' --+'D:'''+''
END

CLOSE dx

DEALLOCATE dx

SELECT Drive,
    convert(DECIMAL(10, 2), TotalSize) AS "TotalSize(GB)",
    convert(DECIMAL(10, 2), FreeSize) AS "FreeSize(GB)"
FROM #DriveInfo
ORDER BY drive

DROP TABLE #Dletter

DROP TABLE #size

DROP TABLE #DriveInfo
Share
Improve this answer
Follow
