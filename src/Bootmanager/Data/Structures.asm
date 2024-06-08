ELF_32_STRUCTURE:
    .SIGNATURE                  equ 0
    .BITS                       equ 4
    .ENDIAN                     equ 5
    .VERSION_HEADER             equ 6
    .OS_ABI                     equ 7
    .PADDING                    equ 8
    .TYPE                       equ 16
    .INSTRUCTION                equ 18
    .VERSION                    equ 20
    .PROGRAM_ENTRY_OFFSET       equ 24
    .PROGRAM_HEADER_OFFSET      equ 28
    .SECTION_HEADER_OFFSET      equ 32
    .FLAGS                      equ 36
    .ELF_HEADER_SIZE            equ 40
    .PROGRAM_HEADER_SIZE        equ 42
    .PROGRAM_HEADER_NUMBER      equ 44
    .SECTION_HEADER_SIZE        equ 46
    .SECTION_HEADER_NUMBER      equ 48
    .SECTION_INDEX_STRING       equ 50

ELF_32_PROGRAM_STRUCTURE:
    .TYPE                       equ 0
    .DATA_OFFSET                equ 4
    .DATA_VIRTUAL_OFFSET        equ 8
    .DATA_PHYSICAL_ADDRESS      equ 12
    .DATA_SIZE                  equ 16
    .DATA_SIZE_MEMORY           equ 20
    .FLAGS                      equ 24
    .ALIGNMENT                  equ 28

ELF_64_STRUCTURE:
    .SIGNATURE                  equ 0
    .BITS                       equ 4
    .ENDIAN                     equ 5
    .VERSION_HEADER             equ 6
    .OS_ABI                     equ 7
    .PADDING                    equ 8
    .TYPE                       equ 16
    .INSTRUCTION                equ 18
    .VERSION                    equ 20
    .PROGRAM_ENTRY_OFFSET       equ 24
    .PROGRAM_HEADER_OFFSET      equ 32
    .SECTION_HEADER_OFFSET      equ 40
    .FLAGS                      equ 48
    .ELF_HEADER_SIZE            equ 52
    .PROGRAM_HEADER_SIZE        equ 54
    .PROGRAM_HEADER_NUMBER      equ 56
    .SECTION_HEADER_SIZE        equ 58
    .SECTION_HEADER_NUMBER      equ 60
    .SECTION_INDEX_STRING       equ 62

ELF_64_PROGRAM_STRUCTURE:
    .TYPE                       equ 0
    .FLAGS                      equ 4
    .DATA_OFFSET                equ 8
    .DATA_VIRTUAL_OFFSET        equ 16
    .DATA_PHYSICAL_ADDRESS      equ 24
    .DATA_SIZE                  equ 32
    .DATA_SIZE_MEMORY           equ 40
    .ALIGNMENT                  equ 48

FAT32_LFN_ENTRY:
    .ORDER                      equ 0x00
    .NAME_A                     equ 0x01
    .ATTRIBUTES                 equ 0x0B
    .ENTRY_TYPE                 equ 0x0C
    .CHECKSUM                   equ 0x0D
    .NAME_B                     equ 0x0E
    .ZERO                       equ 0x1A
    .NAME_C                     equ 0x1C

FAT32_NORMAL_ENTRY:
    .FILE_NAME                  equ 0x00
    .ATTRIBUTES                 equ 0x0B
    .RESERVED_NT                equ 0x0C
    .CREATION                   equ 0x0D
    .TIME                       equ 0x0E
    .DATE                       equ 0x10
    .ACCESS                     equ 0x12
    .CLUSTER_HIGH               equ 0x14
    .MOD_TIME                   equ 0x16
    .MOD_DATE                   equ 0x18
    .CLUSTER_LOW                equ 0x1A
    .SIZE                       equ 0x1C
    
