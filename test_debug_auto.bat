@echo off
echo Starting refterm in background...

REM Delete old log file if exists
if exist kb_debug.log del kb_debug.log

REM Start refterm in background
start "" refterm_debug_msvc.exe

REM Wait a moment for it to start
timeout /t 2 >nul

REM Use PowerShell to send keystrokes to the window
powershell -Command ^
  "Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class Win32 { [DllImport(\"user32.dll\")] public static extern IntPtr FindWindow(string lpClassName, string lpWindowName); [DllImport(\"user32.dll\")] public static extern bool SetForegroundWindow(IntPtr hWnd); }'; ^
  Start-Sleep -Milliseconds 500; ^
  $wnd = [Win32]::FindWindow($null, 'refterm'); ^
  if ($wnd -ne [IntPtr]::Zero) { ^
    [Win32]::SetForegroundWindow($wnd); ^
    Start-Sleep -Milliseconds 500; ^
    [System.Windows.Forms.SendKeys]::SendWait('debug{ENTER}'); ^
    Start-Sleep -Milliseconds 500; ^
    [System.Windows.Forms.SendKeys]::SendWait('Hello World{ENTER}'); ^
    Start-Sleep -Milliseconds 500; ^
    [System.Windows.Forms.SendKeys]::SendWait('Testing 123{ENTER}'); ^
  }" 2>nul

REM Wait for processing
timeout /t 3 >nul

REM Check if log file was created
if exist kb_debug.log (
    echo.
    echo Debug log created! Contents:
    echo =============================
    type kb_debug.log
    echo =============================
) else (
    echo No debug log created. Debug mode may not have been activated.
)

REM Kill refterm
taskkill /IM refterm_debug_msvc.exe /F >nul 2>&1

pause