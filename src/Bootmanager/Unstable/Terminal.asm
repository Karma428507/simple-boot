Terminal:
    xor al, al
    call Get_Key

    cmp al, 0x00
    je Terminal

    cmp al, 0x0E
    je .Backspace

    cmp al, 0x1C
    je .Parser

    xor ecx, ecx
    mov cl, al
    mov al, [ecx + PS2_Keyset]

    test al, al
    jz Terminal

    xor bh, bh
    mov bl, [SHELL_COMMAND_INDEX]
    cmp bl, 30
    jge Terminal

    mov [bx + SHELL_COMMAND_BUFFER], al
    inc bl
    mov [SHELL_COMMAND_INDEX], bl

    call Place_Char_32
    jmp Terminal

    .Backspace:
        xor bh, bh
        mov bl, [SHELL_COMMAND_INDEX]

        cmp bl, 0
        je Terminal

        dec bl
        mov byte [ecx + SHELL_COMMAND_BUFFER], 0
        mov [SHELL_COMMAND_INDEX], bl

        mov ecx, [DISP_POINTER]
        sub ecx, 2
        mov [DISP_POINTER], ecx

        mov al, 0x00
        call Place_Char_32

        mov ecx, [DISP_POINTER]
        sub ecx, 2
        mov [DISP_POINTER], ecx
        jmp Terminal

    .Parser:
        call Next_Line_32
        mov eax, SHELL_COMMAND_BUFFER
        mov ebx, SHELL_COMMAND_SPLITED
        mov cl, ' '
        call Str_Splt

        mov ax, SHELL_COMMAND_SPLITED
        mov bx, SHELL_COMMAND_EXIT
        call Compare_32
        test dx, dx
        jnz .Exit

        jmp Terminal_Parser

    .Return:
        xor bx, bx
        mov cx, 30

    .Wipe_Buffer:
        mov byte [SHELL_COMMAND_SPLITED + bx], 0
        inc bx
        loop .Wipe_Buffer

        xor bl, bl
        mov [SHELL_COMMAND_INDEX], bl

        call Next_Line_32
        mov eax, SHELL_TERMINAL_LINE
        call Print_32
        jmp Terminal

    .Exit:
        ret

Terminal_Parser:
    mov eax, SHELL_COMMAND_SPLITED
    mov ebx, SHELL_COMMAND_BOOTINFO
    call Compare_32
    test dx, dx
    jnz Command_Bootinfo

    mov eax, SHELL_COMMAND_SPLITED
    mov ebx, SHELL_COMMAND_CD
    call Compare_32
    test dx, dx
    jnz Command_CD

    mov eax, SHELL_COMMAND_SPLITED
    mov ebx, SHELL_COMMAND_CLEAR
    call Compare_32
    test dx, dx
    jnz Command_Clear

    mov eax, SHELL_COMMAND_SPLITED
    mov ebx, SHELL_COMMAND_DIR
    call Compare_32
    test dx, dx
    jnz Command_Dir

    mov eax, SHELL_COMMAND_SPLITED
    mov ebx, SHELL_COMMAND_ECHO
    call Compare_32
    test dx, dx
    jnz Command_Echo

    mov eax, SHELL_COMMAND_SPLITED
    mov ebx, SHELL_COMMAND_EXIT
    call Compare_32
    test dx, dx
    jnz Command_Exit

    mov eax, SHELL_COMMAND_SPLITED
    mov ebx, SHELL_COMMAND_HELP
    call Compare_32
    test dx, dx
    jnz Command_Help

    mov eax, SHELL_COMMAND_SPLITED
    mov ebx, SHELL_COMMAND_HEX
    call Compare_32
    test dx, dx
    jnz Command_Hex

    mov eax, SHELL_COMMAND_SPLITED
    mov ebx, SHELL_COMMAND_LDKR
    call Compare_32
    test dx, dx
    jnz Command_LDKR

    mov eax, SHELL_COMMAND_SPLITED
    mov ebx, SHELL_COMMAND_MEM
    call Compare_32
    test dx, dx
    jnz Command_Mem

    mov eax, SHELL_COMMAND_SPLITED
    mov ebx, SHELL_COMMAND_REBOOT
    call Compare_32
    test dx, dx
    jnz Command_Reboot

    mov eax, SHELL_COMMAND_SPLITED
    mov ebx, SHELL_COMMAND_SHUT
    call Compare_32
    test dx, dx
    jnz Command_Shut

    mov eax, SHELL_COMMAND_SPLITED
    mov ebx, SHELL_COMMAND_WPKR
    call Compare_32
    test dx, dx
    jnz Command_WPKR

    mov eax, SHELL_TERMINAL_UNKNOWN
    call Print_32
    call Next_Line_32

    mov eax, SHELL_COMMAND_SPLITED
    call Print_32
    mov al, 'a'
    call Place_Char_32
    jmp Terminal.Return

