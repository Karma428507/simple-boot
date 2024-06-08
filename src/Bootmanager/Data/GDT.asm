GDT_32_START:
    dd 0x0
    dd 0x0

GDT_32_CODE:
    dw 0xffff
    dw 0x0
    db 0x0
    db 10011010b
    db 11001111b
    db 0x0

GDT_32_DATA:
    dw 0xffff
    dw 0x0
    db 0x0
    db 10010010b
    db 11001111b
    db 0x0

GDT_32_END:

GDT_32_DESCRIPTOR:
    dw GDT_32_END - GDT_32_START - 1
    dd GDT_32_START

CODE_32_SEG equ GDT_32_CODE - GDT_32_START
DATA_32_SEG equ GDT_32_DATA - GDT_32_START

GDT_64_START:
    dq 0x00

GDT_64_CODE:
    dd 0xFFFF
    db 0x0
    db 10011010b
    db 10101111b
    db 0x0

GDT_64_DATA:
    dd 0xFFFF
    db 0x0
    db 10010010b
    db 11001111b
    db 0x0

GDT_64_TSS:
    dd 0x00000068
    dd 0x00CF8900

GDT_64_END:

GDT_64_DESCRIPTOR:
    dw GDT_64_END - GDT_64_START - 1
    dq GDT_64_START

CODE_64_SEG equ GDT_64_CODE - GDT_64_START
DATA_64_SEG equ GDT_64_DATA - GDT_64_START
TSS_64_SEG  equ GDT_64_TSS  - GDT_64_START