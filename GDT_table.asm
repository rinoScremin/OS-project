align 4
GDT_PTR:
dw GDT_END-GDT-1 ; size-1
dd GDT ; offset

; 8 bytes per entry
; base bits 24:31
; flags (4 bits)
;   granularity for limit (0=1B, 1=4KB page)
;   size (0=16bit, 1=32bit)
;   L bit (indicates x86_64 code descriptor). if this is set then size should be 0
; limit bits 16:19 (4 bits)
; access byte (8 bits)
;   present
;   privilege (2b)
;   descriptor type (1=code/data segments, 0=system segments)
;   executable
;   direction/conforming
;   readable
;   accessed
; base bits 16:23
; base bits 0:15
; limit bits 0:15

align 16
GDT:
GDT_NULL: dq 0 ; required on some platforms, disallow use of segment 0

; base = 0x00000000
; limit = 0xFFFFF * 4KB granularity = full 4GB address space
; flags = 0xC = 0b1100 (4KB granularity, 32bit)
; access byte = 0x92 = 10010010 (present, ring 0, code/data segment, writable)
GDT_BOOT_DS: dq 0x00CF92000000FFFF
GDT_BOOT_CS: dq 0x00CF9A000000FFFF ; same as DS but with executable set in access byte
GDT_CS64:    dq 0x00209A0000000000 ; same as above but 64-bit
; the 64-bit gdt entry doesn't have a limit because we use paging (I assume)

GDT_END: