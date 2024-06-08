Init_CMOS:
    call Load_CMOS_Data
    ret

Load_CMOS_Data:
    ; Wait if CMOS is updating
    .Load_CMOS_Data_Wait:
        mov dx, 0x70
        mov al, 0x0A
        out dx, al

        mov dx, 0x71
        in al, dx

        and al, 0x80
        jnz .Load_CMOS_Data_Wait

    ; Load date information
    mov al, 0x00
    call Get_RTC_Register
    mov [CMOS_SECOND], al

    mov al, 0x02
    call Get_RTC_Register
    mov [CMOS_MINUTE], al

    mov al, 0x04
    call Get_RTC_Register
    mov [CMOS_HOUR], al

    mov al, 0x07
    call Get_RTC_Register
    mov [CMOS_DAY], al

    mov al, 0x08
    call Get_RTC_Register
    mov [CMOS_MONTH], al

    mov al, 0x09
    call Get_RTC_Register
    mov [CMOS_YEAR], al

    ; Get info from status register B
    mov al, 0x0B
    call Get_RTC_Register
    and al, 0x04
    jnz .Load_CMOS_Data_Complete

    ; Convert the format from BCD to Binary

    ; Convert seconds
    xor ax, ax
    mov al, [CMOS_SECOND]
    mov cl, 16
    div cl
    mov cl, 10
    mul cl
    mov bl, [CMOS_SECOND]
    and bl, 0x0F
    add al, bl
    mov [CMOS_SECOND], al

    ; Convert minutes
    xor ax, ax
    mov al, [CMOS_MINUTE]
    mov cl, 16
    div cl
    mov cl, 10
    mul cl
    mov bl, [CMOS_MINUTE]
    and bl, 0x0F
    add al, bl
    mov [CMOS_MINUTE], al

    ; Convert hours (why are you like this?)
    xor ax, ax
    mov al, [CMOS_HOUR]
    and al, 0x70
    mov cl, 16
    div cl
    mov cl, 10
    mul cl
    mov bl, [CMOS_HOUR]
    and bl, 0x0F
    add al, bl
    mov bl, [CMOS_HOUR]
    and bl, 0x80
    or al, bl
    sub al, 4
    mov [CMOS_HOUR], al

    ; Convert days
    xor ax, ax
    mov al, [CMOS_DAY]
    mov cl, 16
    div cl
    mov cl, 10
    mul cl
    mov bl, [CMOS_DAY]
    and bl, 0x0F
    add al, bl
    mov [CMOS_DAY], al

    ; Convert months
    xor ax, ax
    mov al, [CMOS_MONTH]
    mov cl, 16
    div cl
    mov cl, 10
    mul cl
    mov bl, [CMOS_MONTH]
    and bl, 0x0F
    add al, bl
    mov [CMOS_MONTH], al

    ; Convert years
    xor ax, ax
    mov al, [CMOS_YEAR]
    mov cl, 16
    div cl
    mov cl, 10
    mul cl
    mov bl, [CMOS_YEAR]
    and bl, 0x0F
    add al, bl
    mov [CMOS_YEAR], al

    .Load_CMOS_Data_Complete:
        ret

Get_RTC_Register:
    mov dx, 0x70
    out dx, al

    mov dx, 0x71
    in al, dx
    ret