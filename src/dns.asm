include "../include/spectranet.inc"
include "../include/sysvars.inc"
include "vars.inc"
include "memory.inc"

;========================================================================
; F_dnsAquery
; Queries a DNS server for TXT records, using the servers enumerated
; in system variables v_nameserver1 and v_nameserver2.
; Stores results as a series of null-terminated strings, stored at address of 0x1000 (page a)
; Note that that address is noing to be valid forever - so long page a doesn't change
;
; Parameters: HL = pointer to null-terminated string containing address to query
; Returns   : HL = NULL (error) or a pointer past last byte of series of null-terminated strings
;

STR_connecting_to:
    defb "\n-> ", 0

resolve_dns1:
    defb 8,8,8,8

resolve_dns2:
    defb 208,67,220,220

resolve_dns3:
    defb 9,9,9,9

resolve_dns4:
    defb 1,1,1,1

connect_to_dns:
    ld a, (v_dnsfd)
    ld bc, dns_port
    jp CONNECT


global _resolve_txt_records
_resolve_txt_records:
    ld a, (PAGE_DNS_REQUEST)
    call SETPAGEA

    ld ix, hl                       ; preserve query

    ld hl, STR_connecting_to
    call PRINT42
    ld hl, ix
    call PRINT42

	ld c, SOCK_STREAM	            ; Open a TCP socket
	call SOCKET
	jp c, errorout			        ; bale out on error
	ld (v_dnsfd), a		            ; save the file descriptor

    ld de, resolve_dns1
    call connect_to_dns
    jr nc, _resolved

    ld de, resolve_dns2
    call connect_to_dns
    jr nc, _resolved

    ld de, resolve_dns3
    call connect_to_dns
    jr nc, _resolved

    ld de, resolve_dns4
    call connect_to_dns
    jr nc, _resolved

    jp errorcleanup2

_resolved:
	; set up the query string to resolve in the workspace area
	ld de, buf_workspace+14	        ; write it after the header
	ld hl, ix                       ; restore query
	call F_dnsstring	            ; string to convert in hl

	xor a
	ld b, dns_TXTrecord			    ; query type TXT
	ld (hl), a		                ; MSB of query type (A)
	inc hl
	ld (hl), b		                ; LSB of query type (A)
	inc hl
	ld b, 1                         ; IN
	ld (hl), a		                ; MSB of class (IN)
	inc hl
	ld (hl), b		                ; LSB of class (IN)
	ld de, buf_workspace-1	        ; find out the length
	sbc hl, de		                ; of the query block
	ld (v_querylength), hl	        ; and save it in sysvars

	ld hl, v_nameserver1	        ; set up the first resolver
	ld (v_cur_resolver), hl	        ; and save it in sysvars area

	call RAND16		                ; generate the DNS query ID
	ld (buf_workspace + 2), hl	    ; store it at the start of the workspace

	ld hl, query		            ; start address of standard query data
	ld de, buf_workspace+4	        ; destination
	ld bc, queryend-query	        ; bytes to copy
	ldir			                ; build the query header

    ld a, (v_querylength + 1)
    ld (buf_workspace), a
    ld a, (v_querylength)
	ld (buf_workspace + 1), a	    ; store query length in big endian

	ld a, (v_dnsfd)
	ld de, buf_workspace	        ; point de at the workspace
	ld bc, (v_querylength)	        ; bc = length of query
	inc bc                          ; bump it by two
	inc bc
	call SEND		                ; send the block of data
	jr c, errorcleanup2	            ; recover if there's an error

resolve_txt_records_recv:
    ld a, (v_dnsfd)
    ld de, buf_workspace
    ld bc, 2
    call RECV                       ; ask for response size
	jr c, errorcleanup2	            ; recover if there's an error

	ld a, (buf_workspace+1)         ; read how many data there is
	ld e, a
	ld a, (buf_workspace)           ; in big endian
	ld d, a

	ld hl, PAGE_A_SIZE
	sbc hl, de
    jr c, errorcleanup2             ; we cannot handle more than PAGE_A_SIZE

	ld a, (v_dnsfd)
	ld bc, de		                ; spell how much to request
	ld de, PAGE_A_ADDR	            ; set de to the message buffer
	call RECV
	jr c, errorcleanup2

	ld a, (v_dnsfd)
	call CLOSE

	ld a, (PAGE_A_ADDR + dns_bitfield2)
	and 0x0F		                ; Did we successfully resolve something?
	jr z, result2		            ; yes, so process the answer.
	jp errorout

errorcleanup2:
	push af
	ld a, (v_dnsfd)		            ; free up the socket we've opened
	call CLOSE
	pop af
	jp errorout

