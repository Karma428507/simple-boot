;*****************************************
; Title: Console
; Desc: Console services
; Location: src/Bootmanager/Tools/Console.asm
;*****************************************

; To print to the console
; Inp:
; - eax, message pointer
Print_32:
    pushad
    mov ebx, 0xb8000
    mov dh, [DISP_COLOR]
    mov ecx, [DISP_POINTER]

    .Print_32_Loop:
        mov dl, [eax]

        cmp dl, 0x00
        je .Print_32_Ret

        mov [ecx + ebx], dl
        add ecx, 2

        inc eax
        jmp .Print_32_Loop

    .Print_32_Ret:
        mov [DISP_POINTER], ecx
        popad
        ret

; Sets the console pointer to the next line
Next_Line_32:
    pushad
    xor dx, dx
    mov ax, [DISP_POINTER]
    mov cx, 160

    div cx
    inc ax
    mov dx, ax

    mov ax, 160
    mul dx
    mov [DISP_POINTER], ax

    popad
    ret

; Places one char onto the console
; Inp:
; - al, character
Place_Char_32:
    pushad
    mov ah, [DISP_COLOR]
    mov ecx, [DISP_POINTER]

    mov [ecx + 0xb8000], al
    inc ecx
    mov [ecx + 0xb8000], ah
    inc ecx

    mov [DISP_POINTER], ecx
    popad
    ret

; Clears the screen and pointer
Clear_32:
    pushad
    mov ah, [DISP_COLOR]
    mov edi, 0xb8000
    .Loop:
        cmp di, (80 * 25) * 2
        jge .Ret

        mov byte [edi], 0
        inc edi
        mov [edi], ah
        inc edi

        jmp .Loop

    .Ret:
        mov word [DISP_POINTER], 0x00
        popad
        ret

; Sets a BG
Set_BG:
    pushad
    xor eax, eax
    mov ebx, 0xb8001

    .Set_BG_Loop:
        cmp eax, 80 * 25
        je .Set_BG_Return

        mov ecx, [DISP_COLOR]
        mov byte [ebx], cl

        inc eax
        add ebx, 2
        jmp .Set_BG_Loop

    .Set_BG_Return:
        popad
        ret

; Turns a number to a number string
; Inp:
; - eax, number
ITOA_32:
    pushad
    xor ebx, ebx
    xor ecx, ecx

    .ITOA_Wipe_32:
        cmp ebx, 20
        je .ITOA_Start_32

        mov [ITOA_32_RESVRD + ebx], cl
        inc ebx

        jmp .ITOA_Wipe_32

    .ITOA_Start_32:
        xor ebx, ebx

    .ITOA_Convert_32:
        cmp ebx, 10
        je .ITOA_Prepare_32

        xor edx, edx
        mov ecx, 10
        div ecx

        add dl, 0x30
        mov [ITOA_32_RESVRD + ebx], dl

        cmp eax, 0
        je .ITOA_Prepare_32

        inc ebx
        jmp .ITOA_Convert_32

    .ITOA_Prepare_32:
        xor ebx, ebx
        mov ecx, 9

    .ITOA_Reverse_32:
        mov al, [ITOA_32_RESVRD + ecx]

        cmp al, 0
        je .ITOA_Pass_32

        mov [ITOA_32_BUFFER + ebx], al

        cmp ecx, 0
        je .ITOA_Return_32

        dec ecx
        inc ebx
        jmp .ITOA_Reverse_32
    
    .ITOA_Pass_32:
        dec ecx
        jmp .ITOA_Reverse_32

    .ITOA_Return_32:
        popad
        ret

; Turns a number to a hex string
; Inp:
; - eax, number
ITOX_32:
    pushad
    xor ebx, ebx
    xor ecx, ecx

    .ITOX_Wipe_32:
        cmp ebx, 16
        je .ITOX_Start_32

        mov byte [ITOX_32_RESVRD + ebx], '0'
        inc ebx

        jmp .ITOX_Wipe_32

    .ITOX_Start_32:
        xor ebx, ebx

    .ITOX_Convert_32:
        cmp ebx, 0x08
        je .ITOX_Prepare_32

        xor edx, edx
        mov ecx, 0x10
        div ecx

        cmp dl, 0x09
        jle .ITOX_Normal_Num

        add dl, 0x07

        .ITOX_Normal_Num:
            add dl, 0x30
            mov [ITOX_32_RESVRD + ebx], dl

        cmp eax, 0
        je .ITOX_Prepare_32

        inc ebx
        jmp .ITOX_Convert_32

    .ITOX_Prepare_32:
        xor ebx, ebx
        mov ecx, 0x07

    .ITOX_Reverse_32:
        mov al, [ITOX_32_RESVRD + ecx]

        cmp al, 0
        je .ITOX_Pass_32

        mov [ITOX_32_BUFFER + ebx], al

        cmp ecx, 0
        je .ITOX_Return_32

        dec ecx
        inc ebx
        jmp .ITOX_Reverse_32
    
    .ITOX_Pass_32:
        dec ecx
        jmp .ITOX_Reverse_32

    .ITOX_Return_32:
        popad
        ret

; Clears the line below
; Inp:
; - eax, line
Clear_Below:
    pushad
    mov edx, 0xA0
    mul edx
    mov edi, 0xb8000
    add edi, eax
    
    mov edx, [DISP_POINTER]
    sub edx, eax
    mov [DISP_POINTER], eax

    mov ah, [DISP_COLOR]
    
    .Loop:
        cmp di, (80 * 25) * 2
        jge .Ret

        mov byte [edi], 0
        inc edi
        mov [edi], ah
        inc edi

        jmp .Loop

    .Ret:
        popad
        ret

DISP_COLOR: db 0x0F
DISP_POINTER: dd 0x00000000
ITOA_32_RESVRD: db 0, 0, 0, 0, 0
ITOA_32_BUFFER: db 0, 0, 0, 0, 0, 0
ITOX_32_RESVRD: db 0, 0, 0, 0, 0, 0, 0, 0
ITOX_32_BUFFER: db 0, 0, 0, 0, 0, 0, 0, 0, 0