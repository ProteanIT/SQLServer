USE [master]
GO

:SETVAR LocalBackupsFolder "C:\MSSQL\BACKUP"
:SETVAR LocalDataFileFolder "C:\MSSQL\DATA"
:SETVAR LocalLogFileFolder "C:\MSSQL\LOG"
:SETVAR BackupExtension ".bck0"

DECLARE	@DropPrevious						INT	= 1
,		@IsDebug						INT = 1
,		@MyMachineName						VARCHAR(100)  = 'BANANAMAN' --Pattern of server we want to restore against
,		@ErrorMessage						VARCHAR(1000) = ''
,		@ProgressMessage					VARCHAR(1000) =	''
,		@BackupLocation						VARCHAR(1000) = '$(LocalBackupsFolder)'
,		@DataFileLocation					VARCHAR(4000) = '$(LocalDataFileFolder)'
,		@LogFileLocation					VARCHAR(4000) = '$(LocalLogFileFolder)'
,		@BackupFile						VARCHAR(4000)
,		@DatabaseName						VARCHAR(500)
,		@changeOwnerSQL						NVARCHAR(1000);

DECLARE	@tblBackupFiles	TABLE (
		[FileName]		NVARCHAR(MAX)
);

SET NOCOUNT ON

PRINT 'Script running under account: ' + SUSER_SNAME()

-- Check we are running on our machine
IF (PATINDEX(@MyMachineName + '%', @@SERVERNAME) = 0 )
BEGIN
	SET @ErrorMessage = '''@@SERVERNAME'' variable doesn''t match the local desktop naming pattern!! Is this a team Server??' + CHAR(10) + 'This script has irreversible consequences. Make sure you''re running against the intended machine.'
	GOTO ErrorHandler;
END

-- We'll use this table for getting the filenames later.
IF OBJECT_ID('TempDB..#FileList') IS NOT NULL
BEGIN
	DROP TABLE #FileList
END


CREATE TABLE #FileList
(
	LogicalName			VARCHAR(400) NULL,
	PhysicalName			VARCHAR(4000) NULL,
	Type				CHAR(1) NULL,
	FileGroupName			VARCHAR(100) NULL,
	Size				NUMERIC(20,0) NULL,
	MaxSize				NUMERIC(30,0) NULL,
	FileId				BIGINT NULL,
	CreateLSN			NUMERIC(20,0) NULL,
	DropLSN				BIGINT NULL,
	UniqueId			VARCHAR(255) NULL,
	ReadOnlyLSN			BIGINT NULL,
	ReadWriteLSN			BIGINT NULL,
	BackupSizeInBytes		NUMERIC(20,0) NULL,
	SourceBlockSize			BIGINT NULL,
	FileGroupId			BIGINT NULL,
	LogGroupGUID			UNIQUEIDENTIFIER NULL,
	DifferentialBaseLSN		VARCHAR(255) NULL,
	DifferentialBaseGUID	VARCHAR(255) NULL,
	IsReadOnly			BIGINT NULL,
	IsPresent			BIGINT NULL,
	TDEThumbprint			VARBINARY
)

--Get a list of files in the backup folder
INSERT	@tblBackupFiles
EXEC	xp_cmdshell 'dir /b "$(LocalBackupsFolder)\*.$(BackupExtension)"'

IF @IsDebug = 1
BEGIN
	SELECT	[FileName] RestoringFiles
	FROM	@tblBackupFiles
	WHERE	[FileName] IS NOT NULL;
END

IF EXISTS (	SELECT 1 FROM @tblBackupFiles WHERE [FileName] = 'File Not Found')
BEGIN
	RAISERROR('No files found matching the pattern...',11,1) WITH NOWAIT
	GOTO ErrorHandler;
END

--Loop over databases, restoring each one in turn!
DECLARE	curDatabasesBaks CURSOR FOR
SELECT	[FileName]
FROM	@tblBackupFiles
WHERE	[FileName] IS NOT NULL;
OPEN	curDatabasesBaks;
FETCH	NEXT FROM curDatabasesBaks
INTO	@BackupFile;
WHILE	@@FETCH_STATUS = 0
BEGIN
	
	-- Derive the database name from the filename
	SELECT @DatabaseName = REPLACE(@BackupFile, '.$(BackupExtension)', '')
	
	-- Report progress...
	SET @ProgressMessage = N'DATABASE ''' + @DatabaseName + N''' at ' + CAST(CURRENT_TIMESTAMP AS NVARCHAR(25)) + ' ...';
	
	SET @ProgressMessage = CHAR(10) + REPLICATE('*', LEN(@ProgressMessage)) + CHAR(10) + @ProgressMessage + CHAR(10) + REPLICATE('*', LEN(@ProgressMessage))
	
	RAISERROR(@ProgressMessage, 0,1) WITH NOWAIT
	
	DECLARE @setDatabaseMode NVARCHAR(4000)
	
	IF ((PATINDEX(@MyMachineName + '%', @@SERVERNAME) > 0) AND EXISTS (SELECT * FROM MASTER.SYS.DATABASES WHERE NAME = @DatabaseName))
	BEGIN
		
		-- Single User Mode
		SET @setDatabaseMode = 'ALTER DATABASE [' + @DatabaseName + '] SET SINGLE_USER WITH ROLLBACK IMMEDIATE'
	
		-- Report progress...
		RAISERROR('Setting single user mode...',0,1) WITH NOWAIT
		EXEC sp_executesql @setDatabaseMode
	
	END
	
	IF ((@DropPrevious = 1) AND (PATINDEX(@MyMachineName + '%', @@SERVERNAME) > 0) AND EXISTS (SELECT * FROM MASTER.SYS.DATABASES WHERE NAME = @DatabaseName))
	BEGIN
		DECLARE @dropDatabaseSQL nvarchar(4000) = 'DROP DATABASE [' + @DatabaseName + ']'
		
		-- Report progress...
		RAISERROR('Dropping previous...',0,1) WITH NOWAIT
		EXEC sp_executesql @dropDatabaseSQL
	END
	
	IF ((PATINDEX(@MyMachineName + '%',@@SERVERNAME) > 0) AND NOT EXISTS (SELECT NAME FROM MASTER.SYS.DATABASES WHERE NAME = @DatabaseName))
	BEGIN 
		DECLARE @createDatabaseSQL NVARCHAR(4000) = 'CREATE DATABASE ['+@DatabaseName+']'
	
		-- Print the command if in debug mode
		IF @IsDebug = 1
		BEGIN
			-- Report progress...
			SET @ProgressMessage = 'Creating new database ''' + @DatabaseName + '''...'
			RAISERROR(@ProgressMessage, 0, 1) WITH NOWAIT
			
			-- Display command
			RAISERROR(@createDatabaseSQL, 0, 1) WITH NOWAIT
		END
		
		-- Execute the command
		EXEC sp_executesql @createDatabaseSQL
		
	END
	
	-- Get the filenames from the backups
	INSERT INTO #FileList
	EXEC('RESTORE FILELISTONLY FROM DISK=N''' + @BackupLocation + '\' + @BackupFile + '''')

	DECLARE @MoveCmd nvarchar(max) = ''

	-- Build a move command from the file list
	SELECT	@MoveCmd = @MoveCmd + N'MOVE N''' + LogicalName + ''' TO N''' + CASE [Type] WHEN N'D' THEN @DataFileLocation ELSE @LogFileLocation END + '\' + @DatabaseName + CASE FileId WHEN 1 THEN '.mdf'', ' WHEN 2 THEN '.ldf'', ' ELSE CAST(FileId -2 AS NVARCHAR(2)) + '.ndf'', ' END
	
	FROM	#FileList
	
	-- Restore SQL
	DECLARE @restoreDatabaseSQL NVARCHAR(MAX) = '
	RESTORE DATABASE ['+ @DatabaseName + '] FROM  
	DISK = N''' + @BackupLocation + '\' + @BackupFile + '''  
	WITH	FILE = 1,
			' + @MoveCmd + '
			REPLACE,  
			NOUNLOAD,  
			STATS = 10
			
