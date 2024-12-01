// fastboot_stub.c
#include <stdio.h>

void fastboot_init() {
    printf("fastboot_init: Stubbed out\n");
}

void fastboot_flash(const char* partition, const char* image) {
    printf("fastboot_flash: Stubbed out\n");
}

// Add more functions as required by your project.
