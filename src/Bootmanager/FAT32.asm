;*****************************************
; Title: FAT32 service
; Desc: Manages the FAT32 filesystem
; Location: src/Bootmanager/FAT32.asm
;*****************************************

; Initalizes the FAT32 service
; Does nothing for now
Init_FAT32:
    xor eax, eax
    inc eax
    ret

    .Init_FAT32_Fail:
        xor eax, eax
        ret

; Finds a path for a file
; Inp:
; - eax, folder buffer
; - ebx, file buffer
; - ecx, count
; - edx, path name
; Out:
; - eax, error
FAT32_Find_Path:
    mov [.FOLDER_BUFFER], eax
    mov [.FILE_BUFFER], ebx
    mov [.COUNT], ecx
    mov esi, edx
    xor eax, eax
    xor ebx, ebx

    ; Clear the path buffer
    .Clear_Buffer_Loop:
        cmp ebx, 260
        je .Clear_Buffer_End

        mov byte [FAT32_PATH_BUFFER + ebx], 0

        inc ebx
        jmp .Clear_Buffer_Loop

    .Clear_Buffer_End:
        xor ebx, ebx

    ; Load the name into the buffer
    .Replace_Buffer_Loop:
        mov al, [esi + ebx]

        test al, al
        jz .Replace_Buffer_End

        cmp ebx, 260
        je .Replace_Buffer_End

        mov [FAT32_PATH_BUFFER + ebx], al

        inc ebx
        jmp .Replace_Buffer_Loop

    .Replace_Buffer_End:
        call FAT32_Push_Name

    ; Load first cluster and load it
    call FAT32_Get_Root
    mov [AHCI_Read_STARTL], eax
    mov dword [AHCI_Read_STARTH], 0x00
    xor ebx, ebx
    mov bl, [BPB_SECTORS_PER_CLUSTER]
    mov [AHCI_Read_COUNT], edx
    mov edx, [.FOLDER_BUFFER]
    mov [AHCI_Read_BUFFER], edx
    call AHCI_Read

    ; Load the root folder
    mov eax, [.FOLDER_BUFFER]
    mov ebx, FAT32_NAME_BUFFER_PUSH
    mov ecx, eax
    call FAT32_Read_Folder
    test eax, eax
    jz .Fail

    .Load_Folders:
        mov eax, [FAT32_PATH_BUFFER]
        test eax, eax
        jz .Load_Folders_End

        call FAT32_Push_Name
        mov ebx, [FAT32_PATH_BUFFER]
        test ebx, ebx
        jz .Load_File

        mov eax, [.FOLDER_BUFFER]
        mov ebx, FAT32_NAME_BUFFER_PUSH
        mov ecx, eax
        call FAT32_Read_Folder
        test eax, eax
        jz .Fail
        jmp .Load_Folders

    .Load_File:
        mov eax, [.FOLDER_BUFFER]
        mov ebx, FAT32_NAME_BUFFER_PUSH
        mov ecx, [.FILE_BUFFER]
        mov edx, [.COUNT]
        call FAT32_Read_File
        test eax, eax
        jz .Fail
        jmp .Load_Folders_End

    .Load_Folders_End:
        xor eax, eax
        inc eax
        ret

    .Fail:
        mov eax, .FOLDER_BUFFER
        call Print_32

        xor eax, eax
        ret

    .FOLDER_BUFFER: dd 0x00000000
    .FILE_BUFFER: dd 0x00000000
    .COUNT: dd 0x00000000

