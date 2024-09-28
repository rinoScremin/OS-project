clear32:
    pusha
    mov edi, 0xB8000 ; Video memory start address in EDI
    mov ax, 0x0720   ; Character: space (0x20), Attribute: light grey on black (0x07)
    mov cx, 2000     ; 80 columns * 25 rows = 2000 characters
clear_loop:
    stosw            ; Store AX at [ES:EDI] and increment EDI by 2
    loop clear_loop  ; Loop until CX is 0
.done:
    popa            ; Restore all registers
    ret             ; Return from the function

bin_to_char:
    pusha                   ; Save all registers
    mov edi, buffer         ; Point to the buffer
    mov ecx, 16             ; We are dealing with a 16-bit number
    mov ebx, 1 << 15        ; Initialize EBX to have only the highest bit set
.convert_loop:
    test eax, ebx           ; Test the highest bit in EAX
    jz .set_zero            ; If the bit is 0, jump to set_zero
    mov byte [edi], '1'     ; Set buffer character to '1'
    jmp .next
.set_zero:
    mov byte [edi], '0'     ; Set buffer character to '0'
.next:
    inc edi                 ; Move to the next character in the buffer
    shr ebx, 1              ; Shift EBX right to test the next bit
    loop .convert_loop      ; Repeat for all 16 bits
    mov byte [edi], 0       ; Null-terminate the string
    popa                    ; Restore all registers
    ret

print32:
    pusha
    mov edi, [current_line]   ; Video memory start address in EDI
    ; ESI should be set to the address of the string before calling this function
.loop:
    lodsb                    ; Load byte at [ESI] into AL and increment ESI
    cmp al, 0                ; Check if the end of the string (null terminator)
    je .done                 ; If AL is 0, end of the string is reached
    mov [edi], al            ; Move the character to video memory
    inc edi                  ; Move to the next byte in video memory
    mov byte [edi], 0x07     ; Attribute byte: light grey on black background
    inc edi                  ; Move to the next byte in video memory (character cell is 2 bytes)
    jmp .loop                ; Repeat for the next character
.done:
    mov eax, [current_line]
    add eax, 160
    mov [current_line], eax
    popa                     ; Restore all registers
    ret                      ; Return from the function

int_to_str:
    push eax
    push ebx
    push edx
    mov ebx, divisorTable
    mov esi, buffer     ; Point to the start of the buffer
    mov edi, 0          ; To handle leading zeros
.nextDigit:
    xor edx, edx        ; Clear EDX (required for division)
    div dword [ebx]     ; EAX = quotient, EDX = remainder
    add eax, '0'        ; Convert quotient to ASCII
    cmp eax, '0'        ; Check if the digit is '0'
    je .skipLeadingZero ; Skip leading zeros
    mov edi, 1          ; Set flag to indicate leading zeros are skipped
.skipLeadingZero:
    test edi, edi       ; Check if leading zero flag is set
    jz .continue        ; If not set, skip storing the digit
    mov [esi], al       ; Store the ASCII character in the buffer
    inc esi             ; Move to the next position in the buffer
.continue:
    mov eax, edx        ; Move the remainder to EAX
    add ebx, 4          ; Move to the next divisor
    cmp dword [ebx], 0  ; Have all divisors been processed?
    jne .nextDigit
    mov byte [esi], 0   ; Null-terminate the string
    pop edx
    pop ebx
    pop eax
    ret

hex_to_str:
    pusha                    ; Save all registers
    mov edi, buffer + 7      ; Point to the end of the buffer (excluding null terminator)
    mov byte [buffer + 8], 0 ; Null terminator
.hex_loop:
    mov edx, eax             ; Copy EAX to EDX
    and edx, 0xF             ; Get the last hex digit
    cmp edx, 9
    jle .digit_is_number
    add dl, 'A' - 10         ; Convert to ASCII letter (A-F)
    jmp .store_digit
.digit_is_number:
    add dl, '0'              ; Convert to ASCII number (0-9)
.store_digit:
    mov byte [edi], dl       ; Store the ASCII character in buffer
    dec edi                  ; Move to the next position in the buffer
    shr eax, 4               ; Shift EAX right by 4 bits to get the next hex digit
    test eax, eax            ; Check if EAX is 0
    jnz .hex_loop            ; Repeat if EAX is not 0
    ; Fill leading zeros with '0'
.fill_zeros:
    mov byte [edi], '0'
    dec edi
    cmp edi, buffer - 1
    jne .fill_zeros
    popa                     ; Restore all registers
    ret

hex_to_str32_input:
    pusha                    ; Save all registers
    mov eax, [input32]       ; Load the value from input32 buffer into EAX
    mov edi, buffer32 + 7      ; Point to the end of the buffer (excluding null terminator)
    mov byte [buffer32 + 8], 0 ; Null terminator

.hex_loop:
    mov edx, eax             ; Copy EAX to EDX
    and edx, 0xF             ; Get the last hex digit
    cmp edx, 9
    jle .digit_is_number
    add dl, 'A' - 10         ; Convert to ASCII letter (A-F)
    jmp .store_digit

.digit_is_number:
    add dl, '0'              ; Convert to ASCII number (0-9)

.store_digit:
    mov byte [edi], dl       ; Store the ASCII character in buffer
    dec edi                  ; Move to the next position in the buffer
    shr eax, 4               ; Shift EAX right by 4 bits to get the next hex digit
    test eax, eax            ; Check if EAX is 0
    jnz .hex_loop            ; Repeat if EAX is not 0

    ; Fill leading zeros with '0'
.fill_zeros:
    mov byte [edi], '0'
    dec edi
    cmp edi, buffer32 - 1
    jne .fill_zeros

    popa                     ; Restore all registers
    ret

input32: dd 0x0              ; Input buffer for the 32-bit value
buffer32 db 17 dup(0)          ; Buffer to store the binary string (16 bits + null terminator)


current_line: dd 0x000B8000  ; Start of video memory

buffer db 17 dup(0)          ; Buffer to store the binary string (16 bits + null terminator)

divisorTable:
    dd 1000000000
    dd 100000000
    dd 10000000
    dd 1000000
    dd 100000
    dd 10000
    dd 1000
    dd 100
    dd 10
    dd 1
    dd 0

newLine db ' ',0

save_ESP_state: dd 0x0 