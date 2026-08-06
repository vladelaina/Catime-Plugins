@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
title Time Date Weekday

:: Update output.txt once per second for Catime.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$output = Join-Path (Get-Location) 'output.txt';" ^
    "$weekPrefix = [string][char]0x661F + [char]0x671F;" ^
    "$dayCharacters = @(0x65E5, 0x4E00, 0x4E8C, 0x4E09, 0x56DB, 0x4E94, 0x516D);" ^
    "$utf8 = New-Object System.Text.UTF8Encoding($false);" ^
    "while ($true) {" ^
    "    $now = Get-Date;" ^
    "    $time = $now.ToString('HH:mm:ss');" ^
    "    $weekday = $weekPrefix + [char]$dayCharacters[[int]$now.DayOfWeek];" ^
    "    $date = '{0}/{1}/{2} {3}' -f $now.Year, $now.Month, $now.Day, $weekday;" ^
    "    [System.IO.File]::WriteAllText($output, $time + [Environment]::NewLine + $date, $utf8);" ^
    "    Start-Sleep -Seconds 1;" ^
    "}"

endlocal
