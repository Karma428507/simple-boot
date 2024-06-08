# Simpleboot
This project is to help OS developers have a easy way of booting into there own systems without the need of worrying about trying to run a file in 512 bytes, trying to build an ELF reader, using a large amount of assembly and mode transitioning. We also provide a 'root' folder to allow the developer to put there system files for ease of access. This manager is intended for beginners at this version with internal tools and multiboot information not present yet.

## Features
Due to this manager being in early versions, it is limited on what it can do. However it can still function as any other manager with the features being:
- FAT32 support
- ACHI support
- ELF support
- Multiple OS support (max 5)

Due to this being an early version and lack of time developing, ATA drive is not supported yet.

## Setting up
This manager has only four steps to set up:
- Setup environment
- Link Kernel
- Assemble code
- Prepare disk

This project already does all steps except for linking your kernel within the bash file but all steps will be explained below so you're not required to use the bash file.

> WARNING: The bash file creates a disk image that's 4 GB, this can be adjusted.

### Setup environment
To setup the environment you'll need a folder named **root**, this folder is where the boot manager and your OS is located in. Within **root**, create a folder called **System** and inside that folder create a folder called **Boot**. The boot folder is where the boot manager is located in. The manager must be inside **root/System/Boot/** since the boot sector only searches that path and loads the manager. Your OS can be in any location as long as it's a path within the disk.

### Link Kernel
Linking the kernel is a simple step but you are required to edit a file within the source code, luckily the file in question are only assembly pre-processors. To link your OS(es) you must specify the amout of OSes within `%define TOTAL_ENTRIES`. If you're only linking one OS, only put '1' after it. Below is information about the OS that you'll need to put in. `%define OS_1_NAME` is of course the name of your OS and `%define OS_1_FILE` is the path to your OS. Having the name and path to your OS is required.

For example:

```
%define TOTAL_ENTRIES 2

%define OS_1_NAME "test A"
%define OS_1_FILE "root/System/Test.elf"

%define OS_2_NAME "test B"
%define OS_2_FILE "root/User/Public/OS/Build.elf"
```

### Assemble code
To assemble the code it's recommended that you use the bash file to assemble but you can assemble on your own bash file but it must be near the source code. The commands to assemble are:
> nasm -f bin src/bootsector.asm -o bin/bootsector.bin

and
> nasm -f bin src/Bootmanager/Main.asm -o root/System/BOOTMAN.bin

These commands are all that are required for assembling the source code.

### Prepare disk
Preparing the disk for booting is the most difficult step but still can be easy to add by either using the bash file or adding the commands below.

The first step is to build the disk, to build a disk run
> dd if=/dev/zero of=Disk.img bs=1 count=0 seek=(size of disk)

Running this will create a disk for your system, the second step is to convert it into a FAT32 system by running
> mkfs.vfat -F 32 Disk.img

The third step is to load all of the files needed into the disk, you'll need to copy all directories and files into a mounting point (a folder) and then run

> sudo mount -o loop Disk.img MOUNT

>sudo cp -r root MOUNT

After this unmount by running
> sudo umount MOUNT

The final step is to load the bootsector within the disk which would load the main manager. For this final step run
> dd if=bin/bootsector.bin of=Disk.img conv=notrunc bs=1 count=420 skip=90 seek=90

This command copies the boot sector assembly and puts in an 90 byte offset. This is the most important step for it being able to load BOOTMAN.bin and have the manager running.

### Running

Despite this not being a step on building, it is important to learn this to even run the code, for this you'll need QEMU and run the command
> qemu-system-x86_64 -drive id=disk,file=Disk.img,if=none -device ahci,id=ahci -device ide-hd,drive=disk,bus=ahci.0

Due to an ATA drive not being present, the emulator uses and AHCI device.

## Road map
These are the updates I'm planning to add to this manager, the 'Possible future updates' list are for things I'd like to add to the boot manager but don't know if I could.

### Version 1.1:
- Changing the config file into a seperate JSON file
- ATA driver support
- Having an executable to assemble the code and allow the manager to be placed anywhere
- Bug fixes

### Version 1.2:
- Improved ELF executer
- MULTIBOOT 2 information
- 16 bit program launcher
- OS memory restrictions (Can't boot to a kernel if it doesn't fit the size of RAM).

### Version 1.3:
- Improved FAT32 "driver"
- Terminal
- System information commands
- Built in text editor and hex editor

### Version 1.4:
- MBR support
- Different drive support
- FAT12/16 file support
- UEFI support

### Possible future updates
- GUI
- PE/COFF format support
- Internal assembler
- Custom script file
- NTFS support

## History

This project has started out as a low level game. This game was planned to be a few month project that started in 11/17/2023. After a weeks, I've decided to make a functional OS instead but I didn't know about filesystems yet and I was too stuborn to use GRUB. I've used MKFS.VFAT and created a boot sector that loads a file. After I've loaded into the kernel, I've spent two months creating an ACHI driver but realize that I need to finish this project soon. Building my FAT32 "driver" made me realize that I don't have time to make an OS but I can still make a boot manager. I've added all the features, fixed some bugs and made more optimised. After working on that I've published on GIT.