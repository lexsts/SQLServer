 select dp.NAME AS principal_name,
           dp.type_desc AS principal_type_desc,
           o.NAME AS object_name,
           p.permission_name,
           p.state_desc AS permission_state_desc 
   from    sys.database_permissions p
   left    OUTER JOIN sys.all_objects o
   on     p.major_id = o.OBJECT_ID
   inner   JOIN sys.database_principals dp
   on     p.grantee_principal_id = dp.principal_id
   
   
   
   
   /*
    select 'GRANT ' + P.PERMISSION_NAME COLLATE DATABASE_DEFAULT + ' ON ' + O.NAME + ' TO ' + dp.NAME AS principal_name
   from    sys.database_permissions p
   left    OUTER JOIN sys.all_objects o
   on     p.major_id = o.OBJECT_ID
   inner   JOIN sys.database_principals dp
   on     p.grantee_principal_id = dp.principal_id
   where dp.name in (select DISTINCT name from sysusers where name not in ('PUBLIC') and name not like 'DBG%')
   and O.NAME IS NOT NULL
   ORDER BY 1
   */