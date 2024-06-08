%define AHCI_Base 0x400000
%define COMMAND_AMOUNT 18

%define CPUID_FEAT_EDX_MSR           1 << 5
%define CPUID_FEAT_EDX_APIC          1 << 9

%define Entry_Code_32_Bits              1 << 0
%define Entry_Code_64_Bits              1 << 1
%define Entry_Code_Null_1               1 << 2
%define Entry_Code_Null_2               1 << 3
%define Entry_Code_Error_Corrupt        1 << 4
%define Entry_Code_Error_Missing        1 << 5
%define Entry_Code_Error_MZ             1 << 6
%define Entry_Code_Error_PE             1 << 7
%define Entry_Code_Error_Longmode       1 << 8

%define HBA_PxCMD_ST                            0x0001
%define HBA_PxCMD_FRE                           0x0010
%define HBA_PxCMD_FR                            0x4000
%define HBA_PxCMD_CR                            0x8000
%define HBA_PxIS_TFES                           1<<30

%define IA32_APIC_BASE_MSR 0x1B
%define IA32_APIC_BASE_MSR_BSP 0x100
%define IA32_APIC_BASE_MSR_ENABLE 0x800

%define PAGING_ADDRESS 0x80000