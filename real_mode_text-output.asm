Carriage_return db 0x0D, 0
Line_feed db 0x0A, 0

print16:
    pusha
    cld
    
.print_loop:
    lodsb            ; load value pointed to by 'si' in to 'al' then increment the 'si' register 
    cmp al, 0
    je .done
    call print_char
    jmp short .print_loop
.done:
    popa              
    ret

print_char:
    mov ah, 0eh      ; Function to write character in teletype mode
    mov bh, 0        ; Page number
    int 0x10         ; BIOS video interrupt
    ret

; Set cursor position to the top-left corner
%macro reset_cursor 2
    pusha
    mov ah, 0x02    ; Set cursor position function
    mov bh, 0x00    ; Page number
    mov dh, %1       ; Row
    mov dl, %2      ; Column
    int 0x10        ; BIOS interrupt for video services
    popa
%endmacro


hex_to_str16:
    pusha                    ; Save all registers

    ; Handle the first hex digit (bits 12-15)
    mov ax, [input16]
    shr ax, 12               ; Shift right by 12 bits to get the highest hex digit
    and ax, 0xF              ; Mask out all but the lowest 4 bits
    call digit_to_ascii
    mov [buffer16], al

    ; Handle the second hex digit (bits 8-11)
    mov ax, [input16]
    shr ax, 8                ; Shift right by 8 bits to get the second highest hex digit
    and ax, 0xF              ; Mask out all but the lowest 4 bits
    call digit_to_ascii
    mov [buffer16+1], al

    ; Handle the third hex digit (bits 4-7)
    mov ax, [input16]
    shr ax, 4                ; Shift right by 4 bits to get the third highest hex digit
    and ax, 0xF              ; Mask out all but the lowest 4 bits
    call digit_to_ascii
    mov [buffer16+2], al

    ; Handle the fourth hex digit (bits 0-3)
    mov ax, [input16]
    and ax, 0xF              ; Mask out all but the lowest 4 bits
    call digit_to_ascii
    mov [buffer16+3], al

    popa                     ; Restore all registers
    ret

digit_to_ascii:
    cmp al, 9
    jle .digit_is_number
    add al, 'A' - 10         ; Convert to ASCII letter (A-F)
    ret
.digit_is_number:
    add al, '0'              ; Convert to ASCII number (0-9)
    ret

buffer16: db 8 dup(0)            ; Buffer to store the hex string
input16: db 0
