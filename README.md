# SQL Server AutoMon Centralized alert monitoring


It is a centralized monitoring solution and alert triggering by using database mail. This needs two databases to be created called DBAData and DBAData_Archive, the current data will be stored in DBAData and the archive will be stored in Archive database. The monitoring works based on the master table data DBA_All_servers and SVR_status column should be ‘running’.

I suggest to have a dedicated VM or Instance to have this databases, so that it is easy to have firewall opened to DMZ or different subnet servers from one source. I have started using this from 2008, when we have no tool to invest cost and even some places, we will have limited licence and those will monitor only important servers.

<Strong> <u>Benefit of AutoMon</u></Strong>:<br> This will collect the data by linked server and send a consolidated report by email based on the threshold. The archive data can been integrated with SSRS and the report can be pulled to view as graph and trend of last week/month/year data of disk, CPU, RAM etc.</br>
<br>You can write your own customized scripts like send an email which logins are expiring next one week. </br>

For performance related issue, this will give some idea but I recommend to use PerfMon.msc https://www.sqlserverblogforum.com/dba/integrate-ssrs-with-perfmon-dashboard-performance-of-database-graph-using-ssrs-collect-perfmon-and-automate-it-load-to-sql-database-and-generate-reports/

Download all 30+ scripts. Each script will have own data collection and needs a modification @PROFILE_NAME='muthu' and SELECT @EMAILIDS1= 'dbateam@xxx.com'.

<Strong> <u>Setup scripts to be created to activate</u></Strong>:
<br>Enable the database email and create a profile. We need to edit each script of @PROFILE_NAME='muthu' and SELECT @EMAILIDS1= 'dbateam@xxx.com'. Also, DBA_ALL_OPERATORS table will have email recipient details, you can add your email into the table </br>
<br>1_0_1_CMS – Collect data by register server, it is easy one (OR) add one by one manually</br>
<br>1_0_Test_setup – Create a table to load the servers</br>
<br>https://www.sqlserverblogforum.com/dba/dba-automon-configure-database-centralized-management-server-cms/<br>
<br>1_1_2_Add_server_SQL_sever – Add servers into AutoMon system (This also can be done manually by creating linked server and adding the server into the monitoring table DBA_All_servers). I prefer to use dynamic SQL to add all in one-shot.</br>
<br>https://www.sqlserverblogforum.com/automon/add-server-into-automon-dba-sps-am01/</br>
<br>Add_Or_Drop_server_Input_parameter_Target – Sample input we need for this scripts to work and tables, SPs needed in the target servers</br>
<br>For drop: 1_2_1_Drop_server_SQL_server – This script will drop the server from monitoring tool.</br>
<br>https://www.sqlserverblogforum.com/automon/drop-server-into-automon-dba-sps-am02/</br>
<br>Supported versions from: SQL Server 2005 onwards, some script will have version based ex: 12_0_RAM_Above_SQL2008_New_Agu_2017</br>

<u><Strong>Documentation</u></Strong>
<br>https://www.sqlserverblogforum.com/</br>
<br>https://www.sqlserverblogforum.com/AutoMon</br>

<u><Strong>Licence </u></Strong>
<br>https://github.com/muthukkumarankaliyamoorthy/SQL-AutoMon-free-monitoring-tool/blob/master/LICENSE</br>

