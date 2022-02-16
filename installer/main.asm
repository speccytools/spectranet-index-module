global _main
extern strcmp
extern module_binary
extern install_new_module
extern install_replace_module

include "../include/spectranet.inc"
include "../include/sysvars.inc"

STR_welcome:
    defb "Welcome to Spectranet Index installer!\n\n", 0

STR_install_complete_message:
    defb "Installing complete!\n\nReboot and use type:\n\n!\n\n(excl.mark) to start.\n", 0

STR_nmf_message:
    defb "Installing a new module...\n", 0

STR_upd_message:
    defb "Installing updated module...\n", 0

search_modules:
    ld hl, vectors		        ; start of vector table
search_modules_loop:
    ld a, (hl)		            ; get ROM ID from table
    and a			            ; check for terminator
    jr z, search_modules_not_found
    inc l			            ; increment table pointer
    inc b
    cp 0xDB			            ; looking for installed module ID
    jr nz, search_modules_loop
    ld a, l			            ; get vector address LSB
    sub vectors % 256 - 1	    ; subtract the base to get the ROM slot
    ret
search_modules_not_found:
    scf
    ret

existing_module_page:
    defb 0x00

_main:
    call PAGEIN                 ; page in spestranet
    call CLEAR42

    ld hl, STR_welcome
    call PRINT42

    call search_modules         ; look for installer modules
    ld (existing_module_page), a
    jr nc, main_skip_nmf

    ld hl, STR_nmf_message      ; no such module, install now
    call PRINT42
    call install_new_module
    jr main_complete
main_skip_nmf:

    ld hl, STR_upd_message
    call PRINT42
    ld a, (existing_module_page)
    call install_replace_module

main_complete:
    ld hl, STR_install_complete_message
    call PRINT42

    call PAGEOUT                ; page out spectranet
    ret