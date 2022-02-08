global _gdbserver_state
global t_rst8_handler
global __debug_framepointer
global CONSOLE_ROWS
global CONSOLE_COLUMNS
global __SYSVAR_BORDCR
global _clear42
global _print42
global module_header
global nmi_handler
extern gdbserver_install

include "../include/spectranet.inc"

defc INITIAL_SP = 0xFFFF
defc __SYSVAR_BORDCR = 23624
defc CONSOLE_ROWS = 24
defc CONSOLE_COLUMNS = 40
defc __debug_framepointer = 0x3B00

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

modulecall:
    ret

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
    ld hl, STR_identity
    call PRINT42
    jp EXIT_SUCCESS