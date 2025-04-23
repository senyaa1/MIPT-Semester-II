global  crc32_hw

section .text

; Calculates CRC32
; Input: 	RSI - buffer	RDX - len
; Output:	CRC32 checksum (return value)
crc32_hw:
	push    rbx
	mov     eax, edi
	not     eax

	mov     rbx, rsi        ; buf pointer
	mov     rcx, rdx        ; length

	; 8-byte chunks
.loop8:
	cmp     rcx, 8
	jb      .loop4
	crc32   rax, qword [rbx]
	add     rbx, 8
	sub     rcx, 8
	jmp     .loop8

	; 4-byte chunks
.loop4:
	cmp     rcx, 4
	jb      .loop2
	crc32   eax, dword [rbx]
	add     rbx, 4
	sub     rcx, 4
	jmp     .loop4

	; 2-byte chunks
.loop2:
	cmp     rcx, 2
	jb      .loop1
	crc32   eax, word [rbx]
	add     rbx, 2
	sub     rcx, 2
	jmp     .loop2

	; 1-byte
.loop1:
	cmp     rcx, 1
	jb      .done
	crc32   eax, byte [rbx]
	add     rbx, 1
	sub     rcx, 1
	jmp     .loop1

.done:
	not     eax             ; final invert

	pop     rbx
	ret

