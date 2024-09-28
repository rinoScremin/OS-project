;+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+------------------------------+
;| P   | R/W | U/S | PWT | PCD | A   | D   | PS  | G   | Avl | Page Table Base Address (40 bits) |
;+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+------------------------------+
PageDirectorys:    

    mov edx, 0x00000000  ; Load EDX with the high part of the dividend
    mov eax, [total_pages]
    mov ebx, [page_table_size]
    
    div ebx 
    cmp edx, 0x0
    jz .no_new_entry_needed
    inc eax
    .no_new_entry_needed:
    mov [number_of_page_directorys_needed], eax
    mov eax, [page_table_start_address]    ; Load the lower part of the base address into EAX

    mov edi, [system_PageTables_address_offset]
    mov [page_directorys_start_address], edi

    mov edx, edi
    and edx, 0xfff
    cmp edx, 0x0
    jz .page_is_aligned
    sub edi, edx
    add edi, 0x1000
    .page_is_aligned:
    mov [page_directorys_start_address], edi

    ;--------------------------message---------------------------------
    mov si, PD_set_up_msg
    call print32

    mov edi, [page_directorys_start_address]
    mov [input32], edi
    call hex_to_str32_input
    mov si, buffer32
    call print32
    ;--------------------------message---------------------------------

    xor edx, edx
    xor esi, esi                  ; Clear ESI for use as a loop counter
    xor ebp, ebp 
    xor ecx, ecx 

    mov eax, [page_table_start_address] 
    or eax, [tmp_table_flags]
    .loop_create_entries:

        mov [edi], edx
        add edi, 4

        mov [edi], eax
        add edi, 4
        
        add eax, [page_table_size]
        adc edx, 0

        inc esi
        cmp esi, [number_of_page_directorys_needed]
        jnz .loop_create_entries

    mov [page_directorys_end_address], edi

    ;--------------------------message---------------------------------
    mov esp, 0x90000
    mov si, PD_finish_msg
    call print32

    mov edi, [number_of_page_directorys_needed]
    mov [input32], edi
    call hex_to_str32_input
    mov si, buffer32
    call print32

    mov si, PD_end_address_msg
    call print32    

    mov edi, [page_directorys_end_address]
    mov [input32], edi
    call hex_to_str32_input
    mov si, buffer32
    call print32
    ;--------------------------message---------------------------------

    jmp PageDirectoryPointerTable

number_of_page_directorys_needed: dd 0x0
page_table_size: dd 0x1000 
page_directorys_end_address: dd 0x0
page_directorys_start_address: dd 0x0
page_directory_flags: dd 00000011b 


PD_set_up_msg db 'Setting Up Page Directorys at address:', 0
PD_finish_msg db 'page directory table complete! number of entries:', 0
PD_end_address_msg db 'page directory end address:', 0

