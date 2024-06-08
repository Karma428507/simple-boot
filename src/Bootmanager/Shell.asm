;*****************************************
; Title: Shell
; Desc: Allows the user to select an OS
; Location: src/Bootmanager/Shell.asm
;*****************************************

; To ask what OS to boot to
Shell:
    call Clear_32

    mov eax, SHELL_OS_SELECT_A
    call Print_32
    call Next_Line_32
    mov eax, SHELL_OS_SELECT_B
    call Print_32
    call Next_Line_32

    mov al, 0xC4
    xor ebx, ebx

    .Draw_Line:
        call Place_Char_32

        inc ebx
        cmp ebx, 0x50
        jl .Draw_Line

    ; Print current OS info
    call Print_Entry

    ; Ask for input
    .Input_Loop:
        call Get_Key

        xor ecx, ecx
        mov cl, al
        mov al, [ecx + PS2_Keyset]

        ; Used to access a removed label
        ;cmp cl, 0x3B
        ;je .Enter_Terminal

        cmp cl, 0x1C
        je .Enter_OS

        cmp al, 'a'
        je .Swap_OS_Left

        cmp al, 'd'
        je .Swap_OS_Right

        jmp .Input_Loop

    .Enter_OS:
        cmp dword [Access_Entry.RETURN_CODE], 0x10
        jge .Enter_OS_Failed

        cmp byte [Access_Entry.BITS], 64
        je .ELF_64_Bits

        .ELF_32_Bits:
            jmp Elf32_Jump

        .ELF_64_Bits:
            jmp Elf64_Jump
            
        .Enter_OS_Failed:
            jmp .Input_Loop

    .Swap_OS_Left:
        call Load_Entry_Left
        mov eax, 0x03
        call Clear_Below
        call Print_Entry
        jmp .Input_Loop

    .Swap_OS_Right:
        call Load_Entry_Right
        mov eax, 0x03
        call Clear_Below
        call Print_Entry
        jmp .Input_Loop

    ; Ignore this section of code, this was meant to access the terminal until it was removed.
    ; It'll still be added in an update.
    ;.Enter_Terminal:
    ;    call Clear_32
    ;    mov eax, SHELL_TERMINAL_MESSAGE_A
    ;    call Print_32
    ;    call Next_Line_32
    ;    mov eax, SHELL_TERMINAL_MESSAGE_B
    ;    call Print_32
    ;    call Next_Line_32
    ;    mov eax, SHELL_TERMINAL_LINE
    ;    call Print_32
    ;
    ;    call Terminal
    ;    jmp Shell_Load_OS

    .Continue:
        ret