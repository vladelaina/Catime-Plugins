@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"
title "NASDAQ & S&P 500 Monitor"

:: --- Configuration (edit as needed) ---
:: Note: use %%5E to keep the literal %5E (caret) in URLs.
set API_QUOTE=https://query1.finance.yahoo.com/v7/finance/quote?symbols=%%5EIXIC,%%5EGSPC
set API_IXIC_CHART=https://query1.finance.yahoo.com/v8/finance/chart/%%5EIXIC?range=1d&interval=1d
set API_GSPC_CHART=https://query1.finance.yahoo.com/v8/finance/chart/%%5EGSPC?range=1d&interval=1d
set USER_AGENT=Mozilla/5.0 (Windows NT 10.0; Win64; x64)
set OUTPUT_FILE=output.txt
set REQUEST_INTERVAL_SEC=1
set REQUEST_TIMEOUT_SEC=10

:LOOP
cls
for /f "usebackq delims=" %%T in (`
    powershell -NoProfile -Command ^
      "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue';" ^
      "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" ^
      "$urlQuote='%API_QUOTE%'; $urlIxic='%API_IXIC_CHART%'; $urlGspc='%API_GSPC_CHART%';" ^
      "$ua='%USER_AGENT%'; $out='%OUTPUT_FILE%';" ^
      "$headers = @{ 'User-Agent' = $ua; 'Accept'='application/json'; 'Accept-Language'='en-US,en;q=0.9' };" ^
      "function CalcChange { param($price,$prev,$pct) if($price -ne $null -and $prev -ne $null -and $prev -ne 0){ return (($price - $prev)/$prev*100) } elseif($pct -ne $null){ return [double]$pct } else { return $null } }" ^
      "function FormatLine { param($label,$price,$chg) $up=[char]0x2191; $down=[char]0x2193; $lbl = ('{0,-7}' -f $label); $p = ('{0,10:N2}' -f [double]$price); if($chg -ne $null){ $arrow = $(if($chg -ge 0){$up}else{$down}); $abs=[math]::Abs($chg); $pct = ('{0,5:0.00}' -f $abs); return ('{0}:{1} {2}{3}%%' -f $lbl,$p,$arrow,$pct) } else { return ('{0}:{1}' -f $lbl,$p) } }" ^
      "$lastCode=$null;" ^
      "$nasdaq=$null; $sp=$null; $chgNasdaq=$null; $chgSp=$null;" ^
      "try {" ^
      "  $resp = Invoke-RestMethod -Method Get -Uri $urlQuote -TimeoutSec %REQUEST_TIMEOUT_SEC% -Headers $headers;" ^
      "  $quotes = $resp.quoteResponse.result;" ^
      "  if($quotes -and $quotes.Count -ge 2){" ^
      "    $ixic = $quotes | Where-Object { $_.symbol -eq '^IXIC' } | Select-Object -First 1;" ^
      "    $gspc = $quotes | Where-Object { $_.symbol -eq '^GSPC' } | Select-Object -First 1;" ^
      "    if($ixic){ $nasdaq = $ixic.regularMarketPrice; if(-not $nasdaq){ $nasdaq = $ixic.regularMarketPreviousClose } ; $chgNasdaq = CalcChange $nasdaq $ixic.regularMarketPreviousClose $ixic.regularMarketChangePercent }" ^
      "    if($gspc){ $sp = $gspc.regularMarketPrice; if(-not $sp){ $sp = $gspc.regularMarketPreviousClose } ; $chgSp = CalcChange $sp $gspc.regularMarketPreviousClose $gspc.regularMarketChangePercent }" ^
      "  }" ^
      "} catch { if($_.Exception.Response){ $lastCode=$_.Exception.Response.StatusCode.value__ } }" ^
      "if($nasdaq -eq $null){" ^
      "  try { $resp = Invoke-RestMethod -Method Get -Uri $urlIxic -TimeoutSec %REQUEST_TIMEOUT_SEC% -Headers $headers; $meta=$resp.chart.result[0].meta; if($meta){ $nasdaq=$meta.regularMarketPrice; if(-not $nasdaq){ $nasdaq=$meta.regularMarketPreviousClose }; $prev = $meta.regularMarketPreviousClose; if(-not $prev -and $meta.PSObject.Properties['previousClose']){ $prev=$meta.previousClose }; $chgNasdaq = CalcChange $nasdaq $prev $null } } catch { if(-not $lastCode -and $_.Exception.Response){ $lastCode=$_.Exception.Response.StatusCode.value__ } }" ^
      "}" ^
      "if($sp -eq $null){" ^
      "  try { $resp = Invoke-RestMethod -Method Get -Uri $urlGspc -TimeoutSec %REQUEST_TIMEOUT_SEC% -Headers $headers; $meta=$resp.chart.result[0].meta; if($meta){ $sp=$meta.regularMarketPrice; if(-not $sp){ $sp=$meta.regularMarketPreviousClose }; $prev = $meta.regularMarketPreviousClose; if(-not $prev -and $meta.PSObject.Properties['previousClose']){ $prev=$meta.previousClose }; $chgSp = CalcChange $sp $prev $null } } catch { if(-not $lastCode -and $_.Exception.Response){ $lastCode=$_.Exception.Response.StatusCode.value__ } }" ^
      "}" ^
      "if($nasdaq -ne $null -and $sp -ne $null){" ^
      "  $lines = @(" ^
      "    (FormatLine 'NASDAQ' $nasdaq $chgNasdaq)," ^
      "    (FormatLine 'S&P 500' $sp $chgSp)" ^
      "  );" ^
      "  $lines | Out-File -FilePath $out -Encoding UTF8;" ^
      "  Write-Output ($lines -join \"`n\");" ^
      "} else {" ^
      "  $codeText = if($lastCode){ 'Failed: ' + $lastCode } else { 'Failed: Network/Data' };" ^
      "  $codeText | Out-File -FilePath $out -Encoding UTF8;" ^
      "  Write-Output $codeText;" ^
      "}"
`) do echo %%T

timeout /t %REQUEST_INTERVAL_SEC% >nul
goto LOOP
