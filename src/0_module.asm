
include "../include/spectranet.inc"
include "memory.inc"

extern load_tnfs

module_header:
    org 0x2000
    defb 0xAA               ; This is a code module.
    defb 0xDB               ; This module has the identity 0xDB.
    defw reset              ; The RESET vector - call a routine labeled reset.
    defw 0xFFFF             ; MOUNT vector - not used by this module
    defw 0xFFFF             ; Reserved
    defw 0xFFFF             ; Address of NMI routine
    defw 0xFFFF             ; Reserved
    defw 0xFFFF             ; Reserved
    defw STR_identity       ; Address of the identity string.

STR_spectranet_index:
    defb "%index", 0

basic_ext:
    defb 0x0B                       ; C Nonsense in BASIC
    defw STR_spectranet_index       ; Pointer to string (null terminated)
    defb 0xFF                       ; This module
    defw index_run                  ; Address of routine to call

reset:
    ld hl, basic_ext                ; Pointer to the table entry to add
    call ADDBASICEXT
    ret

STR_identity:
    defb "Spectranet Search Index", 0

STR_index0:
    defb "index.speccytools.org", 0

index_run:
    extern _clear
    extern text_decompress
    extern _records_init
    extern _add_index
    extern _resolve
    extern _search
    extern _render
    extern _process_key

    call STATEMENT_END              ; Check for statement end.

    push ix
    push iy

    ld a, 0xDB                      ; allocate a page for font rendering
    call RESERVEPAGE
    ld (PAGE_FONT_RENDER), a

    call PUSHPAGEA                  ; preserve current page
    call _clear
    call text_decompress

    call _records_init
    ld hl, STR_index0
    call _add_index
    call _resolve

index_run_loop:
    call KEYUP
    call _search
    call _clear
    call _render
index_run_key_loop:
    call GETKEY
    or a
    jr z, index_run_key_loop
    ld h, 0
    ld l, a
    call _process_key
    ld l, a
    and a
    jr nz, index_run_loop

    ld a, (PAGE_FONT_RENDER)        ; free font render page
    call FREEPAGE

    call POPPAGEA                   ; restore original page A

    pop iy
    pop ix

    ld a, (TNFS_LOAD_URL)
    and a
    jr z, index_run_skip_tnfs_load

    jp load_tnfs

index_run_skip_tnfs_load:
    jp EXIT_SUCCESS