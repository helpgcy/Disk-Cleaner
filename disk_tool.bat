@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title 多功能磁盘工具箱

rem ================= 可配置区（改成你自己的 GitHub 仓库信息） =================
rem 仓库根目录需要两个文件：
rem   1. version.txt    内容为版本号，如 1.0.1
rem   2. disk_tool.bat  新版工具本体（本脚本的更新版）
set "VER_URL=https://raw.githubusercontent.com/你的用户名/你的仓库/main/version.txt"
set "BAT_URL=https://raw.githubusercontent.com/你的用户名/你的仓库/main/disk_tool.bat"
set "CURRENT_VER=1.0.0"
rem =========================================================================

rem 若带参数运行说明是"新版替换流程"（由旧版启动）
if not "%~1"=="" goto :install_update

:menu
cls
echo.
echo  ============================================
echo      多功能磁盘工具箱   v%CURRENT_VER%
echo  ============================================
echo   [1] 查看磁盘信息
echo   [2] 磁盘错误检查（只读，不修改磁盘）
echo   [3] 清理临时文件
echo   [4] 打开系统磁盘清理
echo   [5] 检查更新（从 GitHub 仓库）
echo   [6] 退出
echo  ============================================
set /p choice=请输入功能序号后回车：
if "%choice%"=="1" goto :disk_info
if "%choice%"=="2" goto :disk_check
if "%choice%"=="3" goto :clean_temp
if "%choice%"=="4" goto :sys_clean
if "%choice%"=="5" goto :check_update
if "%choice%"=="6" exit /b
echo 无效输入，请重新选择
pause
goto :menu

:disk_info
cls
echo ===== 磁盘信息 =====
powershell -NoProfile -Command "Get-Volume | Format-Table DriveLetter, FileSystemLabel, FileSystem, DriveType, HealthStatus, @{n='SizeGB';e={[math]::Round($_.Size/1GB,1)}}, @{n='FreeGB';e={[math]::Round($_.SizeRemaining/1GB,1)}} -AutoSize"
pause
goto :menu

:disk_check
cls
echo ===== 磁盘错误检查（只读模式，不会修复或改动数据） =====
echo 请输入要检查的盘符（如 C，不带冒号），直接回车默认 C：
set /p drv=
if "%drv%"=="" set "drv=C"
chkdsk %drv%:
pause
goto :menu

:clean_temp
cls
echo ===== 清理临时文件 =====
echo 将清理以下位置的临时文件：
echo   %TEMP%
echo   C:\Windows\Temp
echo 正在运行中的文件会自动跳过，不影响系统。
set /p ok=确认清理？(Y/N)：
if /i not "%ok%"=="Y" goto :menu
del /f /s /q "%TEMP%\*.*" >nul 2>&1
del /f /s /q "C:\Windows\Temp\*.*" >nul 2>&1
echo 清理完成。
pause
goto :menu

:sys_clean
cls
echo 正在打开系统自带的磁盘清理工具...
start cleanmgr
pause
goto :menu

:check_update
cls
echo 正在检查更新...
curl -s "%VER_URL%" > "%TEMP%\latest_ver.txt" 2>nul
set /p LATEST=<"%TEMP%\latest_ver.txt"
if "%LATEST%"=="" (
    echo 无法获取版本信息，请检查 VER_URL 是否配置正确。
    pause
    goto :menu
)
echo 当前版本：%CURRENT_VER%    仓库版本：%LATEST%
if "%LATEST%"=="%CURRENT_VER%" (
    echo 已是最新版本。
    pause
    goto :menu
)
echo 发现新版本，正在下载更新...
curl -sL -o "%TEMP%\disk_tool_new.bat" "%BAT_URL%" 2>nul
if not exist "%TEMP%\disk_tool_new.bat" (
    echo 下载失败，请检查 BAT_URL 是否配置正确。
    pause
    goto :menu
)
echo 下载完成，正在删除旧版并启动新版...
start "" "%TEMP%\disk_tool_new.bat" "%~f0"
exit /b

:install_update
rem 新版启动后执行：等待旧进程退出 → 覆盖删除旧版 → 复制新版到原位置 → 重新启动
ping 127.0.0.1 -n 4 >nul
copy /y "%~f0" "%~1" >nul
del /f /q "%~f0" >nul 2>&1
start "" "%~1"
exit /b
