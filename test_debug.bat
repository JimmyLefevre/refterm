@echo off
echo ============================================
echo KB Library Debug Testing Suite
echo ============================================
echo.

REM Build debug version first
echo Building debug version...
call build.bat
if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

echo.
echo ============================================
echo Test 1: Simple ASCII text
echo ============================================
echo debug | refterm_debug_msvc.exe
timeout /t 1 >nul
echo Hello World | refterm_debug_msvc.exe
timeout /t 2 >nul

echo.
echo ============================================
echo Test 2: Multiple lines
echo ============================================
echo debug | refterm_debug_msvc.exe
timeout /t 1 >nul
(echo Line 1
echo Line 2
echo Line 3) | refterm_debug_msvc.exe
timeout /t 2 >nul

echo.
echo ============================================
echo Test 3: Unicode emojis
echo ============================================
echo debug | refterm_debug_msvc.exe
timeout /t 1 >nul
echo Testing emojis: 😀 😃 😄 | refterm_debug_msvc.exe
timeout /t 2 >nul

echo.
echo ============================================
echo Test 4: RTL text (Arabic)
echo ============================================
echo debug | refterm_debug_msvc.exe
timeout /t 1 >nul
echo مرحبا بالعالم | refterm_debug_msvc.exe
timeout /t 2 >nul

echo.
echo ============================================
echo Test 5: Complex script (Thai)
echo ============================================
echo debug | refterm_debug_msvc.exe
timeout /t 1 >nul
echo สวัสดีชาวโลก | refterm_debug_msvc.exe
timeout /t 2 >nul

echo.
echo ============================================
echo Test 6: Mixed content
echo ============================================
echo debug | refterm_debug_msvc.exe
timeout /t 1 >nul
echo Hello مرحبا 你好 😀 | refterm_debug_msvc.exe
timeout /t 2 >nul

echo.
echo ============================================
echo Test 7: Long line (stress test)
echo ============================================
echo debug | refterm_debug_msvc.exe
timeout /t 1 >nul
echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA | refterm_debug_msvc.exe
timeout /t 2 >nul

echo.
echo ============================================
echo Debug testing complete!
echo ============================================
echo.
echo Check the output above for any [ERROR] messages or unusual behavior.
echo All [KB_INIT], [UTF8], [BREAK], [SEG], [RTL], [CONV] messages show debug flow.
echo.
pause