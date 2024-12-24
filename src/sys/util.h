#ifndef _UTIL_H_
#define _UTIL_H_

#include <stdint.h>

void halt();
void outb(uint16_t port, uint8_t c);
uint8_t inb(uint16_t port);

#endif // _UTIL_H_
