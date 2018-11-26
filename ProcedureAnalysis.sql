--Recompilations
--with a runtime recompilation hint
exec dbo.calcNewPrices @parameter1=1.20 WITH RECOMPILE;

--with a object recompilation
exec sp_recompile 'dbo.calcNewPrices';

--with recompile hint in stored procedure header
alter procedure dbo.calcNewPrices @parameter1 int
WITH RECOMPILE
as ...
go

--with recompile hint on individual statement
alter procedure dbo.calcNewPrices @parameter1 int
as
update products
set prices=prices*parameter1
OPTION (RECOMPILE);
go

--with clearing the cache
DBCC FREEPROCCACHE


--Check executions from a procedure
SELECT DB_NAME(st.dbid) DBName
      ,OBJECT_SCHEMA_NAME(st.objectid,dbid) SchemaName
      ,OBJECT_NAME(st.objectid,dbid) StoredProcedure
      ,max(cp.usecounts) Execution_count
      ,sum(qs.total_worker_time) total_cpu_time
      ,sum(qs.total_worker_time) / (max(cp.usecounts) * 1.0)  avg_cpu_time
  FROM sys.dm_exec_cached_plans cp join sys.dm_exec_query_stats qs on cp.plan_handle = qs.plan_handle
      CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
 where DB_NAME(st.dbid) is not null 
 --and cp.objtype IN ('GET_OPERACOES_RF','GETTRADES_RF_SAC','SP_RECON_RESGATESCETIP','SP_RECON_OPERACOESCETIP','SP_SW_CARTEIRA','SP_RV_CARTEIRA','SP_RECON_TWB_YMF_RV','SP_RECON_TWB_YMF_RF')
 group by DB_NAME(st.dbid),OBJECT_SCHEMA_NAME(objectid,st.dbid), OBJECT_NAME(objectid,st.dbid) 
 order by sum(qs.total_worker_time) desc
