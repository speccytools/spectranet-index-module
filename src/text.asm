EXTERN _text_x
EXTERN _text_y
EXTERN asm_zx_cxy2saddr
PUBLIC _text_ui_write
PUBLIC _text_pagein
PUBLIC text_decompress

include "../include/spectranet.inc"

defc _text_ui_write = 0x1000

_text_pagein:
    ld a, 0xC1
    call SETPAGEA
    ret

compressed_font:
    binary "../build/fontlib__.bin.zx7"

text_decompress:
    call _text_pagein
    extern asm_dzx7_turbo
    ld hl, compressed_font
    ld de, 0x1000
    call asm_dzx7_turbo
    ret