@echo off
echo ======================================
echo      PUNTA ERAWAN MEP - WEB UPDATE
echo ======================================

flutter build web

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Build Failed.
    pause
    exit /b
)

firebase deploy

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Deploy Failed.
    pause
    exit /b
)

echo.
echo ======================================
echo Web Update Complete
echo ======================================

pause