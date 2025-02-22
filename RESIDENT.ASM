.model tiny
.386

.code
org 100h
Start:
	xor	ax, ax
	mov	es, ax

	mov	al, 1d

	cli
	mov	word ptr es:[AL * 4], ffh

	sti

	mov	al, 0		; exit code
	call	tsr


; ---------------------------------------
; Interrupt handler
int9_handler	proc
		pusha



		popa
		iret
		endp


; ---------------------------------------
; Terminate and stay resident
; INPUT:	AL - exit code	DX - resident memory size (16-byte paragraphs)
; OUTPUT:	None
; Destroys::	None
; WARNING::	THIS FUNCTION DOES NOT RETURN
tsr		proc
		mov	ah, 31h
		int	21h

		endp


end Start

