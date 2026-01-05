@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"
title Bitcoin Monitor

:: --- Configuration (edit as needed) ---
set API_URL=https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=bitcoin
set USER_AGENT=Mozilla/5.0 (Windows NT 10.0; Win64; x64)
set OUTPUT_FILE=output.txt
set REQUEST_INTERVAL_SEC=30
set REQUEST_TIMEOUT_SEC=10

:LOOP
cls
for /f "usebackq delims=" %%T in (`
    powershell -NoProfile -Command ^
      "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue';" ^
      "$url='%API_URL%';" ^
      "$outFile='%OUTPUT_FILE%';" ^
      "$ua='%USER_AGENT%';" ^
      "try {" ^
      "  $resp = Invoke-RestMethod -Uri $url -TimeoutSec %REQUEST_TIMEOUT_SEC% -Headers @{ 'User-Agent' = $ua };" ^
      "  if(-not $resp){ throw 'NoData' }" ^
      "  $item = $resp[0];" ^
      "  $price = [double]$item.current_price;" ^
      "  $change = [double]$item.price_change_percentage_24h;" ^
      "  $high = [double]$item.high_24h;" ^
      "  $low  = [double]$item.low_24h;" ^
      "  $volUsd = [double]$item.total_volume;" ^
      "  $mc = [double]$item.market_cap;" ^
      "  $volBtc = if($price -ne 0){ $volUsd / $price } else { 0 };" ^
      "  $mcText = if($mc -ge 1e12){ '$' + ($mc/1e12).ToString('0.00') + 'T' } elseif($mc -ge 1e9){ '$' + ($mc/1e9).ToString('0.00') + 'B' } elseif($mc -ge 1e6){ '$' + ($mc/1e6).ToString('0.00') + 'M' } else { '$' + $mc.ToString('N0') };" ^
      "  $lines = @(" ^
      "    '[ Bitcoin Monitor ]'," ^
      "    ''," ^
      "    ('Price        ${0:N0}' -f $price)," ^
      "    ('24h Change   {0}{1:N2}%' -f $(if($change -ge 0){'+'}else{''}), $change)," ^
      "    ('High 24h     ${0:N0}' -f $high)," ^
      "    ('Low 24h      ${0:N0}' -f $low)," ^
      "    ('Volume 24h   {0:N0} BTC' -f $volBtc)," ^
      "    ('Market Cap   ' + $mcText)" ^
      "  );" ^
      "  $text = $lines -join \"`n\";" ^
      "  $text | Out-File -FilePath $outFile -Encoding UTF8;" ^
      "  Write-Output $text;" ^
      "} catch {" ^
      "  $fallback = \"[ Bitcoin Monitor ]`n`nWaiting for data...\";" ^
      "  $fallback | Out-File -FilePath $outFile -Encoding UTF8;" ^
      "  Write-Output $fallback;" ^
      "}"
`) do echo %%T

timeout /t %REQUEST_INTERVAL_SEC% >nul
goto LOOP
