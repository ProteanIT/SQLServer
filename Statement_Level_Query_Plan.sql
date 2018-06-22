--  statement_level_query_plan.sql ***********************************************
-----------------------------------------------------------

CREATE FUNCTION statement_level_query_plan(

        @handle as varbinary(64) -- Handle for the overall query plan

)

RETURNS TABLE as 

RETURN (

  select 

        statement_nbr,                 -- Sequential number of statement within batch or SP

        statement_type,                       -- SELECT, INSERT, UPDATE, etc

        statement_subtree_cost,               -- Estimated Query Cost

        statement_estimated_rows,             -- Estimated Rows Returned

        statement_optimization_level,         -- FULL or TRIVIAL

        statement_text,                       -- Text of query

        statement_plan                -- XML Plan    To view as a graphical plan

                                                     --      save the column output to a file with extension .SQLPlan

                                                     --      then reopen the file by double-clicking

   from (

        select 

               C.value('@StatementId','int') as statement_nbr,

               C.value('(./@StatementText)','nvarchar(max)') as statement_text,

               C.value('(./@StatementType)','varchar(20)') as statement_type,

               C.value('(./@StatementSubTreeCost)','float') as statement_subtree_cost,

               C.value('(./@StatementEstRows)','float') as statement_estimated_rows,

               C.value('(./@StatementOptmLevel)','varchar(20)') as statement_optimization_level,

--             Construct the XML headers around the single plan that will permit

--             this column to be used as a graphical showplan.

--             Only generate plan columns where statement has an associated plan

               C.query('declare namespace PLN="http://schemas.microsoft.com/sqlserver/2004/07/showplan";

                       if (./PLN:QueryPlan or ./PLN:Condition/PLN:QueryPlan) 

                       then

                               <PLN:ShowPlanXML><PLN:BatchSequence><PLN:Batch><PLN:Statements><PLN:StmtSimple>

                              { ./attribute::* }

                              { ./descendant::PLN:QueryPlan[1] }

                               </PLN:StmtSimple></PLN:Statements></PLN:Batch></PLN:BatchSequence></PLN:ShowPlanXML>

                       else ()

               ') as statement_plan

        from 

               sys.dm_exec_query_plan(@handle)

        CROSS APPLY 

--             This expression finds all nodes containing attribute StatementText

--             regardless of how deep they are in the potentially nested batch hierarchy

--             The results of this expression are processed by the Select expressions above

               query_plan.nodes('declare namespace PLN="http://schemas.microsoft.com/sqlserver/2004/07/showplan";

                /PLN:ShowPlanXML/PLN:BatchSequence/PLN:Batch/PLN:Statements/descendant::*[attribute::StatementText]') 

                       as T(C) 

        ) x

  )