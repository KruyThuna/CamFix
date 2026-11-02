@echo off
title Starting Android Emulator 9_Pro
echo ===================================================
echo   Starting Android Emulator 9_Pro for CamFix
echo ===================================================
start "" "%LOCALAPPDATA%\Android\sdk\emulator\emulator.exe" -avd 9_Pro
echo.
echo Emulator is starting! The phone window will appear on your desktop shortly.
timeout /t 5

