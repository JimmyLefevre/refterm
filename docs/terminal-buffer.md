# Terminal Buffer Interface

The Terminal Buffer Interface manages terminal state and text processing through a sophisticated circular buffer design with SIMD-optimized operations for high-performance text rendering and escape sequence handling.

## Architecture Overview

### Core Components
- **Circular Buffer Design** for efficient scrolling without data movement
- **SIMD-Optimized UTF-8 Scanning** processing 16 bytes in parallel
- **VT100/ANSI Escape Sequences** for terminal control
- **Uniscribe Integration** for complex script handling
- **24-bit RGB Colors** with attribute flags in high bits
- **Cell-Based Storage** with 12 bytes per terminal cell

## Implementation Details

### Circular Buffer Implementation

#### Source Buffer Structure
`refterm_example_source_buffer.h:8-18`
```c
typedef struct {
    size_t DataSize;
    char *Data;
    
    // For circular buffer
    size_t RelativePoint;
    
    // For cache checking
    size_t AbsoluteFilledSize;
} source_buffer;
```

Key features:
- **Memory mapping technique**: Back-to-back mapping for seamless wraparound
- **RelativePoint tracking**: Current write position in circular buffer
- **AbsoluteFilledSize**: Total data processed for cache validation
- **Page-aligned allocation**: Required for Windows memory mapping

#### Terminal Screen Buffer
`refterm_example_terminal.h:13-18`
```c
typedef struct {
    renderer_cell *Cells;
    uint32_t DimX, DimY;
    uint32_t FirstLineY;  // Circular scroll position
} terminal_buffer;
```

Circular scrolling implementation:
`refterm_example_d3d11.c:430-434`
```c
uint32_t TopCellCount = Term->DimX * (Term->DimY - Term->FirstLineY);
uint32_t BotCellCount = Term->DimX * (Term->FirstLineY);
memcpy(Cells, Term->Cells + Term->FirstLineY*Term->DimX, TopCellCount*sizeof(renderer_cell));
memcpy(Cells + TopCellCount, Term->Cells, BotCellCount*sizeof(renderer_cell));
```

### SIMD-Optimized UTF-8 Scanning

#### 16-Byte Block Processing
`refterm_example_terminal.c:304-343`
```c
__m128i Carriage = _mm_set1_epi8('\n');
__m128i Escape = _mm_set1_epi8('\x1b');
__m128i Complex = _mm_set1_epi8(0x80);

while(Count >= 16) {
    __m128i Batch = _mm_loadu_si128((__m128i *)Data);
    __m128i TestC = _mm_cmpeq_epi8(Batch, Carriage);
    __m128i TestE = _mm_cmpeq_epi8(Batch, Escape);
    __m128i TestX = _mm_and_si128(Batch, Complex);
    __m128i Test = _mm_or_si128(TestC, TestE);
    int Check = _mm_movemask_epi8(Test);
    
    if(Check) {
        int Advance = _tzcnt_u32(Check);  // Find first match
        // Handle found character
        break;
    }
    
    ContainsComplex = _mm_or_si128(ContainsComplex, TestX);
    Count -= 16;
    Data += 16;
}
```

SIMD Features:
- **Parallel character detection**: Simultaneously scans for newlines, escapes, and UTF-8
- **Bitmask extraction**: `_mm_movemask_epi8()` for efficient branching
- **Trailing zero count**: `_tzcnt_u32()` finds first occurrence
- **Complex character tracking**: Accumulates UTF-8 detection for Uniscribe routing

