BITS 32
extern main

section .text
    global _start

_start:
    mov esp, 0x90000

    push ebx
    call main
    jmp $