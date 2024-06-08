;*****************************************
; Title: Paging
; Desc: Enables paging for 32 or 64 bits
; Location: src/Bootmanager/Paging.asm
;*****************************************

; Loads and enables paging for 32 bits
Paging_32:
    mov ecx, 1024

    .Directory_Loop:
        mov dword [PAGING_ADDRESS + ecx * 4], 2
        loop .Directory_Loop

    xor ebx, ebx
    mov ecx, 1024

    .Kernel_Page_Loop:
        dec ecx
        mov eax, ecx
        mov edx, 0x1000
        mul edx
        or eax, 3

        add eax, ebx
        mov [PAGING_ADDRESS + 0x1000 + ecx * 4], eax
        inc ecx
        loop .Kernel_Page_Loop

    mov ebx, 0x400000
    mov ecx, 1023

    .Mapping_Page_Loop:
        dec ecx
        mov eax, ecx
        mov edx, 0x1000
        mul edx
        or eax, 3

        add eax, ebx
        mov [PAGING_ADDRESS + 0x2000 + ecx * 4], eax
        inc ecx
        loop .Mapping_Page_Loop

    mov eax, PAGING_ADDRESS + 0x1000 | 3
    mov [PAGING_ADDRESS], eax
    mov eax, PAGING_ADDRESS + 0x2000 | 3
    mov [PAGING_ADDRESS + 4], eax

    mov eax, PAGING_ADDRESS
    mov cr3, eax

    mov eax, cr4
    or eax, 0x00000010
    mov cr4, eax ; Uncomment to make it from 4kb to 4mb

    mov eax, cr0
    or eax, 1<<31
    mov cr0, eax
    ret

; Loads paging for 64 bits
Paging_64:
    ; Clear the tables
    mov edi, 0x30000
    mov cr3, edi
    xor eax, eax
    mov ecx, 4096
    rep stosd
    mov edi, cr3

    ; Make level 4 paging point to the PDPT
    mov DWORD [edi], 0x31003
    add edi, 0x1000
    mov DWORD [edi], 0x32003
    add edi, 0x1000
    mov DWORD [edi], 0x33003
    add edi, 0x08
    mov DWORD [edi], 0x34003
    add edi, 0x08
    mov DWORD [edi], 0x35003
    mov edi, 0x33000

    ; For the first mb
    mov ebx, 0x00000003
    mov ecx, 512
    .Main_Page:
        mov DWORD [edi], ebx
        add ebx, 0x1000
        add edi, 8
        loop .Main_Page

    ; Where the kernel is located
    mov ebx, 0x00200003
    mov ecx, 512
    .Kernel_Page:
        mov DWORD [edi], ebx
        add ebx, 0x1000
        add edi, 8
        loop .Kernel_Page

    ; Extra space for mapping
    mov ebx, 0x00400003
    mov ecx, 512
    .Mapping_Page:
        mov DWORD [edi], ebx
        add ebx, 0x1000
        add edi, 8
        loop .Mapping_Page

    ; Enable PAE
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax
    ret