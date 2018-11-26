select
dp.type_desc AS principal_type_desc,
dbp.class_desc,
OBJECT_NAME(dbp.major_id) AS object_name,
dbp.permission_name,
dbp.state_desc AS permission_state_desc
from    sys.database_permissions dbp
INNER JOIN sys.database_principals dp
on dbp.grantee_principal_id = dp.principal_id
--where dp.name='ro_funcao_01'