'
	IF @IsDebug = 1
	BEGIN
		-- Report progress...
		RAISERROR('Restoring...', 0, 1) WITH NOWAIT
		
		-- Display command
		RAISERROR(@restoreDatabaseSQL, 0, 1) WITH NOWAIT
	END
	
	-- Check that we are on the intended machine.
	IF (PATINDEX(@MyMachineName + '%', @@SERVERNAME) > 0)
	BEGIN
		EXEC (@restoreDatabaseSQL)
	
		-- In prod all DBs are owned by sa, so applying the same to dev	- FB 20131014
		SET @changeOwnerSQL = N'EXEC ' + @DatabaseName + N'.dbo.sp_changedbowner @loginame = N''sa'', @map = false'

		RAISERROR('Changing DB owner to [sa] for database: %s', 0, 1, @DatabaseName) WITH NOWAIT

		EXEC sp_executesql @ChangeOwnerSQL
	
	END
	
	-- Return to multi user mode
	IF ((PATINDEX(@MyMachineName + '%', @@SERVERNAME) > 0) AND EXISTS (SELECT * FROM MASTER.SYS.DATABASES WHERE NAME = @DatabaseName))
	BEGIN
		
		-- Single User Mode
		SET @setDatabaseMode = 'ALTER DATABASE [' + @DatabaseName + '] SET MULTI_USER'
	
		-- Report progress...
		RAISERROR('Setting multi user mode...',0,1) WITH NOWAIT
		EXEC sp_executesql @setDatabaseMode
	
	END	
	
	-- Empty the filelist for the next database
	DELETE FROM #FileList
	
	FETCH	NEXT FROM curDatabasesBaks
	INTO	@BackupFile;
END

CLOSE	curDatabasesBaks;
DEALLOCATE	curDatabasesBaks;

GOTO NormalExecution

ErrorHandler:
	SET @ErrorMessage = 'Failed to restore database(s)'
	RAISERROR(@ErrorMessage, 16, 1)
	RETURN

NormalExecution:
-- Report progress...
	RAISERROR('Script completed successfully...', 0, 1)
