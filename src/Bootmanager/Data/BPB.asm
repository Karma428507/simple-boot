; BPB
BPB_JMP_CODE: db 0, 0, 0
BPB_OEM_IDENT: db "        "
BPB_BYTES_PER_SECTOR: dw 0
BPB_SECTORS_PER_CLUSTER: db 0
BPB_RESERVED_SECTORS: dw 0
BPB_AMOUNT_OF_FATS: db 0
BPB_AMOUNT_OF_ROOT_DIRECTORIES: dw 0
BPB_SECTORS_IN_LOGICAL_VOLUME: dw 0
BPB_MEDIA_DESCRIPTOR_TYPE: db 0
BPB_FAT_12_16_RESERVED: dw 0
BPB_SECTORS_PER_TRACT: dw 0
BPB_HEADS_ON_TRACT: dw 0
BPB_HIDDEN_SECTORS: dd 0
BPB_LARGE_SECTOR_COUNT: dd 0

; FAT32 BPB
BPB_FAT32_SECTORS_PER_FAT: dd 0
BPB_FAT32_FAT_FLAGS: dw 0
BPB_FAT32_FAT_VERSION: dw 0
BPB_FAT32_CLUSTER_ROOT_NUMBER: dd 0
BPB_FAT32_FS_INFO_LOCATION: dw 0
BPB_FAT32_BACKUP_BOOT_SECTOR_LOCATION: dw 0
BPB_FAT32_FAT_RESERVED: db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
BPB_FAT32_DRIVE_NUMBER: db 0
BPB_FAT32_WINDOWS_NT_FLAGS: db 0
BPB_FAT32_SIGNATURE: db 0
BPB_FAT32_VOLUME_ID: dd 0
BPB_FAT32_VOLUME_SERIAL: db "           "
BPB_FAT32_INDENTIFIER: db "        "