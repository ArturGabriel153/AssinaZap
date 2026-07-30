@echo off
chcp 65001 >nul
title Instalador do AssinaZap
echo.
echo  ============================================
echo    Instalador do AssinaZap
echo  ============================================
echo.

set "AHK=C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
set "DEST=%LOCALAPPDATA%\AssinaZap"

rem --- 1) Garantir que o AutoHotkey v2 esta instalado ---
if exist "%AHK%" goto ahk_ok
echo  AutoHotkey v2 nao encontrado. Tentando instalar automaticamente...
winget install --id AutoHotkey.AutoHotkey -e --accept-source-agreements --accept-package-agreements
if exist "%AHK%" goto ahk_ok
echo.
echo  Nao foi possivel instalar automaticamente.
echo  Vou abrir o site oficial: baixe e instale a versao v2,
echo  depois rode este Instalar.bat de novo.
start https://www.autohotkey.com/
pause
exit /b 1

:ahk_ok
echo  [OK] AutoHotkey v2 encontrado.

rem --- 2) Copiar o programa para o computador (sem config.ini: cada pessoa cria o seu) ---
mkdir "%DEST%" 2>nul
copy /Y "%~dp0AssinaZap.ahk" "%DEST%\" >nul
copy /Y "%~dp0*.txt" "%DEST%\" >nul
echo  [OK] Programa copiado para: %DEST%

rem --- 3) Criar atalho na Inicializacao do Windows (inicio automatico) ---
powershell -NoProfile -Command "$s=New-Object -ComObject WScript.Shell; $l=$s.CreateShortcut([Environment]::GetFolderPath('Startup')+'\AssinaZap.lnk'); $l.TargetPath='%AHK%'; $l.Arguments='\"%DEST%\AssinaZap.ahk\"'; $l.WorkingDirectory='%DEST%'; $l.Description='Inicia o AssinaZap com o Windows'; $l.Save()"
echo  [OK] Inicio automatico com o Windows configurado.

rem --- 4) Iniciar agora ---
start "" "%AHK%" "%DEST%\AssinaZap.ahk"
echo  [OK] AssinaZap iniciado!
echo.
echo  Na janela que abrir, digite o NOME da pessoa e clique em Salvar.
echo  Pronto: a partir de agora ele liga sozinho com o Windows.
echo.
pause
