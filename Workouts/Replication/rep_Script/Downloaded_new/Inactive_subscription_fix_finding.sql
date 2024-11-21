-- Author: Kin Shah
-- Date: 4-1-2013
-- For dba.stackexchange.com
-- Good to find out 
-- publisher_id
-- publisher_db
-- publication_id
-- subscriber_id
-- subscriber_db
select * From distribution..MSsubscriptions where status = 0 

--- based on the above values, run below statement
--- this can be run using SQLAgent job

if exists (select 1 from distribution..MSsubscriptions where status = 0)
begin
UPDATE distribution..MSsubscriptions
SET STATUS = 2
WHERE publisher_id = 0--'--publisher_id -- will be integer --' 
    AND publisher_db ='HDXDB' --'--publisher db name ---'
    AND publication_id = 38--'--publication_id -- will be integer --'
    AND subscriber_id = 4--'--subscriber_id -- will be integer ---'
    AND subscriber_db ='HDXDB' --'-- subscriber_db ---'
end
else
begin
print 'The subscription is not INACTIVE ... you are good for now .... !!'
end



use distribution
go

exec sp_browsereplcmds


