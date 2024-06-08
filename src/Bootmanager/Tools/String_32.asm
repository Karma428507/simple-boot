;*****************************************
; Title: String 32 bits
; Desc: String services
; Location: src/Bootmanager/Tools/String_32.asm
;*****************************************

; To get the string size
; Inp:
; - eax, message pointer
; Out:
; - ebx, size
Str_Len:
    pushad
    xor ebx, ebx

    .Loop:
        lodsb

        cmp al, 0x00
        je .Ret

        inc ebx
        jmp .Loop

    .Ret:
        mov [.STR_SIZE], ebx
        popad
        mov eax, [.STR_SIZE]
        ret

    .STR_SIZE dd 0x00

; Compares two strings
; Inp:
; - eax, string a
; - ebx, string b
; Out:
; - edx, is equal
Str_Cmp:
    pushad

    .Loop:
        mov dh, [eax]
        mov dl, [ebx]

        cmp dl, 0x00
        je .Both_Zero

        cmp dl, dh
        jne .Fail

        inc ebx
        inc eax
        jmp .Loop
    
    .Both_Zero:
        cmp dh, 0x00
        jne .Fail

    .Pass:
        popad
        xor edx, edx
        inc edx
        ret

    .Fail:
        popad
        xor edx, edx
        ret

    .ADDRESS: dd 0x00000000

; WIP
Str_Cpy:
    ret

    .STR_A dd 0x00
    .STR_B dd 0x00

; Splits a string and place into a buffer
Str_Splt:
    pushad
    mov edx, ecx
    mov ecx, ebx
    xor ebx, ebx

    .Copy:
        mov dh, [eax + ebx]

        test dh, dh
        jz .Copy_End
        cmp dh, dl
        je .Copy_End

        mov [ecx + ebx], dh
        inc ebx
        jmp .Copy

    .Copy_End:
        inc ebx
        mov ecx, eax

    .Shift:
        mov dl, [ebx + ecx]

        test dl, dl
        jz .Shift_End

        mov [ecx], dl
        inc ecx
        jmp .Shift

    .Shift_End:

    .Remove:
        mov byte [ebx + ecx], 0x00

        test ebx, ebx
        jz .Remove_End
        
        dec ebx
        jmp .Remove

    .Remove_End:
        popad
        ret

; Sets a part of memory to a value
; Inp:
; - ebx, offset
; - ecx, count
; - dl, value
Mem_Set:
    dec ecx
    mov [ecx + ebx], dl

    cmp ecx, 0
    jnz Mem_Set

; WIP
Mem_Cpy:
    ret

    .SIZE dd 0x00

; WIP
Mem_Cmp:
    ret

    .SIZE dd 0x00