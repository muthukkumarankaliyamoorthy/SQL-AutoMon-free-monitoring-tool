alter table [Home Dynamix, LLC_$Customer] add [Not Allowed Change Warehouse] [tinyint] NOT NULL;

alter table [Home Dynamix, LLC_$Customer] drop column [Not Allowed Change Warehouse]

ALTER TABLE  [Home Dynamix, LLC_$Customer] ALTER COLUMN [Not Allowed Change Warehouse] [tinyint]  NOT NULL;

select top 1 * from [Home Dynamix, LLC_$Customer]

ALTER TABLE dbo.MyTable ADD
MyColumn text NOT NULL CONSTRAINT DF_MyTable_MyColumn DEFAULT 'defaultValue'
ALTER TABLE dbo.MyTable
DROP CONSTRAINT DF_MyTable_MyColumn