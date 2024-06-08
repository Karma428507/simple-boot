Set_Multiboot_Info:
    call E820_Loader
    test eax, eax
    jz .E820_Missing
    cmp si, 32
    jge .E820_Entry_Oversized
    jmp .Extra_Memory_Segments

    .E820_Missing:
        mov si, MEMORY_E820_MISSING
        call Print_16
        jmp $

    .E820_Entry_Oversized:
        mov si, MEMORY_E820_OVERFLOW
        call Print_16
        jmp $

    .Extra_Memory_Segments:
        call Get_Total_Memory
        mov [BOOT_INFO.MEMORY_SIZE_USABLE], eax
        mov [BOOT_INFO.MEMORY_SIZE_RESERVED], ebx
        add eax, ebx
        mov [BOOT_INFO.MEMORY_SIZE], eax

        call Get_Extented_Memory
        mov [BOOT_INFO.MEMORY_EXTENTION], eax

Get_Extented_Memory:
    mov ah, 0x88
    int 0x15
    ret

E820_Loader:
    xor si, si
    mov eax, 0xE820
    xor ebx, ebx
    mov ecx, 24
    mov edx, [MEMORY_E820_VERIFY]
    mov di, BOOT_INFO.MEMORY_E820_STORAGE
    int 0x15

    jc .Fail
    mov edx, [MEMORY_E820_VERIFY]
    cmp eax, edx
    jne .Fail
    test ebx, ebx
	je .Fail
    jmp .Add_Entry

    .Loop:
        mov eax, 0xE820
        mov [es:di + 20], dword 1
        mov ecx, 24
        mov edx, [MEMORY_E820_VERIFY]
        int 0x15

        jc .End
        mov edx, [MEMORY_E820_VERIFY]
        
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
        inc si
        add di, 24
    
    .Nullify_Entry:
        test ebx, ebx
        jne .Loop

    .End:
        mov [BOOT_INFO.MEMORY_E820_ENTRIES], si
        mov eax, 1
        ret

    .Fail:
        xor eax, eax
        ret

; This will be fun.
Continuous_Memory_Mapper:
    xor esi, esi
    mov cx, 1

    mov edi, [BOOT_INFO.MEMORY_E820_STORAGE + E820_MEMORY_MAP.ADDRESS_LOW]
    mov esi, edi
    mov edi, [BOOT_INFO.MEMORY_E820_STORAGE + E820_MEMORY_MAP.SIZE_LOW]
    add esi, edi

    .Loop_Entries:
        mov ax, 24
        mov dx, cx
        mul dx
        mov bx, ax

        call .Compare_Entry
        
        mov dx, [BOOT_INFO.MEMORY_E820_ENTRIES]
        cmp cx, dx
        jge .End

        inc cx
        jmp .Loop_Entries

    .Compare_Entry:
        mov edi, [BOOT_INFO.MEMORY_E820_STORAGE + bx + E820_MEMORY_MAP.ADDRESS_LOW]
        cmp esi, edi
        jne .End

        mov esi, edi
        mov edi, [BOOT_INFO.MEMORY_E820_STORAGE + bx + E820_MEMORY_MAP.SIZE_LOW]
        add esi, edi

        ret

    .End:
        mov eax, esi
        ret

Get_Total_Memory_USABLE dd 0x00
Get_Total_Memory_RESERVED dd 0x00
Get_Total_Memory:
    xor cx, cx

    .Loop_Entries:
        mov ax, 24
        mov dx, cx
        mul dx
        mov bx, ax

        call .Check_Type
        
        mov dx, [BOOT_INFO.MEMORY_E820_ENTRIES]
        cmp cx, dx
        jge .End

        inc cx
        jmp .Loop_Entries

    .End:
        mov eax, [Get_Total_Memory_USABLE]
        mov ebx, [Get_Total_Memory_RESERVED]
        ret

    .Check_Type:
        mov al, [BOOT_INFO.MEMORY_E820_STORAGE + bx + E820_MEMORY_MAP.TYPE]
        cmp al, 1
        je .Is_Usable

        mov eax, [Get_Total_Memory_RESERVED]
        mov edx, [BOOT_INFO.MEMORY_E820_STORAGE + bx + E820_MEMORY_MAP.SIZE_LOW]
        add eax, edx
        mov [Get_Total_Memory_RESERVED], eax
        ret

    .Is_Usable:
        mov eax, [Get_Total_Memory_USABLE]
        mov edx, [BOOT_INFO.MEMORY_E820_STORAGE + bx + E820_MEMORY_MAP.SIZE_LOW]
        add eax, edx
        mov [Get_Total_Memory_USABLE], eax
        ret