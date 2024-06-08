bash misc.sh

rmdir /S /Q C:\Users\knick\Desktop\OS_Dev\Insanity\MOUNT

qemu-system-x86_64 -drive id=disk,file=Disk.img,if=none -device ahci,id=ahci -device ide-hd,drive=disk,bus=ahci.0
pause