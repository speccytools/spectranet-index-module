EXTERN asm_zx_cxy2saddr
EXTERN asm_zx_cxy2aaddr

defc text_color = 32768

org 0x1000

; stack: string to write
; stack: amount to write
; registers used:
;     ixl - number of characters left to write
;     hl - current screen address
;     de - current characted data address
;     bc - current string address
_text_ui_write:
    pop de                          ; ret

    pop ix                          ; pop the amount into ix

    pop bc                          ; y
    ld h, c
    pop bc
    ld l, c                         ; x

    push hl                         ; preserve yx for asm_zx_cxy2aaddr
    call asm_zx_cxy2aaddr           ; get color data addr
    ld c, ixl                       ; get chars amount into ixl
    inc c                           ; divide it in half
    rr c                            ; with round top
    ld a, (text_color)

_text_ui_write_color_loop:          ; fill up color info
    ld (hl), a
    inc hl
    dec c
    jr nz, _text_ui_write_color_loop

    pop hl                          ; restore hl to yx
    call asm_zx_cxy2saddr           ; hl now holds a screen address
    pop bc                          ; pop string address into bc
    push de                         ; ret

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
