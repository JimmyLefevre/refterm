@echo off
echo Testing RELEASE version with KB library
echo =======================================
echo.

REM Test that release version also processes Unicode correctly
echo Testing: café | refterm_release_msvc.exe
timeout /t 2 >nul

echo Testing: مرحبا | refterm_release_msvc.exe
timeout /t 2 >nul

echo Testing: 😀 | refterm_release_msvc.exe
timeout /t 2 >nul

echo.
echo Both debug and release versions use the same KB library code!
echo The only difference is optimization level.
pause