; Pushes a name from the path into a buffer
FAT32_Push_Name:
    xor ebx, ebx

    .Wipe_Name_Loop:
        cmp ebx, 256
        je .Wipe_Name_End

        mov byte [FAT32_NAME_BUFFER_PUSH + ebx], 0

        inc ebx
        jmp .Wipe_Name_Loop

    .Wipe_Name_End:
        xor ebx, ebx

    .Load_Path_Loop:
        mov al, [FAT32_PATH_BUFFER + ebx]
        mov [FAT32_NAME_BUFFER_PUSH + ebx], al

        cmp al, 0
        je .Load_Path_End_Zero
        cmp al, '/'
        je .Load_Path_End_Slash

        inc ebx
        jmp .Load_Path_Loop

    .Load_Path_End_Slash:
        xor edx, edx
        inc edx
        jmp .Load_Path_End

    .Load_Path_End_Zero:
        xor edx, edx

    .Load_Path_End:
        mov byte [FAT32_NAME_BUFFER_PUSH + ebx], 0
        xor ecx, ecx
        inc ebx

    .Shift_Path_Loop:
        mov al, [FAT32_PATH_BUFFER + ebx + ecx]
    
        test al, al
        jz .Shift_Path_Ret

        mov [FAT32_PATH_BUFFER + ecx], al

        inc ecx
        jmp .Shift_Path_Loop

    .Shift_Path_Ret:

    .Clear_Path_Loop:
        mov byte [FAT32_PATH_BUFFER + ebx + ecx], 0

        test ebx, ebx
        jz .Clear_Path_End

        dec ebx
        jmp .Clear_Path_Loop

    .Clear_Path_End:
        ret

; Gets the root directory
FAT32_Get_Root:
    xor edx, edx
    mov eax, [BPB_FAT32_SECTORS_PER_FAT]
    mov dl, [BPB_AMOUNT_OF_FATS]
    mul edx
    xor edx, edx

    mov dx, [BPB_RESERVED_SECTORS]
    add eax, edx
    ret

; Converts clustors to sectors
Cluster_To_Sector:
    xor edx, edx
    sub ax, 2
    mov dl, [BPB_SECTORS_PER_CLUSTER]
    mul edx
    ret

; Returns the entry location
; Inp:
; - eax, offset
; - ebx, index
; Out:
; - eax, address
; - ebx, flags
FAT32_Return_Entry:
    ; Get current index
    mov ecx, eax
    mov eax, ebx
    xor edx, edx
    mov dx, 0x20
    mul dx
    sub ax, 0x20
    add eax, ecx

    ; Load Attributes
    mov dl, [eax + FAT32_NORMAL_ENTRY.ATTRIBUTES]
    xor ebx, ebx

    ; Decide what type it is
    cmp dl, 0x20
    je .File
    cmp dl, 0x10
    je .Pass
    ret

    ; Sets the FILE flag
    .File:
        or ebx, 2

    ; Converts to LFN and sets the ACTIVE flag
    .Pass:
        or ebx, 1
        call FAT32_Convert_LFN
        ret

%macro InsertLetterLFN 1
    mov bl, [eax + %1]
    cmp bl, 0xFF
    je .End
    mov [FAT32_NAME_BUFFER + edx], bl
    inc edx
%endmacro

; Converts an 8.3 name into LFN
; Inp:
; - eax, name address
; Out:
; - eax, buffer address
FAT32_Convert_LFN:
    pushad

    ; Clear the name buffer
    xor ebx, ebx

    .Wipe_Name_Loop:
        cmp ebx, 256
        je .Wipe_Name_End

        mov byte [FAT32_NAME_BUFFER + ebx], 0

        inc ebx
        jmp .Wipe_Name_Loop

    .Wipe_Name_End:
    
    ; Check if there's a LFN entry before it.
    mov bl, [eax + FAT32_LFN_ENTRY.ATTRIBUTES - 0x20]
    cmp bl, 0x0F
    jne .83

    sub eax, 0x20
    xor edx, edx

    .LFN_Loop:
        mov bl, [eax + FAT32_LFN_ENTRY.ATTRIBUTES]
        cmp bl, 0x0F
        jne .End

        InsertLetterLFN FAT32_LFN_ENTRY.NAME_A
        InsertLetterLFN FAT32_LFN_ENTRY.NAME_A + 2
        InsertLetterLFN FAT32_LFN_ENTRY.NAME_A + 4
        InsertLetterLFN FAT32_LFN_ENTRY.NAME_A + 6
        InsertLetterLFN FAT32_LFN_ENTRY.NAME_A + 8

        InsertLetterLFN FAT32_LFN_ENTRY.NAME_B
        InsertLetterLFN FAT32_LFN_ENTRY.NAME_B + 2
        InsertLetterLFN FAT32_LFN_ENTRY.NAME_B + 4
        InsertLetterLFN FAT32_LFN_ENTRY.NAME_B + 6
        InsertLetterLFN FAT32_LFN_ENTRY.NAME_B + 8
        InsertLetterLFN FAT32_LFN_ENTRY.NAME_B + 10

        InsertLetterLFN FAT32_LFN_ENTRY.NAME_C
        InsertLetterLFN FAT32_LFN_ENTRY.NAME_C + 2

        sub eax, 0x20
        jmp .LFN_Loop

    ; If there's no LFN preceeding
    .83:
        xor ebx, ebx

        mov cl, [eax + FAT32_LFN_ENTRY.ATTRIBUTES]
        cmp cl, 0x20
        je .83_Loop_Name

    .83_Loop_Folder:
        cmp ebx, 11
        je .End

        mov cl, [eax + ebx]
        mov [FAT32_NAME_BUFFER + ebx], cl

        inc ebx
        jmp .83_Loop_Folder

    .83_Loop_Name:
        cmp ebx, 8
        je .83_Seperator

        mov cl, [eax + ebx]
        mov [FAT32_NAME_BUFFER + ebx], cl

        inc ebx
        jmp .83_Loop_Name

    .83_Seperator:
        mov byte [FAT32_NAME_BUFFER + ebx], '.'

    .83_Loop_Ext:
        cmp ebx, 11
        je .End

        mov cl, [eax + ebx]
        mov [FAT32_NAME_BUFFER + 1 + ebx], cl

        inc ebx
        jmp .83_Loop_Ext

    .End:
        popad
        mov eax, FAT32_NAME_BUFFER
        ret

