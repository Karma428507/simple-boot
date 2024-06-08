Init_ACPI:
    mov ecx, 0x80000

    .Init_ACPI_RSDP_Loop:
        mov eax, [ACPI_RSDP_SIGNATURE_A]
        cmp ecx, 0xFFFFF
        jg .Init_ACPI_Fail

        mov ebx, [ecx]
        cmp eax, ebx
        je .Init_ACPI_Confirm

        inc ecx
        jmp .Init_ACPI_RSDP_Loop

    .Init_ACPI_Confirm:
        mov [ACPI_RSDP_ADDRESS], ecx
        mov eax, [ACPI_RSDP_SIGNATURE_B]
        add ecx, 4

        mov ebx, [ecx]
        cmp eax, ebx
        je .Init_ACPI_Continue

        jmp .Init_ACPI_RSDP_Loop

    .Init_ACPI_Continue:
        mov ecx, [ACPI_RSDP_ADDRESS]
        mov ebx, [ecx + RSDP.ADDRESS]

        mov eax, 0x03
        int 0xA0
        ret

    .Init_ACPI_Fail:
        ret

ACPI_Shutdown:

ACPI_Reboot: