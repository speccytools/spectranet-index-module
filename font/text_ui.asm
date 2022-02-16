EXTERN asm_zx_cxy2saddr
EXTERN asm_zx_cxy2aaddr

include "../include/spectranet.inc"
include "../include/defs.inc"
include "../include/stdmodules.inc"
include "../include/fcntl.inc"
include "../include/zxrom.inc"
include "../include/sysvars.inc"
include "../include/zxsysvars.inc"
include "../src/memory.inc"

org 0x1000

; stack: string to write
; stack: amount to write
; registers used:
;     ixl - number of characters left to write
;     hl - current screen address
;     de - current characted data address
;     bc - current string address
text_ui_write:
    pop iy                          ; ret

    ld de, hl                       ; store string address into de for a bit
    ld ix, 0xFF                     ; -1

count_loop:
    ld a, (hl)
    inc hl
    inc ixl
    and a
    jr nz, count_loop               ; string length is in ixl

    pop hl                          ; yx

    push hl                         ; preserve yx for asm_zx_cxy2aaddr
    call asm_zx_cxy2aaddr           ; get color data addr
    ld c, ixl                       ; get chars amount into ixl
    inc c                           ; divide it in half
    rr c                            ; with round top
    ld a, (TEXT_COLOR)

_text_ui_write_color_loop:          ; fill up color info
    ld (hl), a
    inc hl
    dec c
    jr nz, _text_ui_write_color_loop

    pop hl                          ; restore hl to yx
    call asm_zx_cxy2saddr           ; hl now holds a screen address
    ld bc, de                       ; pop string address into bc
    push iy                         ; ret

_text_ui_write_loop:
    ; even
    include "text_ui_routine_loop_header.inc"

    include "text_ui_routine_even.inc"
    inc h
    include "text_ui_routine_even.inc"
    inc h
    include "text_ui_routine_even.inc"
    inc h
    include "text_ui_routine_even.inc"
    inc h
    include "text_ui_routine_even.inc"
    inc h
    include "text_ui_routine_even.inc"
    inc h
    include "text_ui_routine_even.inc"
    inc h
    include "text_ui_routine_even.inc"

    ld a, h                         ; restore (h)l from 7 increments
    sub 7
    ld h, a
    inc bc                          ; onto next character
    dec ixl                         ; do we have more to print?
    ret z                           ; we're done

    ; odd
    include "text_ui_routine_loop_header.inc"

    include "text_ui_routine_odd.inc"
    inc h
    include "text_ui_routine_odd.inc"
    inc h
    include "text_ui_routine_odd.inc"
    inc h
    include "text_ui_routine_odd.inc"
    inc h
    include "text_ui_routine_odd.inc"
    inc h
    include "text_ui_routine_odd.inc"
    inc h
    include "text_ui_routine_odd.inc"
    inc h
    include "text_ui_routine_odd.inc"

    inc hl                          ; onto next screen address position
    ld a, h                         ; restore (h)l from 7 increments
    sub 7
    ld h, a
    inc bc                          ; onto next character
    dec ixl                         ; do we have more to print?
    ret z                           ; we're done
    jp _text_ui_write_loop

font:
    binary "font_4x8_80columns.bin"