#### AES-NI Hash Computation
`refterm_example_source_buffer.c:194-237`
```c
__m128i HashValue = _mm_cvtsi64_si128(Count);
HashValue = _mm_xor_si128(HashValue, _mm_loadu_si128((__m128i *)Seedx16));

while(ChunkCount--) {
    __m128i In = _mm_loadu_si128((__m128i *)At);
    HashValue = _mm_xor_si128(HashValue, In);
    // 4 AES rounds per 16-byte chunk
    HashValue = _mm_aesdec_si128(HashValue, _mm_setzero_si128());
    HashValue = _mm_aesdec_si128(HashValue, _mm_setzero_si128());
    HashValue = _mm_aesdec_si128(HashValue, _mm_setzero_si128());
    HashValue = _mm_aesdec_si128(HashValue, _mm_setzero_si128());
    At += 16;
}
```

### VT100/ANSI Escape Sequence Parsing

#### Escape Detection
`refterm_example_terminal.c:118-122`
```c
static int AtEscape(source_buffer_range *Range) {
    int Result = ((PeekToken(Range, 0) == '\x1b') &&
                  (PeekToken(Range, 1) == '['));
    return Result;
}
```

#### Parameter Parsing
`refterm_example_terminal.c:223-285`
```c
static int ParseEscape(example_terminal *Terminal, source_buffer_range *Range, 
                      cursor_state *Cursor) {
    GetToken(Range);  // Skip ESC
    GetToken(Range);  // Skip [
    
    uint32_t ParamCount = 0;
    uint32_t Params[8] = {0};
    
    // Parse numeric parameters
    while((ParamCount < ArrayCount(Params)) && Range->Count) {
        if(IsDigit(PeekToken(Range, 0))) {
            Params[ParamCount++] = ParseNumber(Range);
            // Handle semicolon separation
        }
    }
    
    // Process command
    switch(Command) {
        case 'H': /* Cursor position */
        case 'm': /* Graphics mode - colors, attributes */
    }
}
```

Supported Sequences:
- **Cursor positioning**: `ESC[H` with row/column parameters
- **Graphics modes**: `ESC[m` for colors and text attributes
- **24-bit RGB colors**: `ESC[38;2;R;G;B` (foreground) and `ESC[48;2;R;G;B` (background)

### Uniscribe Integration

#### Partitioner Structure
`refterm_example_terminal.h:38-51`
```c
typedef struct {
    // TODO(casey): Get rid of Uniscribe so this garbage doesn't have to happen
    
    SCRIPT_DIGITSUBSTITUTE UniDigiSub;
    SCRIPT_CONTROL UniControl;
    SCRIPT_STATE UniState;
    SCRIPT_CACHE UniCache;
    
    wchar_t Expansion[1024];
    SCRIPT_ITEM Items[1024];
    SCRIPT_LOGATTR Log[1024];
    DWORD SegP[1026];
} example_partitioner;
```

Complex text is routed through Uniscribe for proper grapheme cluster handling, though the author notes significant frustration with its API limitations and performance.

### Color and Attribute Storage

#### Cell Structure
`refterm_example_d3d11.h:15-20`
```c
#define RENDERER_CELL_BLINK 0x80000000
typedef struct {
    uint32_t GlyphIndex;    // Packed Y.X coordinates (16.16)
    uint32_t Foreground;    // Color + flags in high bits
    uint32_t Background;    // Top bit indicates blinking
} renderer_cell;
```

#### Color Encoding
`refterm_example_terminal.c:67-73,205`
```c
static uint32_t PackRGB(uint32_t R, uint32_t G, uint32_t B) {
    if(R > 255) R = 255;
    if(G > 255) G = 255;
    if(B > 255) B = 255;
    uint32_t Result = ((B << 16) | (G << 8) | (R << 0));
    return Result;
}

// Attribute flags stored in high byte
Dest->Foreground = Foreground | (Props.Flags << 24);
```

#### Attribute Flags
`refterm_example_terminal.h:1-11`
```c
enum {
    TerminalCell_Bold = 0x1,
    TerminalCell_Dim = 0x2,
    TerminalCell_Italic = 0x4,
    TerminalCell_Underline = 0x8,
    TerminalCell_Blinking = 0x10,
    TerminalCell_ReverseVideo = 0x20,
    TerminalCell_Invisible = 0x40,
    TerminalCell_Strikethrough = 0x80,
};
```

