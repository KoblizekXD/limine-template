#ifndef _SYS_CPUID_H_
#define _SYS_CPUID_H_

#include <stdint.h>

/* Checks if the CPUID instruction is supported by the CPU */
extern int cpuid_check();

/* Does a CPUID instruction */
void cpuid(uint32_t leaf, uint32_t subleaf, uint32_t *eax, uint32_t *ebx, uint32_t *ecx, uint32_t *edx);

#endif // _SYS_CPUID_H_
