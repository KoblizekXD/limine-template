#include <sys/cpuid.h>

void cpuid(uint32_t leaf, uint32_t subleaf, uint32_t *eax, uint32_t *ebx, uint32_t *ecx, uint32_t *edx) {
    uint64_t rax, rbx, rcx, rdx;
    asm volatile (
        "mov %4, %%rax\n\t"
        "mov %5, %%rcx\n\t"
        "cpuid\n\t"        
        "mov %%rax, %0\n\t"
        "mov %%rbx, %1\n\t"
        "mov %%rcx, %2\n\t"
        "mov %%rdx, %3\n\t"
        : "=r" (rax), "=r" (rbx), "=r" (rcx), "=r" (rdx)
        : "r" ((uint64_t)leaf), "r" ((uint64_t)subleaf)
        : "rax", "rbx", "rcx", "rdx"
    );
    if (eax) *eax = (uint32_t)rax;
    if (ebx) *ebx = (uint32_t)rbx;
    if (ecx) *ecx = (uint32_t)rcx;
    if (edx) *edx = (uint32_t)rdx;
}
