
-- a list of table that scheculed to be archived   
--TableName				Current Archive_To_Date	 Retation_period_Month	Planned_Archive_To_Date
-----------------------------------------------------------------------------------------------------
--Actual_Service			2/01/2011					36						30/06/2014
--Activity_Work_Table		3/01/2013					36						30/06/2014
--Messages				2/07/2013					12						30/06/2016
--Message_Recipient			2/07/2013					12						30/06/2016
--Task_Profiles			2/04/2008					36					     30/06/2014

--Includes following tables  
--Task_Schedule_Allocation	2/04/2008					36						30/06/2014
--Task_Schedule_Care_Action	5/04/2008					36						30/06/2014
--Round_Allocation			3/04/2008					36						30/06/2014

--Schedule_Allocation_Time	4/04/2008					36						30/06/2014
--Person_Access_Log			2/04/2012					12						30/06/2016
--FS_BLOB					9/10/2012					12						30/06/2016


--SELECT * FROM dbo.Archived_Object_Parameters

UPDATE dbo.Archived_Object_Parameters
SET Archive_To_Date = DATEADD(DAY,1, Archive_To_Date) ,Last_Modified_Date = GETDATE(), Last_Modified_User_Name = '75347245'
WHERE Object_Description = 'Actual_Service'
AND Archive_To_Date <= '2014-06-30' --(SELECT Archive_To_Date FROM @table_list WHERE table_name = 'Actual_Service')

UPDATE dbo.Archived_Object_Parameters
SET Archive_To_Date = DATEADD(DAY,1, Archive_To_Date) ,Last_Modified_Date = GETDATE(), Last_Modified_User_Name = '75347245'
WHERE Object_Description =  'Activity_Work_Table'
AND Archive_To_Date <= '2014-06-30' -- (SELECT Archive_To_Date FROM @table_list WHERE table_name =  'Activity_Work_Table')

UPDATE dbo.Archived_Object_Parameters
SET Archive_To_Date = DATEADD(DAY,1, Archive_To_Date) ,Last_Modified_Date = GETDATE(), Last_Modified_User_Name = '75347245'
WHERE Object_Description = 'Messages'
AND Archive_To_Date <= '2016-06-30' --(SELECT Archive_To_Date FROM @table_list WHERE table_name = 'Messages')

UPDATE dbo.Archived_Object_Parameters
SET Archive_To_Date = DATEADD(DAY,1, Archive_To_Date) ,Last_Modified_Date = GETDATE(), Last_Modified_User_Name = '75347245'
WHERE Object_Description = 'Person_Access_Log'
AND Archive_To_Date <= '2016-06-30' --(SELECT Archive_To_Date FROM @table_list WHERE table_name = 'Person_Access_Log')

UPDATE dbo.Archived_Object_Parameters
SET Archive_To_Date = DATEADD(DAY,1, Archive_To_Date) ,Last_Modified_Date = GETDATE(), Last_Modified_User_Name = '75347245'
WHERE Object_Description = 'Task_Profiles'
AND Archive_To_Date <= '2014-06-30' --(SELECT Archive_To_Date FROM @table_list WHERE table_name = 'Task_Profiles')

UPDATE dbo.Archived_Object_Parameters
SET Archive_To_Date = DATEADD(DAY,1, Archive_To_Date) ,Last_Modified_Date = GETDATE(), Last_Modified_User_Name = '75347245'
WHERE Object_Description = 'FS_BLOB'
AND Archive_To_Date <= '2016-06-30' --(SELECT Archive_To_Date FROM @table_list WHERE table_name = 'FS_BLOB')

INSERT INTO [DBA].dbo.ComCareArchiveJobLog
SELECT GETDATE() DataTimeStamp, Object_Description,Archive_To_Date 
FROM dbo.Archived_Object_Parameters
--EXEC dbo.CC_ArchivedObjectParameters 1
EXEC dbo.CC_ArchivedObjectParameters;2 @UserName = '75347245'

--SELECT TOP 100 * FROM dbo.Archived_Tables_Log ORDER BY Archived_Date DESC



--- Check table size ---
--DateofCheck	SchemaName	TableName				 Row_Count	  reserved_mb	data_mb	index_size_mb	unused_mb
--2017-09-22 14:22:09.273	dbo	Person_Access_Log		 160074777	  26607.953125	10531.179687	16035.914062	40.859375
--2017-09-22 14:22:09.273	dbo	Activity_Work_Table		 15876150		  13639.523437	7251.562500	6325.453125	62.507812
--2017-09-22 14:22:09.273	dbo	Actual_Service			 18019465		  18256.484375	5614.500000	12534.250000	107.734375
--2017-09-22 14:22:09.273	dbo	Message_Recipient		 11991758		  7675.710937	2668.718750	4984.617187	22.375000
--2017-09-22 14:22:09.273	dbo	Task_Schedule_Allocation	 10896144		  6445.343750	2189.195312	4173.046875	83.101562
--2017-09-22 14:22:09.273	dbo	Round_Allocation		 11216018		  3961.406250	1484.914062	2414.562500	61.929687
--2017-09-22 14:22:09.273	dbo	Schedule_Allocation_Time	 11431019		  1395.851562	954.687500	432.828125	8.335937
--2017-09-22 14:22:09.273	dbo	Task_Schedule_Care_Action 3585035		  493.523437	254.031250	238.476562	1.015625
--2017-09-22 14:22:09.273	dbo	FS_Blob				 1324554		  261.578125	152.031250	108.351562	1.195312
---------------------------------------------