## Cell Structure and Memory Layout

### Physical Layout
- **12 bytes per cell**: GlyphIndex (4) + Foreground (4) + Background (4)
- **Contiguous allocation**: Single VirtualAlloc for entire screen buffer
- **Row-major ordering**: `Cell = Buffer->Cells + Y*DimX + X`
- **GPU compatibility**: Structured buffer format matches HLSL requirements

### Memory Access Pattern
The row-major layout ensures:
- Cache-friendly sequential access
- Efficient GPU transfer
- Simple coordinate calculation

## Text Processing Algorithms

### Multi-Path Processing

1. **SIMD Scan Phase**
   - Identifies escape sequences
   - Detects complex UTF-8 characters
   - Finds line breaks

2. **Simple ASCII Path**
   - Direct glyph cache lookup
   - Immediate cell assignment
   - Bypasses complex processing

3. **Complex Unicode Path**
   - UTF-8 to UTF-16 conversion
   - Uniscribe processing
   - Grapheme cluster handling

4. **Escape Sequence Path**
   - Parameter parsing
   - Terminal state updates
   - Attribute modifications

### Performance Optimizations

- **Direct codepoint mapping**: ASCII 32-126 bypass cache lookup
- **Line splitting**: Large lines split at 4096 characters
- **Lazy rasterization**: Glyphs rasterized on first use
- **Batch processing**: Multiple characters processed per iteration

## Buffer Management and Resizing

### Dynamic Resizing
`refterm_example_terminal.c:1290-1302`
```c
uint32_t NewDimX = SafeRatio1(Width - Margin, Terminal->GlyphGen.FontWidth);
uint32_t NewDimY = SafeRatio1(Height - Margin, Terminal->GlyphGen.FontHeight);

if((NewDimX != Terminal->ScreenBuffer.DimX) || 
   (NewDimY != Terminal->ScreenBuffer.DimY)) {
    DeallocateTerminalBuffer(&Terminal->ScreenBuffer);
    Terminal->ScreenBuffer = AllocateTerminalBuffer(NewDimX, NewDimY);
    // Trigger full repaint
}
```

### Allocation Strategy
- Allocate new buffer before deallocating old
- Preserve terminal content when possible
- Clear buffer on dimension changes

## Performance Characteristics

### SIMD Optimizations
- **16-byte parallel processing**: 16x speedup for text scanning
- **AES-NI hashing**: Hardware-accelerated hash computation
- **SSE string operations**: Optimized memory copies

### Circular Buffer Benefits
- **O(1) scrolling**: No data movement required
- **Constant memory usage**: Fixed buffer size
- **Cache-friendly access**: Sequential memory patterns

### Escape Sequence Handling
- **Early detection**: SIMD identifies escapes quickly
- **Lazy parsing**: Only parse when escape detected
- **Minimal state changes**: Batch attribute updates

## Integration Points

### Renderer Integration
The terminal buffer provides:
- Updated cell array each frame
- Circular buffer metadata for reordering
- Color and attribute information

### Glyph Cache Integration
Text processing triggers:
- Hash computation for new glyphs
- Cache lookups for existing glyphs
- Rasterization requests for cache misses

### Fast Pipe Integration
Input arrives through:
- Fast pipe for direct communication
- Standard handles as fallback
- Bulk reads for efficiency

## Design Philosophy

The Terminal Buffer Interface demonstrates:
- **Performance-first design**: SIMD optimization throughout
- **Pragmatic engineering**: Works around Uniscribe limitations
- **Clean abstractions**: Clear separation of concerns
- **Efficient algorithms**: Circular buffers and batched processing

This interface achieves exceptional performance through careful optimization of every text processing path, from SIMD-accelerated scanning to efficient escape sequence parsing, enabling RefTerm to process terminal output at speeds that rival native applications.