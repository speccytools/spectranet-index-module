global strcmp

; Compare a string with another. Strings pointed to by HL and DE
strcmp:
	ld a, (de)
	cpi
	ret nz
	and a			; at the null?
	ret z
	inc de
	jr strcmp