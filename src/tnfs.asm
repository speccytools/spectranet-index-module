PUBLIC _load_tnfs

include "../include/spectranet.inc"
include "../include/defs.inc"
include "../include/stdmodules.inc"
include "../include/sysvars.inc"
include "../page_a/page_a_functions.inc"

; HL contains load url
_load_tnfs:
    ld ix, buf_workspace	; where to place the mount struct
    ld de, hl	            ; location of the string to parse
    ld hl, PARSEURL			; call PARSEURL in the tnfs ROM
    rst MODULECALL_NOPAGE
    jr c, errorout

    ld a, 0xC1
    call SETPAGEA

    call load_tnfs
    jr c, errorout
    ld hl, 0
    ret
errorout:
    ld hl, 1
    ret