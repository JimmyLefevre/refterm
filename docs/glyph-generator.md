# Glyph Generator Interface

The Glyph Generator Interface provides font rasterization through DirectWrite, wrapping the C++ API in a C-compatible interface. Despite being the primary performance bottleneck in RefTerm, intelligent caching transforms this limitation into acceptable real-world performance.

## Architecture Overview

### Core Components
- **DirectWrite Integration** via C wrapper hiding C++ complexity
- **Direct2D Rendering** for glyph rasterization
- **Draw-then-Transfer Pattern** for GPU texture updates
- **Tile-Based Scaling** for oversized glyphs
- **Transfer Buffer System** for GPU communication

## The Performance Challenge

`refterm_example_glyph_generator.c:95-109`
> "Regardless of whether DirectWrite or GDI is used, rasterizing glyphs via Windows' libraries is **extremely slow**... the performance is still about **two orders of magnitude** away from where it should be."

The author's assessment:
> "I believe the only solution to actual fast glyph generation is to just write something that isn't as bad as GDI/DirectWrite."

This fundamental limitation makes the glyph cache absolutely critical for acceptable performance.

## Implementation Details

### DirectWrite C Wrapper

`refterm_example_dwrite.cpp`

The wrapper provides C-compatible functions for DirectWrite's C++ API:

#### Initialization
`refterm_example_dwrite.cpp:60`
```c
void DWriteInit(struct IDWriteFactory **Factory) {
    HRESULT Result = DWriteCreateFactory(
        DWRITE_FACTORY_TYPE_SHARED,
        __uuidof(IDWriteFactory),
        (IUnknown **)Factory);
}
```

#### Font Configuration
`refterm_example_dwrite.cpp:138`
```c
void DWriteSetFont(struct IDWriteTextFormat **Format, 
                   struct IDWriteFactory *Factory,
                   wchar_t *FontName, 
                   float FontHeight) {
    Factory->CreateTextFormat(
        FontName,
        NULL,  // Font collection
        DWRITE_FONT_WEIGHT_REGULAR,
        DWRITE_FONT_STYLE_NORMAL,
        DWRITE_FONT_STRETCH_NORMAL,
        FontHeight,
        L"en-us",  // Locale (hardcoded, suboptimal)
        Format);
}
```

### Glyph Generator Structure

`refterm_example_glyph_generator.h:17-30`
```c
struct glyph_generator {
    uint32_t FontWidth, FontHeight;
    uint32_t Pitch;
    uint32_t *Pixels;
    uint32_t TransferWidth, TransferHeight;
    
    // DirectWrite objects
    struct IDWriteFactory *DWriteFactory;
    struct IDWriteFontFace *FontFace;
    struct IDWriteTextFormat *TextFormat;
};
```

## Font Rasterization Process

### 1. Dimension Calculation

`refterm_example_glyph_generator.c:35` - `GetGlyphDim()`
```c
// Use DirectWrite to measure text extents
DWriteGetTextExtent(Format, Factory, 
                    At->Data, SafeTruncateToU32(At->Count),
                    FontHeight, &Size);

// Calculate tile requirements
Result.TileCountX = SafeRatio1((Size.cx + FontWidth/2), FontWidth);
Result.TileCountY = SafeRatio1((Size.cy + FontHeight/2), FontHeight);

// Compute scaling factors
Result.XScale = SafeRatio1((Result.TileCountX * FontWidth), Size.cx);
Result.YScale = SafeRatio1(FontHeight, Size.cy);
```

### 2. Text Rendering

`refterm_example_glyph_generator.c:82` - `PrepareTilesForTransfer()`
```c
// Render text with computed scaling
DWriteDrawText(Entry.Range.Data, SafeTruncateToU32(Entry.Range.Count),
               Font->FontWidth * Entry.TileCount,
               Font->FontHeight,
               Entry.XScale, Entry.YScale,
               Font->Pixels, Font->Pitch,
               Font->TextFormat, Font->DWriteFactory);
```

