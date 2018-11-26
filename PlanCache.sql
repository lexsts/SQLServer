SELECT cp.objtype AS ObjectType,
OBJECT_NAME(st.objectid,st.dbid) AS ObjectName,
cp.usecounts AS ExecutionCount,
st.TEXT AS QueryText,
qp.query_plan AS QueryPlan
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
--WHERE OBJECT_NAME(st.objectid,st.dbid) = 'YourObjectName'

--#procedure(s) de validação e processamento do retorno bancário (por upload)
--USE msdb; EXEC PROC_ADICIONAR_JOB_RETORNO_BRA @TIPO, @REMESSA_ID

--#procedure(s) de validação e processamento do arquivo de remessa (por upload)
--USE msdb; EXEC PROC_ADICIONAR_JOB @TIPO, @REMESSA_ID --CNAB
--Ou
--                EXEC msdb.dbo.PROC_ADICIONAR_JOB_WS_REMESSA @REMESSA_ID –-API xml

--#procedure(s) de liquidação (execução diária às 19:00)
--EXEC PROC_API_AGENDAMENTO_LIQUIDACOES 0, 0

--#procedure(s) de fechamento do dia (execução diária)
--EXEC PROC_EXECUTAR_FECHAMENTO_ESTOQUE 0

--#procedure(s) que gera fotografia do estoque (execução diária)
--EXEC PROC_EXECUTAR_FECHAMENTO_ESTOQUE 0

--#procedure(s) de PDD (execução diária)
--EXEC PROC_EXECUTAR_CALCULOS_TITULOS 0, 0

--#procedure(s) de PDD 21/60 (execução diária)
--EXEC PROC_TITULO_PROCESSAR_CALCULO_PDD_2160 0, 0

--#procedure(s) de apropriação diária (execução diária)
--EXEC PROC_EXECUTAR_CALCULOS_TITULOS 0, 0
