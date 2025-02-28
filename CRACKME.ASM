;	Simple MS-DOS crackme that contains 2 vulnerabilities
; 	1) Very simple buffer overflow, the password literally overflows the correct password buffer
;	2) if the password starts with C then it would execute the buffer as code


.model tiny

.386
.387

BIOS_MEMORY_SEG	equ	0f00h
BUF_LEN		equ	32d

.code
org 100h
Start:		
	call	anti_debug		; player should disable this simple anti-debugging feature by NOP-ing this function
	call	password_prompt	
	call	exit


; ---------------------------------------
; Just a macro that spells "stop nothing here" with the first instruction letters
STOP_NOTHING_HERE	macro
		LOCAL	@@loop_macro
		xchg	ax, bx
		xchg	ax, bx
		xchg	ax, bx

@@loop_macro:
		Sar	ax, 1d
		Test	dx, dx
		Or	bx, ax
		Push	si
		Nop
		Or	ax, ax
		Test	ax, ax
		Hlt
		Int	3d
		Nop
		Hlt
		Enter	0, 0
		Ror	ax, 1d 
		Enter	0, 0
		
		xchg	ax, bx
		xchg	ax, bx
		xchg	ax, bx
		jmp	@@loop_macro

		endm


; ---------------------------------------
; INPUT:	IDT interrupt 1,3
; OUTPUT:	Loops in case it detects a debugger
; WARNING:	This function might not return!
anti_debug	proc
		push	ds
		xor	ax, ax
		mov	ds, ax

		mov	bx, 4d
		mov	ax, word ptr ds:[BX + 2]	; load the segment of interrupt vector 1

		mov	bx, 12d
		mov	cx, word ptr ds:[BX + 2]	; load the segment of interrupt vector 3

		cmp	cx, BIOS_MEMORY_SEG
		jg	@@detected
		cmp	cx, BIOS_MEMORY_SEG
		jg	@@detected

		pop	ds
		ret

@@detected:
		pop	ds
		mov	dx, offset detected
		call	display_string

		STOP_NOTHING_HERE

		call	exit
		endp


; ---------------------------------------
; Main password prompt function
; INPUT:	None
; OUTPUT:	Returns success or failure on the screen
; DESTROYS:	None
password_prompt	proc
		call	newline
		mov	dx, offset enter_password_str
		call	display_string

		mov	di, offset password_buf
		call	read_stdin

		; "vuln" 2) in case of 'C' first letter => execute the code on the buffer
		;	should write a resident program to enter those bytes
		mov	al, byte ptr [offset password_buf]
		cmp	al, 'C'
		je	password_buf + 1

		mov	si, offset password_buf
		mov	di, offset required_pass
		mov	cx, word ptr[required_pass_len]
		call	strcmp
		test	cx, cx
		jz	@@correct
		
		mov	dx, offset password_failed
		call	display_string
		ret
@@correct:
		mov	dx, offset password_ok
		call	display_string
		ret
		endp


;---------------------------------------
; Compares 2 strings
; INPUT:	ES:SI, DS:SI, CX - length
; OUTPUT:	CX = 0 if equal
; DESTROYS:	
strcmp		proc
		
@@cmploop:
		lodsb
		scasb
		jne	@@not_equal
		loop	@@cmploop

@@not_equal:
		ret
		endp



; ---------------------------------------
; Reads string from stdin
; INPUT:	DI - destination ptr
; OUTPUT:	Data from STDIN in buf at DI; 	CX - bytes written
; DESTROYS:	AX, CX
read_stdin	proc
@@read_loop:
		xor	ax, ax
		xor     cx, cx
		mov     ah, 08h         ; read char from stdin
		int     21h

		cmp     al, 0Dh         ; Check if carriage return
		je      @@finished_input

		stosb
;		First vuln -- EZ overflow
;		cmp     cx, BUF_LEN - 1         
;		jae     @@finished_input  ; if reached 127, exit loop
	
		jmp     @@read_loop
@@finished_input:
		mov     byte ptr [di], 0 ; null-terminate the string

		call	newline
		ret
		endp


; ---------------------------------------
; INPUT:	DS:DX string to be printed
; OUTPUT:	None
; DESTROYS:	AX
display_string	proc
		xor	ax, ax
		mov	ah, 09h
		int	21h
		ret
		endp


; ---------------------------------------
; INPUT:	AL - return code
; OUTPUT:	None
; DESTROYS:	AX
; WARNING:	This function does not return!
exit		proc
		xor	ax, ax
		mov 	ah, 4ch		
		int 	21h
		endp


; ---------------------------------------
; INPUT:	None
; OUTPUT:	Prints newline
; DESTROYS:	AH, DL
newline		proc
		mov     ah, 02h
		mov     dl, 0Dh
		int     21h

		mov     dl, 0Ah
		int	21h

		ret
		endp


.data
	password_ok		db	"Correct password! Authorized!$"
	password_failed		db	"Wrong password, you should try again...$"
	detected 		db	"i see ya doing some shady stuff... better not..$"
	enter_password_str 	db	"Enter password: $"
	required_pass_len	dw 	11d

	password_buf:		db 	BUF_LEN dup(0)
	required_pass		db 	"iamveryreal"


END	Start

