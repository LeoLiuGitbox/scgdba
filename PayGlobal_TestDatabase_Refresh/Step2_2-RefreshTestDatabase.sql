
:Connect SCG-CLSQLDEV2

SELECT 'Connected to : ' + Name FROM sys.databases where name like '_NODE%'
GO


USE [master]
GO

ALTER AVAILABILITY GROUP [SCG-PGTESTAG]
REMOVE DATABASE [BI_Reference];
GO

USE [master]
GO

ALTER AVAILABILITY GROUP [SCG-PGTESTAG]
REMOVE DATABASE [Payglobal_Reference_Prod];

GO
USE [master]
GO

ALTER AVAILABILITY GROUP [SCG-PGTESTAG]
REMOVE DATABASE [PGSC_Prod];

GO


-- Drop database before restore
USE [master]
GO
ALTER DATABASE [BI_Reference] SET OFFLINE WITH ROLLBACK IMMEDIATE
GO
DROP DATABASE [BI_Reference]
GO
ALTER DATABASE [Payglobal_Reference_Prod] SET OFFLINE WITH ROLLBACK IMMEDIATE
GO
DROP DATABASE [Payglobal_Reference_Prod]
GO
ALTER DATABASE [PGSC_Prod] SET OFFLINE WITH ROLLBACK IMMEDIATE
GO
DROP DATABASE [PGSC_Prod]
GO


--Restore databases 

USE [master]
RESTORE DATABASE [Payglobal_Reference_Prod] 
FROM  DISK = N'\\schain-dbk\DatabaseTransfer\Payglobal_Reference_Prod_FULL_Transfer.bak' 
WITH  FILE = 1, 
MOVE N'Payglobal_Reference_Prod' TO N'E:\MSSQL\DATA\Payglobal_Reference_Prod.mdf',  
MOVE N'Payglobal_Reference_Prod_log' TO N'E:\MSSQL\DATA\Payglobal_Reference_Prod.ldf',  
NOUNLOAD,  REPLACE,  STATS = 20
GO

USE [master]
RESTORE DATABASE [BI_Reference] 
FROM  DISK = N'\\schain-dbk\DatabaseTransfer\BI_reference_FULL_Transfer.bak' 
WITH  FILE = 1,  
MOVE N'BI_Reference' TO N'E:\MSSQL\DATA\BI_Reference.mdf',  
MOVE N'BI_Reference_log' TO N'E:\MSSQL\DATA\BI_Reference_log.ldf',  
NOUNLOAD,  REPLACE,  STATS = 20

GO
USE [master]
RESTORE DATABASE [PGSC_Prod] 
FROM  DISK = N'\\schain-dbk\DatabaseTransfer\PGSC_Prod_FULL_Transfer.bak' 
WITH  FILE = 1,  
MOVE N'PGSC_Prod' TO N'E:\MSSQL\DATA\PGSC_Prod.mdf',  
MOVE N'PGSC_Prod_log' TO N'E:\MSSQL\DATA\PGSC_Prod_log.LDF',  
NOUNLOAD,  REPLACE,  STATS = 20

GO



USE [master]
GO
ALTER DATABASE [BI_Reference] SET RECOVERY FULL WITH NO_WAIT
GO

BACKUP DATABASE [BI_Reference] TO  DISK = N'\\schain-dbk\SQLCluster\Initialization\BI_Reference.bak' 
WITH  FORMAT, INIT, SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 20
GO


--Delete teh backup file 
EXEC xp_cmdshell  'DEL \\schain-dbk\SQLCluster\Initialization\BI_Reference.bak'


:Connect SCG-CLSQLDEV1
-- Drop database before re-join to availability group 
SELECT 'Connected to : ' + Name FROM sys.databases where name like '_NODE%'
GO

USE [master]
GO
DROP DATABASE [BI_Reference]
GO
DROP DATABASE [Payglobal_Reference_Prod]
GO
DROP DATABASE [PGSC_Prod]
GO


-- Re-Join database to HA Group 

:Connect SCG-CLSQLDEV2

BACKUP DATABASE [BI_Reference] TO  DISK = N'\\SCHAIN-DBK\SQLCluster\Initialization\BI_Reference.bak' WITH  COPY_ONLY, FORMAT, INIT, SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 20

GO

:Connect SCG-CLSQLDEV1

RESTORE DATABASE [BI_Reference] FROM  DISK = N'\\SCHAIN-DBK\SQLCluster\Initialization\BI_Reference.bak' WITH  NORECOVERY,  NOUNLOAD,  STATS = 20

GO



:Connect SCG-CLSQLDEV2

BACKUP LOG [BI_Reference] TO  DISK = N'\\SCHAIN-DBK\SQLCluster\Initialization\BI_Reference_20171017065355.trn' WITH NOFORMAT, NOINIT, NOSKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 20

