/**********************************************************************
Description: Script to generate attach statements for all user databases on an instance
Author: Frank Gill
Date: 12/5/2017
**********************************************************************/
 
 
USE master
GO
 
-- SET NOCOUNT ON to exclude row counts from printed results
SET NOCOUNT ON

IF OBJECT_ID('tempdb.dbo.#attach') IS NOT NULL
BEGIN
	
	DROP TABLE #attach;

END
 
-- Create a temp table to hold database and file information
CREATE TABLE #attach
(database_name SYSNAME
,[file_name] VARCHAR(1000));
 
-- Declare local variables
DECLARE @loopcount INT,
@looplimit INT,
@loopcount2 INT,
@looplimit2 INT,
@database_name SYSNAME,
@sqlstr VARCHAR(2000),
@filename VARCHAR(2000);
 
-- Initialize both loop counters
SELECT @loopcount = 1, @loopcount2 = 1;
 
-- Use sp_MSforeachdb to insert a list of database names and files into #attach
-- You can find more information on sp_MSforeachdb at this link
-- http://www.databasejournal.com/features/mssql/article.php/3441031/SQL-Server-Undocumented-Stored-Procedures-spMSforeachtable-and-spMSforeachdb.htm
 
DECLARE @RETURN_VALUE INT;
DECLARE @command1 NVARCHAR(2000);
SET @command1 = 'use [?] INSERT INTO #attach SELECT DB_NAME(), physical_name FROM sys.database_files ORDER BY DB_NAME()';
EXEC @RETURN_VALUE = sp_MSforeachdb @command1 = @command1;
 
-- Run a select of distinct database names to populate the @looplimit with the @@ROWCOUNT
(SELECT @looplimit = COUNT(DISTINCT(database_name)) FROM #attach
WHERE database_name NOT IN ('tempdb', 'master', 'msdb', 'model'));
 
-- Begin looping through the list of databases
WHILE @loopcount <= @looplimit
BEGIN
 
    -- Pull the first user database name out of the table
    SELECT TOP 1 @database_name = database_name FROM #attach WHERE database_name NOT IN ('tempdb', 'master', 'msdb', 'model');
 
    -- Set the limit for the inner loop to the count of files for that database
    SELECT @looplimit2 = COUNT(*) FROM #attach WHERE database_name = @database_name;
 
    -- Begin building the dynamic SQL string with the call to sp_attach_db and database name
    SET @sqlstr = 'EXEC sp_attach_db @dbname = N''' + @database_name + '''' + ',';
  
    -- Loop through each file for the database
    WHILE @loopcount2 <= @looplimit2
    BEGIN
 
        -- Select the top file name for the database into @filename
        SET @filename = (SELECT TOP 1 file_name FROM #attach WHERE database_name = @database_name);
         
        -- Append @sqlstr using the @filename parameter plus the current loop count to adhere to the syntax of sp_attach_db 
        SET @sqlstr = @sqlstr + '@filename' + CONVERT(VARCHAR(2), @loopcount2) + ' = N''' + @filename + ''',';
         
        -- Delete the current row from the temp table and increment the inner loop counter
        DELETE  FROM #attach WHERE file_name = @filename;
 
        SET @loopcount2 += 1;
     
    END
     
    -- Because I want to generate a series of attach statements for future use, I am printing @sqlstr
    -- If I wanted to run the statement in the loop I would change the PRINT to EXEC(@sqlstr)
    -- Print @sqlstr using the SUBSTRING to remove the last comma
    -- Include a line return and the GO to delimit the attach statements
    PRINT SUBSTRING(@sqlstr,1,(LEN(@sqlstr) - 1)) + N';' + CHAR(10) +  'GO';
 
    -- Increment the outer loop counter and intitial the inner loop counter
    SET @loopcount = @loopcount + 1;
    SET @loopcount2 = 1;
 
END
