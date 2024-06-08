;*****************************************
; Title: PCI driver
; Desc: Finds devices from PCI
; Location: src/Bootmanager/Driver/PCI.asm
;*****************************************

; Reads 32 bytes from a device config
PCI_Config_Read_Word_BUS db 0
PCI_Config_Read_Word_SLOT db 0
PCI_Config_Read_Word_FUNC db 0
PCI_Config_Read_Word_OFFSET db 0
PCI_Config_Read_Word: ; bus, slot, func, offset
    xor eax, eax

    xor ebx, ebx
    mov bl, [PCI_Config_Read_Word_BUS]
    shl ebx, 16
    or eax, ebx

    xor ebx, ebx
    mov bl, [PCI_Config_Read_Word_SLOT]
    shl ebx, 11
    or eax, ebx

    xor ebx, ebx
    mov bl, [PCI_Config_Read_Word_FUNC]
    shl ebx, 8
    or eax, ebx

    xor ebx, ebx
    mov bl, [PCI_Config_Read_Word_OFFSET]
    and ebx, 0xFC
    or eax, ebx

    mov ebx, 0x80000000
    or eax, ebx

    mov edx, 0xCF8
    out dx, eax
    mov dx, 0xCFC
    in eax, dx
    ret

; Writes 32 bytes from a device config
PCI_Config_Write_Word_BUS db 0
PCI_Config_Write_Word_SLOT db 0
PCI_Config_Write_Word_FUNC db 0
PCI_Config_Write_Word_OFFSET db 0
PCI_Config_Write_Word_VALUE dd 0
PCI_Config_Write_Word: ; bus, slot, func, offset
    xor eax, eax
    mov [PCI_Config_Write_Word_VALUE], edx

    xor ebx, ebx
    mov bl, [PCI_Config_Write_Word_BUS]
    shl ebx, 16
    or eax, ebx

    xor ebx, ebx
    mov bl, [PCI_Config_Write_Word_SLOT]
    shl ebx, 11
    or eax, ebx

    xor ebx, ebx
    mov bl, [PCI_Config_Write_Word_FUNC]
    shl ebx, 8
    or eax, ebx

    xor ebx, ebx
    mov bl, [PCI_Config_Write_Word_OFFSET]
    and ebx, 0xFC
    or eax, ebx

    mov ebx, 0x80000000
    or eax, ebx

    mov edx, 0xCF8
    out dx, eax
    mov dx, 0xCFC
    mov eax, [PCI_Config_Write_Word_VALUE]
    out dx, eax
    ret

; Checks if a PCI device exists
; Inp:
; - al, bus
; - bl, slot
; - cl, func
PCI_Check_Device_EDX dd 0
PCI_Check_Device:
    mov [PCI_Config_Read_Word_BUS], al
    mov [PCI_Config_Read_Word_SLOT], bl
    mov [PCI_Config_Read_Word_FUNC], cl
    mov [PCI_Check_Device_EDX], edx

    mov byte [PCI_Config_Read_Word_OFFSET], 0x00
    call PCI_Config_Read_Word

    and eax, 0xFFFF
    cmp eax, 0xFFFF
    je .PCI_Check_Device_Return

    mov [PCI_Header_VendorID], eax

    mov edx, 0x04
    mov [PCI_Config_Read_Word_OFFSET], dl
    call PCI_Config_Read_Word
    mov [PCI_Header_Command], eax

    mov edx, 0x08
    mov [PCI_Config_Read_Word_OFFSET], dl
    call PCI_Config_Read_Word
    mov [PCI_Header_RevisionID], eax

    mov edx, 0x0C
    mov [PCI_Config_Read_Word_OFFSET], dl
    call PCI_Config_Read_Word
    mov [PCI_Header_Cache_Line], eax
    
    .PCI_Check_Device_Return:
        mov al, [PCI_Config_Read_Word_BUS]
        mov bl, [PCI_Config_Read_Word_SLOT]
        mov cl, [PCI_Config_Read_Word_FUNC]
        mov edx, [PCI_Check_Device_EDX]
        ret

; Loads PCI information
PCI_Get_Device_Information_CLASS db 0
PCI_Get_Device_Information_SUB db 0
PCI_Get_Device_Information_PROG db 0
PCI_Get_Device_Information:
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx

    .PCI_Get_Device_Information_Bus_Loop:
        cmp al, 0xFF
        je .PCI_Get_Device_Information_Fail

    .PCI_Get_Device_Information_Slot_Loop:
        call PCI_Check_Device

        mov dl, [PCI_Header_Class_Code]
        cmp dl, [PCI_Get_Device_Information_CLASS]
        je .PCI_Get_Device_Information_Compare_Slot
    
    .PCI_Get_Device_Information_New_Slot:
        cmp bl, 31
        je .PCI_Get_Device_Information_New_Bus

        inc ebx
        jmp .PCI_Get_Device_Information_Slot_Loop

    .PCI_Get_Device_Information_New_Bus:
        inc eax
        jmp .PCI_Get_Device_Information_Bus_Loop

    .PCI_Get_Device_Information_Compare_Slot:
        mov dl, [PCI_Header_Sub_Class]
        cmp dl, [PCI_Get_Device_Information_SUB]
        jne .PCI_Get_Device_Information_New_Slot

    .PCI_Get_Device_Information_Compare_Func:
        mov dl, [PCI_Header_Prog_IF]
        cmp dl, [PCI_Get_Device_Information_PROG]
        jne .PCI_Get_Device_Information_New_Slot

    .PCI_Get_Device_Information_Pass:
        xor eax, eax
        ret

    .PCI_Get_Device_Information_Fail:
        mov eax, 1
        ret