GO

:Connect SCG-CLSQLDEV1

RESTORE LOG [BI_Reference] FROM  DISK = N'\\SCHAIN-DBK\SQLCluster\Initialization\BI_Reference_20171017065355.trn' WITH  NORECOVERY,  NOUNLOAD,  STATS = 20

GO

:Connect SCG-CLSQLDEV1


-- Wait for the replica to start communicating
BEGIN TRY
DECLARE @conn BIT
DECLARE @count INT
DECLARE @replica_id UNIQUEIDENTIFIER 
DECLARE @group_id UNIQUEIDENTIFIER
SET @conn = 0
SET @count = 30 -- wait for 5 minutes 

IF (SERVERPROPERTY('IsHadrEnabled') = 1)
	AND (ISNULL((SELECT member_state FROM master.sys.dm_hadr_cluster_members WHERE UPPER(member_name COLLATE Latin1_General_CI_AS) = UPPER(CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS NVARCHAR(256)) COLLATE Latin1_General_CI_AS)), 0) <> 0)
	AND (ISNULL((SELECT state FROM master.sys.database_mirroring_endpoints), 1) = 0)
BEGIN
    SELECT @group_id = ags.group_id FROM master.sys.availability_groups AS ags WHERE name = N'SCG-PGTESTAG'
	SELECT @replica_id = replicas.replica_id FROM master.sys.availability_replicas AS replicas WHERE UPPER(replicas.replica_server_name COLLATE Latin1_General_CI_AS) = UPPER(@@SERVERNAME COLLATE Latin1_General_CI_AS) AND group_id = @group_id
	WHILE @conn <> 1 AND @count > 0
	BEGIN
		SET @conn = ISNULL((SELECT connected_state FROM master.sys.dm_hadr_availability_replica_states AS states WHERE states.replica_id = @replica_id), 1)
		IF @conn = 1
		BEGIN
			-- exit loop when the replica is connected, or if the query cannot find the replica status
			BREAK
		END
		WAITFOR DELAY '00:00:10'
		SET @count = @count - 1
	END
END
END TRY
BEGIN CATCH
	-- If the wait loop fails, do not stop execution of the alter database statement
END CATCH
ALTER DATABASE [BI_Reference] SET HADR AVAILABILITY GROUP = [SCG-PGTESTAG];

GO


:Connect SCG-CLSQLDEV2

BACKUP DATABASE [Payglobal_Reference_Prod] TO  DISK = N'\\SCHAIN-DBK\SQLCluster\Initialization\Payglobal_Reference_Prod.bak' WITH  COPY_ONLY, FORMAT, INIT, SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 20

GO

:Connect SCG-CLSQLDEV1

RESTORE DATABASE [Payglobal_Reference_Prod] FROM  DISK = N'\\SCHAIN-DBK\SQLCluster\Initialization\Payglobal_Reference_Prod.bak' WITH  NORECOVERY,  NOUNLOAD,  STATS = 20

GO



:Connect SCG-CLSQLDEV2

BACKUP LOG [Payglobal_Reference_Prod] TO  DISK = N'\\SCHAIN-DBK\SQLCluster\Initialization\Payglobal_Reference_Prod.trn' WITH NOFORMAT, NOINIT, NOSKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 20

GO

:Connect SCG-CLSQLDEV1

RESTORE LOG [Payglobal_Reference_Prod] FROM  DISK = N'\\SCHAIN-DBK\SQLCluster\Initialization\Payglobal_Reference_Prod.trn' WITH  NORECOVERY,  NOUNLOAD,  STATS = 20

GO

:Connect SCG-CLSQLDEV1


-- Wait for the replica to start communicating
BEGIN TRY
DECLARE @conn BIT
DECLARE @count INT
DECLARE @replica_id UNIQUEIDENTIFIER 
DECLARE @group_id UNIQUEIDENTIFIER
SET @conn = 0
SET @count = 30 -- wait for 5 minutes 

IF (SERVERPROPERTY('IsHadrEnabled') = 1)
	AND (ISNULL((SELECT member_state FROM master.sys.dm_hadr_cluster_members WHERE UPPER(member_name COLLATE Latin1_General_CI_AS) = UPPER(CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS NVARCHAR(256)) COLLATE Latin1_General_CI_AS)), 0) <> 0)
	AND (ISNULL((SELECT state FROM master.sys.database_mirroring_endpoints), 1) = 0)