### 3. GPU Transfer

`refterm_example_glyph_generator.c:91` - `TransferTile()`
```c
// Copy from transfer buffer to glyph atlas
D3D11_BOX SourceBox = {
    .left = TileIndex * FontWidth,
    .right = (TileIndex + 1) * FontWidth,
    .top = 0,
    .bottom = FontHeight,
    .front = 0, .back = 1,
};

ID3D11DeviceContext_CopySubresourceRegion(
    DeviceContext,
    GlyphTexture, 0, X, Y, 0,
    GlyphTransfer, 0, &SourceBox);
```

## DirectWrite Integration Details

### Text Layout and Metrics

`refterm_example_dwrite.cpp:73-101` - `DWriteGetTextExtent()`
```c
// Create text layout
Factory->CreateTextLayout(
    String, StringLength,
    Format,
    10000.0f, FontHeight,  // Max width, height
    &Layout);

// Get metrics
DWRITE_TEXT_METRICS Metrics = {};
Layout->GetMetrics(&Metrics);

// Return dimensions
Result->cx = (LONG)(Metrics.width + 0.5f);
Result->cy = (LONG)FontHeight;
```

### Font Metrics Collection

`refterm_example_dwrite.cpp:104-169` - `IncludeLetterBounds()`
- Measures 'M' and 'g' characters for font dimensions
- Uses `DWRITE_TEXT_METRICS` and `DWRITE_LINE_METRICS`
- Computes maximum width/height across measured characters

### Direct2D Rendering

`refterm_example_dwrite.cpp:171-195` - `DWriteDrawText()`
```c
// Set transform for scaling
D2D1_MATRIX_3X2_F Transform = D2D1::Matrix3x2F::Scale(XScale, YScale);
RenderTarget->SetTransform(&Transform);

// Configure text rendering
RenderTarget->SetTextAntialiasMode(D2D1_TEXT_ANTIALIAS_MODE_GRAYSCALE);

// Draw text
RenderTarget->DrawTextLayout(
    D2D1::Point2F(0, 0),
    Layout,
    Brush,
    D2D1_DRAW_TEXT_OPTIONS_ENABLE_COLOR_FONT);
```

## Tile-Based Scaling System

### Scaling Algorithm

`refterm_example_glyph_generator.c:64-77`

For oversized glyphs:
```c
// Calculate tiles needed (with rounding)
TileCount = SafeRatio1((Size.cx + FontWidth/2), FontWidth);

// X scaling when glyph exceeds font width
if(Size.cx > FontWidth) {
    XScale = SafeRatio1((TileCount * FontWidth), Size.cx);
}

// Y scaling when glyph exceeds font height
if(Size.cy > FontHeight) {
    YScale = SafeRatio1(FontHeight, Size.cy);
}
```

### Multi-Tile Hash Generation

`refterm_example_source_buffer.c:240-254`
```c
// Generate derived hash for each tile
for(TileIndex = 0; TileIndex < TileCount; ++TileIndex) {
    glyph_hash TileHash;
    TileHash.Value = _mm_xor_si128(BaseHash.Value, _mm_set1_epi32(TileIndex));
    
    // 4 rounds of AES for uniqueness
    TileHash.Value = _mm_aesdec_si128(TileHash.Value, _mm_setzero_si128());
    TileHash.Value = _mm_aesdec_si128(TileHash.Value, _mm_setzero_si128());
    TileHash.Value = _mm_aesdec_si128(TileHash.Value, _mm_setzero_si128());
    TileHash.Value = _mm_aesdec_si128(TileHash.Value, _mm_setzero_si128());
}
```

## GPU Texture Management

### Transfer Buffer Configuration

