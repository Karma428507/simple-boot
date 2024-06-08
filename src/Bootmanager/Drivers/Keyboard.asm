;*****************************************
; Title: Keyboard driver
; Desc: Gets key inputs
; Location: src/Bootmanager/Drivers/Keyboard.asm
;*****************************************

; Returns a key input
; Out:
; - ax, scancode
Get_Key:
    .Loop:
        mov edx, 0x64
        in al, dx

        and al, 1
        jnz .Loop_Exit
        jmp .Loop

    .Loop_Exit:
        mov edx, 0x60
        in al, dx
        mov [.SCAN], al

        and al, 0x80
        jnz .Ret
        
        mov al, [.SCAN]
        ret

    .Ret:
        xor ebx, ebx
        ret

    .SCAN: db 0

PS2_Keyset:
    db 0, 27, "1234567890-=", 0, 0
    db "qwertyuiop[]", 0xA, 0
    db "asdfghjkl;'`", 0
    db "\zxcvbnm,./", 0
    db '*', 0, ' ', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '-', 0, 0, 0, '+', 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0