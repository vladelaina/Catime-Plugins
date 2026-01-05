@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
cd /d "%~dp0"
title Poison Soup

:: --- Configuration ---
set OUTPUT_FILE=output.txt
set REFRESH_SEC=10

echo Poison soup started...
echo Press Ctrl+C to exit
echo.

:loop
:: Fetch poison soup from API (returns plain text)
set "quote="
for /f "usebackq delims=" %%a in (`powershell -NoProfile -Command "(Invoke-RestMethod 'https://api.shadiao.pro/du').data.text" 2^>nul`) do (
    set "quote=%%a"
)

:: Fallback if API fails
if "!quote!"=="" set "quote=努力不一定成功，但不努力真的很舒服。"

:: Output
cls
echo !quote!
>"%OUTPUT_FILE%" echo !quote!

:: Wait
ping -n %REFRESH_SEC% 127.0.0.1 >nul 2>&1
goto loop
