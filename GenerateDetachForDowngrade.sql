/**********************************************************************
Description: Script to generate detach statements for all user databases on an instance
Author: Frank Gill
Date: 12/5/2017
**********************************************************************/
 
-- SET NOCOUNT ON to prevent row counts from showing up in the output
SET NOCOUNT ON

IF OBJECT_ID('tempdb.dbo.#detach') IS NOT NULL
BEGIN

	DROP TABLE #detach;

END

/* Create a temp table to hold the list of databases on the instance */
CREATE TABLE #detach
(rowid INT IDENTITY(1,1)
,dbname VARCHAR(255));
 
-- Declare local variables
DECLARE @dbname VARCHAR(255),
@sqlstr VARCHAR(2000),
@loopcount INT,
@looplimit INT
 
-- Initialize loop counter
SELECT @loopcount = 1;
 
-- Insert a list of user databases into the temp table
INSERT INTO #detach
SELECT name FROM sys.databases
WHERE database_id > 4;
 
-- Set the loop limit to the count of user databases on the instance
SELECT @looplimit = MAX(rowid) FROM #detach;
 
--SELECT * FROM #detach
 
-- Loop through the list of databases
WHILE @loopcount <= @looplimit
BEGIN
     
    -- Pull the first database out of the temp table
    SELECT @dbname = dbname FROM #detach WHERE rowid = @loopcount;
     
    -- Build the dynamic SQL string, including a SET SINGLE_USER statement to allow the detach
    -- DO NOT RUN THIS ON AN ACTIVE SYSTEM
    -- Make sure that all user activity has stopped prior to executing any detach activity
    SELECT @sqlstr = 'USE master' + CHAR(10) + 'GO' + CHAR(10) + 'ALTER DATABASE ' + @dbname + 
    ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE' + CHAR(10) + 'GO' + CHAR(10);
     
    -- Append the detach statement to the SET SINGLE_USER
    SELECT @sqlstr =  @sqlstr + 'EXEC sp_detach_db ''' + @dbname + ''', ''true'';
GO';
     
    -- Print @sqlstr to generate a script for use later
    -- If you want to execute @sqlstr within the loop, replace the PRINT with EXEC(@sqlstr)
    -- You will need to remove the GO from the end of the dynamic SQL string
    PRINT @sqlstr;
     
    --  Increment the loop counter
    SET @loopcount += 1;
 
END
 
