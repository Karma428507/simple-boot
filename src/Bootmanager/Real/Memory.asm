;*****************************************
; Title: Memory Retriver
; Desc: Gets information from BIOS to provide memory information
; Location: src/Bootmanager/Real/Memory.asm
;*****************************************

Load_1MB_Memory:
    int 0x12
    jc .Fail
    mov [BIOS_DATA_TABLE.LOWER], ax

    mov ah, 0x88
    mov [BIOS_DATA_TABLE.UPPER], ax
    int 0x15
    jc .Fail
    ret

    .Fail:
        mov al, [BIOS_DATA_TABLE.FLAGS]
        xor al, 1
        mov [BIOS_DATA_TABLE.FLAGS], al
        ret

E820_Loader:
    mov di, BIOS_E820_STORAGE
    add di, 4
    
    xor si, si
    mov eax, 0xE820
    xor ebx, ebx
    mov ecx, 24
    mov edx, 0x0534D4150
    mov [es:di + 20], dword 1
    int 0x15

    jc .Fail
    mov edx, 0x0534D4150
    cmp eax, edx
    jne .Fail
    test ebx, ebx
	je .Fail
    jmp .Add_Entry

    .Loop:
        mov eax, 0xE820
        mov [es:di + 20], dword 1
        mov ecx, 24
        mov edx, 0x0534D4150
        int 0x15

        jc .End
        mov edx, 0x0534D4150
        
    .Add_Entry:
        test cx, cx
        jz .Nullify_Entry
        cmp cl, 20
        jbe .No_Text
        test byte [es:di + 20], 1
	    je .Nullify_Entry

    .No_Text:
        mov ecx, [es:di + 8]
        or ecx, [es:di + 12]
        jz .Nullify_Entry
        add si, 24
        add di, 24
    
    .Nullify_Entry:
        test ebx, ebx
        jne .Loop

    .End:
        mov [BIOS_DATA_TABLE.E820_TOTAL], si
        mov eax, 1
        ret

    .Fail:
        mov al, [BIOS_DATA_TABLE.FLAGS]
        xor al, 64
        mov [BIOS_DATA_TABLE.FLAGS], al
        ret