#include "Kernel_print.h"

// Inline functions to interact with ports
static inline void outb(unsigned short port, unsigned char data) {
    asm volatile("outb %0, %1" : : "a"(data), "Nd"(port));
}

static inline unsigned char inb(unsigned short port) {
    unsigned char result;
    asm volatile("inb %1, %0" : "=a"(result) : "Nd"(port));
    return result;
}

void reset_cursor(void) {
    set_cursor_offset(0); // Set cursor position to the start of the video memory
}

void set_cursor_offset(int offset) {
    outb(REG_SCREEN_CTRL, 14); // Set high byte
    outb(REG_SCREEN_DATA, (unsigned char)(offset >> 8));
    outb(REG_SCREEN_CTRL, 15); // Set low byte
    outb(REG_SCREEN_DATA, (unsigned char)(offset & 0xFF));
}

int get_cursor_offset(void) {
    outb(REG_SCREEN_CTRL, 14);
    int offset = inb(REG_SCREEN_DATA) << 8; // High byte
    outb(REG_SCREEN_CTRL, 15);
    offset += inb(REG_SCREEN_DATA); // Low byte
    return offset * 2; // Convert from cell offset to byte offset
}

int get_offset(int col, int row) {
    return 2 * (row * VGA_WIDTH + col);
}

int get_offset_row(int offset) {
    return offset / (2 * VGA_WIDTH);
}

int get_offset_col(int offset) {
    return (offset - (get_offset_row(offset) * 2 * VGA_WIDTH)) / 2;
}

void print_char(char character, int col, int row, char attribute_byte) {
    unsigned char *vidmem = (unsigned char *)VIDEO_MEMORY;
    if (!attribute_byte) {
        attribute_byte = 0x07; // Default color: light grey on black background
    }
    int offset;
    if (col >= 0 && row >= 0) {
        offset = get_offset(col, row);
    } else {
        offset = get_cursor_offset();
    }
    if (character == '\n') {
        int rows = get_offset_row(offset);
        offset = get_offset(0, rows + 1);
    } else {
        vidmem[offset] = character;
        vidmem[offset + 1] = attribute_byte;
        offset += 2;
    }
    set_cursor_offset(offset);
}

void print(const char* message) {
    int i = 0;
    while (message[i] != 0) {
        print_char(message[i++], -1, -1, 0);
    }
}

void clear_screen(void) {
    int screen_size = VGA_WIDTH * VGA_HEIGHT;
    unsigned char *vidmem = (unsigned char *)VIDEO_MEMORY;
    for (int i = 0; i < screen_size; i++) {
        vidmem[i * 2] = ' ';
        vidmem[i * 2 + 1] = 0x07;
    }
    reset_cursor();
}
