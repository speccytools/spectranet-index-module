global __debug_framepointer
global _clear42
global _print42
global _search_into
global _clear
global _sitoa

include "../include/spectranet.inc"

defc _print42 = PRINT42
defc INITIAL_SP = 0xFFFF
defc __debug_framepointer = 0x3B00

_sitoa:
    pop ix
    ld a, l
    pop hl
    call ITOA8
    push ix
    ret

STR_search_prompt:
    defb  "Query:\n", 0

_search_into:
    push hl
    call CLEAR42
    ld hl, STR_search_prompt
    call PRINT42
    ld c, 32
    pop de
    call INPUTSTRING
    ret

_clear:
    ld a, 0
    out (254), a

    ld hl, 0x4000
    ld de, 0x4001
    ld bc, 6912
    ld (hl), 0
    ldir

    ret