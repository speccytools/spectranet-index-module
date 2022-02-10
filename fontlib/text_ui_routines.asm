EXTERN asm_zx_cxy2saddr

defc _text_x = 32768
defc _text_y = 32769

org 0x1000

; stack: string to write
; stack: amount to write
; registers used:
;     ixl - number of characters left to write
;     hl - current screen address
;     de - current characted data address
;     bc - current string address
_text_ui_write:
    pop hl                          ; ret
    pop ix                          ; pop the amount into ix
    pop bc                          ; pop string address into bc
    push hl                         ; ret

    call _text_ui_get_screen_addr   ; hl now holds a screen address

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

_text_ui_get_screen_addr:
    ld a, (_text_x)                 ; get initial screen address
    ld l, a
    ld a, (_text_y)
    ld h, a
    jp asm_zx_cxy2saddr             ; hl now holds a screen address

font:
    binary "font_4x8_80columns.bin"
