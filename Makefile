# Define the compiler and assembler
CC = gcc
AS = nasm

# Define the flags for the compiler
CFLAGS = -I.

# Define the flags for the assembler
ASFLAGS_ELF64 = -f elf64
ASFLAGS_BIN = -f bin

# Define the linker flags
LDFLAGS = -Ttext 0x1000 --oformat binary

# Define the target
TARGET = kernel.bin

# Define the source files
C_SRC = Kernel_print.c Kernel_main.c
ASM_ELF64_SRC = Kernel_init.asm
ASM_BIN_SRC = boot.asm

# Define the object files
OBJ = Kernel_init.o Kernel_main.o Kernel_print.o

BIN_OBJ = $(ASM_BIN_SRC:.asm=.bin)

# The default rule (usually the first rule)
all: final_kernel.bin

# Rule to create the target (linking ELF object files)
$(TARGET): $(OBJ)
	ld -o $(TARGET) $(LDFLAGS) $(OBJ)

# Rule to concatenate boot.bin and kernel.bin into final_kernel.bin
final_kernel.bin: boot.bin $(TARGET)
	cat boot.bin $(TARGET) > final_kernel.bin

# Rule to create the boot.bin file
boot.bin: $(ASM_BIN_SRC)
	$(AS) $(ASFLAGS_BIN) $< -o $@

# Rule to compile C files into object files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Rule to assemble .asm files into ELF64 object files
%.o: %.asm
	$(AS) $(ASFLAGS_ELF64) $< -o $@

# Clean up build files
clean:
	rm -f $(OBJ) $(TARGET) final_kernel.bin $(BIN_OBJ)

# Rule to test the final kernel using QEMU
run: final_kernel.bin
	dd if=final_kernel.bin of=main_floppy.img conv=notrunc
	qemu-system-x86_64 -enable-kvm -drive format=raw,file=main_floppy.img,if=floppy -monitor stdio -m 6G
