@echo off
echo Testing KB Text Rendering Implementation
echo =======================================
echo.

REM Build the test executable first
call build.bat
if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

REM Create test files with various Unicode content
echo Creating test files...

REM Test 1: Basic ASCII
echo Hello, World! This is a basic ASCII test. > test_ascii.txt
echo Testing 123... Testing special chars: !@#$%^&*()_+-=[]{}^|;':",".<>?/ >> test_ascii.txt

REM Test 2: Extended Unicode - Emojis and symbols
echo Testing emojis and symbols: > test_unicode.txt
echo 😀 😃 😄 😁 😆 😅 🤣 😂 🙂 🙃 😉 😊 >> test_unicode.txt
echo Mathematical: ∑ ∏ ∫ √ ∞ ≈ ≠ ≤ ≥ >> test_unicode.txt
echo Arrows: ← → ↑ ↓ ↔ ↕ ⇐ ⇒ ⇑ ⇓ >> test_unicode.txt
echo Box drawing: ┌─┬─┐ │ │ │ ├─┼─┤ └─┴─┘ >> test_unicode.txt

REM Test 3: RTL Languages (Arabic and Hebrew)
echo Testing RTL languages: > test_rtl.txt
echo Arabic: مرحبا بالعالم - هذا نص عربي للاختبار >> test_rtl.txt
echo Hebrew: שלום עולם - זהו טקסט עברי לבדיקה >> test_rtl.txt
echo Mixed: Hello مرحبا שלום World! >> test_rtl.txt

REM Test 4: Complex Scripts
echo Testing complex scripts: > test_complex.txt
echo Thai: สวัสดีชาวโลก นี่คือข้อความทดสอบ >> test_complex.txt
echo Devanagari: नमस्ते दुनिया - यह परीक्षण पाठ है >> test_complex.txt
echo Tamil: வணக்கம் உலகம் - இது சோதனை உரை >> test_complex.txt
echo Chinese: 你好世界 - 这是测试文本 >> test_complex.txt
echo Japanese: こんにちは世界 - これはテストテキストです >> test_complex.txt
echo Korean: 안녕하세요 세계 - 이것은 테스트 텍스트입니다 >> test_complex.txt

REM Test 5: Combining Characters
echo Testing combining characters: > test_combining.txt
echo Base + combining: a◌́ e◌̀ i◌̂ o◌̃ u◌̈ >> test_combining.txt
echo Stacked diacritics: ḛ̈ ṻ̈ >> test_combining.txt
echo Zalgo text: T̸͎̅h̵͉̃ȉ̷̢s̶̰̈ ̷̬́ỉ̶͇s̴̜̾ ̸͙̈́t̶̰̾ë̵́ͅs̵̱̈t̸̯̾ >> test_combining.txt

echo.
echo Running tests with refterm...
echo ==============================
echo.

REM Run each test file through refterm
echo Test 1: Basic ASCII
type test_ascii.txt | refterm_debug_msvc.exe
timeout /t 2 >nul

echo.
echo Test 2: Unicode Symbols and Emojis
type test_unicode.txt | refterm_debug_msvc.exe
timeout /t 2 >nul

echo.
echo Test 3: RTL Languages (Arabic/Hebrew)
type test_rtl.txt | refterm_debug_msvc.exe
timeout /t 2 >nul

echo.
echo Test 4: Complex Scripts (Thai/Devanagari/CJK)
type test_complex.txt | refterm_debug_msvc.exe
timeout /t 2 >nul

echo.
echo Test 5: Combining Characters
type test_combining.txt | refterm_debug_msvc.exe
timeout /t 2 >nul

echo.
echo ==============================
echo Testing complete!
echo.
echo Please visually verify that:
echo 1. ASCII text renders correctly
echo 2. Emojis and symbols display properly
echo 3. RTL text flows right-to-left
echo 4. Complex scripts render with proper shaping
echo 5. Combining characters stack correctly
echo.
echo If any rendering issues are observed, please document them.

REM Clean up test files
del test_ascii.txt test_unicode.txt test_rtl.txt test_complex.txt test_combining.txt 2>nul

pause