BEGIN
    SELECT @group_id = ags.group_id FROM master.sys.availability_groups AS ags WHERE name = N'SCG-PGTESTAG'
	SELECT @replica_id = replicas.replica_id FROM master.sys.availability_replicas AS replicas WHERE UPPER(replicas.replica_server_name COLLATE Latin1_General_CI_AS) = UPPER(@@SERVERNAME COLLATE Latin1_General_CI_AS) AND group_id = @group_id
	WHILE @conn <> 1 AND @count > 0
	BEGIN
		SET @conn = ISNULL((SELECT connected_state FROM master.sys.dm_hadr_availability_replica_states AS states WHERE states.replica_id = @replica_id), 1)
		IF @conn = 1
		BEGIN
			-- exit loop when the replica is connected, or if the query cannot find the replica status
			BREAK
		END
		WAITFOR DELAY '00:00:10'
		SET @count = @count - 1
	END
END
END TRY
BEGIN CATCH
	-- If the wait loop fails, do not stop execution of the alter database statement
END CATCH
ALTER DATABASE [Payglobal_Reference_Prod] SET HADR AVAILABILITY GROUP = [SCG-PGTESTAG];

GO


:Connect SCG-CLSQLDEV2

BACKUP DATABASE [PGSC_Prod] TO  DISK = N'\\SCHAIN-DBK\SQLCluster\Initialization\PGSC_Prod.bak' WITH  COPY_ONLY, FORMAT, INIT, SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 20

GO

:Connect SCG-CLSQLDEV1

RESTORE DATABASE [PGSC_Prod] FROM  DISK = N'\\SCHAIN-DBK\SQLCluster\Initialization\PGSC_Prod.bak' WITH  NORECOVERY,  NOUNLOAD,  STATS = 20

GO



:Connect SCG-CLSQLDEV2

BACKUP LOG [PGSC_Prod] TO  DISK = N'\\SCHAIN-DBK\SQLCluster\Initialization\PGSC_Prod.trn' WITH NOFORMAT, NOINIT, NOSKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 20

GO

:Connect SCG-CLSQLDEV1

RESTORE LOG [PGSC_Prod] FROM  DISK = N'\\SCHAIN-DBK\SQLCluster\Initialization\PGSC_Prod.trn' WITH  NORECOVERY,  NOUNLOAD,  STATS = 20

GO

:Connect SCG-CLSQLDEV1


-- Wait for the replica to start communicating
BEGIN TRY
DECLARE @conn BIT
DECLARE @count INT
DECLARE @replica_id UNIQUEIDENTIFIER 
DECLARE @group_id UNIQUEIDENTIFIER
SET @conn = 0
SET @count = 30 -- wait for 5 minutes 

IF (SERVERPROPERTY('IsHadrEnabled') = 1)
	AND (ISNULL((SELECT member_state FROM master.sys.dm_hadr_cluster_members WHERE UPPER(member_name COLLATE Latin1_General_CI_AS) = UPPER(CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS NVARCHAR(256)) COLLATE Latin1_General_CI_AS)), 0) <> 0)
	AND (ISNULL((SELECT state FROM master.sys.database_mirroring_endpoints), 1) = 0)
BEGIN
    SELECT @group_id = ags.group_id FROM master.sys.availability_groups AS ags WHERE name = N'SCG-PGTESTAG'
	SELECT @replica_id = replicas.replica_id FROM master.sys.availability_replicas AS replicas WHERE UPPER(replicas.replica_server_name COLLATE Latin1_General_CI_AS) = UPPER(@@SERVERNAME COLLATE Latin1_General_CI_AS) AND group_id = @group_id
	WHILE @conn <> 1 AND @count > 0
	BEGIN
		SET @conn = ISNULL((SELECT connected_state FROM master.sys.dm_hadr_availability_replica_states AS states WHERE states.replica_id = @replica_id), 1)
		IF @conn = 1
		BEGIN
			-- exit loop when the replica is connected, or if the query cannot find the replica status
			BREAK
		END
		WAITFOR DELAY '00:00:10'
		SET @count = @count - 1
	END
END
END TRY
BEGIN CATCH
	-- If the wait loop fails, do not stop execution of the alter database statement
END CATCH
ALTER DATABASE [PGSC_Prod] SET HADR AVAILABILITY GROUP = [SCG-PGTESTAG];

GO

--Clean up stage 
--Delete teh backup file 
EXEC xp_cmdshell  'DEL \\schain-dbk\SQLCluster\Initialization\BI_Reference.bak'
EXEC xp_cmdshell  'DEL \\schain-dbk\SQLCluster\Initialization\BI_Reference.trn'

EXEC xp_cmdshell  'DEL \\schain-dbk\SQLCluster\Initialization\Payglobal_Reference_Prod.bak'
EXEC xp_cmdshell  'DEL \\schain-dbk\SQLCluster\Initialization\Payglobal_Reference_Prod.trn'

EXEC xp_cmdshell  'DEL \\schain-dbk\SQLCluster\Initialization\PGSC_Prod.bak'
EXEC xp_cmdshell  'DEL \\schain-dbk\SQLCluster\Initialization\PGSC_Prod.trn'


GO



