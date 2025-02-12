.model tiny

; TODO:
;	render lines and polygons
;	write text by copying from bios memory region
;	make it scroll
;	actually implement the fucking table
;	maybe sound??
;

; DONE:
;	setup vector3, faces and polygon structs
;	set video mode to 13h

Vector3	STRUC
	X	dw ?
	Y	dw ?
	Z	dw ?
Vector3	ENDS

Line	STRUC
	V1	Vector3 <>
	V2	Vector3 <>
Line	ENDS

Polygon	STRUC
	V1	Vector3 <>
	V2	Vector3 <>
	V3	Vector3 <>
Polygon	ENDS


.code
org 100h

Start:
	call	init_gfx
	call	test_draw
	call	exit_0


; ---------------------------------------
; Draw smthing
; INPUT:	None
; OUTPUT:	
; DESTROYS:	
test_draw	proc
		   ; Set Video Mode 13h (320x200, 256 colors)
    mov  ax, 13h
    int  10h

    ; DS:SI -> BIOS ROM font memory (typically F000:FA6E)
    mov  ax, 0F000h  ; Segment address of ROM font
    mov  ds, ax
    mov  si, 0FA6Eh  ; Offset to start of font table

    ; ES:DI -> Video Memory (A000:0000)
    mov  ax, 0A000h
    mov  es, ax
    xor  di, di      ; Start at top-left (0,0) in video memory

    mov  cx, 256     ; Loop through all 256 ASCII characters

draw_chars:
    push cx          ; Save loop counter
    push si          ; Save font pointer

    mov  dx, 8       ; Each character is 8 rows tall

draw_rows:
    mov  al, ds:[si] ; Read 1 byte (8 pixels) from font memory
    inc  si          ; Move to next row of the same character
    mov  ah, al      ; Copy pixel data for manipulation

    ; Store 8 pixels horizontally in video memory
    mov  cl, 8       ; Loop through 8 bits in the byte
draw_pixels:
    test ah, 80h     ; Check the highest bit (leftmost pixel)
    jz  skip_pixel
    mov bl, 0Fh
	mov es:[di], bl  ; Draw white pixel (0x0F color)
skip_pixel:
    inc  di          ; Move to next pixel
    shl  ah, 1       ; Shift left to check the next bit
    loop draw_pixels

    add  di, 312     ; Move to next row in video memory (320 - 8)
    dec  dx
    jnz  draw_rows   ; Repeat for 8 rows

    add  di, 8       ; Move to the next character's position
    pop  si
    add  si, 8       ; Advance font pointer to next character
    pop  cx
    loop draw_chars  ; Process all 256 characters

    ; Wait for key press before exiting
    mov  ah, 0
    int  16h

    ; Restore text mode (mode 03h)
    mov  ax, 03h
    int  10h

    ret

		endp
; ---------------------------------------
; Sets up 13h video mode and ES register
; INPUT:	None
; OUTPUT:	ES - video segment
; DESTROYS:	AX
init_gfx	proc
		mov	ax, 0a100h
		mov	es, ax

		xor	ah, ah
		mov	al, 13h
		int	10h

		ret
		endp


; ---------------------------------------
; Exits with exit code 0
; WARNING:	THIS FUNCTION DOES NOT RETURN
; INPUT:	None
; OUTPUT:	None
; Clobbers:	AX
exit_0		proc
		mov	ah, 4ch
		xor	al, al
		int	21h
		
		endp

.data
	TestVector	Vector3	<1, 2, 3>

END Start

