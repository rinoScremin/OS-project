;+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+------------------------------+
;| P   | R/W | U/S | PWT | PCD | A   | IGN | MBZ | AVL | AVL | Page Directory Pointer Table |
;|     |     |     |     |     |     |     |     |     |     | Base Address (40 bits)       |
;+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+------------------------------+
;|                             PDPT Base Address (Bits 12-51)                               |
;+------------------------------------------------------------------------------------------+
;|   AVL (Bits 52-62)  | NX |
;+---------------------+----+

PML4:
    mov edx, 0x00000000  ; Load EDX with the high part of the dividend
    mov eax, [number_PDPT_needed]
    mov ebx, [PML4_table_size]
    
    div ebx 
    cmp edx, 0x0
    jz .no_new_entry_needed
    inc eax
    .no_new_entry_needed:
    mov [number_PML4_tables_needed], eax

    mov eax, [PDPT_start_address]    ;the address where the PDT starts
    mov edi, [PDPT_end_address]                ;where to start the PDPT

    mov edx, edi
    and edx, 0xfff
    cmp edx, 0x0
    jz .page_is_aligned
    sub edi, edx
    add edi, 0x1000
    .page_is_aligned:
    mov [PML4_start_address], edi    

    xor edx, edx
    xor esi, esi                  ; Clear ESI for use as a loop counter
    xor ebp, ebp 
    xor ecx, ecx 

    mov eax, [PDPT_start_address]
    or eax, [tmp_table_flags]    
    
    .loop_create_entries:

        mov [edi], edx
        add edi, 4

        mov [edi], eax
        add edi, 4
        
        add eax, [PML4_table_size]
        adc edx, 0

        inc esi
        cmp esi, [number_PML4_tables_needed]
        jnz .loop_create_entries

    mov [PML4_end_address], edi

    ;--------------------------message---------------------------------
    mov esp, 0x90000
    mov si, PML4_finish_msg
    call print32

    mov edi, [number_PML4_tables_needed]
    mov [input32], edi
    call hex_to_str32_input
    mov si, buffer32
    call print32

    mov si, PML4_start_address_msg
    call print32    

    mov edi, [PML4_start_address]
    mov [input32], edi
    call hex_to_str32_input
    mov si, buffer32
    call print32
    ;--------------------------message---------------------------------

    jmp long_mode_set_up

hlt

PML4_start_address: dd 0x0
PML4_table_size: dd 0x1000 
PML4_end_address: dd 0x0
number_PML4_tables_needed: dd 0x0
PML4_flags: dd 00000011b ; or 0x00000083

PML4_set_up_msg db 'Setting Up PML4.....', 0
PML4_finish_msg db 'PML4 Complete! Number Of Entries:', 0
PML4_end_address_msg db 'PML4 end Address:', 0
PML4_start_address_msg db 'PML4 start Address:', 0