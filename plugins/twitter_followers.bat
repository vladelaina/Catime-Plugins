@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"
title Twitter Followers Monitor

:: --- Configuration ---
set USERNAME=appinn
set OUTPUT_FILE=output.txt
set REQUEST_INTERVAL_SEC=60
set REQUEST_TIMEOUT_SEC=5

echo Twitter Followers Monitor
echo User: %USERNAME%
echo.

:LOOP
cls
powershell -NoProfile -Command ^
  "$ProgressPreference='SilentlyContinue';" ^
  "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" ^
  "$user='%USERNAME%'; $out='%OUTPUT_FILE%';" ^
  "$headers = @{ 'User-Agent'='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' };" ^
  "try {" ^
  "  $url = 'https://syndication.twitter.com/srv/timeline-profile/screen-name/' + $user;" ^
  "  $resp = Invoke-WebRequest -Uri $url -TimeoutSec 5 -Headers $headers -UseBasicParsing;" ^
  "  if($resp.Content -match '\"followers_count\":(\d+)'){ " ^
  "    $result = $matches[1];" ^
  "    $result | Out-File -FilePath $out -Encoding UTF8 -NoNewline;" ^
  "    Write-Output ('Followers: ' + $result);" ^
  "  } else { 'N/A' | Out-File -FilePath $out -Encoding UTF8 -NoNewline; Write-Output 'Parse failed' }" ^
  "} catch { 'N/A' | Out-File -FilePath $out -Encoding UTF8 -NoNewline; Write-Output 'Request failed' }"

timeout /t %REQUEST_INTERVAL_SEC% >nul
goto LOOP
