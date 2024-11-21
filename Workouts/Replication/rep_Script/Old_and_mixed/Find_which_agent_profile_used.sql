SELECT
    [publication] as Publication
    ,c.srvname as SubscriberName 
    ,b.profile_name as Profile
    ,[name] as DistributionJobName
FROM 
    [distribution].[dbo].[MSdistribution_agents] a
INNER JOIN
    msdb.[dbo].[MSagent_profiles] b
    ON a.profile_id = b.profile_id
INNER JOIN 
    master..sysservers c
    ON a.subscriber_id = c.srvid
ORDER BY 
    b.profile_name;