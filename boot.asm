org 0x7c00
bits 16
;
; FAT12 header
; 
jmp short _start
nop

bdb_oem:                    db 'MSWIN4.1'           ; 8 bytes
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880                 ; 2880 * 512 = 1.44MB
bdb_media_descriptor_type:  db 0F0h                 ; F0 = 3.5" floppy disk
bdb_sectors_per_fat:        dw 9                    ; 9 sectors/fat
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

; extended boot record
ebr_drive_number:           db 0                    ; 0x00 floppy, 0x80 hdd, useless
                            db 0                    ; reserved
ebr_signature:              db 29h
ebr_volume_id:              db 12h, 34h, 56h, 78h   ; serial number, value doesn't matter
ebr_volume_label:           db 'NANOBYTE OS'        ; 11 bytes, padded with spaces
ebr_system_id:              db 'FAT12   '           ; 8 bytes

_start:
    mov ah,0x00 ; set mode
    mov al,0x03 ; text mode 80x25
    int 0x10

    cli

    jmp main

%include "real_mode_text-output.asm"    

mmap_idtentry_address_pointer: db 0x0000
mem_map_descriptor_sp_offset: dd 0x0000
msg1 db 'boot sector found!', 0
msg3 db '32BIT', 0
msg4 db ' ', 0
mmap_total_size: db 0x0000

%macro read_disk 5
    mov ah, 0x02                ; BIOS read function
    mov al, %1                  ; Number of sectors to read
    mov ch, %4                   ; Cylinder number (0 for simplicity)
    mov cl, %2                  ; Sector number (starting at 2 for example)
    mov dh, %5                   ; Head number (0 for simplicity)
    mov dl, [ebr_drive_number]  ; Drive number (stored in ebr_drive_number)
    mov bx, %3                  ; Buffer address
    int 0x13                    ; Call BIOS interrupt
    jc disk_error               ; Jump if carry flag is set (error)
%endmacro

main:
    
    ; setup data segments
    mov ax, 0                   ; can't set ds/es directly
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00              ; stack grows downwards from where we are loaded in memory    

    mov si, msg1
    call print16

    ; read something from floppy disk
    ; BIOS should set DL to drive number
    mov [ebr_drive_number], dl
    read_disk 15, 2, sector2, 0, 0

    mov sp, mem_map_descriptor

    read_memory_map:
        mov ax, 0x0800              ; Segment where the buffer is located
        mov es, ax
        xor di, di                  ; Offset within the segment
        xor ebx, ebx                ; Clear BX for the first call
        mov cx, 0x20                ; Buffer size (32 bytes)
        mov edx, 0x534D4150         ; 'SMAP' signature
    .loop:
        mov ax, 0xE820
        int 0x15
        jc .error                   ; Jump if carry flag is set (error)
        cmp eax, 0x534D4150         ; Check if EAX returns 'SMAP'
        jne .done                   ; Exit loop if not 'SMAP'

        ; Save the starting address to another segment
        mov bp, di
        add bp, memory_map_buffer
        push bp
        mov [mmap_idtentry_address_pointer], sp

        ; Continue reading the memory map
        mov bp, 0x0800              ; Segment where the buffer is located
        mov es, bp

        add di, cx                  ; Move to the next buffer position
        test ebx, ebx               ; Check if EBX is zero
        jnz .loop                   ; Repeat if EBX is not zero
        jmp .done                   ; Exit loop if EBX is zero
    .error:
        ; Handle error here (e.g., indicate no memory map available)
        jmp $ 
    .done:

    ; enable A20 line, this enables bit number 20 in the address
    in al,0x92
    or al,2
    out 0x92,al

    ; ds is uninitialized. lgdt uses ds as its segment so let's init it
    xor ax,ax
    mov ds,ax

    lgdt [GDT_PTR]
    ;lidt [IDTR]    

    mov eax,0x11 ; paging disabled, protection bit enabled. bit4, the extension type is always 1
    mov cr0,eax
    
    jmp GDT_BOOT_CS-GDT:protected_mode ; jump using our new code segment from the gdt to set cs

