;*****************************************
; Title: Boot sector
; Desc: loads the main program within one sector.
; Location: src/bootsector.asm
;*****************************************

[bits 16]
[org 0x7c00]

; Normal BPB
JMP_CODE: db 0, 0, 0
OEM_IDENT: db "OEMIDENT"
BYTES_PER_SECTOR: dw 0
SECTORS_PER_CLUSTER: db 0
RESERVED_SECTORS: dw 0
AMOUNT_OF_FATS: db 0
AMOUNT_OF_ROOT_DIRECTORIES: dw 0
SECTORS_IN_LOGICAL_VOLUME: dw 0
MEDIA_DESCRIPTOR_TYPE: db 0
FAT_12_16_RESERVED: dw 0
SECTORS_PER_TRACT: dw 0
HEADS_ON_TRACT: dw 0
HIDDEN_SECTORS: dd 0
LARGE_SECTOR_COUNT: dd 0

; FAT32 BPB
SECTORS_PER_FAT: dd 0
FAT_FLAGS: dw 0
FAT_VERSION: dw 0
CLUSTER_ROOT_NUMBER: dd 0
FS_INFO_LOCATION: dw 0
BACKUP_BOOT_SECTOR_LOCATION: dw 0
FAT_RESERVED: db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
DRIVE_NUMBER: db 0
WINDOWS_NT_FLAGS: db 0
SIGNATURE: db 0
VOLUME_ID: dd 0
VOLUME_SERIAL: db "           "
INDENTIFIER: db "        "

times 0x5A - ($ - $$) db 0

Start:
    ; Sets segment registers
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; Put the cluster size as sector count
    mov al, [SECTORS_PER_CLUSTER]
    mov [SECTOR_SIZE_DAP], ax

    ; Get the first root directory
    call Calculate_Root_Sector
    mov [SECTOR_SIZE_LOW_DAP_A], eax

    ; Load the first directory
    mov ah, 0x42
    mov dl, [DRIVE_NUMBER]
    mov si, DAP
    int 0x13

    ; Set to the next entry
    mov ax, [Memory_Pointer]
    add ax, 0x20
    mov [Memory_Pointer], ax

; Find the root folder
Phase_1_ROOT:
    mov si, ROOT
    call Find_File

    mov ah, 0x42
    mov dl, [DRIVE_NUMBER]
    mov si, DAP
    int 0x13

; Find the system folder
Phase_2_SYSTEM:
    mov si, SYSTEM
    call Find_File

    mov ah, 0x42
    mov dl, [DRIVE_NUMBER]
    mov si, DAP
    int 0x13

; Find the boot manager
Phase_3_BOOTMG:
    mov si, FILE
    call Find_File

    xor ax, ax
    mov al, 0x40
    mov [SECTOR_SIZE_DAP], ax

    mov ax, 0x7e00
    mov [MEMORY_LOCATION_DAP], ax

    mov ah, 0x42
    mov dl, [DRIVE_NUMBER]
    mov si, DAP
    int 0x13

; Load to the boot manager
Phase_4_LOADING:
    mov ax, 0xDEED
    mov ebx, [SECTOR_SIZE_LOW_DAP_A]
    jmp 0x7e00

; Gets the first boot directory
; Out:
; - ax, location of the first directory
Calculate_Root_Sector:
    push dx
    xor dx, dx
    mov ax, [SECTORS_PER_FAT]
    mov dl, [AMOUNT_OF_FATS]
    mul dx
    xor dx, dx

    mov dx, [RESERVED_SECTORS]
    add ax, dx
    pop dx
    ret

; Converts clusters to sectors
; Inp:
; - ax, clusters
; Out:
; - ax, sectors
Cluster_To_Sector:
    push dx
    xor dx, dx
    sub ax, 2
    mov dl, [SECTORS_PER_CLUSTER]
    mul dx
    pop dx
    ret

; Finds specified files within a directory
; Inp:
; - si, name
Find_File:
    .Loop:
        cmp ax, 0xFF00
        je Crash

        mov ax, [Memory_Pointer]
        mov di, ax

        call Compare_Name

        cmp dl, 1
        je .Found

        add ax, 0x20
        mov [Memory_Pointer], ax
        jmp .Loop

    .Found:
        mov bx, ax
        add bx, 26
        mov ax, [bx]
        mov cx, bx

        call Cluster_To_Sector
        mov bx, ax

        call Calculate_Root_Sector
        add ax, bx
        mov [SECTOR_SIZE_LOW_DAP_A], ax

        sub cx, 6
        mov bx, cx
        mov ax, [bx]

        call Cluster_To_Sector
        mov bx, ax

        call Calculate_Root_Sector
        add ax, bx
        ret
        
; Compares two strings
; Inp:
; - si, string a
; - di, string b
; Out:
; - dx, is equal
Compare_Name:
    push ax
    xor cx, cx
    xor dx, dx

    .Loop:
        mov bx, cx
        mov al, [si + bx]
        mov ah, [di + bx]
        
        cmp al, ah
        jne .Return

        cmp cx, 10
        je .Pass

        inc cx
        jmp .Loop

    .Pass:
        inc dx
    .Return:
        pop ax
        ret

; Prints an error message
Crash:
    mov si, Error_Message
    mov ah, 0x0E
    .Loop:
        lodsb

        cmp al, 0x00
        je .Ret

        int 0x10
        jmp .Loop
    .Ret:
        jmp $

ROOT    db      "ROOT       "
SYSTEM  db      "SYSTEM     "
FILE    db      "BOOTMAN BIN"

Error_Message db "The boot manager couldn't be loaded to memory.", 0x00

times 492 - ($ - $$) db 0

Memory_Pointer: dw 0x1000

DAP: db 0x10
RESERVED_DAP: db 0
SECTOR_SIZE_DAP: dw 1
MEMORY_LOCATION_DAP: dd 0x1000
SECTOR_SIZE_LOW_DAP_A: dw 0
SECTOR_SIZE_LOW_DAP_B: dw 0
SECTOR_SIZE_HIGH_DAP: dd 0

dw 0xAA55