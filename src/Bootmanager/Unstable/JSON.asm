%define JSON_TYPE_ENTRY  0x01
%define JSON_TYPE_END    0x02
%define JSON_TYPE_STRING 0x03
%define JSON_ENTRY       0x100000
%define JSON_STRINGS     0x108000

%define RIGHT_BRACKET_CHAR '{'
%define LEFT_BRACKET_CHAR '}'

Parse_JSON:
    mov [.CONFIG_LOCATION], eax
    mov [.CONFIG_BUFFER], ebx

    mov eax, [AHCI_Read_COUNT]
    mov edx, 0x200
    mul edx
    inc eax

    mov ecx, eax
    add ecx, [.CONFIG_LOCATION]
    mov ebx, [.CONFIG_LOCATION]
    mov edx, [.CONFIG_BUFFER]
    
    .Buffer_Exchange:
        cmp ebx, ecx
        je .Parse_Buffer

        mov al, [ebx]

        test al, al
        jz .Buffer_Exchange_End
        cmp al, 0x0D
        je .Buffer_Exchange_End
        cmp al, 0x0A
        je .Buffer_Exchange_End

        cmp al, '"'
        je .Quote_Flag
        mov si, [.QUOTE_FLAG]
        test si, si
        jnz .Buffer_Exchange_Move
        cmp al, 0x20
        je .Buffer_Exchange_End

    .Buffer_Exchange_Move:
        mov [edx], al
        inc edx

    .Buffer_Exchange_End:
        inc ebx
        jmp .Buffer_Exchange

    .Quote_Flag:
        mov si, [.QUOTE_FLAG]
        xor si, 0x01
        mov [.QUOTE_FLAG], si
        jmp .Buffer_Exchange_Move

    .Parse_Buffer:
        mov eax, [.CONFIG_BUFFER]
        mov bl, [eax]
        cmp bl, RIGHT_BRACKET_CHAR
        jne .Fail

        mov bl, JSON_TYPE_ENTRY
        call Push_JSON_Entry
        mov eax, [.CONFIG_BUFFER]
        inc eax

    .Parse_Buffer_Loop:
        xor ebx, ebx

    .Wipe_String:
        mov byte [.CURRENT_NAME + ebx], 0x00
        inc ebx
        cmp ebx, 0x1A
        jne .Wipe_String

        ; Check if it's the end of an entry
        mov bl, [eax]
        cmp bl, LEFT_BRACKET_CHAR
        je .New_Directory_Entry_Pop

        ; If not an end to an entry, read the string
        call Push_JSON_Name
        inc eax

        ; Check if it's valid
        mov bl, [eax]
        cmp bl, ':'
        jne .Fail

        ; Go to the next character
        inc eax
        mov bl, [eax]

        ; If it's creating a new entry
        cmp bl, RIGHT_BRACKET_CHAR
        je .New_Directory_Entry_Push

        ; If there's a string
        cmp bl, '"'
        je .New_Directory_String

    .Can_Pass:
        inc eax
        mov bl, [eax]
        test bl, bl
        jz .Pass

    ; Returns false
    .Fail:
        xor eax, eax
        ret

    ; Returns true
    .Pass:
        xor eax, eax
        inc eax
        ret

    .New_Directory_Entry_Push:
        mov bl, [.ENTRY_STACK]
        inc bl
        mov [.ENTRY_STACK], bl

        mov bl, JSON_TYPE_ENTRY
        call Push_JSON_Entry
        inc eax
        jmp .Parse_Buffer_Loop

    .New_Directory_Entry_Pop:
        ; Decreases the stack number
        mov bl, JSON_TYPE_END
        call Push_JSON_Entry

        ; Returns if last stack
        mov bl, [.ENTRY_STACK]
        cmp bl, 1
        jle .Can_Pass
        dec bl
        mov [.ENTRY_STACK], bl

        inc eax
        mov bl, [eax]
        cmp bl, ','
        je .Next_Entry

        jmp .Parse_Buffer_Loop
    
    .Next_Entry:
        inc eax
        mov bl, [eax]
        jmp .Parse_Buffer_Loop

    .New_Directory_String:
        call Push_JSON_String

        mov bl, JSON_TYPE_STRING
        call Push_JSON_Entry

        jmp .Parse_Buffer_Loop

    .CONFIG_LOCATION: dd 0x00
    .CONFIG_BUFFER: dd 0x00
    .QUOTE_FLAG: dw 0x00
    .CURRENT_NAME: times 0x1A db 0x00
    .CURRENT_STRING: times 0x100 db 0x00
    .ENTRY_STACK: db 0x01