[bits 32]
protected_mode:
    ; Set up the data segment registers

    mov ax,GDT_BOOT_DS-GDT
    mov ds,ax
    mov ss,ax
    mov es,ax
    mov esp,0x90000 ; tmp stack.

    mov eax,0xA0
    mov cr4,eax

    ;call clear32
    ;mov si, msg3
    ;call print32

    ;jmp create_mem_map_PageTables

long_mode_set_up:
    ; 1. Set up the PT table
    mov eax, 0x7000               ; Starting physical address
    or eax, 0x3                   ; Set Present and RW flags
    mov [0x100000], eax           ; Page 1 (0x7000)
    
    mov eax, 0x8000               ; Starting physical address
    or eax, 0x3                   ; Set Present and RW flags
    mov [0x100008], eax           ; Page 2 (0x8000)

    mov eax, 0x9000               ; Starting physical address
    or eax, 0x3                   ; Set Present and RW flags
    mov [0x100010], eax           ; Page 3 (0x9000)

    mov eax, 0xA000               ; Starting physical address
    or eax, 0x3                   ; Set Present and RW flags
    mov [0x100018], eax           ; Page 4 (0xA000)

    ; 2. Set up the PD table
    mov eax, 0x100000             ; PT table address
    or eax, 0x3                   ; Set Present and RW flags
    mov [0x101000], eax           ; PD entry pointing to PT

    ; 3. Set up the PDPT table
    mov eax, 0x101000             ; PD table address
    or eax, 0x3                   ; Set Present and RW flags
    mov [0x102000], eax           ; PDPT entry pointing to PD
    
    ; 4. Set up the PML4 table
    mov eax, 0x102000             ; PDPT table address
    or eax, 0x3                   ; Set Present and RW flags
    mov [0x103000], eax           ; PML4 entry pointing to PDPT
    
    ; 6. Load the address of PML4 into CR3
    mov eax, 0x103000
    mov cr3, eax

    ; 7. Set Long Mode Enable in IA32_EFER MSR (64-bit register wrmsr)
    mov ecx, 0xC0000080           ; IA32_EFER MSR
    mov eax, 0x00000100           ; Set LME bit (bit 8)
    xor edx, edx
    wrmsr

    ; 8. Enable paging in CR0
    mov eax, cr0
    or eax, 0x80000000            ; Set PG bit (bit 31) to enable paging
    ;mov cr0, eax

    hlt

disk_error:
    jmp $

times 510-($-$$) db 0
dw 0AA55h

sector2:    ;sector 0x7e00
    %include "GDT_table.asm"
sector2_end:
times 0x200-(sector2_end-sector2) db 0
    
sector5:    ;sector 0x8000
    memory_map_buffer:
sector5_end:
times 0x200-(sector5_end-sector5) db 0
mem_map_descriptor:

sector3:    ;sector 0x8200
    %include "IDT_table.asm"
sector3_end:
times 0x400-(sector3_end-sector3) db 0

sector4:    ;sector 0x8600
    %include "ISRs.asm"
sector4_end:
times 0x200-(sector4_end-sector4) db 0

sector6:    ;sector 0x8800
    %include "PageDirectoryPointerTable.asm"
sector6_end:
times 0x200-(sector6_end-sector6) db 0

sector7:    ;sector 0x8a00
    %include "PML4.asm"
sector7_end:
times 0x200-(sector7_end-sector7) db 0

sector9:    ;sector 0x8c00
    %include "PageDirectorys.asm"
sector9_end:
times 0x200-(sector9_end-sector9) db 0

sector10:    ;sector 0x8e00
    %include "MemoryMap.asm"
sector10_end:
times 0x200-(sector10_end-sector10) db 0

sector11:    ;sector 0x9000
    %include "protected_mode_text-output.asm"
sector11_end:
times 0x200-(sector11_end-sector11) db 0

[bits 64]
sector12:    ;sector 0x9200
init_kernel:

hlt

;;pmemsave 0x00000000 0x80000000 ram_dump.bin