result2:
	xor a
	ld (v_ansprocessed), a	        ; set answers processed = 0
	ld hl, PAGE_A_ADDR + dns_headerlen

questionloop4:
	ld a, (hl)		                ; advance to the end of the question record
	and a			                ; null terminator?
	inc hl
	jr nz, questionloop4	        ; not null, check the next character
	inc hl			                ; go past QTYPE
	inc hl
	inc hl			                ; go past QCLASS
	inc hl
    ld de, PAGE_A_ADDR	            ; retrieve pointer to result buffer
decodeanswer4:
	ld a, (hl)		                ; Test for a pointer or a label
	and 0xC0		                ; First two bits are 1 for a pointer
	jr z, skiplabel4	            ; otherwise it's a label so skip it
	inc hl
	inc hl
recordtype4:
	inc hl			                ; skip MSB
	ld a, (hl)		                ; what kind of record?
	cp dns_TXTrecord		        ; is it an A record?
	jr nz, skiprecord4	            ; if not, advance HL to next answer
	ld bc, 9		                ; TXT record length is the 9th byte
	add hl, bc		                ; further on in an A record response
	ld b, 0
    ld c, (hl)                      ; get the record length
    inc hl                          ; move over
    ldir			                ; copy
    ld (de), 0                      ; zero-terminate
    inc de
    jp decodeanswer4                ; next answer
skiplabel4:
	ld a, (hl)
	and a			                ; is it null?
	jr z, recordtype4	            ; yes - process the record type
	inc hl
	jr skiplabel4
skiprecord4:
	ld a, (buf_message+dns_ancount+1)
	ld b, a			                ; number of RR answers in B
	ld a, (v_ansprocessed)	        ; how many have we processed already?
	inc a			                ; pre-increment processed counter
	cp b			                ; compare answers processed with total
	jr z, allrecordscomplete		; we've processed all records
	ld (v_ansprocessed), a
	ld bc, 7		                ; skip forward
	add hl, bc		                ; 7 bytes - now pointing at data length
	ld b, (hl)		                ; big-endian length MSB
	inc hl
	ld c, (hl)		                ; LSB
	inc hl
	add hl, bc		                ; advance hl to the end of the data
	jr decodeanswer4	            ; decode the next answer
allrecordscomplete:
    ld hl, de                       ; return pointer to past last data byte
    ret
errorout:
    ld hl, 0                        ; return NULL
    ret

;========================================================================
; F_dnsstring
; Convert a string (such as 'spectrum.alioth2.net2') into the format
; used in DNS queries and responses. The string is null terminated.
;
; The format adds an 8 bit byte count in front of every part of the
; complete host/domain, replacing the dots, so 'spectrum.alioth2.net2'
; would become [0x08]spectrum[0x06]alioth[0x03]net - the values in
; square brackets being a single byte (8 bit integer).
;
; Parameters: HL - pointer to string to convert
;             DE - destination address of finished string
; On exit   : HL - points at next byte after converted data
;	      DE is preserved.

F_dnsstring:
	ld (v_fieldptr), de	; Set current field byte count pointer
	inc e			; Intial destination address.
findsep3:
	ld c, 0xFF		; byte counter, decremented by LDI
loop3:
	ld a, (hl)		; What are we looking at?
	cp '.'			; DNS string field separator?
	jr z, dot3
	and a			; Null terminator?
	jr z, done3
	ldi			; copy (hl) to (de), incrementing both
	jr loop3
dot3:
	push de			; save current destination address
	ld a, c			; low order of byte counter (255 - bytes)
	cpl			; turn it into the byte count
	ld de, (v_fieldptr)	; retrieve field pointer
	ld (de), a		; store byte counter
	pop de			; get current destination address back
	ld (v_fieldptr), de	; save it
	inc e			; and update pointer to new address
	inc hl			; address pointer at next character
	jr findsep3		; and get next bit
done3:
	push de			; save current destination address
	xor a			; put a NULL on the end of the result
	ld (de), a
	ld a, c			; low order of byte count (255 - bytes)
	cpl			; turn it into a byte count
	ld de, (v_fieldptr)	; retrieve field pointer
	ld (de), a		; save byte count
	pop hl			; get current address pointer
	inc hl			; add 1 - hl points at next byte after end
	ret			; finished.

query:           defb 0x01,0x00  ; 16 bit flags field - std. recursive query
qdcount:         defb 0x00,0x01  ; we only ever ask one question at a time
ancount:         defw 0x0000     ; No answers in a query
nscount:         defw 0x0000     ; No NS RRs in a query
arcount:         defw 0x0000     ; No additional records
queryend:
