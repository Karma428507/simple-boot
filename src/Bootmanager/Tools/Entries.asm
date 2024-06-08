;*****************************************
; Title: String 32 bits
; Desc: String services
; Location: src/Bootmanager/Tools/String_32.asm
;*****************************************

; Ignore
Add_Entries:
    pushad
    popad
    ret

; Ignore
Add_Entries_Old:
    ;mov [.NAME], eax
    ;mov [.FILEPATH_NAME], ebx
    ;mov [.VIDEO_MODE], ecx
    ;mov [.MEMORY], edx

    ;xor eax, eax
    ;mov al, [OS_Entry_Index]
    ;cmp al, 0x20
    ;je .Return
    ;mov edx, 0x20
    ;mul edx

    ;mov ebx, [.NAME]
    ;mov [eax + OS_Entry.NAME], ebx
    ;mov ebx, [.FILEPATH_NAME]
    ;mov [eax + OS_Entry.FILE_LOCATION], ebx
    ;mov ebx, [.VIDEO_MODE]
    ;mov [eax + OS_Entry.VIDEO_MODE], ebx
    ;mov ebx, [.MEMORY]
    ;mov [eax + OS_Entry.MEMORY], ebx;

    ;mov al, [OS_Entry_Index]
    ;inc al
    ;mov [OS_Entry_Index], al

    .Return:
        xor eax, eax
        ret

    .Error_List_Overflow:
        mov eax, 0x01
        ret
    
    .Error_File_Missing:
        mov eax, 0x02
        ret

    .NAME: dd 0x00
    .FILEPATH_NAME: dd 0x00
    .VIDEO_MODE: dd 0x00
    .MEMORY: dd 0x00

; Prints information about the current entry
Print_Entry:
    ; Get entry index
    xor eax, eax
    mov al, [OS_Entry_Index]
    mov edx, 0x120
    mul edx
    mov ebx, eax
    add ebx, OS_ENTRIES

    ; Print file name
    mov eax, INFO_ENTRY_NAME
    call Print_32
    mov eax, ebx
    call Print_32
    call Next_Line_32

    ; Print file path
    mov eax, INFO_ENTRY_FILE
    call Print_32
    mov eax, ebx
    add eax, OS_ENTRIES_STRUCTURE.FILE_LOCATION
    call Print_32
    call Next_Line_32

    ; Check accessability
    mov eax, ebx
    add eax, OS_ENTRIES_STRUCTURE.FILE_LOCATION
    call Access_Entry

    ; Print bits
    mov eax, INFO_ENTRY_BITS
    call Print_32
    xor eax, eax
    mov al, [Access_Entry.BITS]
    call ITOA_32
    mov eax, ITOA_32_BUFFER
    call Print_32
    call Next_Line_32

    ; Print supportability
    mov eax, INFO_ENTRY_KERNEL_SUPPORT
    call Print_32
    mov eax, [Access_Entry.RETURN_CODE]
    cmp eax, 0x10
    jl .No_Issues

    mov eax, INFO_ENTRY_UNSUPPORTED
    call Print_32

    call .Print_Errors
    jmp .Display_Code

    .No_Issues:
        mov eax, INFO_ENTRY_SUPPORTED
        call Print_32

    .Display_Code:
    call Next_Line_32

    mov eax, INFO_ENTRY_KERNEL_CODE
    call Print_32
    mov eax, [Access_Entry.RETURN_CODE]
    call ITOX_32
    mov eax, ITOX_32_BUFFER
    call Print_32
    call Next_Line_32
    ret

    .Print_Errors:
        mov ebx, [Access_Entry.RETURN_CODE]

        test ebx, Entry_Code_Error_Corrupt
        jz .Not_Corrupt

        mov eax, INFO_ENTRY_KERNEL_CORRUPT
        call Next_Line_32
        call Print_32

    .Not_Corrupt:
        test ebx, Entry_Code_Error_Missing
        jz .Not_Missing

        mov eax, INFO_ENTRY_KERNEL_MISSING
        call Next_Line_32
        call Print_32

    .Not_Missing:
        test ebx, Entry_Code_Error_MZ
        jz .Not_MZ

        mov eax, INFO_ENTRY_KERNEL_MZ
        call Next_Line_32
        call Print_32

    .Not_MZ:
        test ebx, Entry_Code_Error_PE
        jz .Not_PE

        mov eax, INFO_ENTRY_KERNEL_PE
        call Next_Line_32
        call Print_32

    .Not_PE:
        test ebx, Entry_Code_Error_Longmode
        jz .Not_Longmode

        mov eax, INFO_ENTRY_KERNEL_LONGMODE
        call Next_Line_32
        call Print_32

    .Not_Longmode:
        ret

