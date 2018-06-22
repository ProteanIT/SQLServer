-- SQLCMD Variables
:SETVAR ProdDirectory "\\ADW-MIS02\Backups\FromProd\OvernightCopy"
:SETVAR TargetDirectory "\\ADW-PRCDB02\d$\MSSQL\Backup\Latest"


-- Only diffs since last Sunday
DECLARE @LastSundayDate VARCHAR(8) = ( SELECT CONVERT(VARCHAR(8), DATEADD(wk, DATEDIFF(wk, 6, GETDATE()), 6), 112) ),
		@Debug BIT = 1

/* Create 2 tables */

-- Left table contains all available bck and diff files

IF OBJECT_ID('tempdb..##FilesAvailable') IS NOT NULL 
BEGIN
	DROP TABLE ##FilesAvailable
END

CREATE TABLE ##FilesAvailable (
	FileName NVARCHAR(1000) NULL 
)

IF OBJECT_ID('tempdb..##FilesAlreadyCopied') IS NOT NULL 
BEGIN
	DROP TABLE ##FilesAlreadyCopied
END

CREATE TABLE ##FilesAlreadyCopied (
	FileName NVARCHAR(1000) NULL 
)

BEGIN TRY

SET NOCOUNT ON

INSERT INTO ##FilesAvailable
EXEC master..xp_cmdshell 'DIR /b $(ProdDirectory)\*.bck';

INSERT INTO ##FilesAvailable
EXEC master..xp_cmdshell 'DIR /b $(ProdDirectory)\*.dif';

INSERT INTO ##FilesAlreadyCopied
EXEC master..xp_cmdshell 'DIR /b $(TargetDirectory)\*.bck';

INSERT INTO ##FilesAlreadyCopied
EXEC master..xp_cmdshell 'DIR /b $(TargetDirectory)\*.dif';

-- Create a cursor to copy each missing file

IF (	SELECT		COUNT(*)

		FROM		##FilesAvailable A

		LEFT JOIN	##FilesAlreadyCopied C
		ON			A.FileName = C.FileName

		WHERE		C.FileName IS NULL
		AND			A.FileName >= @LastSundayDate	) > 0

BEGIN
		DECLARE @ThisFileName NVARCHAR(1000)

		-- Create a cursor to delete records id by id
		DECLARE SyncCsr CURSOR
		FOR

		SELECT		A.FileName

		FROM		##FilesAvailable A

		LEFT JOIN	##FilesAlreadyCopied C
		ON			A.FileName = C.FileName

		WHERE		C.FileName IS NULL
		AND			A.FileName >= @LastSundayDate

		-- Get on the merry go round
		OPEN	SyncCsr;

		FETCH NEXT FROM SyncCsr INTO @ThisFileName

		WHILE @@FETCH_STATUS = 0

		BEGIN

			RAISERROR  ('Copying %s to $(TargetDirectory)...', 0, 1, @ThisFileName) WITH NOWAIT

			IF @Debug = 1
			BEGIN

				PRINT 'EXEC master..xp_cmdshell XCOPY $(ProdDirectory)\' + @ThisFileName

			END
			ELSE
			BEGIN

				DECLARE @Cmd NVARCHAR(MAX) = 'master..xp_cmdshell ''XCOPY "$(ProdDirectory)\' + @ThisFileName + '" "$(TargetDirectory)"'''
				EXEC(@Cmd)

			END

			
			
			FETCH NEXT FROM SyncCsr INTO @ThisFileName

		END

		CLOSE SyncCsr;
		DEALLOCATE SyncCsr;
		
	END
	ELSE
	BEGIN
		RAISERROR  ('There are no backup files to copy...', 0, 1) WITH NOWAIT
	END
END TRY
BEGIN CATCH

	DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE()

	RAISERROR(@ErrorMessage, 16, 1)

END CATCH

-- Cleanup

IF OBJECT_ID('tempdb..##FilesAvailable') IS NOT NULL 
BEGIN
	DROP TABLE ##FilesAvailable
END


IF OBJECT_ID('tempdb..##FilesAlreadyCopied') IS NOT NULL 
BEGIN
	DROP TABLE ##FilesAlreadyCopied
END
