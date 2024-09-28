;Summary of the Memory Map
;Usable Memory:
;0x0000000000000000 to 0x000000000009FBFF (640 KB)
;0x0000000000100000 to 0x00000000007EEDFF (7.69 MB)

;Reserved Memory:
;0x000000000009FC00 to 0x000000000009FFFF (1 KB)
;0x00000000000F0000 to 0x00000000000FFFFF (64 KB)
;0x00000000007EE000 to 0x00000000007EE1FF (512 bytes)
;0x00000000007FE000 to 0x00000000007FEFFF (4 KB)
;0x00000000007FF000 to 0x00000000007FFFFF (4 KB)

;Base Address: 0x0000000000000000
;Length:       0x000000000009FC00 (654,336 bytes or 640 KB)
;Type:         0x00000001 (usable RAM)

;Base Address: 0x000000000009FC00
;Length:       0x0000000000000400 (1,024 bytes or 1 KB)
;Type:         0x00000002 (reserved memory)

;Base Addresses:
;0x0000000000000000 (Usable)
;0x000000000009FC00 (Reserved)
;0x00000000000F0000 (Reserved)
;0x0000000000100000 (Usable)
;0x00000000007EE000 (Reserved)
;0x00000000007FE000 (Reserved)
;0x00000000007FF000 (Reserved)

;+----------------------------------------------------------------------------+
;| 63     52 | 51       40 | 39       12 | 11  9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
;+-----------+-------------+-------------+-------+---+---+---+---+---+---+---+---+---+
;| Reserved  |  Physical   |  Physical   | Avl   | G | P | A | D | 0 | W | C | U | R |
;| (0)       | Address     | Address     |       |   |   |   |   |   | T | D | S | W |
;+----------------------------------------------------------------------------+

create_mem_map_PageTables:

    ;--------------------------message---------------------------------
    mov esp, 0x90000
    mov si, usable_memory_msg
    call print32
    ;--------------------------message---------------------------------

    xor eax, eax
    mov eax, [page_table_start_address]   ; START OF PAGE TABLE
    mov [system_PageTables_address_offset], eax

    xor esp, esp
    mov sp, [mmap_idtentry_address_pointer]
    mov [mmap_idtentry_address_pointer_start], sp

    .addVGA_MMap:
    pop di  ; mmap_idtentry_address 8
    mov sp, di
    ; Popping values in the correct order
    pop eax                    ; Pop Type (32 bits)
    pop ebx 
    pop ecx
    pop edx
    pop esi

    mov eax, 0x000B8000 ; address low
    mov ebx, 0x0        ; address high 
    mov ecx, 0x00000fff ; size low
    mov edx, 0x0        ; size high
    mov esi, 0x1        ; type (usable memory)

    push esi            ; push type
    push edx            ; push size high (0)
    push ecx            ; push size low (0x0fff)
    push ebx            ; push address high (0)
    push eax            ; push address low (0xB8000)

    mov sp, [mmap_idtentry_address_pointer]

    pop ax

    .create_PageTables:    

    pop ax  ; mmap_idtentry_address 7 
    
    mov [mmap_idtentry_address], ax

    mov [mmap_idtentry_address_pointer], sp

    mov sp, ax

    ; Popping values in the correct order
    pop ebx                    ; Pop Type (32 bits)
    pop ecx 
    pop edx
    pop esi
    pop edi
    
    ; Example of storing Base Address and Length:
    mov [Base_Address_Low], ebx
    mov [Base_Address_High], ecx

    cmp edi, 0x2    ;only add the Usable memory to the page table
    jz .skip_entry
    
    mov ebx, [page_size]      ; Load the divisor (4K or 0x1000)

    mov eax, edx          ; Move the lower 32 bits (EDX) into EAX
    mov edx, ecx          ; Move the upper 32 bits (ECX) into EDX
    div ebx               ; Divide the 64-bit value in EDX:EAX by EBX
                        ; Result: EAX will hold the quotient, EDX will hold the remainder
    cmp edx, 0x0
    jz .next
    inc eax
    .next:
    mov [pages_needed], eax

        ; Load the address of system_PageTables into a register
    mov edi, [system_PageTables_address_offset]   ; EDI will point to the start of system_PageTables in RAM

        ; Load the base address into EAX and EDX
    mov eax, [Base_Address_Low]    ; Load the lower part of the base address into EAX
    mov edx, [Base_Address_High]   ; Load the higher part of the base address into EDX
        
    ;--------------------------message---------------------------------
    mov esp, 0x90000
    mov [input32], edi
    call hex_to_str32_input
    mov si, buffer32
    call print32
    ;--------------------------message---------------------------------

    xor ebp, ebp  
    xor ebx, ebx 
    xor esi, esi 
    
    or eax, [tmp_table_flags]
    .loop_create_entries:

        mov [edi], edx
        add edi, 4

        mov [edi], eax
        add edi, 4
        
        add eax, [page_size]
        adc edx, 0

        inc esi
        cmp esi, [pages_needed]
        jnz .loop_create_entries

    mov eax, [mmap_idtentry_address] ; Load the full 32-bit value
    mov ebx, memory_map_buffer       ; Compare with the memory_map_buffer

    mov [system_PageTables_address_offset], edi

    .skip_entry:
    xor esp, esp 
    mov sp, [mmap_idtentry_address_pointer]     

    or eax,eax
    cmp eax, memory_map_buffer
    
    jnz .create_PageTables           ; Jump if not equal
    .done:

    ;--------------------------message---------------------------------
    mov esp, 0x90000

    mov si, complete_msg
    call print32

    mov si, page_table_ending_address_msg
    call print32

    mov [input32], edi
    call hex_to_str32_input
    mov si, buffer32
    call print32
    ;--------------------------message---------------------------------

    mov edi, [system_PageTables_address_offset]
    sub edi, [page_table_start_address]
    mov [total_pages],  edi
    
    jmp PageDirectorys
hlt    

page_table_start_address: dd 0x00100000
total_pages: dd 0x0
last_reserved_mmap_entry_low: dd 0x0
last_reserved_mmap_entry_high: dd 0x0
mmap_idtentry_address_pointer_start: dd 0x0
mmap_idtentry_address: dd 0x0
page_size: dd 0x1000
pages_needed: dd 0x0
system_PageTables_address_offset: dd 0x0

tmp_table_flags: dd 00000011b

Base_Address_Low:  dd 0x0
Base_Address_High: dd 0x0

usable_memory_msg db 'Usable Memory Pages:', 0
complete_msg db 'System MMap PT Complete!', 0
page_table_ending_address_msg db 'last PT Entry Address:', 0

