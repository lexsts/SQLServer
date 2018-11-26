@echo off
::efetua o backup das procedures
for /F %%i in ('dir /b c:\temp\procedures\*.sql') do (
sqlcmd -S %1 -d %2 -Q "SP_HELPTEXT %%~ni;" -o c:\temp\procedures\bkp\%%~ni_BKP.sql
)
echo "Backup da estrutura das procedures efetuado."

echo "Iniciando backup dos privilegios."
pause
for /F %%i in ('dir /b c:\temp\procedures\*.sql') do (
sqlcmd -S %1 -d %2 -Q "select 'GRANT ' + P.PERMISSION_NAME COLLATE DATABASE_DEFAULT + ' ON ' + s.name +'.' + O.NAME + ' TO ' + dp.NAME + ';' from sys.database_permissions p left OUTER JOIN sys.all_objects o on p.major_id = o.OBJECT_ID inner JOIN sys.database_principals dp on p.grantee_principal_id = dp.principal_id JOIN SYS.SCHEMAS s ON o.schema_id=s.schema_id where O.NAME='%%~ni';">> c:\temp\procedures\Privilegios.txt
)
type Privilegios.txt | findstr "GRANT" > c:\temp\procedures\bkp\Privilegios_BKP.sql
del Privilegios.txt
echo "Finalizado backup dos privilegios ."

echo "Iniciando a publicacao das procedures."
pause
for /F %%i in ('dir /b c:\temp\procedures\*.sql') do (
sqlcmd -S %1 -d %2 -i %%i
sqlcmd -S %1 -d %2 -Q "SELECT SCH.NAME,SOB.NAME,SOB.TYPE,SOB.CREATE_DATE,SOB.MODIFY_DATE FROM SYS.OBJECTS SOB JOIN SYS.SCHEMAS SCH ON SOB.schema_id=SCH.schema_id WHERE SOB.NAME='%%~ni';">> %%~ni_OUTPUT.txt
)
echo "Finalizado publicacao das procedures."

echo "Iniciando a concessao de privilegios."
pause
sqlcmd -S %1 -d %2 -i c:\temp\procedures\bkp\Privilegios_BKP.sql -o Privilegios_output.txt
echo "Finalizado a concessao de privilegios."

echo "Gerando lista com a data de publicacao de todas as procedures."
pause
for /F %%i in ('dir /b c:\temp\procedures\*.sql') do (
sqlcmd -S %1 -d %2 -Q "SELECT SCH.NAME,SOB.NAME,SOB.TYPE,SOB.CREATE_DATE,SOB.MODIFY_DATE FROM SYS.OBJECTS SOB JOIN SYS.SCHEMAS SCH ON SOB.schema_id=SCH.schema_id WHERE SOB.NAME='%%~ni';">> Procedures_publicadas.txt
)
set /p firstline=<Procedures_publicadas.txt
echo %firstline% > Lista_Procedures_publicadas.txt
type Procedures_publicadas.txt | findstr /V "\-\-\-\-\-" | findstr /V "(1 rows affected)" | findstr /V "MODIFY_DATE" >> Lista_Procedures_publicadas.txt
del Procedures_publicadas.txt
echo "Finalizado a listagem de procedures publicadas."
pause

::pubProcedure.bat "SQL2012SVC\SQL2012,49599" AdventureWorks2012
::select 'GRANT ' + P.PERMISSION_NAME COLLATE DATABASE_DEFAULT + ' ON ' + s.name +'.' + O.NAME + ' TO ' + dp.NAME + ';' from sys.database_permissions p left OUTER JOIN sys.all_objects o on p.major_id = o.OBJECT_ID inner JOIN sys.database_principals dp on p.grantee_principal_id = dp.principal_id JOIN SYS.SCHEMAS s ON o.schema_id=s.schema_id where O.NAME in ('uspGetBillOfMaterials','uspGetEmployeeManagers','uspGetManagerEmployees')
