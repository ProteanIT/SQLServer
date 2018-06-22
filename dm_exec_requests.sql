/* Get SQL - Only runs with SQL 2005+ Compatible level - RUN ON MASTER OR DEFAULT */
SELECT session_id, DB_NAME(database_id) database_name, start_time, command, [text], [status], wait_type, OBJECT_NAME(objectid) [object_name]
FROM sys.dm_exec_requests a
CROSS APPLY sys.dm_exec_sql_text(a.sql_handle)
WHERE a.session_id <> @@SPID

sp_who2

/* Get RESTORE progress */
SELECT DB_NAME(database_id) DATABASE_NAME, COMMAND,PERCENT_COMPLETE
FROM sys.dm_exec_requests a
WHERE COMMAND LIKE '%RESTORE%'

/* Get BACKUP progress */
SELECT DB_NAME(database_id) DATABASE_NAME, COMMAND,PERCENT_COMPLETE
FROM sys.dm_exec_requests a
WHERE COMMAND LIKE '%BACKUP%'

EXEC sp_updatestats
