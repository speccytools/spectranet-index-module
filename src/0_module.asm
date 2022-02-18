
include "../include/spectranet.inc"
include "memory.inc"

extern load_tnfs
global _VERSION

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

_VERSION:
    defb "0.3", 0

STR_spectranet_index:
    defb "!", 0

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
    defb "Spectranet Index", 0

STR_index0:
    defb "index.speccytools.org", 0

STR_index1:
    defb "tnfs.robertmorrison.me", 0

STR_dns:
    defb "Looking...", 0

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

    ld a, 0xDB                      ; allocate a page for dns requests
    call RESERVEPAGE
    ld (PAGE_DNS_REQUEST), a

    call PUSHPAGEA                  ; preserve current page
    call text_decompress

    call _records_init

    ld hl, STR_index0               ; add indexes
    call _add_index
    ld hl, STR_index1
    call _add_index

    call CLEAR42
    ld hl, STR_dns
    call PRINT42
    call _resolve
    call _clear

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

    ld a, (PAGE_DNS_REQUEST)        ; free dns requests page
    call FREEPAGE

    call POPPAGEA                   ; restore original page A

    pop iy
    pop ix

    ld a, (TNFS_LOAD_URL)
    and a
    jp nz, load_tnfs
    jp EXIT_SUCCESS