USE dbamaint
GO

If Exists (	SELECT	1 
			FROM	sys.objects 
			WHERE	object_id = object_id(N'dbo.dbm_Find') 
					And Type = 'P')
	Drop Procedure dbo.dbm_Find;
Go

CREATE Procedure [dbo].[dbm_Find] 
	  @SearchText VARCHAR(8000)
	, @DBName SYSNAME = Null
	, @PreviewTextSize INT = 100
	, @SearchDBsFlag CHAR(1) = 'Y'
	, @SearchJobsFlag CHAR(1) = 'Y'
	, @SearchSSISFlag CHAR(1) = 'Y'
As
/*
* Created: 12/19/06, Michael F. Berry (SQL Server Magazine contributor)
*
* Modified: 01/25/07, Michael F. Berry, Make it output to one main recordset for clarity
* Modified: 09/04/08, Bill Lescher and Chase Jones, Updated for SQL2005 and added Jobs & SSIS Packages
* Modified: 07/22/09, Bill L, Returning the PreviewText
*
* Description: Find any string within the T-SQL code on this SQL Server instance, specifically
*				Database objects and/or SQL Agent Jobs and/or SSIS Packages
*
* Test: sp_Find 'track'
*		sp_Find 'AS400'
*		sp_Find 'track', 'Common', 50
*		sp_Find 'track', 'Common', 50, 'Y', 'N', 'N' --DB Only
*		sp_Find 'track', 'Common', 50, 'N', 'N', 'Y' --SSIS Only
*/
Set Transaction Isolation Level Read Uncommitted;
Set Nocount On;

CREATE TABLE #FoundObject (
	  DatabaseName SYSNAME
	, ObjectName SYSNAME
	, ObjectTypeDesc NVARCHAR(60)
	, PreviewText VARCHAR(MAX))--To show a little bit of the code

DECLARE	@SQL as nvarchar(max);

SELECT 'Searching For: ''' + @SearchText + '''' As CurrentSearch;

/**************************
*  Database Search
***************************/
If @SearchDBsFlag = 'Y'
BEGIN
	IF @DBName Is Null --Loop through all normal user databases
	BEGIN
		DECLARE ObjCursor CURSOR LOCAL FAST_FORWARD FOR 
			SELECT	[Name]
			FROM	Master.sys.Databases
			WHERE	[Name] NOT IN ('AdventureWorks', 'AdventureWorksDW', 'Distribution', 'Master', 'MSDB', 'Model', 'TempDB');

		OPEN ObjCursor;

		FETCH NEXT FROM ObjCursor INTO @DBName;
		WHILE @@Fetch_Status = 0
		BEGIN
			SELECT @SQL = '
				Use [' + @DBName + ']

				INSERT INTO #FoundObject (
					  DatabaseName
					, ObjectName
					, ObjectTypeDesc
					, PreviewText)
				SELECT	DISTINCT
						  ''' + @DBName + '''
						, sch.[Name] + ''.'' + obj.[Name] AS ObjectName
						, obj.Type_Desc
						, REPLACE(REPLACE(SUBSTRING(mod.Definition, CHARINDEX(''' + @SearchText + ''', mod.Definition) - ' + CAST(@PreviewTextSize / 2 AS VARCHAR) + ', ' + 
							CAST(@PreviewTextSize AS VARCHAR) + '), char(13) + char(10), ''''), ''' + @SearchText + ''', ''***' + @SearchText + '***'')
				FROM 	sys.objects obj 
				INNER JOIN sys.SQL_Modules mod ON obj.Object_Id = mod.Object_Id
				INNER JOIN sys.Schemas sch ON obj.Schema_Id = sch.Schema_Id
				WHERE	mod.Definition Like ''%' + @SearchText + '%'' 
				ORDER BY ObjectName';

			EXEC dbo.sp_executesql @SQL;

			FETCH NEXT FROM ObjCursor INTO @DBName;
		END;

		CLOSE ObjCursor;

		DEALLOCATE ObjCursor;
	END
	ELSE --Only look through given database
	BEGIN
			SELECT @SQL = '
				USE [' + @DBName + ']

				INSERT INTO #FoundObject (
					  DatabaseName
					, ObjectName
					, ObjectTypeDesc
					, PreviewText)
				SELECT	DISTINCT
						  ''' + @DBName + '''
						, sch.[Name] + ''.'' + obj.[Name] AS ObjectName
						, obj.Type_Desc
						, REPLACE(REPLACE(SUBSTRING(mod.Definition, CHARINDEX(''' + @SearchText + ''', mod.Definition) - ' + CAST(@PreviewTextSize / 2 AS VARCHAR) + ', ' + 
							CAST(@PreviewTextSize AS VARCHAR) + '), CHAR(13) + CHAR(10), ''''), ''' + @SearchText + ''', ''***' + @SearchText + '***'')
				FROM 	sys.objects obj 
				INNER JOIN sys.SQL_Modules mod On obj.Object_Id = mod.Object_Id
				INNER JOIN sys.Schemas sch On obj.Schema_Id = sch.Schema_Id
				WHERE	mod.Definition Like ''%' + @SearchText + '%'' 
				ORDER BY ObjectName';

			EXEC dbo.sp_ExecuteSQL @SQL;
	END;

	SELECT 'Database Objects' AS SearchType;

	SELECT
		  DatabaseName
		, ObjectName
		, ObjectTypeDesc AS ObjectType
		, PreviewText
	FROM	#FoundObject
	ORDER BY DatabaseName, ObjectName;
END

/**************************
*  Job Search
***************************/
IF @SearchJobsFlag = 'Y'
BEGIN
	SELECT 'Job Steps' AS SearchType;


	SELECT	  j.[Name] AS [Job Name]
			, s.Step_Id AS [Step #]
			, REPLACE(REPLACE(SUBSTRING(s.Command, CHARINDEX(@SearchText, s.Command) - @PreviewTextSize / 2, @PreviewTextSize), CHAR(13) + CHAR(10), ''), @SearchText, '***' + @SearchText + '***') AS Command
	FROM	MSDB.dbo.sysJobs j
	INNER JOIN MSDB.dbo.sysJobSteps s On j.Job_Id = s.Job_Id 
	WHERE	s.Command LIKE '%' + @SearchText + '%';
END

/**************************
*  SSIS Search
***************************/
IF @SearchSSISFlag = 'Y'
BEGIN
	SELECT 'SSIS Packages' AS SearchType;

	SELECT	  [Name] AS [SSIS Name]
			, REPLACE(REPLACE(SUBSTRING(CAST(CAST(PackageData AS VARBINARY(Max)) AS VARCHAR(Max)), CHARINDEX(@SearchText, CAST(CAST(PackageData AS VARBINARY(MAX)) AS VARCHAR(MAX))) -
				@PreviewTextSize / 2, @PreviewTextSize), char(13) + char(10), ''), @SearchText, '***' + @SearchText + '***') AS [SSIS XML]
	FROM	MSDB.dbo.sysSSISPackages
	WHERE	CAST(CAST(PackageData AS VARBINARY(MAX)) AS VARCHAR(MAX)) LIKE '%' + @SearchText + '%';
END
GO

EXEC sp_ms_marksystemobject '[dbo].[dbm_Find]'
GO
