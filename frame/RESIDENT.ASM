include	FRAME.INC

extrn	Current_Settings:FRAME_SETTINGS

ON_KEY		equ	3bh
OFF_KEY		equ	3ch
DEF_WIDTH	equ	8d
DEF_HEIGHT	equ	10d

.model tiny
.386

.code
org 100h
Start:
	call	frame_setup

	mov	ax, offset int8_handler		; handler offset
	mov	bx, 08h				; interrupt num
	mov	di, offset int8_original_jmp
	call	hook_interrupt


	mov	ax, offset int9_handler		; handler offset
	mov	bx, 09h				; interrupt num
	mov	di, offset int9_original_jmp
	call	hook_interrupt
		

	xor	al, al		; exit code
	call	tsr


; ---------------------------------------
; Hooks specified interrupt and saves original interrupt vector in specified memory address
; INPUT:	AX  - new interupt vector offset    BX - interrupt number   ES:DI - ptr to copy original vector to 2 words (offset then segment)
;		Assumes that the interrupt vector lies in CS segment
; OUTPUT:	None
; Destroys:	AX BX CX SI DI
hook_interrupt	proc
		push	ds

		xor	cx, cx
		mov	ds, cx			; ds = 0000
		shl	bx, 2			; bx *= 4
		mov	si, bx
		
		movsw				; copy offset
		movsw				; copy segment

		cli
		mov	word ptr ds:[BX], ax		; copy new offset
		mov	word ptr ds:[BX + 2], cs	; copy new segment
		sti
		
		pop	ds
		ret
		endp


; ---------------------------------------
; Timer interrupt handler
; Updates frame state every timer tick
int8_handler	proc
		call	frame_tick

		db 0eah		; far jump
int8_original_jmp:
		dw 0		; offset
		dw 0		; segment
		endp


; ---------------------------------------
; Keyboard interrupt handler
int9_handler	proc
		push	ax es

		in	al, 60h		; get current scan-code
		cmp	al, ON_KEY
		je	@@turn_on
		cmp	al, OFF_KEY
		je	@@turn_off

					; otherwise jump to original interrupt
		pop	es ax
		db 0eah		; far jump
int9_original_jmp:
		dw 0		; offset
		dw 0		; segment

@@turn_on:
		mov	al, 1
		cmp	byte ptr cs:[is_active], al
		je	@@toggle_end			; if al == 1, then skip

		mov	byte ptr cs:[is_active], al
		call	save_buf		; es = video seg, save video buffer
		jmp	@@toggle_end
@@turn_off:
		xor	al, al
		cmp	byte ptr cs:[is_active], al
		je	@@toggle_end			; if al == 0, then skip

		mov	byte ptr cs:[is_active], al
		call	restore_buf
@@toggle_end:
		call	frame_tick

		in	al, 61h
		mov	ah, al		; get keyboard control line 
		or	al, 80h		; enable keyboard
		out	61h, al		; send
		xchg	ah, al
		out	61h, al		; send back original control port val

		mov	al, 20h
		out	20h, al		; end-of-interrupt
		pop	es ax
		iret
		endp


; ---------------------------------------
; Converts AX register to hex representation
; INPUT:	AX - hex number	DI - start of the destination string
; OUTPUT:	HEX string in DI
; Destroys:	None
convert_hex	proc
		push	ax bx cx di
		add	di, 3             ; move dI to the last hex digit (hex_str[3])
		mov	cx, 4             ; we have 4 hex digits in a 16-bit value

@@convert_loop:
		mov	bx, ax
		and	bx, 0Fh           ; BX = low nibble

		cmp	bx, 9
		jbe	@@digit
		add	bx, 37h           ; 37h = 'A' - 10 
		jmp	@@store_char

@@digit:
		add	bx, '0'

@@store_char:
		mov	cs:[di], bl
		dec	di
		shr	ax, 4
		loop	@@convert_loop	   ; copy final char

		pop	di cx bx ax
		ret
		endp


; ---------------------------------------
; Saves registers in a string for future display
; INPUT:	AX BX CX DX SI DI
; Output:	Populates Current_Settings.FR_STR with register values (global var)
; Destroys:	None
save_registers	proc
		push	es
		push	ax bx cx dx sp bp si di
		
		push	cs
		pop	es	; es = cs

		mov	di, offset Current_Settings.FR_STR
		mov	si, offset reg_names

		mov	al, ' '
		stosb

		mov	cx, 8d
		mov	bx, sp
		add	bx, 8d * 2d			; add offset to 8 word regs

@@copy_reg_loop:
		push    ds cs
		pop	ds
		movsw
		movsw
		pop	ds				; copy vals
		
		sub	bx, 2d	; bx -= 2
		mov	ax, word ptr [bx]
		call	convert_hex
		add	di, 4d

		mov	ax, '\'				; add newline
		stosw

		loop	@@copy_reg_loop

		pop	di si bp sp dx cx bx ax

		pop	es
		ret
		endp


; ---------------------------------------
; Frame setup procedure
; Destroys:	AX
frame_setup	proc
		xor	al, al
		mov	byte ptr [Current_Settings.FR_START_X], al
		mov	byte ptr [Current_Settings.FR_START_Y], al	; startx = starty = 0

		mov	al, DEF_WIDTH
		mov	byte ptr [Current_Settings.FR_WIDTH], al

		mov	al, DEF_HEIGHT
		mov	byte ptr [Current_Settings.FR_HEIGHT], al

		mov	byte ptr cs:[Current_Settings.FR_STR_LEN], 8d * 10d + 1d

		ret
		endp


; ---------------------------------------
; Main frame tick procedure
frame_tick	proc
		call	save_registers			; first of all save registers

		push	es ds
		pusha
	
		push	cs
		pop	ds				; ds = cs

		mov	al, byte ptr cs:[is_active]
		test	al, al
		jz	@@frame_tick_end		; if (is_active == 0) => return

		push	GFX_MEM_SEGMENT			; es = video segment
		pop	es

		call	show_frame


@@frame_tick_end:
		popa
		pop	ds es	
		ret
		endp


; ---------------------------------------
; Terminate and stay resident
; INPUT:	AL - exit code	DX - resident memory size (16-byte paragraphs)
; OUTPUT:	None
; Destroys:	None
; WARNING:	THIS FUNCTION DOES NOT RETURN
tsr		proc
		mov	ah, 31h
		int	21h
		endp

.data
	is_active:	db 0
reg_names:	db "ax: bx: cx: dx: sp: bp: di: si: "
end Start




