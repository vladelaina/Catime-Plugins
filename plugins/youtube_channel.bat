@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
title YouTube Channel Monitor

:: --- Configuration ---
set CHANNEL_URL=https://www.youtube.com/@SawanoHiroyukiSMEJ
set OUTPUT_FILE=output.txt
set REQUEST_INTERVAL_SEC=60

echo YouTube Channel Monitor
echo URL: %CHANNEL_URL%
echo.

:LOOP
cls

set "TEMP_PS=%TEMP%\yt_ch_%RANDOM%.ps1"

> "%TEMP_PS%" echo $ProgressPreference='SilentlyContinue'
>> "%TEMP_PS%" echo [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
>> "%TEMP_PS%" echo $url = '%CHANNEL_URL%'
>> "%TEMP_PS%" echo $out = '%OUTPUT_FILE%'
>> "%TEMP_PS%" echo $headers = @{ 'User-Agent'='Mozilla/5.0'; 'Accept-Language'='en-US' }
>> "%TEMP_PS%" echo try {
>> "%TEMP_PS%" echo     $resp = Invoke-WebRequest -Uri $url -TimeoutSec 15 -Headers $headers -UseBasicParsing
>> "%TEMP_PS%" echo     $html = $resp.Content
>> "%TEMP_PS%" echo     $subs = '0'
>> "%TEMP_PS%" echo     if($html -match '([\d\.]+[KMB]?) subscribers') { $subs = $matches[1] }
>> "%TEMP_PS%" echo     $subs ^| Out-File -FilePath $out -Encoding UTF8 -NoNewline
>> "%TEMP_PS%" echo     Write-Output ('Subscribers: ' + $subs)
>> "%TEMP_PS%" echo } catch { 'Failed' ^| Out-File -FilePath $out -Encoding UTF8 -NoNewline; Write-Output 'Request failed' }

powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP_PS%"
del "%TEMP_PS%" 2>nul

timeout /t %REQUEST_INTERVAL_SEC% >nul
goto LOOP
