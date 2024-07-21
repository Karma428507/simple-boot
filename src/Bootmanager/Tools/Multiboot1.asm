;*****************************************
; Title: Multiboot1
; Desc: Loads the multiboot1 table with provided information
; Location: src/Bootmanager/Tools/Mulitboot1.asm
;*****************************************

MULTIBOOT1_INFO:
    .FLAGS: dd 0x00000000
    
    .MEM_LOWER: dd 0x00000000
    .MEM_UPPER: dd 0x00000000

    .BOOT_DEVICE: dd 0x00000000

    .CMD_LINE: dd 0x00000000

    .MOD_COUNT: dd 0x00000000
    .MOD_ADDRESS: dd 0x00000000

    .SYSM:
        dd 0x00000000
        dd 0x00000000
        dd 0x00000000
        dd 0x00000000

    .MEMMAP_LENGTH: dd 0x00000000
    .MEMMAP_ADDRESS: dd 0x00000000

    .DRIVES_LENGTH: dd 0x00000000
    .DRIVES_ADDRESS: dd 0x00000000

    .CONFIG_TABLE: dd 0x00000000

    .BOOT_LOADER_NAME: dd 0x00000000

    .AMP_TABLE: dd 0x00000000

    .VBE_Control_Info: dd 0x00000000
    .VBE_Mode_Info: dd 0x00000000
    .VBE_Mode: dw 0x0000
    .VBE_Interface_Segment: dw 0x0000
    .VBE_Interface_Offset: dw 0x0000
    .VBE_Interface_Length: dw 0x0000

    .Framebuffer_Address: dd 0x00000000
    .Framebuffer_Pitch: dd 0x00000000
    .Framebuffer_Width: dd 0x00000000
    .Framebuffer_Height: dd 0x00000000
    .Framebuffer_BPP: db 0x00
    .Framebuffer_Type: db 0x00
    .Framebuffer_Color_Info: times 6 db 0x00

MULTIBOOT1_LOAD:
    ; Flags

    mov eax, 0b0001000000010
    or al, [BIOS_DATA_TABLE.FLAGS]
    mov [MULTIBOOT1_INFO.FLAGS], eax

    ; Load Upper and Lower mem
    mov ax, [BIOS_DATA_TABLE.LOWER]
    mov [MULTIBOOT1_INFO.MEM_LOWER], ax
    mov ax, [BIOS_DATA_TABLE.UPPER]
    mov [MULTIBOOT1_INFO.MEM_UPPER], ax

    ; Boot device
    mov eax, [BPB_FAT32_DRIVE_NUMBER]
    shl eax, 24
    or eax, 0xFFFFFF
    mov [MULTIBOOT1_INFO.BOOT_DEVICE], eax
    
    ; Mem address
    mov eax, [BIOS_DATA_TABLE.E820_TOTAL]
    mov [MULTIBOOT1_INFO.MEMMAP_LENGTH], eax
    mov dword [MULTIBOOT1_INFO.MEMMAP_ADDRESS], BIOS_E820_STORAGE

    ; Bootloader name
    mov dword [MULTIBOOT1_INFO.BOOT_LOADER_NAME], SHELL_OS_SELECT_A

    ; VBE info
    mov dword [MULTIBOOT1_INFO.VBE_Control_Info], VBE_CONTROL_INFO
    mov dword [MULTIBOOT1_INFO.VBE_Mode_Info], VBE_MODE_INFO
    mov ax, [BIOS_DATA_TABLE.VBE_MODE]
    mov [MULTIBOOT1_INFO.VBE_Mode], ax

    ; Framebuffer info
    mov eax, [VBE_MODE_INFO.Framebuffer]
    test eax, eax
    jz .NoFramebuffer

    mov [MULTIBOOT1_INFO.Framebuffer_Address], eax

    mov eax, [MULTIBOOT1_INFO.FLAGS]
    or eax, 1<<12
    mov [MULTIBOOT1_INFO.FLAGS], eax

    .NoFramebuffer:
    ret