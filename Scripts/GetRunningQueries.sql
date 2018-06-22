SELECT pln.*, req.* from sys.dm_exec_requests as req  

CROSS APPLY statement_level_query_plan(plan_handle) as pln

WHERE 
req.session_id <> @@SPID
and statement_text like

'%' +

replace(

left(

               substring((select text from master.sys.dm_exec_sql_text(sql_handle)), 

                       statement_start_offset/2, 

                       1+      case when statement_end_offset = -1 

                              then LEN((select text from master.sys.dm_exec_sql_text(sql_handle))) - statement_start_offset/2

                               else statement_end_offset/2 - statement_start_offset/2 

                              end) 

        ,3000)

, '[','[[]') + '%'
