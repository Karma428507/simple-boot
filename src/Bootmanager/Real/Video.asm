;*****************************************
; Title: Video Retriver
; Desc: Gets information from BIOS to provide video information
; Location: src/Bootmanager/Real/Video.asm
;*****************************************

VBE_Setup:
    xor ax, ax
    mov es, ax
    
    mov ax, 0x4f00
    mov di, VBE_CONTROL_INFO
	int 0x10
	cmp ax, 0x004f
	jne .Fail

    mov ax, 0x4f03
    int 0x10
    cmp ax, 0x004f
    jne .Fail
    mov [BIOS_DATA_TABLE.VBE_MODE], bx
    
    and bx, 0x3FFF
    mov ax, 0x4f01
    mov cx, bx
    mov di, VBE_MODE_INFO
    int 0x10
    cmp ax, 0x004f
    jne .Fail
    ret

    .Fail:
        ret