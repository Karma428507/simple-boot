static short* video = (short *)(0xb8000);

void printk(const char *msg) {

    for (int i = 0; msg[i] != 0; i++) {
        *video = msg[i] + (0x0F << 8);
        video++;
    }
}

void main(int signature) {
    printk("Example Kernel Test");

    while (1) {

    }
}