; Finds an entry of a folder
; Inp:
; - eax, location buffer
; - ebx, name address
; Out:
; - eax, does exist
; - ebx, starting sector
FAT32_Find_Folder:
    mov [.ADDRESS], eax
    mov [.NAME], ebx

    mov ax, 0x10
    xor bx, bx
    mov bl, [BPB_SECTORS_PER_CLUSTER]
    mul bx
    mov [.COUNTER], ax

    .Loop_Folder:
        mov eax, [.ADDRESS]
        xor ebx, ebx
        mov bx, [.COUNTER]
        xor ecx, ecx
        xor edx, edx
        call FAT32_Return_Entry
        
        ; Check results
        mov ecx, ebx
        and ecx, 1
        jz .Loop_Folder_End
        mov ecx, ebx
        and ecx, 2
        jnz .Loop_Folder_End

        ; Compare
        mov ebx, [.NAME]
        call Str_Cmp
        test edx, edx
        jnz .Pass

        ; Check and loop
        .Loop_Folder_End:
            ; Decrease counter
            mov bx, [.COUNTER]
            dec bx
            mov [.COUNTER], bx

            test bx, bx
            jz .Fail

        jmp .Loop_Folder

    .Pass:
        xor eax, eax
        mov ax, [.COUNTER]
        xor edx, edx
        mov dx, 0x20
        mul dx
        sub ax, 0x20
        add eax, [.ADDRESS]
        
        xor ebx, ebx
        mov bx, [eax + FAT32_NORMAL_ENTRY.CLUSTER_HIGH]
        shl ebx, 8
        mov bx, [eax + FAT32_NORMAL_ENTRY.CLUSTER_LOW]
        
        mov eax, ebx
        call Cluster_To_Sector
        mov ebx, eax
        call FAT32_Get_Root
        add ebx, eax

        xor eax, eax
        inc eax
        ret

    .Fail:
        xor eax, eax
        ret

    .COUNTER dw 0
    .ADDRESS dd 0
    .NAME dd 0

; Loads a folder
; Inp:
; - eax, folder location
; - ebx, name address
; - ecx, folder buffer
; Out:
; - eax, does exist
FAT32_Read_Folder:
    call FAT32_Find_Folder
    test eax, eax
    jz .FAT32_Read_Folder_Fail

    ; Load the folder
    mov [AHCI_Read_STARTL], ebx
    mov dword [AHCI_Read_STARTH], 0x00

    xor ebx, ebx
    mov bl, [BPB_SECTORS_PER_CLUSTER]
    mov [AHCI_Read_COUNT], edx

    mov edx, [FAT32_Find_Folder.ADDRESS]
    mov [AHCI_Read_BUFFER], edx
    call AHCI_Read

    xor eax, eax
    inc eax
    ret

    .FAT32_Read_Folder_Fail:
        xor eax, eax
        ret

