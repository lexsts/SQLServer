SELECT OBJECT_name(OBJECT_ID) Tabela, name AS Indice, STATS_DATE(OBJECT_ID, index_id) AS DataAtualizado 
FROM sys.indexes where is_hypothetical  = 0 
AND OBJECT_name(OBJECT_ID) NOT LIKE ‘sys%’ ORDER BY  OBJECT_name(OBJECT_ID)
SELECT OBJECT_name(OBJECT_ID) Tabela, name AS Indice, STATS_DATE(OBJECT_ID, index_id) AS DataAtualizado 
FROM sys.indexes where is_hypothetical  = 0 
AND OBJECT_name(OBJECT_ID) NOT LIKE 'sys%' ORDER BY  OBJECT_name(OBJECT_ID)