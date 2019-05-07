
WITH XMLNAMESPACES 
( DEFAULT 
  'http://schemas.microsoft.com/sqlserver/reporting/2010/01/reportdefinition'
, 'http://schemas.microsoft.com/SQLServer/reporting/reportdesigner' AS ReportDefinition )

SELECT  cat.[Name] AS ReportName,
		cat.[Path] AS ReportPathLocation,
		cat.[ItemId] AS ReportGuid,
		xmlcolumn.value('(@Name)[1]', 'VARCHAR(250)') AS DataSetName,
		xmlcolumn.value('(Query/DataSourceName)[1]','VARCHAR(250)') AS DataSoureName,
		xmlcolumn.value('(Query/CommandText)[1]','VARCHAR(2500)') AS CommandText

FROM (  	SELECT	C.[Name],
					C.[Path],
					C.[ItemId],
					CONVERT(XML,CONVERT(VARBINARY(MAX),C.Content)) AS reportXML

			FROM	ReportServer.dbo.[Catalog] C
	
			WHERE	C.Content IS NOT NULL
			AND		C.Type = 2
			AND		C.Path NOT LIKE '%backup%'
			AND		C.Path NOT LIKE '%[_]development[_]%'
			
			) cat

CROSS APPLY reportXML.nodes('/Report/DataSets/DataSet') xmltable ( xmlcolumn )

WHERE 1=1

ORDER BY cat.[Name]
