bits 64

global _start  ; Declare the entry point

section .text
_start:
    ; Your kernel initialization code here
    ; Call kernel_main
    extern kernel_main
    call kernel_main

    hlt