Command_Bootinfo:
    jmp Terminal.Return

Command_CD:
    ; Store vars
    mov eax, 0x30000
    mov ebx, .NAME_83_FORMAT
    mov ecx, eax
    xor edx, edx
    call FAT32_Read_Folder
    test eax, eax
    jnz .DEV_Command_CD_Pass

    .DEV_Command_CD_83:
        xor ebx, ebx

    .DEV_Command_CD_83_Loop_Strlen:
        cmp ebx, 11
        jge .DEV_Command_CD_Fail

        mov al, [.NAME_83_FORMAT + ebx]
        test al, al
        jz .FAT32_Read_Folder_83_End_Strlen

        inc ebx
        jmp .DEV_Command_CD_83_Loop_Strlen

    .FAT32_Read_Folder_83_End_Strlen:
        ;xor ebx, ebx

    .DEV_Command_CD_83_Loop:
        cmp ebx, 11
        jge .DEV_Command_CD_83_End

        mov byte [.NAME_83_FORMAT + ebx], 0x20

        inc ebx
        jmp .DEV_Command_CD_83_Loop

    .DEV_Command_CD_83_End:
        mov eax, 0x30000
        mov ebx, .NAME_83_FORMAT
        mov ecx, eax
        xor edx, edx
        call FAT32_Read_Folder
        test eax, eax
        jnz .DEV_Command_CD_Pass

        test eax, eax
        jz .DEV_Command_CD_Fail

    .DEV_Command_CD_Fail:
        mov eax, FAT32_FOLDER_NOT_FOUND
        call Print_32
        call Next_Line_32

    .DEV_Command_CD_Pass:
        jmp Terminal.Return

    .NAME_83_FORMAT: times 13 db 0x00

Command_Clear:
    call Clear_32
    jmp Terminal.Return

