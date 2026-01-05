@echo off
setlocal EnableDelayedExpansion

:: Edit these values: session lengths (minutes) and output file path.
set "sessions_minutes=25 5 25 10"
set "final_message=Pomodoro complete
set "output=%~dp0output.txt"."

:: Quick Pomodoro-style countdown demo that updates output.txt once per second.

set /a total_sessions=0
for %%d in (%sessions_minutes%) do set /a total_sessions+=1

set /a session_index=0
for %%d in (%sessions_minutes%) do (
    set /a session_index+=1
    set /a durationSec=%%d*60
    for /l %%s in (!durationSec!,-1,0) do (
        set /a minutes=%%s/60
        set /a seconds=%%s %% 60
        set "mm=0!minutes!"
        set "ss=0!seconds!"
        set "mm=!mm:~-2!"
        set "ss=!ss:~-2!"

        > "!output!" echo !mm!:!ss! [!session_index!/!total_sessions!]
        if not %%s==0 timeout /t 1 /nobreak >nul
    )
)

> "!output!" echo !final_message!

endlocal
