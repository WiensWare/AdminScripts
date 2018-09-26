@echo off
@echo Installing updates.  This will take a long time.  Please wait...
powershell -f %~dp0\Update-Computer.ps1
timeout /t 30