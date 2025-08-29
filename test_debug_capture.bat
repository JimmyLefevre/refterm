@echo off
echo Capturing debug output for analysis...

REM Build first
call build.bat >nul 2>&1
if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

REM Create test input file
echo debug > test_input.txt
echo Hello World >> test_input.txt

REM Run with debug and capture output
refterm_debug_msvc.exe < test_input.txt > debug_output.txt 2>&1

echo Debug output captured to debug_output.txt
echo.
type debug_output.txt

REM Clean up
del test_input.txt

pause