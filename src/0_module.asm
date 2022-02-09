
include "../include/spectranet.inc"

module_header:
    org 0x2000
    defb 0xAA               ; This is a code module.
    defb 0xDB               ; This module has the identity 0xBC.
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
    extern _modulecall
    call _modulecall
    jp EXIT_SUCCESS