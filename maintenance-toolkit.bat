@echo off
setlocal EnableDelayedExpansion
title Maintenance Toolkit
color 0a

:: ==========================================================================
::  Maintenance Toolkit
::  Interactive menu for routine Windows diagnostics and maintenance.
::
::  Every action wraps a built-in Windows utility. No third-party binaries
::  are downloaded or executed.
::
::  Author:  Daniel Batista
::  License: MIT
:: ==========================================================================

:: --- Require elevation -----------------------------------------------------
:: sfc, mdsched and system-wide temp cleanup all fail silently without it,
:: which is worse than failing loudly.
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo.
    echo   Administrator privileges are required.
    echo   Right-click this file and choose "Run as administrator".
    echo.
    pause >nul
    exit /b 1
)

:menu
cls
echo.
echo   Maintenance Toolkit  -  Diagnostics and Network
echo   ------------------------------------------------------
for /f "tokens=*" %%d in ('date /t') do echo   %%d
for /f "tokens=*" %%t in ('time /t') do echo   %%t
echo.
echo      /\_/\
echo     ( o.o )   What can I help you with?
echo      ^> ^^ ^<
echo.
echo   ======================================================
echo    1 . Clean temporary files
echo    2 . Windows Disk Cleanup
echo    3 . Malicious Software Removal Tool
echo    4 . Memory Diagnostics
echo    5 . System File Checker (sfc /scannow)
echo    6 . Show local IP addresses
echo    7 . Restart a network adapter
echo    8 . Check network connectivity
echo    9 . Open Windows Update
echo    0 . Exit
echo   ======================================================
echo.

set "choice="
set /p "choice=  Select an option: "

if "%choice%"=="1"  goto clean_temp
if "%choice%"=="2"  goto disk_cleanup
if "%choice%"=="3"  goto malware_removal
if "%choice%"=="4"  goto memory_check
if "%choice%"=="5"  goto sfc_scan
if "%choice%"=="6"  goto show_ip
if "%choice%"=="7"  goto restart_adapter
if "%choice%"=="8"  goto check_network
if "%choice%"=="9"  goto windows_update
if "%choice%"=="0"  goto quit

echo.
echo      /\_/\
echo     ( x.x )   Invalid option.
echo      ^> ^^ ^<
timeout /t 2 >nul
goto menu


:: --------------------------------------------------------------------------
:clean_temp
cls
echo.
echo   Cleaning temporary files...
echo.

:: Files currently locked by running processes are skipped; that is expected
:: and not an error worth surfacing.
del /f /s /q "%TEMP%\*.*" >nul 2>&1
for /d %%x in ("%TEMP%\*") do rd /s /q "%%x" >nul 2>&1

del /f /s /q "%WINDIR%\Temp\*.*" >nul 2>&1
for /d %%x in ("%WINDIR%\Temp\*") do rd /s /q "%%x" >nul 2>&1

del /f /s /q "%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Recent\*.*" >nul 2>&1

:: Note: Prefetch is deliberately NOT cleared. Windows manages it, clearing it
:: degrades application start times, and it is a useful forensic artifact.

echo   Done.
goto pause_return


:: --------------------------------------------------------------------------
:disk_cleanup
cls
echo.
echo   Launching Windows Disk Cleanup in a separate window...
start "" cleanmgr
goto pause_return


:: --------------------------------------------------------------------------
:malware_removal
cls
echo.
echo   Launching the Microsoft Malicious Software Removal Tool...
echo   Note: this is a targeted removal tool, not a replacement for
echo   a resident antivirus product.
echo.
start "" mrt
goto pause_return


:: --------------------------------------------------------------------------
:memory_check
cls
echo.
echo   Windows Memory Diagnostic requires a restart to run.
echo   You will be prompted to restart now or schedule it for next boot.
echo.
start "" mdsched
goto pause_return


:: --------------------------------------------------------------------------
:sfc_scan
cls
echo.
echo   Running System File Checker. This can take several minutes.
echo   Do not close this window.
echo.
sfc /scannow
echo.
echo   Scan complete. Review the output above.
echo   Full log: %WINDIR%\Logs\CBS\CBS.log
goto pause_return


:: --------------------------------------------------------------------------
:show_ip
cls
echo.
echo   Local IPv4 addresses:
echo.
ipconfig | findstr /i /c:"IPv4"
echo.
echo   Default gateway:
ipconfig | findstr /i /c:"Default Gateway"
goto pause_return


:: --------------------------------------------------------------------------
:restart_adapter
cls
echo.
echo   Available network interfaces:
echo.
netsh interface show interface
echo.
set "adapter="
set /p "adapter=  Enter the exact interface name (blank to cancel): "

if "%adapter%"=="" goto menu

echo.
echo   Disabling "%adapter%" ...
netsh interface set interface name="%adapter%" admin=disable
if not "%errorlevel%"=="0" (
    echo   Failed. Check that the name matches exactly.
    goto pause_return
)

timeout /t 3 >nul

echo   Re-enabling "%adapter%" ...
netsh interface set interface name="%adapter%" admin=enable
echo.
echo   Adapter restarted.
goto pause_return


:: --------------------------------------------------------------------------
:check_network
cls
echo.
echo   Checking connectivity...
echo.

ping -n 2 1.1.1.1 >nul 2>&1
if "%errorlevel%"=="0" (
    echo   [ OK ]   IP connectivity reachable
) else (
    echo   [ FAIL ] No IP connectivity
)

ping -n 2 cloudflare.com >nul 2>&1
if "%errorlevel%"=="0" (
    echo   [ OK ]   DNS resolution working
) else (
    echo   [ FAIL ] DNS resolution failing
)

echo.
echo   If IP works but DNS fails, the issue is name resolution,
echo   not the connection itself.
goto pause_return


:: --------------------------------------------------------------------------
:windows_update
cls
echo.
echo   Opening Windows Update settings...
start "" "ms-settings:windowsupdate"
goto pause_return


:: --------------------------------------------------------------------------
:pause_return
echo.
echo   Press any key to return to the menu...
pause >nul
goto menu


:: --------------------------------------------------------------------------
:quit
cls
echo.
echo      /\_/\
echo     ( ^-^ )   Goodbye.
echo      ^> ^^ ^<
echo.
timeout /t 1 >nul
endlocal
exit /b 0
