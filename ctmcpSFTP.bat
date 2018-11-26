::@echo off

set dia=%date:~0,2%
set DirOrigem=%1
set DirDestino=%2
set Lista=C:\ctmag\Data\ssh\lista%3.lst
set exec_SFTP=c:\ctmag\data\sftp_%3.txt
set exec_BKP=c:\ctmag\data\bkp_%3.bat
set KeyAcesso=C:\ctmag\Data\ssh\saoshappp0139.ppk
set comandos=D:\monitor\check\bin

if exist c:\ctmag\data\lockf%3.txt goto :FIM
echo Arquivo de lock da bat, nao deletar manualmente durante a execucao da mesma. > c:\ctmag\data\lockf%3.txt

dir %DirOrigem% /on | find ":" > c:\ctmag\data\comp1%3.txt
sleep 5
dir %DirOrigem% /on | find ":" > c:\ctmag\data\comp2%3.txt

fc c:\ctmag\data\comp1%3.txt c:\ctmag\data\comp2%3.txt > c:\ctmag\data\fccond%3.txt
type c:\ctmag\data\fccond%3.txt | find "FC: no differences encountered"

if %errorlevel%==1 goto :DELARQ

%comandos%\ls %DirOrigem% > %Lista%

::Monta o arquivo de execução para o SFTP
echo cd %DirDestino% > %exec_SFTP%
echo cls > %exec_BKP%
for /F "tokens=* delims= " %%i in (%Lista%) do (
echo mput "%%i" >> %exec_SFTP%
echo move "%%i" \\saoappl01\appl\Production_IT\BKPArqs\%dia% >> %exec_BKP%
)
echo quit >> %exec_SFTP%
echo DEL /Q c:\ctmag\data\lockf%3.txt >> %exec_BKP%
::::Encerra a execução

::Executa a movimentacao e backup
%comandos%\PSFTP2.EXE -v -2 -b %exec_SFTP% -i %KeyAcesso% weblogic@saoshappp0139 
%exec_BKP%

:DELARQ
DEL /Q c:\ctmag\data\lockf%3.txt