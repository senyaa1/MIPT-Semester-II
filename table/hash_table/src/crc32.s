global hash_crc32

section .text

hash_crc32:
	push    rbp
	mov     rbp, rsp
	sub     rsp, 32

	vmovdqu ymm0, [rsp]

	mov     rax, 0FFFFFFFFh

	lea     rsi, [rsp]
	crc32   rax, qword [rsi]        ; bytes  0– 7
	crc32   rax, qword [rsi +  8]   ; bytes  8–15
	crc32   rax, qword [rsi + 16]   ; bytes 16–23
	crc32   rax, qword [rsi + 24]   ; bytes 24–31

	not     eax

	leave
	ret

