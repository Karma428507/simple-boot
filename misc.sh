# Assembles the boot manager itself
nasm -f bin src/bootsector.asm -o bin/bootsector.bin
nasm -f bin src/Bootmanager/Main.asm -o root/System/BOOTMAN.bin

# This was used to create the test kernel.
#make

# Creates a 4GB disk
dd if=/dev/zero of=Disk.img bs=1 count=0 seek=4194304k
mkfs.vfat -F 32 Disk.img

# Creates a mounting point and loads the file into the image.
mkdir MOUNT
sudo mount -o loop Disk.img MOUNT
sudo cp -r root MOUNT
sudo umount MOUNT

# Adds the bootsector
dd if=bin/bootsector.bin of=Disk.img conv=notrunc bs=1 count=420 skip=90 seek=90