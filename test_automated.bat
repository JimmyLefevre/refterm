@echo off
echo Automated KB Rendering Tests
echo ============================
echo.

REM Build first
call build.bat
if errorlevel 1 (
    echo [FAIL] Build failed
    exit /b 1
)
echo [PASS] Build successful

REM Test basic execution
echo Testing | refterm_debug_msvc.exe >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Basic execution failed
    exit /b 1
)
echo [PASS] Basic execution

REM Test ASCII input
echo ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 | refterm_debug_msvc.exe >nul 2>&1
if errorlevel 1 (
    echo [FAIL] ASCII input test failed
    exit /b 1
)
echo [PASS] ASCII input

REM Test Unicode input
echo 😀🎉✨ | refterm_debug_msvc.exe >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Unicode emoji test failed
    exit /b 1
)
echo [PASS] Unicode emoji

REM Test RTL input
echo مرحبا שלום | refterm_debug_msvc.exe >nul 2>&1
if errorlevel 1 (
    echo [FAIL] RTL text test failed
    exit /b 1
)
echo [PASS] RTL text

REM Test complex scripts
echo สวัสดี नमस्ते 你好 | refterm_debug_msvc.exe >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Complex script test failed
    exit /b 1
)
echo [PASS] Complex scripts

REM Test VT codes
echo [31mRed[0m [32mGreen[0m [34mBlue[0m | refterm_debug_msvc.exe >nul 2>&1
if errorlevel 1 (
    echo [FAIL] VT code test failed
    exit /b 1
)
echo [PASS] VT codes

REM Test long input
setlocal enabledelayedexpansion
set "longtext="
for /l %%i in (1,1,100) do set "longtext=!longtext!This is line %%i of test text. "
echo !longtext! | refterm_debug_msvc.exe >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Long input test failed
    exit /b 1
)
echo [PASS] Long input

echo.
echo ============================
echo All automated tests passed!
echo.
echo Run test_kb_rendering.bat for visual verification tests.