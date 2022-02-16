global install_new_module
global install_replace_module
extern module_binary

include "../include/spectranet.inc"
include "../include/sysvars.inc"

STR_install_message:
    defb "Installing Spectranet Search Index...\n", 0

STR_install_fail:
    defb "Failed!\n", 0

install_replace_module:
    ld (v_workspace), a
    and 0xFC			; mask out bottom two bits to find
    ld (v_workspace + 1), a		; the sector, store it for later
    call F_copysectortoram		; copy the flash sector
    ld a, (v_workspace)		; calculate the RAM page to use
    and 0x03			; get position in the sector
    add a, 0xDC			; add RAM page number
    call SETPAGEA
    ld hl, module_binary
    ld de, 0x1000
    ld bc, 0x1000
    ldir
    ld a, (v_workspace + 1)		; retrieve sector page
    di
    call F_FlashEraseSector
    ld a, (v_workspace + 1)
    call F_writesector		; write the new contents of RAM
    ei

    ld hl, STR_install_message
    call PRINT42
    ret

; F_copysectortoram
; Copies 4 pages of flash to RAM.
; Parameter: A = first page.
F_copysectortoram:
	ex af, af'			; save ROM page
	ld a, 0xDC			; first RAM page
	ld b, 4				; pages to copy
copyloop14:
	push bc
	call SETPAGEB			; RAM into area B
	inc a
	ex af, af'			; ROM page into A
	call SETPAGEA			; page it in
	inc a
	ex af, af'			; for the next iteration.
	ld hl, 0x1000			; copy the page
	ld de, 0x2000
	ld bc, 0x1000
	ldir
	pop bc
	djnz copyloop14
	ret

install_new_module:
    ld hl, STR_install_message
    call PRINT42

    call F_findfirstfreepage
    jp c, install_module_failed

    call SETPAGEB
    ld hl, module_binary
    ld de, 0x2000
    ld bc, 0x1000
    call F_FlashWriteBlock
    jp c, install_module_failed

    ret

install_module_failed:
    ld hl, STR_install_fail
    call PRINT42
    ret

F_findfirstfreepage:
	ld a, 0x04
loop3:
	call SETPAGEB
	ex af, af'
	ld a, (0x2000)
	cp 0xFF			; FF = free page
	jr z, found3
	ex af, af'
	cp 0x1F			; Last page?
	jr z, nospace3
	inc a
	jr loop3
nospace3:
	scf
	ret
found3:
	ex af, af'
	and a			; make sure carry is reset
	ret
    
;---------------------------------------------------------------------------
; F_FlashEraseSector
; Simple flash writer for the Am29F010 (and probably any 1 megabit flash
; with 16kbyte sectors)
;
; Parameters: A = page to erase (based on 4k Spectranet pages, but
; erases a 16k sector)
; Carry flag is set if an error occurs.
F_FlashEraseSector:
	; Page in the appropriate sector first 4k into page area B.
	; Page to start the erase from is in A.
	call SETPAGEB	; page into page area B

	ld a, 0xAA	; unlock code 1
	ld (0x555), a	; unlock addr 1
	ld a, 0x55	; unlock code 2
	ld (0x2AA), a	; unlock addr 2
	ld a, 0x80	; erase cmd 1
	ld (0x555), a	; erase cmd addr 1
	ld a, 0xAA	; erase cmd 2
	ld (0x555), a	; erase cmd addr 2
	ld a, 0x55	; erase cmd 3
	ld (0x2AA), a	; erase cmd addr 3
	ld a, 0x30	; erase cmd 4
	ld (0x2000), a	; erase sector address

	ld hl, 0x2000
wait1: 
	bit 7, (hl)	; test DQ7 - should be 1 when complete
	jr nz,  complete1
	bit 5, (hl)	; test DQ5 - should be 1 to continue
	jr z,  wait1
	bit 7, (hl)	; test DQ7 again
	jr z,  borked1

complete1: 
	or 0		; clear carry flag
	ret

borked1: 
	scf		; carry flag = error
	ret

;---------------------------------------------------------------------------
; F_FlashWriteBlock
; Copies a block of memory to flash. The flash should be mapped into
; page area B.
; Parameters: HL = source start address
;             DE = destination start address
;             BC = number of bytes to copy
; On error, the carry flag is set.
F_FlashWriteBlock: 
	ld a, (hl)	; get byte to write
	call F_FlashWriteByte
	ret c		; on error, return immediately
	inc hl		; point at next source address
	inc de		; point at next destination address
	dec bc		; decrement byte count
	ld a, b
	or c		; is it zero?
	jr nz, F_FlashWriteBlock
	ret

;---------------------------------------------------------------------------
; F_FlashWriteByte
; Writes a single byte to the flash memory.
; Parameters: DE = address to write
;              A = byte to write
; On return, carry flag set = error
; Page the appropriate flash area into one of the paging areas to write to
; it, and the address should be in that address space.
F_FlashWriteByte: 
	push bc
	ld c, a		; save A

	ld a, 0xAA	; unlock 1
	ld (0x555), a	; unlock address 1
	ld a, 0x55	; unlock 2
	ld (0x2AA), a	; unlock address 2
	ld a, 0xA0	; Program
	ld (0x555), a	; Program address
	ld a, c		; retrieve A
	ld (de), a	; program it

wait3: 
	ld a, (de)	; read programmed address
	ld b, a		; save status
	xor c		
	bit 7, a	; If bit 7 = 0 then bit 7 = data	
	jr z,  byteComplete3

	bit 5, b	; test DQ5
	jr z,  wait3

	ld a, (de)	; read programmed address
	xor c		
	bit 7, a	; Does DQ7 = programmed data? 0 if true
	jr nz,  borked3

byteComplete3: 
	pop bc
	or 0		; clear carry flag
	ret

borked3: 
	pop bc
	scf		; error = set carry flag
	ret

;---------------------------------------------------------------------------
; F_writesector
; Writes 4 pages from the last 4 pages of RAM to flash, starting at the
; page specified in A
F_writesector: 
	ex af, af'	; swap with alternate set
	ld a, 0xDC	; RAM page 0xDC
	ld b, 4		; number of pages
loop4: 
	push bc
	call SETPAGEA ; Page into area A
	inc a		; next page
	ex af, af'	; get flash page to program
	call SETPAGEB
	inc a		; next page
	ex af, af'	; back to ram page for next iteration
	ld hl, 0x1000
	ld de, 0x2000
	ld bc, 0x1000
	push af
	call F_FlashWriteBlock
	jr c,  failed4	; restore stack and exit
	pop af
	pop bc
	djnz  loop4	; next page
	ret
failed4: 		; restore stack, set carry flag
	pop af
	pop bc
	scf
	ret