; Gets header type
; Out:
; - eax, type
PCI_Get_BAR:
    mov bl, [PCI_Header_Header_Type]
    and bl, 0x03

    cmp bl, 0x02
    je .PCI_Get_BAR_Fail

    cmp bl, 0x01
    je .PCI_Get_BAR_Header_1

    .PCI_Get_BAR_Header_0:
        cmp eax, 5
        jg .PCI_Get_BAR_Fail
        jmp .PCI_Get_BAR_Return_BAR

    .PCI_Get_BAR_Header_1:
        cmp eax, 1
        jg .PCI_Get_BAR_Fail

    .PCI_Get_BAR_Return_BAR:
        mov edx, 4
        mul edx

        add eax, 0x10
        mov [PCI_Config_Read_Word_OFFSET], al
        call PCI_Config_Read_Word
        ret

    .PCI_Get_BAR_Fail:
        xor eax, eax
        dec eax
        ret

; Ignore, not important now
PCI_Print_Information_BUS db 0
PCI_Print_Information_SLOT db 0
PCI_Print_Information_FUNC db 0
PCI_Print_Information:
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx

    .PCI_Print_Information_Bus_Loop:
        cmp al, 0xFF
        je .PCI_Print_Information_End

        mov [PCI_Config_Read_Word_BUS], al
        xor bl, bl
        mov [PCI_Print_Information_SLOT], bl

    .PCI_Print_Information_Slot_Loop:
        cmp bl, 0x32
        je .PCI_Print_Information_Bus_Inc

        mov [PCI_Config_Read_Word_SLOT], bl
        xor cl, cl
        mov [PCI_Print_Information_FUNC], cl

    .PCI_Print_Information_Func_Loop:
        cmp cl, 0x08
        je .PCI_Print_Information_Slot_Inc

        mov [PCI_Config_Read_Word_FUNC], cl
        call PCI_Config_Read_Word

        cmp ax, 0xFFFF
        je .PCI_Print_Information_Func_Inc

        mov byte [PCI_Config_Read_Word_OFFSET], 0x08
        call PCI_Config_Read_Word
        mov [PCI_Header_RevisionID], eax

        mov eax, 0x03
        mov ebx, PCI_ENTRY_BUS
        int 0x80

        mov eax, 0x04
        mov ebx, [PCI_Header_Class_Code]
        int 0x80
        mov ebx, eax
        mov eax, 0x03
        int 0x80

        mov eax, 0x03
        mov ebx, PCI_ENTRY_LIST
        int 0x80

        mov eax, 0x03
        mov ebx, PCI_ENTRY_SLOT
        int 0x80

        mov eax, 0x04
        xor ebx, ebx
        mov bl, [PCI_Header_Sub_Class]
        int 0x80
        mov ebx, eax
        mov eax, 0x03
        int 0x80

        mov eax, 0x03
        mov ebx, PCI_ENTRY_LIST
        int 0x80

        mov eax, 0x03
        mov ebx, PCI_ENTRY_FUNC
        int 0x80

        mov eax, 0x04
        xor ebx, ebx
        mov bl, [PCI_Header_Prog_IF]
        int 0x80
        mov ebx, eax
        mov eax, 0x03
        int 0x80

        mov eax, 0x02
        int 0x80

        mov byte [PCI_Config_Read_Word_OFFSET], 0x00

    .PCI_Print_Information_Func_Inc:
        mov cl, [PCI_Print_Information_FUNC]
        inc ecx
        mov [PCI_Print_Information_FUNC], cl
        jmp .PCI_Print_Information_Func_Loop

    .PCI_Print_Information_Slot_Inc:
        mov bl, [PCI_Print_Information_SLOT]
        inc ebx
        mov [PCI_Print_Information_SLOT], bl
        jmp .PCI_Print_Information_Slot_Loop

    .PCI_Print_Information_Bus_Inc:
        mov al, [PCI_Print_Information_BUS]
        inc eax
        mov [PCI_Print_Information_BUS], al
        jmp .PCI_Print_Information_Bus_Loop

    .PCI_Print_Information_End:
        xor al, al
        mov [PCI_Print_Information_BUS], al
        mov [PCI_Print_Information_SLOT], al
        mov [PCI_Print_Information_FUNC], al
        ret

PCI_Header_VendorID: dw 0
PCI_Header_DeviceID: dw 0
PCI_Header_Command: dw 0
PCI_Header_Status: dw 0
PCI_Header_RevisionID: db 0
PCI_Header_Prog_IF: db 0
PCI_Header_Sub_Class: db 0
PCI_Header_Class_Code: db 0
PCI_Header_Cache_Line: db 0
PCI_Header_Latency_Timer: db 0
PCI_Header_Header_Type: db 0
PCI_Header_BIST: db 0