;---Initialized data----------------------------------------------------------
systimer_ticks dq 0
keyboard_scancode dq 0
error_code_low dw 0
error_code_high dw 0

int_message db 'Interrupt raised!',0


;---Code------------------------------------------------------------------------
ISR_dummy:
;***************************************************************************;
; Just a dummy generic handler. It prints the message "Interrupt raised!".  ;
;***************************************************************************;
    cli
    pusha
    ;call clear32
    ;mov si, int_message
    ;call print32
    ;jmp $
    popa
    iret
    

ISR_Division_by_Zero:
;***************************************************************************;
; Divizion by zero handler                                                  ;
;***************************************************************************;
    cli
    pusha


    popa
    iret


ISR_GPF:
;***************************************************************************;
; General Protection Fault handler                                                  ;
;***************************************************************************;
    cli
    pusha


    popa
    iret

ISR_Page_Fault:
;***************************************************************************;
; Page Fault handler                                                  ;
;***************************************************************************;
    cli
    pusha


    popa
    iret


ISR_systimer:
;*****************************************************************************;
; System Timer Interrupt Service Routine (IRQ0 mapped to INT 0x20)            ;
;*****************************************************************************;
    cli
    pusha


    popa
    iret


ISR_keyboard:
;*****************************************************************************;
; Keyboard Controller Interrupt Service Routine (IRQ1 mapped to INT 0x21)     ;
;*****************************************************************************;
    cli
    pusha


    popa
    iret





