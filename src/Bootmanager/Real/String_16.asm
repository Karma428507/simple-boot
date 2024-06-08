;*****************************************
; Title: String 16 bits
; Desc: Console/String services
; Location: src/Bootmanager/Real/String_16.asm
;*****************************************

; To print to the console
; Inp:
; - si, message pointer
Print_16:
    pusha
    mov bx, 0xb800
    mov es, bx
    mov ah, [DISP_COLOR]
    mov di, [DISP_POINTER]
    .Loop:
        lodsb

        cmp al, 0x00
        je .Ret

        mov es:[di], al
        inc di
        mov es:[di], ah
        inc di

        jmp .Loop

    .Ret:
        xor bx, bx
        mov es, bx
        mov [DISP_POINTER], di
        popa
        ret

; To get the string size
; Inp:
; - si, message pointer
; Out:
; - ax, size
Strlen_16:
    pusha
    xor bx, bx

    .Loop:
        lodsb

        cmp al, 0x00
        je .Ret

        inc bx
        jmp .Loop

    .Ret:
        mov [.SIZE], bx
        popa
        mov ax, [.SIZE]
        ret
    
    .SIZE: dw 0x0000

; Places one char onto the console
; Inp:
; - al, character
Place_Char_16:
    pusha
    mov bx, 0xb800
    mov es, bx
    mov ah, [DISP_COLOR]
    mov di, [DISP_POINTER]

    mov es:[di], al
    inc di
    mov es:[di], ah
    inc di

    xor bx, bx
    mov es, bx
    mov [DISP_POINTER], di
    popa
    ret

; Sets the console pointer to the next line
Next_Line_16:
    pusha
    xor dx, dx
    mov ax, [DISP_POINTER]
    mov cx, 160

    div cx
    inc ax
    mov dx, ax

    mov ax, 160
    mul dx
    mov [DISP_POINTER], ax

    popa
    ret

; Turns a number to a number string
; Inp:
; - ax, number
ITOA_16:
    mov cx, 5

    .Wipe:
        mov bx, cx
        mov byte [ITOA_16_RESVRD + bx], 0x00
        mov byte [ITOA_16_BUFFER + bx], 0x00
        loop .Wipe
        xor bx, bx

    .Convert:
        cmp bx, 5
        je .Prepare

        xor dx, dx
        mov cx, 10

        div cx

        add dx, 0x30
        mov [ITOA_16_RESVRD + bx], dx

        cmp ax, 0
        je .Prepare

        inc bx
        jmp .Convert

    .Prepare:
        xor bx, bx
        mov cx, 4

    .Reverse:
        cmp cx, -1
        je .Return

        push bx
        mov bx, cx
        mov al, [ITOA_16_RESVRD + bx]
        pop bx

        cmp al, 0
        je .Pass

        mov [ITOA_16_BUFFER + bx], al

        dec cx
        inc bx
        jmp .Reverse
    
    .Pass:
        dec cx
        jmp .Reverse

    .Return:
        ret
        
; Turns a number to a hex string
; Inp:
; - ax, number
ITOX_16:
    pusha
    xor bx, bx
    xor cx, cx

    .Wipe:
        cmp bx, 16
        je .Start

        mov byte [ITOX_16_RESVRD + bx], '0'
        inc bx

        jmp .Wipe

    .Start:
        xor bx, bx

    .Convert:
        cmp bx, 0x08
        je .Prepare

        xor edx, edx
        mov ecx, 0x10
        div ecx

        cmp dl, 0x09
        jle .Normal_Num

        add dl, 0x07

        .Normal_Num:
            add dl, 0x30
            mov [ITOX_16_RESVRD + bx], dl

        cmp eax, 0
        je .Prepare

        inc bx
        jmp .Convert

    .Prepare:
        xor dx, dx
        mov cx, 0x07

    .Reverse:
        mov bx, cx
        mov al, [ITOX_16_RESVRD + bx]

        cmp al, 0
        je .Pass

        mov bx, dx
        mov [ITOX_16_BUFFER + bx], al

        cmp cx, 0
        je .Return

        dec cx
        inc dx
        jmp .Reverse
    
    .Pass:
        dec ecx
        jmp .Reverse

    .Return:
        popa
        ret

; Clears the screen and pointer
Clear_16:
    pusha
    mov bx, 0xb800
    mov es, bx
    mov ah, [DISP_COLOR]
    xor di, di
    .Loop:
        cmp di, (80 * 25) * 2
        jge .Ret

        mov byte es:[di], 0
        inc di
        mov es:[di], ah
        inc di

        jmp .Loop

    .Ret:
        xor bx, bx
        mov es, bx
        mov word [DISP_POINTER], 0x00
        popa
        ret

; Compares two strings
; Inp:
; - ax, string a
; - bx, string b
; Out:
; - dx, is equal
Compare_16:
    push ax
    push bx
    push cx

    mov cx, bx

    .Loop:
        mov bx, ax
        mov dh, [bx]
        mov bx, cx
        mov dl, [bx]

        cmp dl, 0x00
        je .Zero

        cmp dl, dh
        jne .Fail

        inc ax
        inc cx
        jmp .Loop
    
    .Zero:
        cmp dh, 0x00
        jne .Fail

    .Pass:
        pop ax
        pop bx
        pop cx
        xor dx, dx
        inc dx
        ret

    .Fail:
        pop ax
        pop bx
        pop cx
        xor dx, dx
        ret

ITOA_16_RESVRD: db 0, 0, 0, 0, 0
ITOA_16_BUFFER: db 0, 0, 0, 0, 0, 0
ITOX_16_RESVRD: db 0, 0, 0, 0, 0, 0, 0, 0
ITOX_16_BUFFER: db 0, 0, 0, 0, 0, 0, 0, 0, 0