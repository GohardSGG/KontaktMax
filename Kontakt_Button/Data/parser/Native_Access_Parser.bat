@echo off

C:\Windows\System32\reg.exe query "HKU\S-1-5-19" 1>nul 2>nul || goto :No_Admin
title Native Access SNPID Extractor
color F0
mode con: cols=54 lines=13 

@if (@CodeSection == @Batch) @then

@echo off
	call :Start_Title

:Start_Menu
	set "Backup_Folder=%~dp0NI_Backup"
	if not exist "%Backup_Folder%" ( mkdir "%Backup_Folder%" >nul 2>&1 )
	pushd "%Backup_Folder%"
	set "windir=C:\Windows"
	set "PScommand=%windir%\System32\WindowsPowerShell\v1.0\powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass"
	set "Registry_Key=HKEY_LOCAL_MACHINE\SOFTWARE\Native Instruments"

:SNPID_CHECK
REM Parse .xml files
	@echo >"C:\Users\%username%\AppData\Local\Temp\lock.tmp"
	<nul set /p DummyName= Parsing .xml data, wait
	%PScommand% -File "%~dp0XML_PARSER_Native_Access.ps1"
:Wait_lock
	if exist "C:\Users\%username%\AppData\Local\Temp\lock.tmp" ( goto :Wait_lock )
	echo:
	echo Done
REM Get Installed Libraries
	<nul set /p DummyName= Generating Text File, wait

:Parsing_List_Start
	set "SNPID_Length=3"
	setlocal EnableDelayedExpansion
	for /f "usebackqtokens=1 delims=|" %%a in (Parsed_List.csv) do (
		set "String=%%a" & call :strlen
		for /f "tokens=* delims=0" %%B in ("!result!") do (
			if %%B gtr !SNPID_Length! (
				set "SNPID_Length=%%B"
	)))
	setlocal DisableDelayedExpansion
	setlocal EnableDelayedExpansion
	set /a "SNPIDSTART=0"
	set /a "SNPID_Length+=3"
:Parsed_List_Loop
	if "%SNPIDSTART%"=="%SNPID_Length%" ( goto :Parsing_List_More )
	for /f "usebackqtokens=1-4 delims=|" %%a in (Parsed_List.csv) do (
		set "SNPID=%%a"
		set "LibName=%%b"
		set "RegKey=%%d"
		if not "!SNPID!"=="ThirdParty" ( if not "!SNPID!"=="" ( if not "!LibName!"=="Library Name" ( 
			set "SNPID=!SNPID:~%SNPIDSTART%,3!"
			if "!LibName:~-1!"=="$" ( set "LibName=!LibName:~0,-1!^!" )
			if "!RegKey:~-1!"=="$" ( set "RegKey=!RegKey:~0,-1!^!" )
			if not "!SNPID!"=="" ( (echo !SNPID!^|!LibName!^|%%c^|!RegKey!)>>Parsed_List.txt )
	))))
	set /a "SNPIDSTART+=3"
	goto :Parsed_List_Loop

:Parsing_List_More
	setlocal DisableDelayedExpansion
	echo:
	echo Done
	cd /d "%~dp0"
	for /f "Tokens=1*Delims=|" %%A in (Native_Access_SNPID.txt) do echo %%A^|%%B>>"%Backup_Folder%\Parsed_List.txt"
	cd /d "%Backup_Folder%"
	call "%~dp0jsort.bat" Parsed_List.txt /i /u >file.txt.new
	move /y file.txt.new "C:\Users\%USERNAME%\AppData\Local\Temp\Native_Access_SNPID_List.txt" >nul

	<nul set /p dummyName=  Done >nul 2>&1


	start "" notepad "C:\Users\%USERNAME%\AppData\Local\Temp\Native_Access_SNPID_List.txt" >nul
	PING localhost -n 3 >NUL
	del /f/q/s "%~dp0NI_Backup\Parsed_List.csv" >nul 2>&1
	del /f/q/s "%~dp0NI_Backup\Parsed_List.txt" >nul 2>&1

	del /f/q/s "C:\Users\%USERNAME%\AppData\Local\Temp\Native_Access_SNPID_List.txt" >nul 2>&1
	goto :eof
:eof

	exit /b
del 0%

REM ********* function *****************************
:Start_Title
	echo ======================================================
	echo           Native Access SNPID Extractor
	echo         Listed by SNPID Name Company Regkey
	echo                 updated 06/03/2022
	echo                     Bob Dule
	echo ======================================================
	echo:
	goto :eof

REM ********* function *****************************
:strlen
	(
		(set^ tmp=!String!)
			set "len=1"
			for %%P in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
				if "!tmp:~%%P,1!" NEQ "" (
					set /a "len+=%%P"
					set "tmp=!tmp:~%%P!"
				)
			)
	)
	(
		set "result=!len!"
		exit /b
	)


@end


var shl = new ActiveXObject("Shell.Application");
var folder = shl.BrowseForFolder(0, WScript.Arguments(0), 0x00000050,17);
WScript.Stdout.WriteLine(folder ? folder.self.path : "");