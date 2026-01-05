@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
cd /d "%~dp0"
title Gaokao Countdown

:: --- Configuration ---
set TARGET_MONTH=6
set TARGET_DAY=7
set TARGET_HOUR=0
set TARGET_MINUTE=0
set TARGET_SECOND=0
set OUTPUT_FILE=output.txt

echo Countdown started...
echo Press Ctrl+C to exit
echo.

:loop
:: ========== Get current time ==========
:: Get date (supports formats: 周一 2026/01/05 or 2026/01/05 周一 or 2026-01-05)
set "today=%date%"
:: Remove weekday characters and keep only digits and separators
set "today=!today:周一=!"
set "today=!today:周二=!"
set "today=!today:周三=!"
set "today=!today:周四=!"
set "today=!today:周五=!"
set "today=!today:周六=!"
set "today=!today:周日=!"
:: Remove spaces
set "today=!today: =!"
:: Normalize separators
set "today=!today:/=-!"
set "today=!today:.=-!"
for /f "tokens=1-3 delims=-" %%a in ("!today!") do (
    set "cur_year=%%a"
    set "cur_month=%%b"
    set "cur_day=%%c"
)

:: Get time (handle leading space: " 9:05:03" -> "09:05:03")
set "now=%time: =0%"
set "cur_hour=!now:~0,2!"
set "cur_min=!now:~3,2!"
set "cur_sec=!now:~6,2!"

:: Convert to numbers
set /a "cy=cur_year, cm=1!cur_month!-100, cd=1!cur_day!-100"
set /a "ch=1!cur_hour!-100, cmi=1!cur_min!-100, cs=1!cur_sec!-100"
set /a "tm=%TARGET_MONTH%, td=%TARGET_DAY%"
set /a "th=%TARGET_HOUR%, tmi=%TARGET_MINUTE%, ts=%TARGET_SECOND%"

:: ========== Determine target year ==========
set /a "ty=cy"

:: Compare current datetime with this year's target
set /a "cur_val=cm*100000000+cd*1000000+ch*10000+cmi*100+cs"
set /a "tgt_val=tm*100000000+td*1000000+th*10000+tmi*100+ts"
if !cur_val! GEQ !tgt_val! set /a "ty+=1"

:: ========== Calculate day difference ==========
:: Convert dates to days since year 1 (simplified calculation)
call :date_to_days !cy! !cm! !cd! cur_days
call :date_to_days !ty! !tm! !td! tgt_days
set /a "diff_days=tgt_days-cur_days"

:: ========== Calculate time difference ==========
set /a "cur_secs=ch*3600+cmi*60+cs"
set /a "tgt_secs=th*3600+tmi*60+ts"
set /a "diff_secs=tgt_secs-cur_secs"

:: Handle borrow
if !diff_secs! LSS 0 (
    set /a "diff_days-=1"
    set /a "diff_secs+=86400"
)

:: ========== Format output ==========
if !diff_days! LSS 0 (
    set "output=高考已开始！"
) else (
    set /a "hh=diff_secs/3600"
    set /a "diff_secs%%=3600"
    set /a "mm=diff_secs/60"
    set /a "ss=diff_secs%%60"
    
    if !hh! LSS 10 set "hh=0!hh!"
    if !mm! LSS 10 set "mm=0!mm!"
    if !ss! LSS 10 set "ss=0!ss!"
    
    set "output=高考倒计时: !diff_days!天 !hh!:!mm!:!ss!"
)

cls
echo !output!
>"%OUTPUT_FILE%" echo !output!

:: Wait ~1 second
ping -n 2 127.0.0.1 >nul 2>&1
goto loop

:: ============================================================
:: Subroutine: Convert date to days since year 1
:: Uses formula for direct calculation, no loops, ensures accuracy
:: Params: %1=year %2=month %3=day %4=return variable name
:: ============================================================
:date_to_days
setlocal enabledelayedexpansion
set /a "y=%1, m=%2, d=%3"

:: If month <= 2, treat as 13th/14th month of previous year (simplifies leap year handling)
if !m! LEQ 2 (
    set /a "m+=12"
    set /a "y-=1"
)

:: Calculate total days (Gregorian calendar formula)
set /a "days=365*y + y/4 - y/100 + y/400 + (153*(m-3)+2)/5 + d - 306"

endlocal & set "%4=%days%"
goto :eof
