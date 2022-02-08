; Definitions
dns_headerlen	equ 12		; 12 bytes long
dns_TXTrecord	equ 16		; TXT record indicator in query/answer
dns_port	    equ 53		; port 53/udp
dns_polltime	equ 16384	; How long to poll for DNS response

; Offsets to the fields of the DNS message header
dns_serial	equ 0		; Two byte serial number
dns_bitfield1	equ 2		; First 8 bits of the flags bitfield
dns_bitfield2	equ 3		; Last 8 bits of the flags bitfield
dns_qdcount	equ 4		; Number of questions (2 bytes, big endian)
dns_ancount	equ 6		; Number of resource records
dns_nscount	equ 8		; Number of NS records
dns_arcount	equ 10		; Number of additional records

; Error return codes - DNS
PAGE_A_ADDR equ 0x1000
PAGE_A_SIZE equ 4096

; Socket types
SOCK_STREAM	equ 0x01
SOCK_DGRAM	equ 0x02
SOCK_RAW	equ 0x03
