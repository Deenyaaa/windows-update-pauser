@echo off
cls

set "TASK_NAME=Windows Update Pauser"
set "SRC_EXE=%~dp0builds\PostponeWinUpdate.exe"
set "INSTALL_DIR=%ProgramFiles%\PostponeWinUpdate"
set "EXE_PATH=%INSTALL_DIR%\PostponeWinUpdate.exe"

:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 goto :no_admin

:: Verify the compiled EXE exists
if not exist "%SRC_EXE%" goto :no_exe

:: Stop the task if it is running (so the EXE is not locked)
schtasks /end /tn "%TASK_NAME%" >nul 2>&1

:: Copy the EXE to Program Files
echo [INFO] Installing to: "%INSTALL_DIR%"
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
copy /y "%SRC_EXE%" "%EXE_PATH%" >nul
if %errorLevel% neq 0 goto :copy_failed

:: Register the task: daily at 12:00 + at system startup, catch up missed runs, run as SYSTEM
echo [INFO] Creating Windows Task Scheduler job...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$a = New-ScheduledTaskAction -Execute '%EXE_PATH%'; $t = @((New-ScheduledTaskTrigger -Daily -At 12:00), (New-ScheduledTaskTrigger -AtStartup)); $s = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 5); $p = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest; Register-ScheduledTask -TaskName '%TASK_NAME%' -Action $a -Trigger $t -Settings $s -Principal $p -Force | Out-Null"
if %errorLevel% neq 0 goto :task_failed

:: Run the task once right now
schtasks /run /tn "%TASK_NAME%" >nul 2>&1

echo.
echo --------------------------------------------------
echo [INFO] System task verification:
echo --------------------------------------------------
schtasks /query /tn "%TASK_NAME%"
echo.
echo [OK] Done. Log file: "%ProgramData%\PostponeWinUpdate\log.txt"
goto :end

:no_admin
echo [ERROR] Please run this script AS ADMINISTRATOR!
echo Right-click %~nx0 and choose "Run as administrator".
goto :end

:no_exe
echo [ERROR] Executable not found at: "%SRC_EXE%"
echo Please build the project first so that PostponeWinUpdate.exe is in the 'builds' folder.
goto :end

:copy_failed
echo [ERROR] Failed to copy the EXE to "%INSTALL_DIR%".
goto :end

:task_failed
echo [ERROR] Failed to create the scheduled task.
goto :end

:end
echo.
echo Press any key to exit...
pause >nul