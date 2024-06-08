;*****************************************
; Title: AHCI driver
; Desc: Setups and maintain the AHCI device
; Location: src/Bootmanager/Driver/AHCI.asm
;*****************************************

; Initalize the AHCI driver
Init_AHCI:
    ; Detect AHCI controller
    mov al, 0x02
    mov byte [PCI_Get_Device_Information_CLASS], 0x01
    mov byte [PCI_Get_Device_Information_SUB], 0x06
    mov byte [PCI_Get_Device_Information_PROG], 0x01
    call PCI_Get_Device_Information

    ; Detect if the controler exists
    cmp eax, 0x00
    jne .Missing

    mov eax, 0x05
    call PCI_Get_BAR

    mov [AHCI_HBA_ADDRESS], eax
    call AHCI_Probe_Port

    ; Get a SATA drive port and remap the memory.
    xor eax, eax
    inc eax
    call AHCI_Find_First_Port
    call AHCI_Rebase

    ; Return true
    xor eax, eax
    inc eax
    ret

    .Missing:
        mov eax, AHCI_DEVICE_FAILURE
        call Print_32
        call Next_Line_32

        ; Return false
        xor eax, eax
        ret

; Puts the ports found into an array
AHCI_Probe_Port:
    ; Prepare the PI
    mov eax, [AHCI_HBA_ADDRESS]
    add eax, HBA_MEMORY.PORT_IMPLEMENTED
    mov [.PI], eax

    ; Prepare the ECX variable
    xor ecx, ecx

    .Loop:
        cmp ecx, 32
        jge .Return

        mov eax, [.PI]
        and eax, 1
        jnz .Loop_End

        mov eax, ecx
        call AHCI_Port_Type
        
        add ecx, AHCI_AVAILIBLE_PORTS
        mov [ecx], eax
        sub ecx, AHCI_AVAILIBLE_PORTS

        mov eax, [AHCI_CMD_LIST_LENGHT]
        inc eax
        mov [AHCI_CMD_LIST_LENGHT], eax
    
    .Loop_End:
        mov eax, [.PI]
        shr eax, 1
        mov [.PI], eax

        inc ecx
        jmp .Loop

    .Return:
        ret

    .PI: dd 0x00000000

; Return a number based on the port ID.
; Inp:
; - eax, index
; Out:
; - eax, type
AHCI_Port_Type:
    mov edx, 0x80
    mul edx

    add eax, [AHCI_HBA_ADDRESS]
    add eax, HBA_MEMORY.PORTS
    add eax, HBA_PORT.ST_STATUS
    mov [AHCI_PORT_ADDRESS], eax

    mov eax, [AHCI_PORT_ADDRESS]
    shr eax, 8
    and eax, 0x0F
    
    cmp eax, 3
    je .Return_NULL

    mov eax, [AHCI_PORT_ADDRESS]
    and eax, 0x0F
    cmp eax, 1
    je .Return_NULL

    ; Detect signatures
    mov ebx, [AHCI_PORT_ADDRESS]
    sub ebx, HBA_PORT.ST_STATUS
    add ebx, HBA_PORT.SIGNATURE
    mov eax, [ebx]

    cmp eax, 0x00000101
    je .Return_SATA

    cmp eax, 0xEB140101
    je .Return_SATAPI

    cmp eax, 0xC33C0101
    je .Return_SEMP

    cmp eax, 0x96690101
    je .Return_PM

    .Return_NULL:
        xor eax, eax
        ret

    .Return_SATA:
        xor eax, eax
        inc eax
        ret

    .Return_SATAPI:
        mov eax, 2
        ret

    .Return_SEMP:
        mov eax, 3
        ret

    .Return_PM:
        mov eax, 4
        ret

; Searches for the first specified AHCI port
; Inp:
; - eax, type
; Out:
; - eax, index
AHCI_Find_First_Port:
    xor ebx, ebx

    .Loop:
        cmp ebx, 32
        jge .Fail

        cmp al, [AHCI_AVAILIBLE_PORTS + ebx]
        je .Pass

        inc ebx
        jmp .Loop

    .Pass:
        xor eax, eax
        mov al, bl

        mov edx, 0x80
        mul edx
        add eax, [AHCI_HBA_ADDRESS]
        add eax, HBA_MEMORY.PORTS
        mov [AHCI_PORT_ADDRESS], eax

        xor eax, eax
        mov al, bl
        ret

    .Fail:
        call AHCI_Port_Error_Messager
        call Print_32
        xor eax, eax
        dec eax
        ret

