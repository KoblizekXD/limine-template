#include <stdint.h>
#include <sys/util.h>

void outb(uint16_t port, uint8_t c)
{
    asm(
        "out %0, %1"
        : 
        : "a"(c), "Nd"(port)
    );
}

uint8_t inb(uint16_t port)
{
    uint8_t value;
    asm(
        "in %1, %0"
        : "=a"(value) : "Nd"(port)
    );
    return value;
}

