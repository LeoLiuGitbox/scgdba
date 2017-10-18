:Connect SCG-CLSQLDEV1

SELECT 'Connected to : ' + Name  + ', Take database out from HA Group'FROM sys.databases where name like '_NODE%'
GO

USE [master]
ALTER DATABASE [AG_Dummy] SET HADR SUSPEND;
GO
USE [master]
GO

ALTER AVAILABILITY GROUP [SCG-DEV-HYB-AG]
REMOVE DATABASE [AG_Dummy]
GO


ALTER  Database [AG_Dummy] Set offline with rollback immediate 
GO
DROP Database [AG_Dummy]
GO



:Connect SCG-CLSQLDEV1

SELECT 'Connected to : ' + Name  + ', Restore Database from backup 'FROM sys.databases where name like '_NODE%'
GO

USE [master]
RESTORE DATABASE [AG_Dummy] 
FROM  DISK = N'\\schain-dbk\DatabaseTransfer\AG_Dummy_FULL.bak' 
WITH  FILE = 1,  
MOVE N'Reporting_DEV_Dummy' TO N'E:\MSSQL\DATA\AG_Dummy.mdf',  
MOVE N'Reporting_DEV_Dummy_log' TO N'E:\MSSQL\DATA\AG_Dummy.ldf',  
NOUNLOAD,  REPLACE,  STATS = 20

GO

ALTER DATABASE [AG_Dummy] SET RECOVERY FULL WITH NO_WAIT
GO

BACKUP DATABASE [AG_Dummy] TO  DISK = N'\\schain-dbk\SQLCluster\Initialization\AG_Dummy.bak' 
WITH  FORMAT, INIT, SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 20
GO

----Delete teh backup file 
EXEC xp_cmdshell  'DEL \\schain-dbk\SQLCluster\Initialization\AG_Dummy.bak'

GO


--- YOU MUST EXECUTE THE FOLLOWING SCRIPT IN SQLCMD MODE.
:Connect SCG-CLSQLDEV2

SELECT 'Connected to : ' + Name   + ', Remove Secondary replica 'FROM sys.databases where name like '_NODE%'
GO
--ALTER  Database [AG_Dummy] Set offline with rollback immediate 
--GO
DROP Database [AG_Dummy];
GO


:Connect SCG-CLSQLDEV1
SELECT 'Connected to : ' + Name   + ', Join Database to HA Group 'FROM sys.databases where name like '_NODE%'
GO
USE [master]

GO

ALTER AVAILABILITY GROUP [SCG-DEV-HYB-AG]
ADD DATABASE [AG_Dummy];

GO

:Connect SCG-CLSQLDEV1

BACKUP DATABASE [AG_Dummy] TO  DISK = N'\\schain-dbk\SQLCluster\Initialization\AG_Dummy.bak' WITH  COPY_ONLY, FORMAT, INIT, SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 20

GO

:Connect SCG-CLSQLDEV2

RESTORE DATABASE [AG_Dummy] FROM  DISK = N'\\schain-dbk\SQLCluster\Initialization\AG_Dummy.bak' WITH  NORECOVERY,  NOUNLOAD,  STATS = 20

GO

:Connect SCG-CLSQLDEV1

BACKUP LOG [AG_Dummy] TO  DISK = N'\\schain-dbk\SQLCluster\Initialization\AG_Dummy.trn' WITH NOFORMAT, INIT, NOSKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 20

GO

:Connect SCG-CLSQLDEV2

RESTORE LOG [AG_Dummy] FROM  DISK = N'\\schain-dbk\SQLCluster\Initialization\AG_Dummy.trn' WITH  NORECOVERY,  NOUNLOAD,  STATS = 20

GO

:Connect SCG-CLSQLDEV2


-- Wait for the replica to start communicating
begin try
declare @conn bit
declare @count int
declare @replica_id uniqueidentifier 
declare @group_id uniqueidentifier
set @conn = 0
set @count = 30 -- wait for 5 minutes 

if (serverproperty('IsHadrEnabled') = 1)
	and (isnull((select member_state from master.sys.dm_hadr_cluster_members where upper(member_name COLLATE Latin1_General_CI_AS) = upper(cast(serverproperty('ComputerNamePhysicalNetBIOS') as nvarchar(256)) COLLATE Latin1_General_CI_AS)), 0) <> 0)
	and (isnull((select state from master.sys.database_mirroring_endpoints), 1) = 0)
begin
    select @group_id = ags.group_id from master.sys.availability_groups as ags where name = N'SCG-DEV-HYB-AG'
	select @replica_id = replicas.replica_id from master.sys.availability_replicas as replicas where upper(replicas.replica_server_name COLLATE Latin1_General_CI_AS) = upper(@@SERVERNAME COLLATE Latin1_General_CI_AS) and group_id = @group_id
	while @conn <> 1 and @count > 0
	begin
		set @conn = isnull((select connected_state from master.sys.dm_hadr_availability_replica_states as states where states.replica_id = @replica_id), 1)
		if @conn = 1
		begin
			-- exit loop when the replica is connected, or if the query cannot find the replica status
			break
		end
		waitfor delay '00:00:10'
		set @count = @count - 1
	end
end
end try
begin catch
	-- If the wait loop fails, do not stop execution of the alter database statement
end catch
ALTER DATABASE [AG_Dummy] SET HADR AVAILABILITY GROUP = [SCG-DEV-HYB-AG];

GO

--Clean up stage 
--Delete teh backup file 
EXEC xp_cmdshell  'DEL \\schain-dbk\SQLCluster\Initialization\AG_Dummy.bak'
EXEC xp_cmdshell  'DEL \\schain-dbk\SQLCluster\Initialization\AG_Dummy.trn'


GO

