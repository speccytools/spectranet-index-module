
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
    defw gdbserver_run              ; Address of routine to call

reset:
    ld hl, basic_ext                ; Pointer to the table entry to add
    call ADDBASICEXT
    ret

STR_identity:
    defb "Spectranet Search Index", 0

gdbserver_run:
    call STATEMENT_END              ; Check for statement end.

    push ix
    push iy

    ld a, 0xDB
    call RESERVEPAGE
    ld (MODULE_PAGE_A_USED), a
    call PUSHPAGEA
    extern _clear
    call _clear
    extern text_decompress
    call text_decompress
    extern _modulecall
    call _modulecall
    ld a, (MODULE_PAGE_A_USED)
    call FREEPAGE
    call POPPAGEA

    pop iy
    pop ix

    ld a, (TNFS_LOAD_URL)
    and a
    jr z, gdbserver_run_skip_tnfs_load

    jp load_tnfs

gdbserver_run_skip_tnfs_load:
    jp EXIT_SUCCESS