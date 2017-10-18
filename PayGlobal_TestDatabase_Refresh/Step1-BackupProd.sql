USE master
GO


BACKUP DATABASE [Payglobal_Reference_Prod] 
TO  DISK = N'\\SCHAIN-DBK\DatabaseTransfer\Payglobal_Reference_Prod_FULL_Transfer.bak' 
WITH  COPY_ONLY, FORMAT, INIT,  NAME = N'Payglobal_Reference_Prod-Full Database Backup', 
SKIP, NOREWIND, COMPRESSION, NOUNLOAD, STATS = 20
GO

BACKUP DATABASE [PGSC_Prod] 
TO  DISK = N'\\SCHAIN-DBK\DatabaseTransfer\PGSC_Prod_FULL_Transfer.bak' 
WITH  COPY_ONLY, FORMAT, INIT,  NAME = N'PGSC_Prod-Full Database Backup', 
SKIP, NOREWIND, COMPRESSION, NOUNLOAD, STATS = 20
GO

BACKUP DATABASE [BI_reference] 
TO  DISK = N'\\SCHAIN-DBK\DatabaseTransfer\BI_reference_FULL_Transfer.bak' 
WITH  COPY_ONLY, NOFORMAT, INIT,  NAME = N'BI_reference-Full Database Backup', 
SKIP, NOREWIND, COMPRESSION, NOUNLOAD,  STATS = 20
GO