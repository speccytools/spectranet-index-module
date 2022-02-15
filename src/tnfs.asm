PUBLIC load_tnfs

include "../include/spectranet.inc"
include "../include/defs.inc"
include "../include/stdmodules.inc"
include "../include/sysvars.inc"
include "../include/tnfs_sysvars.inc"
include "./memory.inc"
include "./basic_rom.inc"

; HL contains load url
load_tnfs:
    call CLEAR42

    ld ix, INTERPWKSPC	    ; where to place the mount struct
    ld de, TNFS_LOAD_URL	; location of the string to parse
    ld hl, PARSEURL			; call PARSEURL in the tnfs ROM
    rst MODULECALL_NOPAGE
    jr c, mount_error

    ld a, 2
	call MOUNT              ; mount the structure at ix
	jr c, mount_error
	ld a, 2
	call SETMOUNTPOINT      ; keep it
	jr c, mount_error

	rst CALLBAS             ; clear the calculator stack
	defw ZX_SET_MIN

    ld hl, vectors		    ; start of vector table
findcall6:
    ld a, (hl)		        ; get ROM ID from table
    and a			        ; check for terminator
    ret z
    inc l			        ; increment table pointer
    inc b
    cp 0xFD			        ; looking for basic rom ID
    jr nz, findcall6
found6:
	ld a, l			        ; get vector address LSB
	sub vectors % 256 - 1	; subtract the base to get the ROM slot

    push af                 ; store a
    call PUSHPAGEA          ; switch page a to that page

    ld hl, 0x100A
    ld a, (hl)
    ld c, a
    inc hl
    ld a, (hl)
    ld b, a                 ; bc contains the routine "F_boot" on that page
    add bc, 4               ; skip "call F_shouldboot; ret nz"

    call POPPAGEA
    pop af                  ; a = page number

    ld hl, EXIT_SUCCESS     ; we need to exit this basic call, but F_boot has to do it for us
    push hl                 ; stack: EXIT_SUCCESS

    ld hl, 0xFFFD           ; F_boot is going to switch to that as stack and
    ld (NMISTACK), hl       ; use stack at this point as return address

    push bc                 ; we need to go into bc
                            ; stack: @F_boot EXIT_SUCCESS

F_boot:
    jp SETPAGEB             ; instead of calling it, jp to it
                            ; so it would return to address at top of stack,
                            ; which would contain address of F_boot routine
                            ; that routine will end eventually and would return to EXIT_SUCCESS,
                            ; which is higher up one more stack item

mount_error:
    ld hl, MOUNT_ERROR_STR
    call PRINT42
    jp EXIT_SUCCESS

MOUNT_ERROR_STR:
    defb "An error occured. Make sure mount point 2 is free.\n", 0