--DECLARE @table_list TABLE (table_name VARCHAR(50), retaintation_month INT,  Archive_To_Date DATETIME)
--INSERT INTO @table_list  VALUES ('Actual_Service',		    36, '2014-06-30')
--INSERT INTO @table_list  VALUES ('Activity_Work_Table',	    36, '2014-06-30')
--INSERT INTO @table_list  VALUES ('Messages'	,			    12, '2016-06-30')		
--INSERT INTO @table_list  VALUES ('Message_Recipient',		    12, '2016-06-30')
--INSERT INTO @table_list  VALUES ('Task_Schedule_Allocation',    36, '2014-06-30')
--INSERT INTO @table_list  VALUES ('Round_Allocation',		    36, '2014-06-30')
--INSERT INTO @table_list  VALUES ('Schedule_Allocation_Time',    36, '2014-06-30')
--INSERT INTO @table_list  VALUES ('Task_Schedule_Care_Action',   36, '2014-06-30')
--INSERT INTO @table_list  VALUES ('Task_Profiles',			    36, '2014-06-30')
--INSERT INTO @table_list  VALUES ('Person_Access_Log',		    12, '2016-06-30')
--INSERT INTO @table_list  VALUES ('FS_BLOB',				    12, '2016-06-30')	
--;

--WITH dm_partition_stat AS 
--(
--SELECT 
--                ps.object_id,
--                SUM ( CASE WHEN (ps.index_id < 2) THEN row_count    ELSE 0 END ) AS [rows],
--                SUM (ps.reserved_page_count) AS reserved,
--                SUM (CASE   WHEN (ps.index_id < 2) THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count)
--                            ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count) END
--                    ) AS data,
--                SUM (ps.used_page_count) AS used
--                FROM sys.dm_db_partition_stats ps
--                GROUP BY ps.object_id
--)

-- SELECT GETDATE() DateofCheck,
--        a3.name AS SchemaName,
--        a2.name AS TableName,
--        a1.rows as Row_Count,
--        (a1.reserved )* 8.0 / 1024 AS reserved_mb,
--        a1.data * 8.0 / 1024 AS data_mb,
--        (CASE WHEN (a1.used ) > a1.data THEN (a1.used ) - a1.data ELSE 0 END) * 8.0 / 1024 AS index_size_mb,
--        (CASE WHEN (a1.reserved ) > a1.used THEN (a1.reserved ) - a1.used ELSE 0 END) * 8.0 / 1024 AS unused_mb

--    FROM   dm_partition_stat a1
--    INNER JOIN sys.all_objects a2  ON ( a1.object_id = a2.object_id )
--    INNER JOIN sys.schemas a3 ON (a2.schema_id = a3.schema_id)
--    WHERE a2.type <> N'S' and a2.type <> N'IT'   
--    AND a2.name IN (SELECT table_name FROM @table_list)
--    ORDER by a1.data desc    
-- Build a list of all the records remaining to be processed
--DECLARE @toProcess TABLE ( ID int not null )

--DECLARE @batchSize INT = 10000
--DECLARE @maxRound INT = 100

--DECLARE @round INT = 0
--DECLARE @timestart DATETIME = GETDATE() 

--PRINT @timestart 


---- Iterate through the collection
--WHILE ( 1 = 1 )

--BEGIN TRY
--    -- Bail out of the loop once we're done processing
--	IF NOT EXISTS (   SELECT TOP 1 ID  FROM   WI_Device_Statistics (nolock) WHERE  Server_Timestamp < '2017-02-28' )
--		BREAK
--     IF @round >= @maxRound
--	     BREAK
--	SET @round = @round + 1 

--  BEGIN TRANSACTION SCHEDULEDELETE  
    
--    INSERT INTO @toProcess
--    SELECT TOP (@batchSize) ID
--    FROM   WI_Device_Statistics (nolock) 
--    WHERE  Server_Timestamp < '2017-02-28'
    
--	-- Process the rows
--	DELETE 
--	FROM WI_Device_Statistics 
--	WHERE  ID in ( SELECT ID FROM @toProcess )

--	-- And then purge them from the list
--	DELETE FROM @toProcess
--	--WHERE  ID in ( SELECT TOP 500 ID FROM @toProcess )

-- COMMIT TRANSACTION SCHEDULEDELETE
     
--END TRY

--BEGIN CATCH 
--  IF (@@TRANCOUNT > 0)
--   BEGIN
--      ROLLBACK TRANSACTION SCHEDULEDELETE
--      PRINT 'Error detected, all changes reversed'
--   END 
--    SELECT
--        ERROR_NUMBER() AS ErrorNumber,
--        ERROR_SEVERITY() AS ErrorSeverity,
--        ERROR_STATE() AS ErrorState,
--        ERROR_PROCEDURE() AS ErrorProcedure,
--        ERROR_LINE() AS ErrorLine,
--        ERROR_MESSAGE() AS ErrorMessage
--END CATCH