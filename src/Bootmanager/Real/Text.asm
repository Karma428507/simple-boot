MEMORY_E820_VERIFY db "PAMS"
MEMORY_E820_MISSING db "Error, E820 not supported.", 0x00
MEMORY_E820_OVERFLOW db "Error, too many entries from the E820 map to be supported.", 0x00

STAGE_A_FAILED_SIGNATURE db "The signature passed into the manager doesn't match, halting the CPU", 0x00