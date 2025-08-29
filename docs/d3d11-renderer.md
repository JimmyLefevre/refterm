# D3D11 Renderer Interface

The D3D11 Renderer Interface provides hardware-accelerated terminal rendering through Direct3D 11, implementing a dual-pipeline architecture supporting both traditional rasterization and compute shaders for optimal GPU utilization.

## Architecture Overview

### Dual Pipeline Support
- **Traditional Rasterization**: Vertex shader + pixel shader pipeline
- **Compute Shader Path**: Direct compute shader rendering
- **Fullscreen Quad Generation**: Vertex buffer-free rendering technique
- **Structured Buffer Design**: 12 bytes per terminal cell
- **Glyph Atlas**: 2048x2048 texture for glyph storage
- **Thread Groups**: 8x8 compute threads for optimal GPU occupancy

## Implementation Details

### D3D11 Initialization

`refterm_example_d3d11.c:283-338`

Device creation with hardware fallback:
```c
// Try hardware first, fall back to WARP if necessary
HRESULT hr = D3D11CreateDevice(0, D3D_DRIVER_TYPE_HARDWARE, 0, Flags, 
                               Levels, ARRAYSIZE(Levels), D3D11_SDK_VERSION,
                               &Result.Device, 0, &Result.DeviceContext);
if(FAILED(hr)) {
    hr = D3D11CreateDevice(0, D3D_DRIVER_TYPE_WARP, 0, Flags, 
                           Levels, ARRAYSIZE(Levels), D3D11_SDK_VERSION,
                           &Result.Device, 0, &Result.DeviceContext);
}
```

### Swap Chain Configuration

`refterm_example_d3d11.c:66-81`
```c
DXGI_SWAP_CHAIN_DESC1 SwapChainDesc = {
    .Format = DXGI_FORMAT_B8G8R8A8_UNORM,
    .SampleDesc = {1, 0},
    .BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT,
    .BufferCount = 2,
    .SwapEffect = DXGI_SWAP_EFFECT_FLIP_DISCARD,
    .Scaling = DXGI_SCALING_NONE,
    .AlphaMode = DXGI_ALPHA_MODE_IGNORE,
    .Flags = DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT,
};
```

Key features:
- **Flip model presentation** for reduced latency
- **Frame latency waitable object** for smooth frame pacing
- **No scaling** for pixel-perfect rendering

## Shader Implementation

### Compute Shader

`refterm.hlsl:108-113`
```hlsl
[numthreads(8, 8, 1)]
void ComputeMain(uint3 Id: SV_DispatchThreadID)
{
    uint2 ScreenPos = Id.xy;
    Output[ScreenPos] = ComputeOutputColor(ScreenPos);
}
```

Thread group configuration:
- **8x8 threads** per group (64 threads total)
- Matches warp/wavefront sizes (32 on NVIDIA, 64 on AMD)
- Ensures aligned memory access patterns

### Traditional Rasterization Pipeline

Vertex Shader - Fullscreen Quad Generation:
`refterm.hlsl:91-94`
```hlsl
float4 VertexMain(uint vI : SV_VERTEXID):SV_POSITION {
    return float4(2.0*(float(vI&1) - 0.5), -(float(vI>>1) - 0.5)*2.0, 0, 1);
}
```

This innovative technique generates a fullscreen quad without vertex buffers:
- Vertex 0 (vI=0): (-1, 1) - top-left
- Vertex 1 (vI=1): (1, 1) - top-right
- Vertex 2 (vI=2): (-1, -1) - bottom-left
- Vertex 3 (vI=3): (1, -1) - bottom-right

Pixel Shader:
`refterm.hlsl:96-99`
```hlsl
float4 PixelMain(float4 ScreenPos:SV_POSITION):SV_TARGET
{
    return ComputeOutputColor(ScreenPos);
}
```

## Structured Buffer Layout

### CPU-Side Cell Structure
`refterm_example_d3d11.h:15-20`
```c
typedef struct {
    uint32_t GlyphIndex;    // Packed Y.X coordinates (16.16)
    uint32_t Foreground;    // Color + flags in high bits
    uint32_t Background;    // Color + blink flag in bit 31
} renderer_cell;
```

### GPU-Side Cell Structure
`refterm.hlsl:1-6`
```hlsl
struct TerminalCell {
    uint GlyphIndex;
    uint Foreground;
    uint Background;
};
```

### Buffer Configuration
`refterm_example_d3d11.c:122-130`
```c
D3D11_BUFFER_DESC CellBufferDesc = {
    .ByteWidth = Count * sizeof(renderer_cell),
    .Usage = D3D11_USAGE_DYNAMIC,
    .BindFlags = D3D11_BIND_SHADER_RESOURCE,
    .CPUAccessFlags = D3D11_CPU_ACCESS_WRITE,
    .MiscFlags = D3D11_RESOURCE_MISC_BUFFER_STRUCTURED,
    .StructureByteStride = sizeof(renderer_cell),
};
```

### Flag Encoding
`refterm.hlsl:63-74`
- Bit 28: Blinking
- Bit 25: Dim
- Bit 27: Underline
- Bit 31: Strikethrough

## Glyph Atlas Management

