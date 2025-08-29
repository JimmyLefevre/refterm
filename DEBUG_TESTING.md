# KB Library Debug Testing Documentation

## Overview
This document describes the comprehensive debug instrumentation added to refterm's KB library integration for thorough testing and troubleshooting.

## Debug Instrumentation Added

### 1. Critical Debug Points

The following debug output points have been added to `ParseWithKB()` function:

- **[KB_INIT]**: KB library initialization and state setup
- **[UTF8]**: UTF-8 decoding with codepoint tracking (first 10 codepoints)
- **[BREAK]**: Break processing and RTL detection (first 20 breaks)
- **[BOUNDS]**: Array bounds checking for SegP buffer
- **[ERROR]**: Error handling and state validation
- **[RTL]**: RTL/LTR segment processing logic
- **[SEG]**: Segment bounds validation
- **[CONV]**: UTF-8 to UTF-16 conversion

### 2. Debug Output Mechanisms

#### Console Output (AppendOutput)
- Conditional on `Terminal->DebugHighlighting` flag
- Outputs to terminal display
- Toggle with `debug` command in refterm

#### File Logging (WriteDebugLog)
- Writes to `kb_debug.log` when debug mode enabled
- Writes to `kb_debug_always.log` unconditionally (for testing)
- Persistent logging with immediate flush

### 3. Key Findings

#### ParseWithKB Trigger Conditions
- **Called for**: Complex Unicode (bytes >= 0x80), emojis, RTL text, accented characters
- **NOT called for**: Pure ASCII (0x00-0x7F), simple control characters, VT escape sequences

#### Text Processing Flow
```
Input → ProcessMessages → AppendOutput → ParseLines → ParseLineIntoGlyphs → ParseWithKB
```

## Testing Approach

### Manual Testing Steps

1. **Start refterm**: `refterm_debug_msvc.exe`
2. **Enable debug mode**: Type `debug` and press Enter
3. **Input complex text**:
   - Arabic: `مرحبا بالعالم`
   - Accented: `café`
   - Emojis: `😀 😃 😄`
   - Thai: `สวัสดีชาวโลก`
   - Chinese: `你好世界`
4. **Check log files**: Look for `kb_debug.log` and `kb_debug_always.log`

### Automated Test Scripts

#### test_debug.bat
Interactive debug testing with various Unicode scenarios.

#### test_debug_auto.bat
Automated testing using PowerShell SendKeys for keystroke simulation.

#### test_debug_capture.bat
Captures debug output to file for analysis.

#### test_unicode_debug.bat
Comprehensive Unicode testing with multiple scripts and languages.

## Debug Output Analysis

### Sample Debug Log Entry
```
[KB_INIT] Initialized KB break state with direction=NONE, style=NORMAL
[KB_INIT] Processing UTF-8 range: 15 bytes
[UTF8] Decoded codepoint U+0645 at position 0, consumed 2 bytes
[UTF8] Decoded codepoint U+0631 at position 1, consumed 2 bytes
[BREAK] Break at position 0, flags=0x0002 (DIRECTION)
[RTL] RTL Mode: dSeg=-1, start=3, stop=4294967295, segments=5
[SEG] Processing segment 3: range [8-15]
[CONV] UTF-16 conversion: 7 UTF-8 bytes → 4 UTF-16 units
```

### Performance Considerations

- Debug output limited to first 10 codepoints and 20 breaks
- File I/O only when debug mode enabled
- Immediate flush ensures data capture even on crash

## Troubleshooting

### No Debug Output?
1. Ensure using Unicode text (not pure ASCII)
2. Check debug mode is enabled (`debug` command)
3. Look for log files in refterm directory
4. Verify ParseWithKB is being called (complex chars required)

### Testing Complex Scripts
Use the provided test files or type directly:
- RTL: Arabic (مرحبا), Hebrew (שלום)
- Complex: Thai (สวัสดี), Devanagari (नमस्ते)
- Combining: café, naïve
- Emoji: 😀🎉✨

## Known Issues

1. **GUI Application**: refterm is a Windows GUI app, making automated testing challenging
2. **ASCII Bypass**: Simple ASCII text doesn't trigger ParseWithKB
3. **Recursive Logging**: AppendOutput calls can be recursive through ParseLines

## Future Enhancements

1. Add performance metrics to debug output
2. Include memory usage statistics
3. Add configurable debug levels
4. Create unit tests for ParseWithKB isolation
5. Add graphical visualization of segment boundaries

## Conclusion

The comprehensive debug instrumentation provides deep visibility into KB library text processing, enabling:
- Identification of text flow issues
- RTL processing verification
- Unicode handling validation
- Performance bottleneck detection
- Crash debugging with detailed state information

The laser-focused debug printing at critical points ensures thorough testing capabilities while maintaining performance when debug mode is disabled.