; To return the error text address
; Inp:
; - eax, type
; Out:
; - ebx, message address
AHCI_Port_Error_Messager:
    cmp al, 0x01
    je .Error_Messager_SATA

    cmp al, 0x02
    je .Error_Messager_SATAPI

    cmp al, 0x03
    je .Error_Messager_SEMB

    cmp al, 0x04
    je .Error_Messager_PM

    mov eax, NONE_PORT_NOT_FOUND
    ret

    .Error_Messager_SATA:
        mov eax, SATA_PORT_NOT_FOUND
        ret

    .Error_Messager_SATAPI:
        mov eax, SATAPI_PORT_NOT_FOUND
        ret

    .Error_Messager_SEMB:
        mov eax, SEMB_PORT_NOT_FOUND
        ret

    .Error_Messager_PM:
        mov eax, PE_PORT_NOT_FOUND
        ret

; Sets the area for AHCI operations
AHCI_Rebase:
    ; Load independant variables
    mov [.NUMBER], eax

    ; Stop the current command
    call AHCI_Stop_Command

    ; Set the CLB value
    mov eax, [AHCI_PORT_ADDRESS]
    mov ebx, [.NUMBER]
    shl ebx, 10
    add ebx, AHCI_Base
    mov [eax + HBA_PORT.CL_BASE_ADDRESS], ebx

    ; Load and make the CLBu value 0
    mov dword [eax + HBA_PORT.CL_BASE_ADDRESS_UPPER], 0

    ; Use Mem_Set
    ;add eax, HBA_PORT.CL_BASE_ADDRESS
    mov ebx, [eax + HBA_PORT.CL_BASE_ADDRESS]
    mov ecx, 1024
    xor edx, edx
    call Mem_Set

    ; Set the base for FBA
    mov eax, [AHCI_PORT_ADDRESS]
    mov ebx, [.NUMBER]
    shl ebx, 8
    add ebx, AHCI_Base + (32<<10)
    mov [eax + HBA_PORT.FIS_BASE_ADDRESS], ebx

    ; Load and make the FBAu value 0
    mov eax, [AHCI_PORT_ADDRESS]
    mov dword [eax + HBA_PORT.FIS_BASE_ADDRESS_UPPER], 0

    ; Use Mem_Set again
    mov eax, [AHCI_PORT_ADDRESS]
    add eax, HBA_PORT.FIS_BASE_ADDRESS
    mov ebx, [eax]
    mov ecx, 256
    xor edx, edx
    call Mem_Set

    ; Set the header address
    mov ebx, [AHCI_PORT_ADDRESS]
    add ebx, HBA_PORT.CL_BASE_ADDRESS
    mov eax, [ebx]
    mov [AHCI_CMD_HEADER_ADDRESS], eax

    xor ecx, ecx

    .Loop:
        cmp ecx, 0x20
        jge .Return
        mov [.COUNTER], ecx

        ; Get the current element of the PRDT array
        mov eax, 0x20
        mul ecx
        add eax, [AHCI_CMD_HEADER_ADDRESS]
        mov ebx, [eax]

        ; Set PRDTL to 8
        mov word [ebx + HBA_CMD_HEADER.PRDTL], 8

        ; Set the CTBA
        mov ecx, [.COUNTER]
        mov edx, [.NUMBER]
        shl ecx, 8
        shl edx, 13
        add ecx, edx
        add ecx, AHCI_Base + (40<<10)
        mov [ebx + HBA_CMD_HEADER.CTBA], ecx

        ; Set the CTBAU
        mov dword [ebx + HBA_CMD_HEADER.CTBA_UPPER], 0

        ; Use Mem_Set
        mov ebx, [ecx]
        mov ecx, 256
        xor edx, edx
        call Mem_Set

        mov ecx, [.COUNTER]
        inc ecx
        jmp .Loop
    
    .Return:
        call AHCI_Start_Command
        ret

    .COUNTER: db 0x00
    .NUMBER: db 0x00

; Starts the command engine
AHCI_Start_Command:
    mov ebx, [AHCI_PORT_ADDRESS]
    add ebx, HBA_PORT.CMD_AND_STATUS

    .Wait:
        mov eax, [ebx]
        and eax, HBA_PxCMD_CR
        jnz .Wait

    mov eax, [ebx]
    or eax, HBA_PxCMD_FRE
    mov [ebx], eax
    
    mov eax, [ebx]
    or eax, HBA_PxCMD_ST
    mov [ebx], eax
    ret

; Stops the command engine
AHCI_Stop_Command:
    mov ebx, [AHCI_PORT_ADDRESS]
    mov eax, [ebx + HBA_PORT.CMD_AND_STATUS]
    and eax, ~HBA_PxCMD_ST
    mov [ebx  + HBA_PORT.CMD_AND_STATUS], eax

    mov eax, [ebx + HBA_PORT.CMD_AND_STATUS]
    and eax, ~HBA_PxCMD_FRE
    mov [ebx + HBA_PORT.CMD_AND_STATUS], eax

    .Wait:
        mov eax, [ebx + HBA_PORT.CMD_AND_STATUS]
        and eax, HBA_PxCMD_FR
        jnz .Wait

        mov eax, [ebx + HBA_PORT.CMD_AND_STATUS]
        and eax, HBA_PxCMD_CR
        jnz .Wait

    ret