### Texture Creation
`refterm_example_d3d11.c:192-208`
```c
D3D11_TEXTURE2D_DESC TextureDesc = {
    .Width = Width,           // Typically 2048
    .Height = Height,         // Typically 2048
    .MipLevels = 1,
    .ArraySize = 1,
    .Format = DXGI_FORMAT_B8G8R8A8_UNORM,
    .SampleDesc = { 1, 0 },
    .Usage = D3D11_USAGE_DEFAULT,
    .BindFlags = D3D11_BIND_SHADER_RESOURCE,
};
```

### Glyph Index Packing
`refterm.hlsl:34-39`
```hlsl
uint2 UnpackGlyphXY(uint GlyphIndex) {
    int x = (GlyphIndex & 0xffff);
    int y = (GlyphIndex >> 16);
    return uint2(x, y);
}
```

The 32-bit GlyphIndex encodes:
- Low 16 bits: X coordinate in atlas
- High 16 bits: Y coordinate in atlas

## Render Pipeline Configuration

### Compute Shader Path
`refterm_example_d3d11.c:441-448`
```c
// Set resources
ID3D11DeviceContext_CSSetConstantBuffers(DeviceContext, 0, 1, &ConstantBuffer);
ID3D11DeviceContext_CSSetShaderResources(DeviceContext, 0, ARRAYSIZE(Resources), Resources);
ID3D11DeviceContext_CSSetUnorderedAccessViews(DeviceContext, 0, 1, &RenderView, NULL);
ID3D11DeviceContext_CSSetShader(DeviceContext, ComputeShader, 0, 0);

// Dispatch thread groups
ID3D11DeviceContext_Dispatch(DeviceContext, 
    (Width + 7) / 8,    // X thread groups
    (Height + 7) / 8,   // Y thread groups
    1);                 // Z thread groups
```

### Traditional Rasterization Path
`refterm_example_d3d11.c:453-460`
```c
// Configure pipeline
ID3D11DeviceContext_OMSetRenderTargets(DeviceContext, 1, &RenderTarget, 0);
ID3D11DeviceContext_PSSetConstantBuffers(DeviceContext, 0, 1, &ConstantBuffer);
ID3D11DeviceContext_PSSetShaderResources(DeviceContext, 0, ARRAYSIZE(Resources), Resources);
ID3D11DeviceContext_VSSetShader(DeviceContext, VertexShader, 0, 0);
ID3D11DeviceContext_PSSetShader(DeviceContext, PixelShader, 0, 0);

// Draw fullscreen quad
ID3D11DeviceContext_Draw(DeviceContext, 4, 0);
```

## Performance Optimizations

### GPU Resource Management

Dynamic Buffer Strategy:
`refterm_example_d3d11.c:405,425`
```c
// Use WRITE_DISCARD to prevent GPU stalls
hr = ID3D11DeviceContext_Map(DeviceContext, 
                             (ID3D11Resource*)ConstantBuffer,
                             0, D3D11_MAP_WRITE_DISCARD, 0, &Mapped);
```

Key optimizations:
- **D3D11_MAP_WRITE_DISCARD**: Prevents GPU pipeline stalls
- **Structured buffers**: Efficient GPU memory access patterns
- **Buffer resizing**: Only when terminal dimensions change
- **Resource pooling**: Single allocator design minimizes allocations

### Memory Layout Optimization

The renderer maintains cache-friendly designs:
- Contiguous cell buffer for sequential access
- Aligned structures for SIMD operations
- Minimal GPU state changes between frames

### Shader Compilation

`build.bat:14-16`
```batch
fxc /T cs_5_0 /E ComputeMain /O3 /WX /Fh refterm_cs.h /Vn ReftermCSShaderBytes refterm.hlsl
fxc /T ps_5_0 /E PixelMain /O3 /WX /Fh refterm_ps.h /Vn ReftermPSShaderBytes refterm.hlsl
fxc /T vs_5_0 /E VertexMain /O3 /WX /Fh refterm_vs.h /Vn ReftermVSShaderBytes refterm.hlsl
```

Optimization flags:
- **/O3**: Maximum optimization level
- **/Qstrip_reflect**: Remove reflection data
- **/Qstrip_debug**: Remove debug information
- **/Qstrip_priv**: Remove private data

## Integration with Other Components

### Glyph Cache Integration
The renderer works closely with the glyph cache:
- Cache provides texture coordinates via GlyphIndex
- Renderer samples from glyph atlas texture
- Cache manages atlas space allocation

### Terminal Buffer Integration
The renderer consumes terminal cells:
- Receives updated cell buffer each frame
- Handles circular buffer reordering
- Maps cells to screen positions

## Configuration and Tuning

### Thread Group Sizing
The 8x8 thread group size is optimal for:
- Matching GPU architecture wave/warp sizes
- Minimizing thread divergence
- Ensuring coalesced memory access

### Atlas Dimensions
2048x2048 provides:
- Space for thousands of unique glyphs
- Power-of-2 dimensions for efficient GPU operations
- Balance between memory usage and capacity

### Buffer Management
Dynamic buffers with WRITE_DISCARD:
- Eliminates GPU stalls
- Enables CPU/GPU parallelism
- Minimizes synchronization overhead

## Design Philosophy

The D3D11 Renderer demonstrates sophisticated GPU programming:
- **Minimal abstraction**: Direct API usage for maximum control
- **Dual pipeline support**: Flexibility for different GPU architectures
- **Performance-first design**: Every decision optimizes throughput
- **Clean architecture**: Clear separation between rendering and logic

This renderer achieves performance that "embarrasses commercial terminals" through intelligent GPU utilization, efficient resource management, and careful optimization of the rendering pipeline.