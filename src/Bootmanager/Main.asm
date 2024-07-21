;*****************************************
; Title: Main program
; Desc: The main program that sets up everything
; Location: src/Bootmanager/Main.asm
;*****************************************

[bits 16]
[org 0x7e00]

%include "src/Bootmanager/Data/Defines.asm"

; Checks signature and continues
Start:
    ; Check signature
    cmp ax, 0xDEED
    je Signature_Pass

    mov si, STAGE_A_FAILED_SIGNATURE
    call Print_16

    cli
    hlt

; Sets up stack
Signature_Pass:
    ; Setup the stack
    mov bp, 0x9000
    mov sp, bp

; Copy BPB data
Set_BPB:
    pusha
    xor bx, bx

    .Loop:
        cmp bx, 90
        je .Ret

        mov al, [0x7c00 + bx]
        mov [BPB_JMP_CODE + bx], al

        inc bx
        jmp .Loop

    .Ret:
        popa

; Loads the rest of the manager
Load_Rest:
    add ebx, 0x20
    mov [DAP_Structure.LOWER], ebx

    mov ah, 0x42
    mov dl, [BPB_FAT32_DRIVE_NUMBER]
    mov si, DAP_Structure
    int 0x13

Setup_Multiboot_BIOS:
    call Load_1MB_Memory
    call E820_Loader
    call VBE_Setup

; Loads the screen
Screen_Init:
    ; Setup screen
    mov ah, 0x00
    mov al, 0x03
    int 0x10

    ; Disable Cursor
    mov dx, 0x3D4
    mov al, 0xA
    out dx, al
    inc dx
    mov al, 0x20
    out dx, al

    jmp Decide_Mode

; Enables A20
Check_A20:
    in al, 0x92
    or al, 2
    out 0x92, al

; Loads protected mode
Decide_Mode:
    cli
    lgdt [GDT_32_DESCRIPTOR]

    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    jmp CODE_32_SEG:Protected_Mode_Entry

%include "src/Bootmanager/Real/Memory.asm"
%include "src/Bootmanager/Real/String_16.asm"
%include "src/Bootmanager/Real/Text.asm"
%include "src/Bootmanager/Real/Video.asm"

; Setup segments and jump into the main part of the manager
[bits 32]
Protected_Mode_Entry:
    ; Set up segments
    mov ax, DATA_32_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; Set up stack
    mov ebp, 0x90000
    mov esp, ebp

    jmp 0x10000

DAP_Structure:
    .SIZE       db 0x10
    .RESERVED   db 0x00
    .SECTORS    dw 0x7F
    .BUFFER     dd 0x10000000
    .LOWER      dd 0x00
    .HIGHER     dd 0x00

BIOS_DATA_TABLE:
    .LOWER: dd 0x00000000
    .UPPER: dd 0x00000000
    .E820_TOTAL: dd 0x00000000
    .VBE_MODE: dw 0x0000
    .FLAGS: db 0b01000001

%include "src/Bootmanager/Data/BPB.asm"
%include "src/Bootmanager/Data/GDT.asm"

times (512 * 0x06) - ($ - $$) db 0

VBE_MODE_INFO:
    .Attributes:                dw 0x0000
    .OLD_Window_A:              db 0x00
    .OLD_Window_B:              db 0x00
    .OLD_Grandularity:          dw 0x0000
    .Window_Size:               dw 0x0000
    .Segment_A:                 dw 0x0000
    .Segment_B:                 dw 0x0000
    .OLD_Win_Func_Ptr:          dd 0x00000000
    .Pitch:                     dw 0x0000
    .Width:                     dw 0x0000
    .Height:                    dw 0x0000
    .UNUSED_W_Char:             db 0x00
    .UNUSED_Y_Char:             db 0x00
    .Planes:                    db 0x00
    .BPP:                       db 0x00
    .OLD_Banks:                 db 0x00
    .Memory_Model:              db 0x00
    .OLD_Bank_Size:             db 0x00
    .Image_Pages:               db 0x00
    .Reserved0:                 db 0x00
    .Red_Mask:                  db 0x00
    .Red_Position:              db 0x00
    .Green_Mask:                db 0x00
    .Green_Position:            db 0x00
    .Blue_Mask:                 db 0x00
    .Blue_Position:             db 0x00
    .Reserved_Mask:             db 0x00
    .Reserved_Position:         db 0x00
    .Direct_Color_Attributes:   db 0x00
    .Framebuffer:               dd 0x00000000
    .Off_Screen_Memory_Offset:  dd 0x00000000
    .Off_Screen_Memory_Size:    dw 0x0000
    .Reserved1:                 times 206 db 0x00
    