FAT32_Create_Folder:
    ret

FAT32_Delete_Folder:
    ret

; Finds a file
; Inp:
; - eax, location buffer
; - ebx, name address
; - edx, count
; Out:
; - eax, does exist
; - ebx, starting sector
; - ecx, count
; - edx, buffer
FAT32_Find_File:
    mov [.DIRECTORY], eax
    mov [.NAME], ebx
    mov [.COUNT], edx

    mov ax, 0x10
    xor bx, bx
    mov bl, [BPB_SECTORS_PER_CLUSTER]
    mul bx
    mov [.COUNTER], ax

    .Loop_File:
        mov eax, [.DIRECTORY]
        xor ebx, ebx
        mov bx, [.COUNTER]
        xor ecx, ecx
        xor edx, edx
        call FAT32_Return_Entry
        
        ; Check results
        mov ecx, ebx
        and ecx, 1
        jz .Loop_File_End
        mov ecx, ebx
        and ecx, 2
        jz .Loop_File_End

        ; Compare
        mov ebx, [.NAME]
        call Str_Cmp
        test edx, edx
        jnz .Pass

        ; Check and loop
        .Loop_File_End:
            ; Decrease counter
            mov bx, [.COUNTER]
            dec bx
            mov [.COUNTER], bx

            test bx, bx
            jz .Fail

        jmp .Loop_File

    .Pass:
        xor eax, eax
        mov ax, [.COUNTER]
        xor edx, edx
        mov dx, 0x20
        mul dx
        sub ax, 0x20
        add eax, [.DIRECTORY]

        xor ebx, ebx
        mov bx, [eax + FAT32_NORMAL_ENTRY.CLUSTER_HIGH]
        shl ebx, 8
        mov bx, [eax + FAT32_NORMAL_ENTRY.CLUSTER_LOW]

        mov ecx, [.COUNT]
        test ecx, ecx
        jnz .Skip_Size_Calculations

        mov ebx, eax
        mov eax, [ebx + FAT32_NORMAL_ENTRY.SIZE]
        xor edx, edx
        mov ecx, 0x200
        div ecx

        test edx, edx
        jz .Pass_No_Remain
        inc eax

    .Pass_No_Remain:
        mov ecx, eax
        mov eax, ebx

    .Skip_Size_Calculations:
        xor ebx, ebx
        mov bx, [eax + FAT32_NORMAL_ENTRY.CLUSTER_HIGH]
        shl ebx, 8
        mov bx, [eax + FAT32_NORMAL_ENTRY.CLUSTER_LOW]
        
        mov eax, ebx
        call Cluster_To_Sector
        mov ebx, eax
        call FAT32_Get_Root
        add ebx, eax

        xor eax, eax
        inc eax
        ret

    .Fail:
        xor eax, eax
        ret

    .COUNT: dd 0x00000000
    .COUNTER: dw 0x0000
    .DIRECTORY: dd 0x00000000
    .NAME: dd 0x00000000
    .ADDRESS: dd 0x00000000

; Loads a file
; Inp:
; - eax, location buffer
; - ebx, name address
; - ecx, file buffer
; - edx, count
; Out:
; - eax, does exist
FAT32_Read_File:
    mov [.LOCATION], ecx

    call FAT32_Find_File
    test eax, eax
    jz .FAT32_Read_File_Fail

    ; Load the file
    add ebx, [.START_OFFSET]
    mov [AHCI_Read_STARTL], ebx
    mov dword [AHCI_Read_STARTH], 0x00
    mov [AHCI_Read_COUNT], ecx
    mov edx, [.LOCATION]
    mov [AHCI_Read_BUFFER], edx
    call AHCI_Read

    xor eax, eax
    inc eax
    ret

    .FAT32_Read_File_Fail:
        xor eax, eax
        ret

    .LOCATION: dd 0x00000000
    .START_OFFSET: dd 0x00000000

FAT32_Create_File:
    ret

FAT32_Delete_File:
    ret

; Buffers
FAT32_PATH_BUFFER: times 260 db 0
FAT32_NAME_BUFFER_PUSH: times 255 db 0
FAT32_NAME_BUFFER: times 255 db 0