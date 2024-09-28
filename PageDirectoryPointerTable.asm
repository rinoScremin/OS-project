;+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+------------------------------+
;| P   | R/W | U/S | PWT | PCD | A   | Ign | PS  | Ign | Avl | Page Directory Base Address (40 bits) |
;+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+------------------------------+
;  0     1     2     3     4     5     6     7     8  11:9         51:12         63:52

PageDirectoryPointerTable:

    mov edx, 0x00000000  ; Load EDX with the high part of the dividend
    mov eax, [number_of_page_directorys_needed]
    mov ebx, [page_directory_table_size]
    
    div ebx 
    cmp edx, 0x0
    jz .no_new_entry_needed
    inc eax
    .no_new_entry_needed:
    mov [number_PDPT_needed], eax
    mov eax, [page_directorys_start_address]    ;the address where the PDT starts

    mov edi, [page_directorys_end_address] ;where to start the PDPT
    mov [PDPT_start_address], edi
    
    mov edx, edi
    and edx, 0xfff
    cmp edx, 0x0
    jz .page_is_aligned
    sub edi, edx
    add edi, 0x1000
    .page_is_aligned:
    mov [PDPT_start_address], edi

    ;--------------------------message---------------------------------
    mov esp, 0x90000
    mov si, PDPT_set_up_msg
    call print32

    mov edi, [PDPT_start_address]
    mov [input32], edi
    call hex_to_str32_input
    mov si, buffer32
    call print32
    ;--------------------------message---------------------------------    

    xor edx, edx
    xor esi, esi                  ; Clear ESI for use as a loop counter
    xor ebp, ebp 
    xor ecx, ecx 

    mov eax, [page_directorys_start_address]
    or eax, [tmp_table_flags]
    .loop_create_entries:

        mov [edi], edx
        add edi, 4

        mov [edi], eax
        add edi, 4
        
        add eax, [page_directory_table_size]
        adc edx, 0

        inc esi
        cmp esi, [number_PDPT_needed]
        jnz .loop_create_entries

    mov [PDPT_end_address], edi

    ;--------------------------message---------------------------------
    mov esp, 0x90000
    mov si, PDPT_finish_msg
    call print32

    mov edi, [number_PDPT_needed]
    mov [input32], edi
    call hex_to_str32_input
    mov si, buffer32
    call print32

    mov si, PDPT_end_address_msg
    call print32    

    mov edi, [PDPT_end_address]
    ;sub edi, 0x8
    mov [input32], edi
    call hex_to_str32_input
    mov si, buffer32
    call print32
    ;--------------------------message---------------------------------

    jmp PML4

hlt

page_directory_table_size: dd 0x1000 
PDPT_end_address: dd 0x0
PDPT_start_address: dd 0x0
number_PDPT_needed: dd 0x0
PDPT_flags: dd 00000011b ; or 0x00000083

PDPT_set_up_msg db 'Setting Up Page Directory Pointer Table at address:', 0
PDPT_finish_msg db 'Page Directory Pointer Table Complete! Number Of Entries:', 0
PDPT_end_address_msg db 'Page Directory Pointer Table End Address:', 0
