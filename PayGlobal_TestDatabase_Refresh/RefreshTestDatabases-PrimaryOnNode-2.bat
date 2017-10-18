sqlcmd -S SCHAIN-PGDB\PGSCPROD -i .\Step1-BackupProd.sql -o .\Runninglog.txt
sqlcmd -S SCG-PGTESTDB -i .\Step2_2-RefreshTestDatabase.sql -o .\Runninglog.txt