Push_JSON_Name:
    pushad
    mov bl, [eax]
    cmp bl, '"'
    jne .Fail

    mov ecx, 0x1A

    .Wipe:
        mov byte [Parse_JSON.CURRENT_NAME + ecx], 0x00
        loop .Wipe

    inc eax
    xor ebx, ebx

    .Copy:
        cmp ebx, 0x1A
        jge .Fail

        mov cl, [eax]
        cmp cl, '"'
        je .Pass

        mov [Parse_JSON.CURRENT_NAME + ebx], cl

        inc eax
        inc ebx
        jmp .Copy

    .Pass:
        mov [.EAX_STORAGE], eax
        popad
        mov eax, [.EAX_STORAGE]
        mov bl, 0x01
        ret

    .Fail:
        mov [.EAX_STORAGE], eax
        popad
        mov eax, [.EAX_STORAGE]
        xor bl, bl
        ret

    .QUOTE_FLAG: dw 0x00
    .EAX_STORAGE: dd 0x00

Push_JSON_String:
    pushad
    mov bl, [eax]
    cmp bl, '"'
    jne .Fail

    mov ecx, 0xFF

    .Wipe:
        mov byte [Parse_JSON.CURRENT_STRING + ecx], 0x00
        loop .Wipe

    inc eax
    xor ebx, ebx

    .Copy:
        cmp ebx, 0x100
        jge .Fail

        mov cl, [eax]
        cmp cl, '"'
        je .Check_Next

        mov [Parse_JSON.CURRENT_STRING + ebx], cl

        inc eax
        inc ebx
        jmp .Copy

    .Check_Next:
        inc eax
        mov cl, [eax]

        cmp cl, ','
        je .Pass_Inc
        cmp cl, LEFT_BRACKET_CHAR
        je .Pass

    .Fail:
        mov [.EAX_STORAGE], eax
        popad
        mov eax, [.EAX_STORAGE]
        xor bl, bl
        ret

    .Pass_Inc:
        inc eax

    .Pass:
        mov [.EAX_STORAGE], eax
        popad
        mov eax, [.EAX_STORAGE]
        mov bl, 0x01
        ret

    .QUOTE_FLAG: dw 0x00
    .EAX_STORAGE: dd 0x00

Push_JSON_Entry:
    pushad
    mov eax, [.ENTRY_INDEX]
    mov edx, 0x20
    mul edx
    add eax, JSON_ENTRY

    mov dl, bl
    xor ebx, ebx

    .Loop:
        cmp ebx, 0x1A
        jge .Loop_End

        mov dh, [Parse_JSON.CURRENT_NAME + ebx]
        mov [eax + ebx], dh

        inc ebx
        jmp .Loop
    
    .Loop_End:
        mov [eax + JSON_ENTRIES.TYPE], dl

        ; Entry just uses the entry below it and end just pops the stack
        ; String is an actual value to and address for strings
        cmp dl, JSON_TYPE_STRING
        je .String_Handler

    .End:
        mov eax, [.ENTRY_INDEX]
        inc eax
        mov [.ENTRY_INDEX], eax
        popad
        ret

    .String_Handler:
        mov ecx, eax
        mov eax, [.STRING_INDEX]
        mov edx, 0x100
        mul edx
        add eax, JSON_STRINGS
        xor ebx, ebx

    .String_Handler_Loop:
        cmp ebx, 0xFF
        je .String_Handler_End

        mov dh, [Parse_JSON.CURRENT_STRING + ebx]
        mov [eax + ebx], dh

        inc ebx
        jmp .String_Handler_Loop

    .String_Handler_End:
        mov [ecx + JSON_ENTRIES.VALUE], eax

        mov eax, [.STRING_INDEX]
        inc eax
        mov [.STRING_INDEX], eax
        jmp .End

    .ENTRY_INDEX: dd 0x00
    .STRING_INDEX: dd 0x00

JSON_Get_Value:
    mov edx, eax

    xor eax, eax
    mov al, [DIRECTORY_STACK]
    call ITOA_32
    mov eax, ITOA_32_BUFFER
    call Print_32
    call Next_Line_32

    xor eax, eax
    mov al, [JSON_Entry_Find.STACK]
    call ITOA_32
    mov eax, ITOA_32_BUFFER
    call Print_32
    call Next_Line_32

    mov eax, edx

    call JSON_Entry_Find
    test bl, bl
    jz .Fail

    mov bl, [eax + JSON_ENTRIES.TYPE]
    cmp bl, JSON_TYPE_STRING
    jne .Fail

    mov ebx, [eax + JSON_ENTRIES.VALUE]

    .Pass:
        xor eax, eax
        inc eax
        ret
        
    .Fail:
        xor eax, eax
        ret

