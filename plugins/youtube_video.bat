@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"
title YouTube Video Monitor

:: --- Configuration ---
set VIDEO_URL=https://www.youtube.com/watch?v=Opp9nqiN5m0
set OUTPUT_FILE=output.txt
set REQUEST_INTERVAL_SEC=60

echo YouTube Video Monitor
echo URL: %VIDEO_URL%
echo.

:LOOP
cls
powershell -NoProfile -Command ^
  "$ProgressPreference='SilentlyContinue';" ^
  "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" ^
  "$videoUrl='%VIDEO_URL%'; $out='%OUTPUT_FILE%';" ^
  "if($videoUrl -match '[?&]v=([a-zA-Z0-9_-]{11})'){ $videoId = $matches[1] } else { 'Invalid URL' | Out-File -FilePath $out -Encoding UTF8 -NoNewline; exit }" ^
  "$headers = @{ 'User-Agent'='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'; 'Accept-Language'='en-US,en;q=0.9' };" ^
  "try {" ^
  "  $url = 'https://www.youtube.com/watch?v=' + $videoId;" ^
  "  $resp = Invoke-WebRequest -Uri $url -TimeoutSec 15 -Headers $headers -UseBasicParsing;" ^
  "  $html = $resp.Content;" ^
  "  $views = '0'; $likes = '0';" ^
  "  if($html -match '\"viewCount\":\"(\d+)\"'){ $views = $matches[1] }" ^
  "  if($html -match '\"likeCount\":\"?(\d+)\"?'){ $likes = $matches[1] }" ^
  "  elseif($html -match 'accessibilityData\":\{\"label\":\"(\d[\d,]*) likes'){ $likes = $matches[1] -replace ',','' }" ^
  "  $text = 'Views: ' + $views + ' Likes: ' + $likes;" ^
  "  $text | Out-File -FilePath $out -Encoding UTF8 -NoNewline;" ^
  "  Write-Output $text;" ^
  "} catch { 'Failed' | Out-File -FilePath $out -Encoding UTF8 -NoNewline; Write-Output 'Request failed' }"

timeout /t %REQUEST_INTERVAL_SEC% >nul
goto LOOP
