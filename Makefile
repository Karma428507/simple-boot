# Ignore this, this is just for testing different kernels
TARGET_32 = root/System/Kernels/Kernel.elf

# List of object files
OBJS_32 = bin/PM.o bin/PMEntry.o

# Compiler and linker flags
CFLAGS_32 = -m32 -std=gnu99 -ffreestanding -Wall -Wextra
LDFLAGS_32 = -T src/Kernels/linker.ld -nostdlib -m elf_i386

all: $(TARGET_32)

# Rule to build the target
$(TARGET_32): $(OBJS_32)
	ld $(LDFLAGS_32) -o $(TARGET_32) $(OBJS_32)

bin/PMEntry.o: src/Kernels/PM.asm
	nasm -f elf32 $< -o $@

bin/PM.o: src/Kernels/PM.c
	gcc $(CFLAGS_32) -c $< -o $@

# Clean up build files
clean:
	rm -f $(TARGET_32) $(OBJS_32)