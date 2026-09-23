@echo off
cls

set "TASK_NAME=Windows Update Pauser"
set "INSTALL_DIR=%ProgramFiles%\PostponeWinUpdate"
set "LOG_DIR=%ProgramData%\PostponeWinUpdate"
set "REG_KEY=HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"

:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 goto :no_admin

echo This will remove PostponeWinUpdate and resume Windows Updates.
choice /c YN /m "Continue?"
if %errorLevel% neq 1 goto :cancelled
echo.

:: Stop and delete the scheduled task
echo [INFO] Removing scheduled task...
schtasks /end /tn "%TASK_NAME%" >nul 2>&1
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1
if %errorLevel% neq 0 (
    echo [WARN] Task not found or could not be deleted.
) else (
    echo [OK] Task deleted.
)

:: Delete the installed EXE
echo [INFO] Removing program files...
if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
if exist "%INSTALL_DIR%" (
    echo [WARN] Could not delete "%INSTALL_DIR%".
) else (
    echo [OK] Program files removed.
)

:: Delete logs
echo [INFO] Removing logs...
if exist "%LOG_DIR%" rmdir /s /q "%LOG_DIR%"
if exist "%LOG_DIR%" (
    echo [WARN] Could not delete "%LOG_DIR%".
) else (
    echo [OK] Logs removed.
)

:: Remove pause values from the registry (resume updates)
echo [INFO] Removing pause settings from the registry...
for %%V in (
    PauseUpdatesStartTime
    PauseUpdatesExpiryTime
    PauseFeatureUpdatesStartTime
    PauseFeatureUpdatesEndTime
    PauseQualityUpdatesStartTime
    PauseQualityUpdatesEndTime
) do (
    reg delete "%REG_KEY%" /v %%V /f /reg:64 >nul 2>&1
)
echo [OK] Pause settings removed.

echo.
echo [OK] Uninstall complete.
echo If Settings still shows updates as paused, click "Resume updates" there.
goto :end

:no_admin
echo [ERROR] Please run this script AS ADMINISTRATOR!
echo Right-click %~nx0 and choose "Run as administrator".
goto :end

:cancelled
echo Cancelled.
goto :end

:end
echo.
echo Press any key to exit...
pause >nul