JSON_Get_Entry:
    call JSON_Entry_Find
    test bl, bl
    jz .Fail

    mov bl, [eax + JSON_ENTRIES.TYPE]

    cmp bl, JSON_TYPE_ENTRY
    jne .Fail

    sub eax, JSON_ENTRY
    mov bl, 0x20
    div bl
    mov bx, ax
    xor eax, eax
    mov ax, bx
    
    inc al
    mov [DIRECTORY_INDEX], al
    mov bl, [DIRECTORY_STACK]
    inc bl
    mov byte [JSON_Entry_Find.STACK], 0x00
    ;mov [DIRECTORY_STACK], bl

    call ITOA_32
    mov eax, ITOA_32_BUFFER
    call Print_32
    call Next_Line_32

    .Pass:
        xor eax, eax
        inc eax
        ret
        
    .Fail:
        xor eax, eax
        ret

JSON_Reset:
    mov byte [DIRECTORY_STACK], 0x00
    mov byte [DIRECTORY_INDEX], 0x01
    ret

JSON_Get_Entries_Of_Path:
    ret

JSON_Next_Directory:
    ret

JSON_Entry_Find:
    mov [.NAME], eax
    xor eax, eax
    mov al, [DIRECTORY_INDEX]
    mov edx, 0x20
    mul edx
    add eax, JSON_ENTRY

    xor ebx, ebx

    .Loop:
        mov dh, [eax + JSON_ENTRIES.TYPE]

        cmp dh, JSON_TYPE_ENTRY
        je .Push_Stack
        cmp dh, JSON_TYPE_STRING
        je .String_Entry
        cmp dh, JSON_TYPE_END
        je .Pop_Stack

    .Loop_End:
        add eax, 0x20

        cmp eax, JSON_STRINGS
        jl .Loop
        jmp .Fail

    .Push_Stack:
        mov dh, [.STACK]
        
        mov dl, [DIRECTORY_STACK]
        cmp dh, dl
        jne .Loop_End

        inc dh
        mov [.STACK], dh

        mov ebx, [.NAME]
        call Compare_32

        test edx, edx
        jnz .Pass
        jmp .Loop_End

    .String_Entry:
        mov dl, [DIRECTORY_STACK]
        cmp dh, dl
        jne .Loop_End

        mov ebx, [.NAME]
        call Compare_32

        test edx, edx
        jnz .Pass
        jmp .Loop_End

    .Pop_Stack:
        ; Can't leave the current directory
        mov dh, [.STACK]
        test dh, dh
        jz .Fail

        dec dh
        mov [.STACK], dh
        jmp .Loop_End

    .Fail:
        mov ebx, eax
        call ITOX_32
        mov eax, ITOX_32_BUFFER
        call Print_32
        call Next_Line_32
        mov eax, ebx

        xor ebx, ebx
        ret

    .Pass:
        mov ebx, eax
        call ITOX_32
        mov eax, ITOX_32_BUFFER
        call Print_32
        call Next_Line_32
        mov eax, ebx

        xor ebx, ebx
        inc ebx
        ret

    .STACK: db 0x00
    .NAME: dd 0x00

JSON_Wipe_Data:
    ret

JSON_Print_Tree:
    mov eax, JSON_TREE
    call Print_32
    mov ebx, JSON_ENTRY

    .Loop:
        mov dl, [ebx + JSON_ENTRIES.TYPE]

        cmp dl, JSON_TYPE_ENTRY
        je .Push
        cmp dl, JSON_TYPE_STRING
        je .String
        cmp dl, JSON_TYPE_END
        je .Pop

    .Loop_End:
        add ebx, 0x20
        cmp ebx, JSON_STRINGS
        jl .Loop

    .End:
        ret

    .Push:
        call .Print_Level
        mov eax, ebx
        call Print_32
        call Next_Line_32

        mov dl, [.STACK]
        inc dl
        mov [.STACK], dl
        jmp .Loop_End

    .String:
        call .Print_Level
        mov eax, ebx
        call Print_32

        mov al, ':'
        call Place_Char_32
        mov al, ' '
        call Place_Char_32

        mov eax, [ebx + JSON_ENTRIES.VALUE]
        call Print_32

        call Next_Line_32
        jmp .Loop_End
    
    .Pop:
        mov dl, [.STACK]
        cmp dl, 0x01
        jle .End
        dec dl
        mov [.STACK], dl
        jmp .Loop_End

    .Print_Level:
        xor ecx, ecx
        mov cl, [.STACK]
        dec ecx

        test ecx, ecx
        jz .End

    .Level_Loop:
        mov al, '-'
        call Place_Char_32
        dec ecx
        test ecx, ecx
        jnz .Level_Loop
        ret

    .STACK: db 0x01

DIRECTORY_INDEX: db 0x01
DIRECTORY_STACK: db 0x00