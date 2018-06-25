
1. Get card info files from datacash devlopers area:
https://testserver.datacash.com/software/download.cgi
Username: .....
Password: .....

2. Use tables.sql file to create database, with necessary tables

3. Modify Import-CSVToSql.ps1 file, run against each csv file, csv information is then imported into tables.

4. 
Modify cardnumbers.ps1 file to point to relevant database and input csv file.
Run ps1 file, it will talk to database and generate tmpTable section necessary for updating EFTCardBinRange.
