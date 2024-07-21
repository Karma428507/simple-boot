;*****************************************
; Title: Executables
; Desc: Executes ELF file types
; Location: src/Bootmanager/FileTypes/Executable.asm
;*****************************************

; Check for alt executable signatures
; Inp:
; - eax, address
; Out:
; - eax, type
Check_Alt_Executable:
    mov cx, [eax]
    mov bx, [FILE_FORMAT_MZ]
    cmp cx, bx
    je .MZ_Signature

    xor eax, eax
    ret

    .MZ_Signature:
        add eax, 0x80
        mov ecx, [eax]
        mov ebx, [FILE_FORMAT_PE]
        cmp ecx, ebx
        je .Check_PE

        call Print_32
        call Next_Line_32

        mov eax, 0x01
        ret
        
    .Check_PE:
        mov eax, 0x02
        ret

; Checks if elf and what mode it supports
; Inp:
; - eax, address
; Out:
; - eax, type
Elf_Define_File:
    mov ecx, [eax]
    mov ebx, [ELF_VERF]
    cmp ecx, ebx
    jne .Elf_Define_File_Not_Verified

    mov cl, [eax + 4]
    cmp cl, 2
    je .Elf_Define_File_Handle_64

    .Elf_Define_File_Handle_32:
        mov eax, 1
        ret

    .Elf_Define_File_Handle_64:
        mov eax, 2
        ret

    .Elf_Define_File_Not_Verified:

        xor eax, eax
        ret

; Loads an entry point then loads into it
Elf32_Jump:
    call Clear_32

    ; Loop through the entries and print some info about them
    xor cx, cx
    mov bx, [0x50000 + ELF_32_STRUCTURE.PROGRAM_HEADER_NUMBER]
    dec bx


    .Loop:
        ; Get current offset
        xor eax, eax
        mov ax, [0x50000 + ELF_32_STRUCTURE.PROGRAM_HEADER_SIZE]
        mul cx
        mov edx, eax
        add edx, [0x50000 + ELF_32_STRUCTURE.PROGRAM_HEADER_OFFSET]
    
        ; Check if executable
        mov eax, [edx + 0x50000 + ELF_32_PROGRAM_STRUCTURE.TYPE]
        cmp eax, 0x01
        jne .Loop_Next

        call Elf32_Load_Segment

    .Loop_Next:
        inc cx
        cmp cx, bx
        jne .Loop

    ; End
    call Paging_32
    mov ebx, MULTIBOOT1_INFO
    mov eax, [0x50000 + ELF_32_STRUCTURE.PROGRAM_ENTRY_OFFSET]
    jmp eax
    ; Jump to end
    jmp $

    .ELF_FILE_LOCATION: dd 0x00

    .BOOT_SIGNATURE:

; Loads the file segments
Elf32_Load_Segment:
    pushad
    mov edi, edx
    
    mov eax, [edi + 0x50000 + ELF_32_PROGRAM_STRUCTURE.DATA_OFFSET]
    xor edx, edx
    mov ecx, 0x200
    div ecx
    mov [FAT32_Read_File.START_OFFSET], eax

    mov eax, [edi + 0x50000 + ELF_32_PROGRAM_STRUCTURE.DATA_SIZE_MEMORY]
    xor edx, edx
    mov ecx, 0x200
    div ecx
    mov edx, eax

    mov eax, 0x30000
    mov ebx, FAT32_NAME_BUFFER_PUSH
    mov ecx, [edi + 0x50000 + ELF_32_PROGRAM_STRUCTURE.DATA_VIRTUAL_OFFSET]
    call FAT32_Read_File
    
    mov eax, [edi + 0x50000 + ELF_32_PROGRAM_STRUCTURE.DATA_VIRTUAL_OFFSET]
    popad
    ret

; Loads an entry point then loads into it
Elf64_Jump:
    call Clear_32

    ; Loop through the entries and print some info about them
    xor cx, cx
    mov bx, [0x50000 + ELF_64_STRUCTURE.PROGRAM_HEADER_NUMBER]
    dec bx


    .Loop:
        ; Get current offset
        xor eax, eax
        mov ax, [0x50000 + ELF_64_STRUCTURE.PROGRAM_HEADER_SIZE]
        mul cx
        mov edx, eax
        add edx, [0x50000 + ELF_64_STRUCTURE.PROGRAM_HEADER_OFFSET]
    
        ; Check if executable
        mov eax, [edx + 0x50000 + ELF_64_PROGRAM_STRUCTURE.TYPE]
        cmp eax, 0x01
        jne .Loop_Next

        call Elf64_Load_Segment

    .Loop_Next:
        inc cx
        cmp cx, bx
        jne .Loop

    ; End
    mov eax, [0x50000 + ELF_64_STRUCTURE.PROGRAM_ENTRY_OFFSET]
    mov [.ENTRY_POINT], eax
    call Protected_Mode_Enter_Long_Mode
    jmp eax
    ; Jump to end
    jmp $

    .ENTRY_POINT: dq 0x00
    .ELF_FILE_LOCATION: dd 0x00

; Loads the file segments
Elf64_Load_Segment:
    pushad
    mov edi, edx
    
    mov eax, [edi + 0x50000 + ELF_64_PROGRAM_STRUCTURE.DATA_OFFSET]
    xor edx, edx
    mov ecx, 0x200
    div ecx
    mov [FAT32_Read_File.START_OFFSET], eax

    mov eax, [edi + 0x50000 + ELF_64_PROGRAM_STRUCTURE.DATA_SIZE_MEMORY]
    xor edx, edx
    mov ecx, 0x200
    div ecx
    mov edx, eax

    mov eax, 0x30000
    mov ebx, FAT32_NAME_BUFFER_PUSH
    mov ecx, [edi + 0x50000 + ELF_64_PROGRAM_STRUCTURE.DATA_VIRTUAL_OFFSET]
    call FAT32_Read_File
    popad
    ret