@echo off
title Reportes Ciudadanos
cd /d "%~dp0"

echo =====================================
echo       REPORTES CIUDADANOS
echo =====================================
echo.
echo Iniciando aplicacion...

flutter run -d emulator-5554 --dart-define-from-file=config/supabase.json

pause
