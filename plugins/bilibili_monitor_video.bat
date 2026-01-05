@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"
title Bilibili Video Monitor

:: --- Configuration (edit as needed) ---
set BVID=BV17U4y1u7HY
set OUTPUT_FILE=output.txt
set USER_AGENT=Mozilla/5.0
set REQUEST_INTERVAL_SEC=30
set REQUEST_TIMEOUT_SEC=10
set API_VIEW=https://api.bilibili.com/x/web-interface/view?bvid=
set API_ONLINE=https://api.bilibili.com/x/player/online/total?bvid=

:LOOP
cls
powershell -NoProfile -Command ^
  "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue';" ^
  "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" ^
  "$bvid='%BVID%'; $out='%OUTPUT_FILE%'; $ua='%USER_AGENT%'; $timeout=%REQUEST_TIMEOUT_SEC%; $script:lastCode=$null;" ^
  "$apiView='%API_VIEW%'; $apiOnline='%API_ONLINE%';" ^
  "function Get-Json($url){ try { Invoke-RestMethod -Method Get -Uri $url -TimeoutSec $timeout -Headers @{ 'User-Agent'=$ua } } catch { if($_.Exception.Response){ $script:lastCode=$_.Exception.Response.StatusCode.value__ }; return $null } }" ^
  "$view = Get-Json($apiView + $bvid);" ^
  "if($view -and $view.code -eq 0){" ^
  "  $stat = $view.data.stat; $cid = $view.data.cid;" ^
  "  $online = 'N/A';" ^
  "  $onlineResp = Get-Json($apiOnline + $bvid + '&cid=' + $cid);" ^
  "  if($onlineResp -and $onlineResp.code -eq 0){ $online = $onlineResp.data.total }" ^
  "  $lines = @(" ^
  "    '在看: ' + $online;" ^
  "    '播放: ' + $stat.view;" ^
  "    '点赞: ' + $stat.like;" ^
  "    '投币: ' + $stat.coin;" ^
  "    '收藏: ' + $stat.favorite;" ^
  "    '转发: ' + $stat.share" ^
  "  );" ^
  "  $text = $lines -join \"`n\";" ^
  "  $text | Out-File -FilePath $out -Encoding UTF8;" ^
  "  Write-Output $text;" ^
  "} else {" ^
  "  $fallback = if($lastCode){ 'Failed: ' + $lastCode } elseif($view -and $view.code){ 'Failed: ' + $view.code } else { 'Failed: Network/Data' };" ^
  "  $fallback | Out-File -FilePath $out -Encoding UTF8;" ^
  "  Write-Output $fallback;" ^
  "}"

timeout /t %REQUEST_INTERVAL_SEC% >nul
goto LOOP
