@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Prepara-APK.ps1"
if errorlevel 1 echo Preparazione fallita. Conserva la chiave esistente.
pause