; Reads from storage
AHCI_Read_STARTH    dd 0
AHCI_Read_STARTL    dd 0
AHCI_Read_COUNT     dd 0
AHCI_Read_BUFFER    dd 0
AHCI_Read:
    ; Clear initial variables
    xor eax, eax
    mov [.Counter], eax

    ; Set Interrupt Status
    mov esi, [AHCI_PORT_ADDRESS]
    dec eax
    mov [esi + HBA_PORT.INTERRUPT_STATUS], eax

    ; Find a slot
    call AHCI_Find_Command_Slot
    mov [.Slot], eax
    
    ; Return false if there's no slot
    cmp eax, -1
    je .Fail

    ; Load the CMD header
    mov esi, [AHCI_PORT_ADDRESS]
    mov ecx, [esi + HBA_PORT.CL_BASE_ADDRESS]

    ; Select a slot
    mov eax, [.Slot]
    mov edx, 0x20
    mul edx
    add ecx, eax
    mov [AHCI_CMD_HEADER_ADDRESS], ecx

    ; Set the command FIS size and put it to read mode
    mov esi, [AHCI_CMD_HEADER_ADDRESS]
    mov al, [esi + HBA_CMD_HEADER.CFL]
    and al, 0b10100000 ; Make it to read mode
    or al, 4 ; Put in the FIS length
    mov [esi + HBA_CMD_HEADER.CFL], al

    ; Set the PDRT entry count (Over 0 if count is bigger then 16)
    mov eax, [AHCI_Read_COUNT]
    dec eax
    shr eax, 5
    inc eax
    mov [esi + HBA_CMD_HEADER.PRDTL], ax

    ; Load the CMD table
    mov eax, [esi + HBA_CMD_HEADER.CTBA]
    mov [AHCI_CMD_TABLE_ADDRESS], eax

    ; Set fill amount
    xor eax, eax
    mov ax, [esi + HBA_CMD_HEADER.PRDTL]
    dec eax
    mov edx, 0x10
    mul edx
    add eax, 0x90
    mov ecx, eax

    ; Use Mem_Set
    mov ebx, [AHCI_CMD_TABLE_ADDRESS]
    xor edx, edx
    call Mem_Set

    mov eax, [AHCI_CMD_TABLE_ADDRESS]
    add eax, HBA_CMD_LIST.PRDT
    mov [AHCI_PRDT_ENTRY_ADDRESS], eax

    mov ecx, [.Counter]

    .Setup_PRDT:
        ; Check if it should end
        mov eax, [AHCI_CMD_HEADER_ADDRESS]
        mov bx, [eax + HBA_CMD_HEADER.PRDTL]
        dec bx
        cmp cx, bx
        jge .PRDT_Loop_End

        ; Set the PRDT address
        mov ebx, [AHCI_CMD_TABLE_ADDRESS]
        add ebx, HBA_CMD_LIST.PRDT
        mov eax, 0x10
        mul ecx
        add ebx, eax

        ; Set DBA
        mov eax, [AHCI_Read_BUFFER]
        mov [ebx + HBA_PRDT_ENTRY.DBA], eax

        ; Set DBC and I
        mov eax, [ebx + HBA_PRDT_ENTRY.DBC]
        and eax, (0b1111111111 << 22)
        or eax, 1<<31
        or eax, 8*1024-1
        mov [ebx + HBA_PRDT_ENTRY.DBC], eax

        ; Increase the buffer by 4kb
        mov ebx, [AHCI_Read_BUFFER]
        add ebx, 8 * 1024
        mov [AHCI_Read_BUFFER], ebx

        ; Decrease the count
        mov ebx, [AHCI_Read_COUNT]
        sub ebx, 16
        mov [AHCI_Read_COUNT], ebx

        ; Increase the counter
        mov ecx, [.Counter]
        inc ecx
        mov [.Counter], ecx

        jmp .Setup_PRDT
    
    .PRDT_Loop_End:

    ; Go to the next PRDT entry
    mov esi, [AHCI_CMD_HEADER_ADDRESS]
    xor eax, eax
    mov ax, [esi + HBA_CMD_HEADER.PRDTL]
    dec eax

    mov ecx, 0x10
    mul ecx

    mov ecx, [AHCI_PRDT_ENTRY_ADDRESS]
    add eax, ecx
    mov esi, eax
    mov [AHCI_PRDT_ENTRY_ADDRESS], esi

    ; Load the buffer to the PRDT
    mov eax, [AHCI_Read_BUFFER]
    mov [esi + HBA_PRDT_ENTRY.DBA], eax

    mov eax, [esi + HBA_PRDT_ENTRY.DBC]
    and eax, (0b1111111111 << 22)
    or eax, 1<<31
    mov ecx, [AHCI_Read_COUNT]
    shl ecx, 9
    dec ecx
    or eax, ecx
    mov [esi + HBA_PRDT_ENTRY.DBC], eax

    ; Setup FIS
    mov esi, [AHCI_CMD_TABLE_ADDRESS]

    ; Set type to Register H2D
    mov byte [esi + FIS_H2D.FIS_TYPE], 0x27

    ; Enable it to command
    mov al, [esi + FIS_H2D.PMPORT]
    or al, 1<<7
    mov [esi + FIS_H2D.PMPORT], al

    ; Set the command
    mov byte [esi + FIS_H2D.CMD], 0x25 ; Idk what to put here, wiki is too secretive

    ; Fill LBA0 - 2
    mov eax, [AHCI_Read_STARTL]
    mov [esi + FIS_H2D.LBA0], al
    shr eax, 8
    mov [esi + FIS_H2D.LBA1], al
    shr eax, 8
    mov [esi + FIS_H2D.LBA2], al

    ; Set Device to LBA mode
    mov byte [esi + FIS_H2D.DEVICE], 1<<6

    ; Fill LBA0 - 2
    shr eax, 8
    mov [esi + FIS_H2D.LBA3], al
    mov eax, [AHCI_Read_STARTH]
    mov [esi + FIS_H2D.LBA4], al
    shr eax, 8
    mov [esi + FIS_H2D.LBA5], al

    ; Set count
    mov eax, [AHCI_Read_COUNT]
    and eax, 0xFF
    mov [esi + FIS_H2D.COUNTL], al

    mov eax, [AHCI_Read_COUNT]
    shr eax, 8
    and eax, 0xFF
    mov [esi + FIS_H2D.COUNTH], al

    xor ecx, ecx

    .Spin_Loop:
        mov ebx, [AHCI_PORT_ADDRESS]
        mov eax, [ebx + HBA_PORT.TASK_FILE_DATA]
        and eax, 0x88
        jz .Spin_End

        cmp ecx, 1000000
        jg .Fail

        inc ecx
        jmp .Spin_Loop

    .Spin_End:

    ; Start the command
    mov esi, [AHCI_PORT_ADDRESS]
    mov ecx, [.Slot]
    xor eax, eax
    inc eax
    shl eax, cl
    mov [esi + HBA_PORT.CMD_ISSUE], eax

    .Complete_Loop:
        mov ecx, [.Slot]
        xor eax, eax
        inc eax
        shl eax, cl

        mov ecx, [ebx + HBA_PORT.CMD_ISSUE]
        and eax, ecx
        jz .Complete_End

        mov eax, [ebx + HBA_PORT.INTERRUPT_STATUS]
        and eax, HBA_PxIS_TFES
        jnz .Fail

        jmp .Complete_Loop

    .Complete_End:

    mov eax, [ebx + HBA_PORT.INTERRUPT_STATUS]
    and eax, HBA_PxIS_TFES
    jnz .Fail

    ; Return
    xor eax, eax
    inc eax
    ret

    ; False
    .Fail:
        xor eax, eax
        ret

    .Counter: db 0x00
    .Slot: dd 0x00000000

