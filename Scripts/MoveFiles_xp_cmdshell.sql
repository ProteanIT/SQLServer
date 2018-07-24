DECLARE @TodaysDate DATE = GETDATE()
DECLARE @EffectiveDate DATE = CASE datename(dw, @TodaysDate) 
								WHEN 'Monday' THEN CONVERT(DATE, DATEADD(DAY,-2, @TodaysDate)) -- Use Saturday's date
								ELSE CONVERT(DATE, @TodaysDate) END , -- This works except on Bank Hols.
		
		@EnvironmentShare VARCHAR(30) = 'Imports-SYS1',
		@EnvironmentServer VARCHAR(15) = 'my-sit-server01',
		@IsServiceAccount BIT = 0, -- If using a local machine, then should be running under developer account and therefore has access to prod directories
		@Command VARCHAR(4000),
		@IsDebug INT = 1,

		/* Date patterns */
		@MARSDatePattern VARCHAR(8),
		@STRDatePattern VARCHAR(8),
		@MurexDatePattern VARCHAR(8),
		@BloombergDatePattern VARCHAR(6),
		@FileDatePattern VARCHAR(8),
		@AnotherVariableTest_DeleteLater VARCHAR(MAX)


SELECT	@MARSDatePattern = CONVERT(VARCHAR(8), @EffectiveDate, 112),
		@STRDatePattern = CONVERT(VARCHAR(8), DATEADD(DAY,-1,@EffectiveDate), 112),
		@MurexDatePattern = CONVERT(VARCHAR(8), DATEADD(DAY,-1,@EffectiveDate), 112), -- Depends on dev schedule
		@BloombergDatePattern = CONVERT(VARCHAR(8), DATEADD(DAY,-1,@EffectiveDate), 12),
		@FileDatePattern = CONVERT(VARCHAR(8), DATEADD(DAY, 0, @EffectiveDate), 112),
		@IsServiceAccount = CASE WHEN PATINDEX('%MLP%', @@SERVERNAME) > 0 THEN ISNULL(@IsDebug, 0) ELSE 1 END
		

-- CLIENT files
SET @command = 'XCOPY "\\my-prod-server01\Imports-PRD1\Archive\Intraday\CLIENTS-' + @FileDatePattern + '????.csv.*.txt" "\\' + @EnvironmentServer + '\'+ @EnvironmentShare + '\Import\Repository"'

IF @IsServiceAccount = 0
BEGIN
	EXEC master..xp_cmdshell @command
END

PRINT @command;