FIS_D2H:
    .FIS_TYPE                   equ 0x00
    .PMPORT                     equ 0x01
    .STATUS                     equ 0x02
    .ERROR                      equ 0x03
    .LBA0                       equ 0x04
    .LBA1                       equ 0x05
    .LBA2                       equ 0x06
    .DEVICE                     equ 0x07
    .LBA3                       equ 0x08
    .LBA4                       equ 0x09
    .LBA5                       equ 0x0A
    .RESERVED_A                 equ 0x0B
    .COUNTL                     equ 0x0C
    .COUNTH                     equ 0x0D
    .RESERVED                   equ 0x0E

FIS_DATA:
    .FIS_TYPE                   equ 0x00
    .PMPORT                     equ 0x01
    .RESERVED                   equ 0x02
    .DATA                       equ 0x04

FIS_DMA_SETUP:


FIS_PIO_SETUP:


FIS_H2D:
    .FIS_TYPE                   equ 0x00
    .PMPORT                     equ 0x01
    .CMD                        equ 0x02
    .FEATUREL                   equ 0x03
    .LBA0                       equ 0x04
    .LBA1                       equ 0x05
    .LBA2                       equ 0x06
    .DEVICE                     equ 0x07
    .LBA3                       equ 0x08
    .LBA4                       equ 0x09
    .LBA5                       equ 0x0A
    .FEATUREH                   equ 0x0B
    .COUNTL                     equ 0x0C
    .COUNTH                     equ 0x0D
    .ICC                        equ 0x0E
    .CONTROLER                  equ 0x0F
    .RESERVED                   equ 0x10

JSON_ENTRIES:
    .NAME                       equ 0x00
    .TYPE                       equ 0x1B
    .VALUE                      equ 0x1C

OS_ENTRIES_STRUCTURE:
    .NAME                       equ 0x00
    .FILE_LOCATION              equ 0x20
    .MEMORY                     equ 0x120

HBA_CMD_HEADER:
    .CFL                        equ 0x00
    .PMP                        equ 0x01
    .PRDTL                      equ 0x02
    .PRDBC                      equ 0x04
    .CTBA                       equ 0x08
    .CTBA_UPPER                 equ 0x0C
    .RESERVED                   equ 0x0F

HBA_CMD_LIST:
    .CMD_FIS                    equ 0x00
    .ATAPI_CMD                  equ 0x40
    .RESERVED                   equ 0x50
    .PRDT                       equ 0x80

HBA_MEMORY:
    .HOST_CAP                   equ 0x0000
    .GLOBAL_HOST_CONTROLS       equ 0x0004
    .INTERRUPT_STATUS           equ 0x0008
    .PORT_IMPLEMENTED           equ 0x000C
    .VERSION                    equ 0x0010
    .CCC_CONTROL                equ 0x0014
    .CCC_PORTS                  equ 0x0018
    .EM_LOCATION                equ 0x001C
    .EM_CONTROL                 equ 0x0020
    .HOST_CAP_EXTENDED          equ 0x0024
    .BOHC                       equ 0x0028
    .RESERVED                   equ 0x002C
    .VENDOR                     equ 0x00A0
    .PORTS                      equ 0x0100

HBA_PORT:
    .CL_BASE_ADDRESS            equ 0x00
    .CL_BASE_ADDRESS_UPPER      equ 0x04
    .FIS_BASE_ADDRESS           equ 0x08
    .FIS_BASE_ADDRESS_UPPER     equ 0x0C
    .INTERRUPT_STATUS           equ 0x10
    .INTERRUPT_ENABLE           equ 0x14
    .CMD_AND_STATUS             equ 0x18
    .RESERVED_A                 equ 0x1C
    .TASK_FILE_DATA             equ 0x20
    .SIGNATURE                  equ 0x24
    .ST_STATUS                  equ 0x28
    .ST_CONTROL                 equ 0x2C
    .ST_ERROR                   equ 0x30
    .ST_ACTIVE                  equ 0x34
    .CMD_ISSUE                  equ 0x38
    .ST_NOTIFICATION            equ 0x3C
    .FISB_CONTROL_SWITCH        equ 0x40
    .RESERVED_B                 equ 0x44
    .VENDOR                     equ 0x70

HBA_PRDT_ENTRY:
    .DBA                        equ 0x00
    .DBA_UPPER                  equ 0x04
    .RESERVED                   equ 0x08
    .DBC                        equ 0x0C