; Gets the entry to the left of the list (loops back when out of bounds)
Load_Entry_Left:
    mov al, [OS_Entry_Index]
    test al, al
    jz .Loop_Back

    dec al
    mov [OS_Entry_Index], al
    ret

    .Loop_Back:
        mov byte [OS_Entry_Index], TOTAL_ENTRIES - 1
        ret

; Gets the entry to the right of the list (loops back when out of bounds)
Load_Entry_Right:
    mov al, [OS_Entry_Index]
    cmp al, TOTAL_ENTRIES - 1
    je .Loop_Back

    inc al
    mov [OS_Entry_Index], al
    ret

    .Loop_Back:
        mov byte [OS_Entry_Index], 0x00
        ret

; Checks if the entry is accessable
; first 4 bits are information, rest are errors
Access_Entry:
    pushad
    mov byte [.BITS], 0x00
    mov dword [.RETURN_CODE], 0x00000000

    xor ecx, ecx

    .Wipe:
        mov dword [0x50000 + ecx], 0x00000000
        add ecx, 4
        cmp ecx, 0x200
        jge .Wipe

    mov edx, eax
    mov eax, 0x30000
    mov ebx, 0x50000
    mov ecx, 0x01
    call FAT32_Find_Path

    mov eax, 0x50000
    call Elf_Define_File

    cmp eax, 1
    je .ELF_32

    cmp eax, 2
    je .ELF_64

    mov eax, 0x50000
    call Check_Alt_Executable

    cmp eax, 1
    je .MZ

    cmp eax, 2
    je .PE

    mov eax, [0x50000]
    test eax, eax
    jz .FILE_MISSING

    ;mov eax, 

    jmp .FILE_CORRUPT

    .ELF_32:
        mov dword [.RETURN_CODE], Entry_Code_32_Bits
        mov byte [.BITS], 32
        jmp .RETURN

    .ELF_64:
        mov dword [.RETURN_CODE], Entry_Code_64_Bits
        mov byte [.BITS], 64

        ; Check if longmode is active
        call .Check_Longmode
        jmp .RETURN
        
    .FILE_CORRUPT:
        mov dword [.RETURN_CODE], Entry_Code_Error_Corrupt
        jmp .RETURN

    .FILE_MISSING:
        mov dword [.RETURN_CODE], Entry_Code_Error_Missing
        jmp .RETURN

    .MZ:
        mov dword [.RETURN_CODE], Entry_Code_Error_MZ
        mov byte [.BITS], 16
        jmp .RETURN

    .PE:
        mov dword [.RETURN_CODE], Entry_Code_Error_PE
        mov byte [.BITS], 32
        jmp .RETURN

    .RETURN:
        ; Check memory here
        popad
        ret

    .Check_Longmode:
        mov al, [Check_Long_Mode.ACTIVE]
        test al, al
        jnz .Longmode_Exists

        mov eax, [.RETURN_CODE]
        or eax, Entry_Code_Error_Longmode
        mov [.RETURN_CODE], eax
        ret

        .Longmode_Exists:
            ret

    .RETURN_CODE: dd 0x00000000
    .BITS: db 0x00

OS_Entry_Index: db 0x00