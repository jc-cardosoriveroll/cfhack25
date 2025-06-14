*********************************************************
***** COLDFUSION HACKATHON 2025 - BACKUP COMPONENT  *****
******** USING CSVWRITE, ENTRY FOR TEAM: CF_MEX *********
*********************************************************
**** CODED BY: JUAN CARLOS CARDOSO (jccriv@gmail.com) ***
*********************************************************

QUICKLINK:
------------------

  TUTORIAL: https://youtu.be/5TRsxF_aiRo
       GIT: https://github.com/jc-cardosoriveroll/cfhack25 

INTRODUCTION
------------

As a developer I find myself in constant need of creating
constant backups for databases. SQL Databases are usually
a pain because backups needs to be executed from console
and accesing data implies mounting a backup which itself
is a stressful, time-consuming and complicated task.

The complexity of backups occurs because fields are "unknown"
or sorting by primary keys to extract partial rows implies custom 
coding and management, A real Nightmare.

Coldfusion has a new and wonderful CSVWRITE function which is 
part of 2025 release and which allows fast writing and processing
of CSV data that streams with total ease unto files and does not
break because of memory allocation limits.

The first version of Backup component has the following features

1. One-click backup of any DSN/Table
2. Dynamic Listing of DSN/Tables using CFADMIN API
3. Identification of Primary Keys for proper sorting 
4. Customizable Output Format with .env/Json settings file
5. Simple UI to view existing backups and process new.

Given the time constraints of the Hackathon, I focused on Export,
however, further iterations would allow me to expand this cfc 
to include features such as:

1. One-click Restore of any Table
2. Automatic Table Schema for Drop/Create Pre-processes
3. Custom Script Management for different Sql Engines
4. Advanced field conversion, storage & recover (ie geography)
5. Local data navigation, filtering and agreggated functions.

STACK
-----

To achieve this component we:
- installed CF2025 in Localhost with CommandBox
- installed mySQL with Docker Image
- updated CFAdmin with Spreadsheet/Debug Packages
- created a test MYSQL database with Workbench
- built required functions with Visual Code 
- used random/sequential dummy data for tests (100K records)
- We also tested in proper Dev Server for MSSQL Compatibility
The total time invested was aprox 4-5hrs.

INSTRUCTIONS
------------

1) Please make sure to expand Full Code into Web Root
2) Make sure to update .env file with Admin credentials
3) Make sure CF Datasources exist registered in CFIDE/ADMIN 
4) Optional update .env file with CSV settings
5) Run /index.cfm and click on the DSN/Table you wish to backup
6) Look at output in /exports folder! (incredible speed!)


CONCLUSION
-----------

This is a tool that we will definitely use ourselves. We will
expand to include restore methods and it will allow us to manage
data without having to run manual export/import processes.
Data will be ready to see, easy to export over to Excel for sharing
and above all fully validated with schema. All fully automatic.

Historically I have spent hours trying to run backups that usually
fail given the recordcount and timeouts. No more. I am extremely happy
with this amazing CF 2025 update which allows me full backups in seconds.
with a single click, without worrying about data-types and without
worrying about the difficulty to actually view backed-up data which
can now be easily downloaded as CSV file and will be equally easy to 
upload after we iterated on our component.

Kudos Adobe! CF_Fan for over 30 years...

