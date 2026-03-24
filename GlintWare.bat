@echo off

NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Requested Admin Privilages...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

set SCRIPT_DIR=%~dp0

set PS_SCRIPT=%SCRIPT_DIR%resources\glintware.ps1

powershell -NoExit -ExecutionPolicy Bypass -File "%PS_SCRIPT%"

pause