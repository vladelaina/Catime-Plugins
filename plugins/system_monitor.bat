@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"
title System Monitor

:: --- Configuration ---
set OUTPUT_FILE=output.txt
set REQUEST_INTERVAL_SEC=2

echo System Monitor Starting...
echo Output: %OUTPUT_FILE%
echo.

:LOOP
cls

set "TEMP_PS=%TEMP%\sysmon_%RANDOM%.ps1"

> "%TEMP_PS%" echo $ProgressPreference='SilentlyContinue'
>> "%TEMP_PS%" echo $out = '%OUTPUT_FILE%'
>> "%TEMP_PS%" echo # CPU
>> "%TEMP_PS%" echo $cpu = Get-CimInstance Win32_Processor
>> "%TEMP_PS%" echo $cpuLoad = [math]::Round((Get-Counter '\Processor(_Total)\%% Processor Time' -ErrorAction SilentlyContinue).CounterSamples.CookedValue)
>> "%TEMP_PS%" echo if(-not $cpuLoad) { $cpuLoad = 0 }
>> "%TEMP_PS%" echo $cpuFreq = [math]::Round($cpu.CurrentClockSpeed / 1000, 2)
>> "%TEMP_PS%" echo $cpuCores = $cpu.NumberOfCores
>> "%TEMP_PS%" echo $cpuThreads = $cpu.NumberOfLogicalProcessors
>> "%TEMP_PS%" echo # Memory
>> "%TEMP_PS%" echo $os = Get-CimInstance Win32_OperatingSystem
>> "%TEMP_PS%" echo $totalMem = [math]::Round($os.TotalVisibleMemorySize / 1MB, 0)
>> "%TEMP_PS%" echo $freeMem = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
>> "%TEMP_PS%" echo $usedMem = [math]::Round($totalMem - $freeMem, 1)
>> "%TEMP_PS%" echo $memPercent = [math]::Round(($usedMem / $totalMem) * 100)
>> "%TEMP_PS%" echo # Disk C:
>> "%TEMP_PS%" echo $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
>> "%TEMP_PS%" echo $diskTotal = [math]::Round($disk.Size / 1GB, 0)
>> "%TEMP_PS%" echo $diskFree = [math]::Round($disk.FreeSpace / 1GB, 0)
>> "%TEMP_PS%" echo $diskUsed = $diskTotal - $diskFree
>> "%TEMP_PS%" echo $diskPercent = [math]::Round(($diskUsed / $diskTotal) * 100)
>> "%TEMP_PS%" echo # Network speed
>> "%TEMP_PS%" echo $net1 = Get-NetAdapterStatistics -ErrorAction SilentlyContinue ^| Measure-Object -Property ReceivedBytes,SentBytes -Sum
>> "%TEMP_PS%" echo $recv1 = ($net1 ^| Where-Object Property -eq 'ReceivedBytes').Sum
>> "%TEMP_PS%" echo $sent1 = ($net1 ^| Where-Object Property -eq 'SentBytes').Sum
>> "%TEMP_PS%" echo Start-Sleep -Seconds 1
>> "%TEMP_PS%" echo $net2 = Get-NetAdapterStatistics -ErrorAction SilentlyContinue ^| Measure-Object -Property ReceivedBytes,SentBytes -Sum
>> "%TEMP_PS%" echo $recv2 = ($net2 ^| Where-Object Property -eq 'ReceivedBytes').Sum
>> "%TEMP_PS%" echo $sent2 = ($net2 ^| Where-Object Property -eq 'SentBytes').Sum
>> "%TEMP_PS%" echo $download = [math]::Round(($recv2 - $recv1) / 1KB, 1)
>> "%TEMP_PS%" echo $upload = [math]::Round(($sent2 - $sent1) / 1KB, 1)
>> "%TEMP_PS%" echo if($download -lt 0) { $download = 0 }
>> "%TEMP_PS%" echo if($upload -lt 0) { $upload = 0 }
>> "%TEMP_PS%" echo # Process count
>> "%TEMP_PS%" echo $procCount = (Get-Process).Count
>> "%TEMP_PS%" echo # Uptime
>> "%TEMP_PS%" echo $uptime = (Get-Date) - $os.LastBootUpTime
>> "%TEMP_PS%" echo $uptimeStr = '{0}h {1}m' -f [int]$uptime.TotalHours, $uptime.Minutes
>> "%TEMP_PS%" echo # Battery
>> "%TEMP_PS%" echo $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
>> "%TEMP_PS%" echo $batteryStr = ''
>> "%TEMP_PS%" echo if($battery) { $batteryStr = 'Battery: ' + $battery.EstimatedChargeRemaining + '%%' }
>> "%TEMP_PS%" echo # Build output
>> "%TEMP_PS%" echo $lines = @()
>> "%TEMP_PS%" echo $lines += "`t [ System Monitor ]"
>> "%TEMP_PS%" echo $lines += ''
>> "%TEMP_PS%" echo $lines += "CPU: $cpuLoad%%  Freq: ${cpuFreq}GHz"
>> "%TEMP_PS%" echo $lines += "Cores: $cpuCores  Threads: $cpuThreads"
>> "%TEMP_PS%" echo $lines += ''
>> "%TEMP_PS%" echo $lines += "RAM:  $memPercent%%  $usedMem/${totalMem}GB"
>> "%TEMP_PS%" echo $lines += "Disk: $diskPercent%%  $diskUsed/${diskTotal}GB"
>> "%TEMP_PS%" echo $lines += ''
>> "%TEMP_PS%" echo $lines += "Net: up $upload KB/s  down $download KB/s"
>> "%TEMP_PS%" echo if($batteryStr) { $lines += ''; $lines += $batteryStr }
>> "%TEMP_PS%" echo $lines += ''
>> "%TEMP_PS%" echo $lines += "Processes: $procCount  Uptime: $uptimeStr"
>> "%TEMP_PS%" echo $text = $lines -join "`n"
>> "%TEMP_PS%" echo $text ^| Out-File -FilePath $out -Encoding UTF8 -NoNewline
>> "%TEMP_PS%" echo Write-Output $text

powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP_PS%"
del "%TEMP_PS%" 2>nul

timeout /t %REQUEST_INTERVAL_SEC% >nul
goto LOOP