Command_Dir:
    xor eax, eax
    xor ebx, ebx

    ; Set .DIR_CONTINUE to the max cluster size
    mov ax, 0x10
    xor bx, bx
    mov bl, [0x7c00 + 0x0D]
    mul bx
    mov [.DIR_CONTINUE], ax

    .Loop_File:
        ; Get the current Entry
        mov eax, 0x30000
        xor ebx, ebx
        mov bx, [.DIR_CONTINUE]
        xor ecx, ecx
        xor edx, edx
        call FAT32_Return_Entry

        ; Decrease the Counter
        mov cx, [.DIR_CONTINUE]
        dec cx
        mov [.DIR_CONTINUE], cx

        ; Check results
        mov ecx, ebx
        and ecx, 1
        jz .Loop_File_End
        mov ecx, ebx
        and ecx, 2
        jz .Loop_File_End

        ; Copy the name
        mov edx, ebx
        xor ebx, ebx

        .Loop_File_Name:
            cmp ebx, 255
            je .Loop_File_Name_End

            mov cl, [eax + ebx]
            mov [FAT32_ENTRY_NAME + ebx], cl

            inc ebx
            jmp .Loop_File_Name

        .Loop_File_Name_End:

        ; Print
        mov eax, FAT32_ENTRY_NAME
        call Print_32
        call Next_Line_32

        ; Check and loop
        .Loop_File_End:
            mov bx, [.DIR_CONTINUE]
            test bx, bx
            jz .Folder

        jmp .Loop_File

    .Folder:
        mov ax, 0x10
        xor bx, bx
        mov bl, [0x7c00 + 0x0D]
        mul bx
        mov [.DIR_CONTINUE], ax

    .Loop_Folder:
        ; Set params
        mov eax, 0x30000
        xor ebx, ebx
        mov bx, [.DIR_CONTINUE]
        xor ecx, ecx
        xor edx, edx
        call FAT32_Return_Entry

        mov cx, [.DIR_CONTINUE]
        dec cx
        mov [.DIR_CONTINUE], cx

        ; Check results
        mov ecx, ebx
        and ecx, 1
        jz .Loop_Folder_End
        mov ecx, ebx
        and ecx, 2
        jnz .Loop_Folder_End

        ; Copy the name
        mov edx, ebx
        xor ebx, ebx

        .Loop_Folder_Name:
            cmp ebx, 255
            je .Loop_Folder_Name_End

            mov cl, [eax + ebx]
            mov [FAT32_ENTRY_NAME + ebx], cl

            inc ebx
            jmp .Loop_Folder_Name

        .Loop_Folder_Name_End:

        mov eax, FAT32_ENTRY_NAME
        call Print_32
        call Next_Line_32

        ; Check and loop
        .Loop_Folder_End:
            mov bx, [.DIR_CONTINUE]
            test bx, bx
            jz .End

        jmp .Loop_Folder

    .End:
        jmp Terminal.Return

    .DIR_CONTINUE: dw 0x00

Command_Echo:
    mov eax, SHELL_COMMAND_BUFFER
    call Print_32
    call Next_Line_32
    jmp Terminal.Return

Command_Exit:
    jmp Terminal.Return

Command_Help:
    xor edx, edx
    mov eax, SHELL_COMMAND_START

    .Outer:
        mov ecx, 7

        cmp edx, COMMAND_AMOUT
        je .Outer_End

        .Inner:
            test ecx, ecx
            jz .Inner_End

            cmp edx, COMMAND_AMOUT
            je .Outer_End_2

            call Print_32
            call Strlen_32

            mov ebx, 10
            sub ebx, eax

            .Space:
                test ebx, ebx
                jz .Space_End

                mov al, ' '
                call Place_Char_32

                dec ebx
                jmp .Space

            .Space_End:

            call Strlen_32
            inc eax

            dec ecx
            inc edx
            jmp .Inner

        .Inner_End:

        call Next_Line_32
        jmp .Outer

    .Outer_End_2:
        call Next_Line_32

    .Outer_End:
        jmp Terminal.Return
        ret

Command_Hex:
    jmp Terminal.Return

Command_LDKR:
    jmp Terminal.Return

