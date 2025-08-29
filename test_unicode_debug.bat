@echo off
chcp 65001 >nul
echo Testing KB Debug with Unicode Input
echo ====================================
echo.

REM Delete old log files
del kb_debug*.log 2>nul

REM Build first
call build.bat
if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

REM Create a Unicode test file (UTF-8)
echo Creating Unicode test file...
(
echo café
echo مرحبا بالعالم
echo 😀 😃 😄 😁
echo Здравствуй мир
echo 你好世界
echo สวัสดีชาวโลก
) > unicode_test.txt

echo.
echo Starting refterm and running Unicode test...
echo.

REM Start refterm and pipe Unicode content
REM This uses cmd to run a child process that outputs Unicode
start "RefTerm Test" refterm_debug_msvc.exe

REM Wait for it to start
timeout /t 2 >nul

REM Send commands using PowerShell to type in the window
powershell -Command ^
  "$wnd = (Get-Process refterm_debug_msvc -ErrorAction SilentlyContinue).MainWindowHandle; ^
   if ($wnd) { ^
     Add-Type @' ^
       using System; ^
       using System.Runtime.InteropServices; ^
       using System.Windows.Forms; ^
       public class Win32 { ^
         [DllImport(\"user32.dll\")] ^
         public static extern bool SetForegroundWindow(IntPtr hWnd); ^
       } ^
'@; ^
     [Win32]::SetForegroundWindow($wnd); ^
     Start-Sleep -Milliseconds 500; ^
     [System.Windows.Forms.SendKeys]::SendWait('debug{ENTER}'); ^
     Start-Sleep -Milliseconds 500; ^
     [System.Windows.Forms.SendKeys]::SendWait('type unicode_test.txt{ENTER}'); ^
     Start-Sleep -Milliseconds 2000; ^
   }"

REM Wait for processing
timeout /t 5 >nul

REM Check for log files
echo.
echo Checking for debug logs...
echo ==========================

if exist kb_debug_always.log (
    echo.
    echo === kb_debug_always.log ===
    type kb_debug_always.log
    echo.
) else (
    echo No kb_debug_always.log found
)

if exist kb_debug.log (
    echo.
    echo === kb_debug.log ===
    type kb_debug.log
    echo.
) else (
    echo No kb_debug.log found
)

REM Kill refterm
taskkill /IM refterm_debug_msvc.exe /F >nul 2>&1

REM Clean up
del unicode_test.txt 2>nul

echo.
pause