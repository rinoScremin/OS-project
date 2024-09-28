#ifndef KERNEL_PRINT_H
#define KERNEL_PRINT_H

#include <stddef.h>
#include <stdint.h>

// VGA screen constants
#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define VIDEO_MEMORY 0xB8000

// VGA port numbers
#define REG_SCREEN_CTRL 0x3D4
#define REG_SCREEN_DATA 0x3D5

// Function declarations
void reset_cursor(void);
void set_cursor_offset(int offset);
int get_cursor_offset(void);
int get_offset(int col, int row);
int get_offset_row(int offset);
int get_offset_col(int offset);
void print(const char* message);
void clear_screen(void);
void print_char(char character, int col, int row, char attribute_byte);

#endif