Command_Mem:
    ; Total memory
    mov eax, SHELL_TERMINAL_MEMORY_TOTAL
    call Print_32
    mov eax, [BOOT_INFO.MEMORY_SIZE]
    call ITOX_32
    mov eax, ITOX_32_BUFFER
    call Print_32
    call Next_Line_32

    ; Usable memory
    mov eax, SHELL_TERMINAL_MEMORY_USABLE
    call Print_32
    mov eax, [BOOT_INFO.MEMORY_SIZE_USABLE]
    call ITOX_32
    mov eax, ITOX_32_BUFFER
    call Print_32
    call Next_Line_32

    ; Reserved memory
    mov eax, SHELL_TERMINAL_MEMORY_RESERVED
    call Print_32
    mov eax, [BOOT_INFO.MEMORY_SIZE_RESERVED]
    call ITOX_32
    mov eax, ITOX_32_BUFFER
    call Print_32
    call Next_Line_32

    ; Extented memory
    mov eax, SHELL_TERMINAL_MEMORY_EXTENTED
    call Print_32
    mov eax, [BOOT_INFO.MEMORY_EXTENTION]
    call ITOX_32
    mov eax, ITOX_32_BUFFER
    call Print_32
    call Next_Line_32

    mov eax, SHELL_TERMINAL_MEMORY_MAP_TITLE
    call Print_32
    call Next_Line_32

    xor ecx, ecx
    mov cx, [BOOT_INFO.MEMORY_E820_ENTRIES]
    dec cx

    .Loop_Entries:
        dec cx

        mov ax, 24
        mov dx, cx
        mul dx
        mov bx, ax

        call .Print_Entry
        call Next_Line_32

        inc cx
        loop .Loop_Entries

    jmp Terminal.Return

    .Print_Entry:
        mov eax, SHELL_TERMINAL_MEMORY_MAP_ADDRESS
        call Print_32

        mov eax, [BOOT_INFO.MEMORY_E820_STORAGE + bx + E820_MEMORY_MAP.ADDRESS_HIGH]
        call ITOX_32
        mov eax, ITOX_32_BUFFER
        call Print_32

        mov al, ':'
        call Place_Char_32

        mov eax, [BOOT_INFO.MEMORY_E820_STORAGE + bx + E820_MEMORY_MAP.ADDRESS_LOW]
        call ITOX_32
        mov eax, ITOX_32_BUFFER
        call Print_32

        mov eax, SHELL_TERMINAL_MEMORY_MAP_SPACE
        call Print_32
        mov eax, SHELL_TERMINAL_MEMORY_MAP_SIZE
        call Print_32

        mov eax, [BOOT_INFO.MEMORY_E820_STORAGE + bx + E820_MEMORY_MAP.SIZE_HIGH]
        call ITOX_32
        mov eax, ITOX_32_BUFFER
        call Print_32

        mov al, ':'
        call Place_Char_32

        mov eax, [BOOT_INFO.MEMORY_E820_STORAGE + bx + E820_MEMORY_MAP.SIZE_LOW]
        call ITOX_32
        mov eax, ITOX_32_BUFFER
        call Print_32

        mov eax, SHELL_TERMINAL_MEMORY_MAP_SPACE
        call Print_32
        mov eax, SHELL_TERMINAL_MEMORY_MAP_TYPE
        call Print_32

        mov al, [BOOT_INFO.MEMORY_E820_STORAGE + bx + E820_MEMORY_MAP.TYPE]
        
        cmp al, 0x01
        je .Entry_Usable
        cmp al, 0x02
        je .Entry_Reserved

        mov eax, SHELL_TERMINAL_MEMORY_MAP_Entry_UNKNOWN
        call Print_32
        ret

        .Entry_Usable:
            mov eax, SHELL_TERMINAL_MEMORY_MAP_Entry_USABLE
            call Print_32
            ret

        .Entry_Reserved:
            mov eax, SHELL_TERMINAL_MEMORY_MAP_Entry_RESERVED
            call Print_32
            ret

Command_Reboot:
    jmp Terminal.Return

Command_Shut:
    jmp Terminal.Return

Command_WPKR:
    jmp Terminal.Return

DEV_Command_DIR:
    
bufferTest times 20 db 0x00
SHELL_COMMAND_INDEX: db 0
SHELL_COMMAND_BUFFER: times 30 db 0x00
SHELL_COMMAND_SPLITED: times 30 db 0x00
db 0

FAT_NAME_LOCATION: db 0,0,0,0,0,0,0,0,0,0,0
FAT_Current_Storage: db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ; extra zeros for debugging
FAT_Convert_Storage: db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
FAT_Memory_Location: dd 0
FAT32_ENTRY_NAME: times 256 db 0