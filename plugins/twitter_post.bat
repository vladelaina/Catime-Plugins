@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"
title Twitter Post Monitor

:: --- Configuration ---
set TWEET_URL=https://x.com/scavin/status/1997609580503650499
set OUTPUT_FILE=output.txt
set REQUEST_INTERVAL_SEC=60

echo Twitter Post Monitor
echo URL: %TWEET_URL%
echo.

:LOOP
cls
powershell -NoProfile -Command ^
  "$ProgressPreference='SilentlyContinue';" ^
  "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" ^
  "$tweetUrl='%TWEET_URL%'; $out='%OUTPUT_FILE%';" ^
  "if($tweetUrl -match '/status/(\d+)'){ $tweetId = $matches[1] } else { 'Invalid URL' | Out-File -FilePath $out -Encoding UTF8 -NoNewline; Write-Output 'Invalid URL'; exit }" ^
  "$headers = @{ 'User-Agent'='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' };" ^
  "try {" ^
  "  $url = 'https://cdn.syndication.twimg.com/tweet-result?id=' + $tweetId + '&token=0';" ^
  "  $resp = Invoke-WebRequest -Uri $url -TimeoutSec 10 -Headers $headers -UseBasicParsing;" ^
  "  $json = $resp.Content | ConvertFrom-Json;" ^
  "  $likes = $json.favorite_count;" ^
  "  $replies = $json.conversation_count;" ^
  "  $text = 'Likes: ' + $likes + ' Replies: ' + $replies;" ^
  "  $text | Out-File -FilePath $out -Encoding UTF8 -NoNewline;" ^
  "  Write-Output $text;" ^
  "} catch { 'Failed' | Out-File -FilePath $out -Encoding UTF8 -NoNewline; Write-Output 'Request failed' }"

timeout /t %REQUEST_INTERVAL_SEC% >nul
goto LOOP
