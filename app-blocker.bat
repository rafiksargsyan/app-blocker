@echo off

set APP_BLOCKER_HOME=%~dp0
set APP_BLOCKER_HOME=%APP_BLOCKER_HOME:~0, -1%

:loop
    ping 127.0.0.1 -n 6 > nul
    call :isBreak isBreak
    if "%isBreak%" == "true" (
	    setlocal EnableDelayedExpansion
        for /f "eol=# delims=" %%p in (%APP_BLOCKER_HOME%\break-time-apps.txt) do (
			wmic process get commandline 2>&1 | findstr /C:"%%p" | findstr /V /C:"findstr" >nul 2>&1		
			if !ERRORLEVEL! neq 0 (
			    start /B "" %%p
			)
			
		)
		endlocal
    )
    if "%isBreak%" == "false" (
        for /f "eol=# delims=" %%p in (%APP_BLOCKER_HOME%\blocked-apps.txt) do (
			WMIC PROCESS WHERE "COMMANDLINE LIKE '%%p'" CALL TERMINATE > nul 2>&1
		)
    )    
goto loop

exit /b


:trim
   setlocal EnableDelayedExpansion
   set params=%*
   for /f "tokens=1*" %%a in ("!params!") do endlocal & set %1=%%b
   exit /b

:pmTo24HoursFormat
   setlocal EnableDelayedExpansion
   set input=%2
   if "%input:~0,3%" == "12:" (
       endlocal & set %1=%2
	   exit /b
   )
   for /f "tokens=1* delims=:" %%a in ("%2") do (
       set h=%%a
	   set m=%%b
   )
   set /a h=1%h%+1%h%-2%h%
   set /a "h = h + 12"
   endlocal & set %1=%h%:%m%
   exit /b

:getCurrentTime
   setlocal
   for /f "tokens=1,2" %%a in ('time /t') do (
	   set dayTime=%%b	
	   set ret=%%a
   )
   if "%dayTime:~0,-1%" == "AM" (
	   endlocal & set "%1=%ret%"
	   exit /b
   )
   call :pmTo24HoursFormat ret %ret%
   endlocal & set "%1=%ret%"
   exit /b
   
:extractStartEndTimes
   setlocal
   for /f "tokens=1* delims=-" %%a in ("%3") do (
       endlocal & set %1=%%a & set %2=%%b
   )      
   exit /b
   
:isBreak
   setlocal EnableDelayedExpansion
   call :getCurrentTime curTime
   for /f "eol=#" %%t in (%APP_BLOCKER_HOME%\break-times.txt) do (
       call :extractStartEndTimes startTime endTime %%t
	   if "%curTime%" geq "!startTime!" (
		   if "%curTime%" leq "!endTime!" (
			   endlocal & set "%1=true"
			   exit /b
		   )
	   )
   )
   endlocal & set "%1=false"
   exit /b
   