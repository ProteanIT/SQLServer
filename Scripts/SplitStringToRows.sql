USE [master]
GO

CREATE FUNCTION [dbo].[SplitStringToRows]
(
	@InputString	NVARCHAR(MAX),
	@Delimiter		NVARCHAR(5)
)
RETURNS @tblParts TABLE
(
	[Index]			INT NOT NULL,
	[StringPart]	NVARCHAR(MAX) NOT NULL
)
AS
BEGIN
	DECLARE @Index INT = 1
	DECLARE @StringPart NVARCHAR(MAX)
	DECLARE @PartLength INT = 1;
	DECLARE @StartPosition INT = 1;

	WHILE (@StartPosition < DATALENGTH(@InputString) + 1)
	BEGIN
		SET @PartLength = CHARINDEX(@Delimiter, SUBSTRING(@InputString, @StartPosition, DATALENGTH(@InputString)), 1)
		
		IF	@PartLength = 0
			SET @PartLength = DATALENGTH(@InputString) - @StartPosition + 1
		
		SET @StringPart = SUBSTRING(SUBSTRING(@InputString, @StartPosition, DATALENGTH(@InputString)), 1, @PartLength)
		SET @StringPart = REPLACE(@StringPart,@Delimiter,'')
		
		INSERT	@tblParts
				([Index]
				,[StringPart])
		VALUES	(@Index
				,@StringPart)
		
		SET @StartPosition += @PartLength
		SET @Index += 1
	END
	
	RETURN

END
