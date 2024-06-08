OS_LIST: times 5 * 0x9A db 0

; Size (0x9A)
OS_ENTRY:
    .NAME                   equ 0x00
    .MEMORY_MAX             equ 0x1D
    .FILES                  equ 0x22

OS_FILE: ; Size, 0x0F (0x78 for 8 entries)
    .FILE_NAME              equ 0x00
    .OFFSET                 equ 0x0B

BOOT_INFO:
    ; Header
    .SIGNATURE              db "BOOT"
    .SIZE_HEADER            dw BOOT_INFO - .MEMORY
    .SEGMENT_MEMORY_START   dd .MEMORY
    .SEGMENT_MEMORY_SIZE    dw .MEMORY - .MEMORY_END
    .SEGMENT_VIDEO_START    dd .VIDEO
    .SEGMENT_VIDEO_SIZE     dw .VIDEO - .VIDEO_END
    .SEGMENT_KERNEL_START   dd .KERNEL
    .SEGMENT_KERNEL_SIZE    dw .KERNEL - .KERNEL_END

    ; Memory Segment
    .MEMORY:
    .MEMORY_SIZE            dq 0x00
    .MEMORY_SIZE_USABLE     dq 0x00
    .MEMORY_SIZE_RESERVED   dq 0x00
    .MEMORY_EXTENTION       dd 0x00
    .MEMORY_E820_ENTRIES    dw 0x00
    .MEMORY_E820_STORAGE    times (24 * 32) db 0
    .MEMORY_END:

    ; Video
    .VIDEO:
    .VIDEO_END:

    ; Kernel (Work on if I add elf support)
    .KERNEL:
    .KERNEL_END:

E820_MEMORY_MAP:
    .ADDRESS_LOW            equ 0x00
    .ADDRESS_HIGH           equ 0x04
    .SIZE_LOW               equ 0x08
    .SIZE_HIGH              equ 0x0C
    .TYPE                   equ 0x10