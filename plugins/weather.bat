@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"
title Weather Monitor

:: --- Configuration (edit as needed) ---
set LAT=51.5074
set LON=-0.1278
set OUTPUT_FILE=output.txt
set USER_AGENT=Catime-Weather
set REQUEST_INTERVAL_SEC=600
set REQUEST_TIMEOUT_SEC=15
set TIMEZONE=Europe/London

:LOOP
cls
powershell -NoProfile -Command ^
  "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue';" ^
  "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" ^
  "$lat=%LAT%; $lon=%LON%; $tz='%TIMEZONE%'; $out='%OUTPUT_FILE%'; $ua='%USER_AGENT%';" ^
  "$url = ('https://api.open-meteo.com/v1/forecast?latitude={0}&longitude={1}&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m,surface_pressure,cloud_cover,precipitation&daily=sunrise,sunset,uv_index_max,temperature_2m_max,temperature_2m_min&timezone={2}' -f $lat,$lon,$tz);" ^
  "try {" ^
    "  $resp = Invoke-RestMethod -Uri $url -TimeoutSec %REQUEST_TIMEOUT_SEC% -Headers @{ 'User-Agent'=$ua };" ^
  "  $cur = $resp.current; $daily = $resp.daily;" ^
  "  if(-not $cur){ throw 'NoData' }" ^
  "  $descMap = @{0='Clear';1='Mainly Clear';2='Partly Cloudy';3='Overcast';45='Fog';48='Fog';51='Light Drizzle';53='Drizzle';55='Dense Drizzle';61='Light Rain';63='Rain';65='Heavy Rain';71='Light Snow';73='Snow';75='Heavy Snow';80='Light Showers';81='Showers';82='Heavy Showers';95='Thunderstorm';96='Thunderstorm';99='Thunderstorm'};" ^
  "  $dirMap = @('N','NE','E','SE','S','SW','W','NW');" ^
  "  $wcode = $cur.weather_code; $desc = $descMap[$wcode]; if(-not $desc){ $desc='Unknown' }" ^
  "  $wdir = $cur.wind_direction_10m;" ^
  "  $dirIdx = $null; if($null -ne $wdir){ $dirIdx = [int](($wdir + 22.5)/45) %% 8 }" ^
  "  $dir = if($dirIdx -ne $null){ $dirMap[$dirIdx] } else { '' };" ^
  "  $sunrise = if($daily.sunrise){ ($daily.sunrise[0] -split 'T')[1] } else { 'N/A' };" ^
  "  $sunset = if($daily.sunset){ ($daily.sunset[0] -split 'T')[1] } else { 'N/A' };" ^
  "  $tmax = if($daily.temperature_2m_max){ $daily.temperature_2m_max[0] } else { 'N/A' };" ^
  "  $tmin = if($daily.temperature_2m_min){ $daily.temperature_2m_min[0] } else { 'N/A' };" ^
  "  $lines = @(" ^
  "    '[ Weather ]'," ^
  "    ''," ^
  "    ('{0}  Cloud: {1}%%' -f $desc, $cur.cloud_cover)," ^
  "    ''," ^
  "    ('Temp: {0}°C  (↑{1}° ↓{2}°)' -f $cur.temperature_2m, $tmax, $tmin)," ^
  "    ('Feels: {0}°C' -f $cur.apparent_temperature)," ^
  "    ('Humidity: {0}%%' -f $cur.relative_humidity_2m)," ^
  "    ''," ^
  "    ('Wind: {0} {1} km/h' -f $dir, $cur.wind_speed_10m)," ^
  "    ('Pressure: {0} hPa' -f $cur.surface_pressure)," ^
  "    ('UV Index: {0}' -f $cur.uv_index)," ^
  "    ('Precip: {0} mm' -f $cur.precipitation)," ^
  "    ''," ^
  "    ('Sunrise: {0}  Sunset: {1}' -f $sunrise, $sunset)" ^
  "  );" ^
  "  $text = $lines -join \"`n\";" ^
  "  $text | Out-File -FilePath $out -Encoding UTF8;" ^
  "  Write-Output $text;" ^
  "} catch {" ^
  "  $code = $null; if($_.Exception.Response){ $code = $_.Exception.Response.StatusCode.value__ };" ^
  "  $msg = if($code){ 'Failed: ' + $code } else { 'Failed: Network/Data' };" ^
  "  $msg | Out-File -FilePath '%OUTPUT_FILE%' -Encoding UTF8;" ^
  "  Write-Output $msg;" ^
  "}"

timeout /t %REQUEST_INTERVAL_SEC% >nul
goto LOOP