`refterm_example_d3d11.c:217-238`
```c
D3D11_TEXTURE2D_DESC TransferDesc = {
    .Width = TransferWidth,
    .Height = TransferHeight,
    .MipLevels = 1,
    .ArraySize = 1,
    .Format = DXGI_FORMAT_B8G8R8A8_UNORM,
    .SampleDesc = { 1, 0 },
    .Usage = D3D11_USAGE_DEFAULT,
    .BindFlags = D3D11_BIND_SHADER_RESOURCE | D3D11_BIND_RENDER_TARGET,
};
```

The transfer buffer is dual-bound:
- **BIND_RENDER_TARGET**: For Direct2D rendering
- **BIND_SHADER_RESOURCE**: For GPU shader access

### DirectWrite Surface Integration

Transfer surface exposed as IDXGISurface for Direct2D:
```c
// Get DXGI surface for Direct2D
IDXGISurface *Surface;
ID3D11Texture2D_QueryInterface(TransferTexture, 
                               &IID_IDXGISurface, 
                               (void**)&Surface);

// Create Direct2D render target
D2DFactory->CreateDxgiSurfaceRenderTarget(
    Surface,
    &RenderTargetProps,
    &RenderTarget);
```

## Performance Bottlenecks

### Identified Issues

1. **DirectWrite Performance**: ~100x slower than optimal
2. **Batching Ineffectiveness**: Only 2x speedup from batching attempts
3. **Draw-then-Transfer Pattern**: Inefficient per-glyph rendering
4. **Windows API Limitations**: Fundamental architectural constraints

### Performance Measurements

From cache statistics:
- **Cache hit rate**: >99% after warmup
- **Rasterization cost**: "Two orders of magnitude" too slow
- **Effective performance**: Acceptable only due to caching

## Error Handling

### DirectWrite Failures

`refterm_example_dwrite.cpp:190-194`
```c
HRESULT Error = RenderTarget->EndDraw();
if(!SUCCEEDED(Error)) {
    Assert(!"EndDraw failed");
}
```

### Size Overflow Handling

`refterm_example_glyph_generator.c:114-117`
> "At the moment, we do not do anything to fix the problem of trying to set the font size so large that it cannot be rasterized into the transfer buffer."

This is an acknowledged limitation requiring future work.

### Resource Creation

Functions return 0/NULL on failure, allowing graceful degradation.

## Configuration and Tuning

### Font Properties
- **Weight**: `DWRITE_FONT_WEIGHT_REGULAR`
- **Style**: `DWRITE_FONT_STYLE_NORMAL`
- **Stretch**: `DWRITE_FONT_STRETCH_NORMAL`
- **Locale**: "en-us" (hardcoded)

### Alignment Settings
- **Paragraph**: `DWRITE_PARAGRAPH_ALIGNMENT_NEAR`
- **Text**: `DWRITE_TEXT_ALIGNMENT_LEADING`

### Rendering Mode
- **Antialiasing**: `D2D1_TEXT_ANTIALIAS_MODE_GRAYSCALE`
- **Color fonts**: Enabled via `D2D1_DRAW_TEXT_OPTIONS_ENABLE_COLOR_FONT`

## Integration Points

### Glyph Cache Integration
The generator works with the cache to:
- Provide glyph dimensions for allocation
- Render glyphs on cache misses
- Update cache entries with rasterized data

### Terminal Buffer Integration
Text processing triggers:
- Glyph dimension queries
- Rasterization requests
- Multi-tile handling for complex glyphs

## Design Philosophy

The Glyph Generator Interface demonstrates:
- **Pragmatic workarounds**: C wrapper for C++ API
- **Performance awareness**: Acknowledges and documents limitations
- **Clean separation**: Isolates platform-specific code
- **Future-looking design**: Author plans custom rasterizer

Despite DirectWrite's severe performance limitations, the combination of intelligent caching and optimized text processing enables RefTerm to achieve excellent real-world performance. The author's frustration with Windows font APIs is evident throughout the code, with multiple TODOs indicating plans for a custom rasterization solution.