VBE_CONTROL_INFO:
    .Signature:                 db "VESA"
    .Version:                   dw 0x0000
    .OEM_String:                dd 0x00000000
    .Capabilities:              dd 0x00000000
    .Video_Modes:               dd 0x00000000
    .Total_Memories:            dw 0x0000
    .Reserved:                  times 492 db 0x00

BIOS_E820_STORAGE:

; Empty space for BIOS data
times (512 * 0x20) - ($ - $$) db 0
; A way for OSes to be reconized before adding JSON support
%include "src/CONFIG"

%macro OS_ENTRY_MACRO 1
    %%NAME_LENGTH:
    db OS_%1_NAME
    times 0x20 - ($ - %%NAME_LENGTH) db 0x00
    %%FILE_LENGTH:
    db OS_%1_FILE
    times 0x100 - ($ - %%FILE_LENGTH) db 0x00
%endmacro

; Loads the main stuff and goes into the shell
Init_Protected_Mode:
    %if TOTAL_ENTRIES == 0
        mov eax, SHELL_NO_OS_FOUND
        call Print_32
        jmp $
    %endif
    
    call Init_AHCI
    call Init_FAT32
    call Check_Long_Mode

    xor ecx, ecx

    .Entry_Loop:
        mov eax, 0x120
        mul ecx

        add eax, OS_ENTRIES
        call Add_Entries

        inc ecx
        cmp ecx, TOTAL_ENTRIES
        jl .Entry_Loop

    call MULTIBOOT1_LOAD
    call Shell
    jmp $

; Setup entries
OS_ENTRIES:
%assign i 1
%rep TOTAL_ENTRIES
OS_ENTRY_MACRO i
%assign i i+1
%endrep

; Checks if there's long mode
Check_Long_Mode:
    call Check_CPUID
    test eax, eax
    jz .NO_CPUID

    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jb .NO_LONG_MODE

    mov eax, 0x80000000
    cpuid
    cmp edx, 1 << 29
    jz .NO_LONG_MODE

    or ebx, 0x01
    mov [.ACTIVE], ebx
    ret

    .NO_CPUID:
        mov ebx, [.ACTIVE]
        or ebx, 0x02

    .NO_LONG_MODE:
        mov ebx, [.ACTIVE]
        or ebx, 0x04
        mov [.ACTIVE], ebx
        ret

    .ACTIVE: db 0x00

; Checks if CPUID is enabled
; Out:
; - eax, is enabled
Check_CPUID:
    pushad

    xor eax, eax
    cpuid

    cmp eax, 0
    je .Fail

    popad
    xor eax, eax
    inc eax
    ret

    .Fail:
        popad
        xor eax, eax
        ret

; Checks if MSR is enabled
; Out:
; - eax, is enabled
Check_MSR:
    pushad

    mov eax, 1
    cpuid
    and edx, CPUID_FEAT_EDX_MSR

    cmp edx, 0
    je .Fail

    popad
    xor eax, eax
    inc eax
    ret

    .Fail:
        popad
        xor eax, eax
        ret

; Goes into long mode
Protected_Mode_Enter_Long_Mode:
    call Paging_64

    ; Switch to long mode
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; Enable paging
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    ; Jump to the 64 bit entry
    lgdt [GDT_64_DESCRIPTOR]
    jmp CODE_64_SEG:Long_Mode_Entry

%include "src/Bootmanager/Drivers/AHCI.asm"
%include "src/Bootmanager/Drivers/PCI.asm"
%include "src/Bootmanager/Drivers/Keyboard.asm"
%include "src/Bootmanager/FileTypes/Executable.asm"
%include "src/Bootmanager/Tools/Console.asm"
%include "src/Bootmanager/Tools/Entries.asm"
%include "src/Bootmanager/Tools/Multiboot1.asm"
%include "src/Bootmanager/Tools/String_32.asm"
%include "src/Bootmanager/FAT32.asm"
%include "src/Bootmanager/Paging.asm"
%include "src/Bootmanager/Shell.asm"

; Long Mode
[bits 64]
Long_Mode_Entry:
    cli
    mov ax, DATA_64_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov rbx, MULTIBOOT1_INFO
    mov rax, [Elf64_Jump.ENTRY_POINT]
    jmp rax

    .LONG_MODE_SIGNATURE: db "SMPLBOOT"

%include "src/Bootmanager/Data/Structures.asm"
%include "src/Bootmanager/Data/Text.asm"
times (512 * (0x7F + 0x40)) - ($ - $$) db 0