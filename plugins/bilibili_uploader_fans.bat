@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"
title Bilibili Uploader Fans

:: --- Configuration (edit as needed) ---
set UPLOADER_MID=3546970870253823
set OUTPUT_FILE=output.txt
set USER_AGENT=Mozilla/5.0
set REQUEST_INTERVAL_SEC=30
set REQUEST_TIMEOUT_SEC=10
set API_FANS=https://api.bilibili.com/x/relation/stat?vmid=

:LOOP
cls
powershell -NoProfile -Command ^
  "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue';" ^
  "$mid='%UPLOADER_MID%'; $out='%OUTPUT_FILE%'; $ua='%USER_AGENT%'; $timeout=%REQUEST_TIMEOUT_SEC%;" ^
  "$api='%API_FANS%' + $mid;" ^
  "try {" ^
  "  $resp = Invoke-RestMethod -Method Get -Uri $api -TimeoutSec $timeout -Headers @{ 'User-Agent'=$ua };" ^
  "  if($resp -and $resp.code -eq 0){ $fans = $resp.data.follower; $fans | Out-File -FilePath $out -Encoding UTF8 -NoNewline; Write-Output $fans } else { $msg = 'Failed: ' + ($resp.code); $msg | Out-File -FilePath $out -Encoding UTF8 -NoNewline; Write-Output $msg }" ^
  "} catch {" ^
  "  $code = $null; if($_.Exception.Response){ $code = $_.Exception.Response.StatusCode.value__ };" ^
  "  $msg = if($code){ 'Failed: ' + $code } else { 'Failed: Network/Data' };" ^
  "  $msg | Out-File -FilePath $out -Encoding UTF8 -NoNewline; Write-Output $msg;" ^
  "}"

timeout /t %REQUEST_INTERVAL_SEC% >nul
goto LOOP
