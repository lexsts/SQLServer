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
	WHERE DP.NAME IN 	
   ('jdcabine',		
'hnatsum',		
'masswil',		
'segarob',		
'uasymf-g',		
'dta_ui_login',		
'lschipjd',		
'spb_rob',		
'user_volumetrix',		
'usr_funcao',		
'usr_sgi',		
'uymfsac',		
'wli_select',		
'wli_user',		
'DBG\carvjul',		
'ujdcabine',		
'dbg\damacas',		
'DBG\costrob',		
'usr_sgt',		
'DBG\kiaerau',		
'DBG\seckjos',		
'DBG\areabru',		
'DBG\rosshen')		
ORDER BY 1;		
