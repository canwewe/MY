@echo off
color 0A
%~d0
cd %~dp0

:: 读取MY.lua文件中的插件版本号
set szVersion=0x0000000
for /f "tokens=2,4 delims= " %%i in (.Framework/src/MY.lua) do (
	if "%%i"=="_VERSION_" (
		set szVersion=%%j
	)
	REM if "%%i"=="_DEBUG_" (
	REM 	if "%%j" NEQ "4" (
	REM 		color 0C
	REM 		echo Warning: Addon is still in debug mode! Release progress abended!
	REM 		pause && exit
	REM 	)
	REM )
)

:: 获取并格式化当前时间字符串
set szTime=%date:~0,10%%time:~0,8%
set szTime=%szTime:/=%
set szTime=%szTime: =0%
set szTime=%szTime::=%

:: 拼接字符串开始压缩文件
set szFile=!src-dist\releases\MY.%szTime%v%szVersion:~5,2%.7z
echo zippping...
7z a -t7z %szFile% -xr!manifest.dat -xr!manifest.key -xr!publisher.key -x@7zipignore.txt
echo File(s) compressing acomplete!
echo Url: %szFile%
set /p _=press enter to exit...
