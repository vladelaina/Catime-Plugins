@echo off
cd /d "%~dp0"
title GitHub Star Monitor

:: --- Configuration ---
set REPO_URL=https://github.com/vladelaina/Catime
set TOKEN=
set OUTPUT_FILE=output.txt
set TEMP_JSON=temp_data.json
set CURL_TIMEOUT_SEC=10
set REQUEST_INTERVAL_SEC=60

:: Build API URL from normal repo URL (easier for users to edit).
set URL=
for /f "usebackq delims=" %%r in (`
    powershell -NoProfile -Command ^
        "$u='%REPO_URL%'; $u=$u.Trim('/'); if($u -match 'github\.com/([^/]+)/([^/]+)$'){ $owner=$matches[1]; $repo=$matches[2] -replace '\.git$',''; $api='https://api.github.com/repos/' + $owner + '/' + $repo; Write-Output $api }"
`) do set URL=%%r

if not defined URL (
    echo Invalid REPO_URL. Use format https://github.com/owner/repo
    exit /b 1
)

:: Cleanup leftovers from previous runs
if exist "%TEMP_JSON%" del "%TEMP_JSON%"

echo Monitor started.
echo Output file: %~dp0%OUTPUT_FILE%
echo.

:LOOP
set "RESULT="
set "stars="

set "AUTH_HEADER="
if defined TOKEN set "AUTH_HEADER=-H \"Authorization: token %TOKEN%\""

:: 1. Download data
:: -f: Fail on HTTP errors (404/401/etc)
:: -s: Silent
curl -f -s --max-time %CURL_TIMEOUT_SEC% %AUTH_HEADER% -H "User-Agent: Catime-Monitor" "%URL%" -o "%TEMP_JSON%"

:: 2. Error Check: Network or Auth
if %ERRORLEVEL% EQU 22 (
    set "RESULT=AuthErr"
    goto :WRITE_OUTPUT
)
if %ERRORLEVEL% NEQ 0 (
    set "RESULT=NetErr"
    goto :WRITE_OUTPUT
)

:: 3. Parse JSON (Only if curl succeeded)
for /f "usebackq delims=" %%a in (`powershell -NoProfile -Command "Get-Content '%TEMP_JSON%' | ConvertFrom-Json | Select-Object -ExpandProperty stargazers_count"`) do (
    set "stars=%%a"
)

:: 4. Error Check: Data Parsing
if defined stars (
    set "RESULT=%stars%"
) else (
    set "RESULT=DataErr"
)

:WRITE_OUTPUT
:: 5. Atomic Write & Display
:: Use set /p to write without newline
echo|set /p="%RESULT%" > "%OUTPUT_FILE%"

cls
echo %RESULT%

:: Cleanup
if exist "%TEMP_JSON%" del "%TEMP_JSON%"

:: Wait 60 seconds
timeout /t %REQUEST_INTERVAL_SEC% >nul
goto LOOP