; Finds a free command slot
; Out:
; - eax, type
AHCI_Find_Command_Slot:
    mov esi, [AHCI_PORT_ADDRESS]
    mov eax, [esi + HBA_PORT.ST_ACTIVE]
    mov ebx, [esi + HBA_PORT.CMD_ISSUE]
    or eax, ebx
    mov [.SLOT], eax

    xor ecx, ecx

    .Loop:
        mov edx, [AHCI_CMD_LIST_LENGHT]
        cmp ecx, edx
        jge .Fail

        and eax, 1
        jz .Pass
        
        mov eax, [.SLOT]
        shr eax, 1
        mov [.SLOT], eax

        inc ecx
        jmp .Loop

    .Pass:
        mov eax, ecx
        ret

    .Fail:
        xor eax, eax
        dec eax
        ret

    .SLOT: dd 0x00000000

; AHCI variables
AHCI_HBA_ADDRESS: dd 0
AHCI_PORT_ADDRESS: dd 0
AHCI_CMD_HEADER_ADDRESS: dd 0
AHCI_CMD_TABLE_ADDRESS: dd 0
AHCI_PRDT_ENTRY_ADDRESS: dd 0
AHCI_CMD_LIST_LENGHT: dd 0
AHCI_AVAILIBLE_PORTS: times 32 db 0