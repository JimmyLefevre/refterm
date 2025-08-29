// Simple test program to directly test ParseWithKB function
#include <windows.h>
#include <stdio.h>
#include <stdint.h>

typedef struct {
    uint32_t Count;
    uint8_t *Data;
} buffer;

typedef struct {
    void *BreakState[100];
    DWORD SegP[1026];
    uint32_t SegmentCount;
} kb_partitioner;

typedef struct {
    int DebugHighlighting;
    kb_partitioner KBPartitioner;
} example_terminal;

void ParseWithKB(example_terminal *Terminal, buffer UTF8Range);

void AppendOutput(example_terminal *Terminal, char *Format, ...)
{
    va_list args;
    va_start(args, Format);
    vprintf(Format, args);
    va_end(args);
}

// Include the actual ParseWithKB implementation
// Note: This would need the actual function copied here or linked

int main()
{
    printf("=== ParseWithKB Debug Test ===\n\n");
    
    example_terminal Terminal = {0};
    Terminal.DebugHighlighting = 1;
    
    ZeroMemory(&Terminal.KBPartitioner, sizeof(kb_partitioner));
    
    printf("Test 1: Simple ASCII\n");
    printf("--------------------\n");
    char test1[] = "Hello World";
    buffer utf8_1 = { strlen(test1), (uint8_t*)test1 };
    ParseWithKB(&Terminal, utf8_1);
    printf("\n");
    
    printf("Test 2: Unicode Emoji\n");
    printf("---------------------\n");
    char test2[] = "Test 😀 emoji";
    buffer utf8_2 = { strlen(test2), (uint8_t*)test2 };
    ParseWithKB(&Terminal, utf8_2);
    printf("\n");
    
    printf("Test 3: RTL Arabic\n");
    printf("------------------\n");
    char test3[] = "مرحبا";
    buffer utf8_3 = { strlen(test3), (uint8_t*)test3 };
    ParseWithKB(&Terminal, utf8_3);
    printf("\n");
    
    printf("=== Tests Complete ===\n");
    
    return 0;
}