-- Delete from a localgroup
master..xp_cmdshell 'NET LOCALGROUP ADMINISTRATORS /Delete "DOMAIN\UserName"'

-- Add to a localgroup
master..xp_cmdshell 'NET LOCALGROUP ADMINISTRATORS /Add "DOMAIN\UserName"'

--Get members of a domain group
master..xp_cmdshell 'NET GROUP "APP_MICore_MIControl_DEV_Editor" /DOMAIN'

-- Get members of a localgroup
master..xp_cmdshell 'NET LOCALGROUP ADMINISTRATORS'

-- What account am I running under SQL2K5
master..xp_cmdshell 'sqlcmd -S"ADW-PRCDB02\MIDEV02" -Q"SELECT SUSER_SNAME();"'

-- What account am I running under SQL2K0
master..xp_cmdshell 'isql -E -Q"SELECT SUSER_SNAME();"'

-- Contents of a directory
master..xp_cmdshell 'DIR D:\MSSQL\Backup\'

-- Active sessions on remote machine
master..xp_cmdshell 'QUERY SESSION /SERVER:ADW-PRCDB02'

-- Reset the session
master..xp_cmdshell 'RESET SESSION 0 /SERVER:ADW-PRCDB02'

master..xp_cmdshell 'DIR \\ADW-MIS02\Backups$\FromProd\OvernightCopy\*Finance*.trn'

-- Copy a diff file from admin only to share folder
master..xp_cmdshell 'XCOPY "\\ADW-MIS02\Backups$\FromProd\OvernightCopy\20141125*MIStaging*.trn" "D:\MSSQL\Backup\MOCREC_COB2411\"'

-- Copy a bck file from admin only to share folder
master..xp_cmdshell 'XCOPY "D:\MSSQL\Backup\Latest\APW-PRCS01@DB_PRD_01.Finance.*.bck" "D:\MSSQL\Backup\MOCREC_COB2411"'

-- Delete a set of files with pattern from local directory
xp_cmdshell 'del "D:\MSSQL\Backup\MOCREC_COB2411\*.bck"'

--APW-PRCS01@DB_PRD_01.Finance.01Of10.bck
--APW-PRCS01@DB_PRD_01.Finance.02Of10.bck
--APW-PRCS01@DB_PRD_01.Finance.03Of10.bck
--APW-PRCS01@DB_PRD_01.Finance.04Of10.bck
--APW-PRCS01@DB_PRD_01.Finance.05Of10.bck
--APW-PRCS01@DB_PRD_01.Finance.06Of10.bck
--APW-PRCS01@DB_PRD_01.Finance.07Of10.bck
--APW-PRCS01@DB_PRD_01.Finance.08Of10.bck
--APW-PRCS01@DB_PRD_01.Finance.09Of10.bck
--APW-PRCS01@DB_PRD_01.Finance.10Of10.bck

master..xp_cmdshell 'XCOPY /?'

-- Contents of a directory
master..xp_cmdshell 'DIR "E:\MSSQL\Backup\346_SIT_DoNotDelete"'
master..xp_cmdshell 'DIR "D:\Build\ProdDataFiles"'

-- All files and subfolders as a filelist with no header info /S = SubDirectory /B = Bare filenames
master..xp_cmdshell 'DIR /S /B "C:\Program Files"'

master..xp_cmdshell 'DIR "D:\Build\DatabaseBackups\COB20140501_MUREX_SIT"'

-- Delete a dir
master..xp_cmdshell 'RMDIR /Q /S "D:\Build\3.92.12215.117204"'

xp_fixeddrives

-- Unzip using winzip
master..xp_cmdshell '"C:\Program Files (x86)\WinZip\wzunzip.exe" -v ''\\Miami5\Clients\MyArchive_12072011.zip'''

-- Unzip using 7zip (not correct yet but will be something like this)
master..xp_cmdshell '''C:\Program Files (x86)\7-Zip\7z.exe'' -e"D:\APPS\PRS-SYS1\Imports\ProdFiles.7z"  -o''D:\APPS\PRS-SYS1\Imports\TestFCB\'''

-- restart a remote machine
master..xp_cmdshell 'shutdown -r -m \\INVTMIAVDDBFB01.fti4olap.local'

-- Ping
master..xp_cmdshell 'ping -a INVTMIAVDDBFB01'

-- Move contents of a directory
master..xp_cmdshell 'move "\\Fti4olap\resources\Projects\DBA Projects\Sterling\Migration\Delta Files\Export*.txt" "\\Fti4olap\resources\Projects\DBA Projects\Sterling\Migration\Delta Files\Archive\"'

-- Tasklist
master..xp_cmdshell 'tasklist'

-- Kill process
master..xp_cmdshell 'taskkill /PID 12248 12076'

-- Running Services
master..xp_cmdshell 'tasklist /svc'

-- Stop a service
master..xp_cmdshell 'NET STOP MIControlService-DEV1'
                       
-- Start a service
master..xp_cmdshell 'NET START MIControlService-DEV1'

-- Run DTExec
master..xp_cmdshell 'dtexec.exe /FILE "D:\Apps\PRS-DEV2\SSIS\Packages\Derivation.1830.Master.dtsx" /MAXCONCURRENT "1" /CHECKPOINTING OFF /REPORTING V /CONSOLELOG X >D:\APPS\PRS-DEV2\SSIS\ExecutionLog\Derivation.1830.Master.log'

-- What port am I connected on
SELECT	@@SERVERNAME As SqlServer,   
		LOCAL_NET_ADDRESS AS 'SqlServerIP',
		LOCAL_TCP_PORT  AS 'Port'
,*
FROM	SYS.DM_EXEC_CONNECTIONS WHERE SESSION_ID = @@SPID

