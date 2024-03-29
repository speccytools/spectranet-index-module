;The MIT License
;
;Copyright (c) 2009 Dylan Smith
;
;Permission is hereby granted, free of charge, to any person obtaining a copy
;of this software and associated documentation files (the "Software"), to deal
;in the Software without restriction, including without limitation the rights
;to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;copies of the Software, and to permit persons to whom the Software is
;furnished to do so, subject to the following conditions:
;
;The above copyright notice and this permission notice shall be included in
;all copies or substantial portions of the Software.
;
;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;THE SOFTWARE.


; Temporary storage
v_snapfd		equ 0x32FF	; Snapshot FD
v_stacksave		equ 0x32FD	; Save the stack pointer
v_snapstack		equ 0x32FB	; Start of snapshot stack

AUTOBOOT		equ 0x81	; Config ID for autoboot flag
ROM_ID			equ 0xFD

INTERPWKSPC		equ 0x3003	; workspace
SN_SCR_CT		equ 0x3000	; scroll count
FILE_ADDR		equ 0x3001	; storage of file address
COPY_ERRNO		equ 0x3000	; errno during copy operation
SRC_FD			equ 0x3001	; source file descriptor
DST_FD			equ 0x3002	; destination file descriptor

