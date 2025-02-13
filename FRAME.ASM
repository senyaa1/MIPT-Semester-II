.model tiny
.code
org 100h


PSP_CMDLINE_LEN_OFFSET	equ	80h
PSP_CMDLINE_OFFSET	equ	81h
GFX_MEM_SEGMENT		equ	00b800h 
GFX_MODE		equ	3h


FRAME_SETTINGS STRUC
	FR_START_X		db ?
	FR_START_Y		db ?
	FR_WIDTH		db ?
	FR_HEIGHT		db ?
	FR_SELECTED_STYLE	db ?
	; FR_STR_LEN		db ?
	; FR_STR			db 128 dup(?)
	FR_STR			db "amogus is\ absolutely real"
	FR_STR_LEN		db 26
FRAME_SETTINGS ENDS


FRAME_STYLE STRUC
	ST_CHARMAP		db 9 dup(?)
	ST_COLOR		db ?
FRAME_STYLE ENDS


Start:		
		call init_gfx

		call parse_cmdline
		call get_chars

		call draw_frame 
		call draw_text

		call wait_for_key

		xor al, al
		call exit



; Converts string to int, iterates over the string, until it finds non-numeric character
; Input:	SI - ptr to the string
; Output:	BX - converted integer
; Destroys:	None
strtod		proc
		push	ax
		push	cx
		push	dx
		xor	bx, bx

@@next_num:
		lodsb

		cmp	ax, '0'
		jb	@@not_digit
		cmp	ax, '9'
		ja	@@not_digit

		mov	cx, ax
		mov	ax, bx
		mov	dx, 10d
		mul	dx
		mov	bx, ax
		mov	ax, cx
	
		sub	ax, 30h		; AL -  decimal digit
		add	bx, ax

		jmp	@@next_num

@@not_digit:				
		pop dx
		pop cx
		pop ax
		ret
		endp

; Parses command line arguments
; Input:	
; Output:	
; Destroys:
parse_cmdline	proc
		push	es
		mov	dx, ds
		mov	es, dx

		xor	dx, dx
		mov	dl, byte ptr ds:[PSP_CMDLINE_LEN_OFFSET]
		mov	si, PSP_CMDLINE_OFFSET
		add	dx, si				; DX points to the end of the string + 1
		inc	si

		mov	di, offset Current_Settings

		mov	ax, ' '				; Skip whitespaces
		xor	cx, cx				; CX will store the amount of arguments parsed so far
		cld
@@read_loop:
		push	cx
		xor	cx, cx
	repe	scasb
		pop	cx

		call	strtod				; BX now has the parsed integer
		mov	byte ptr [di], bl
		inc	di

			
		cmp	si, dx
		jle	@@read_loop
		
		;int 3
		pop	es
		ret
		endp


; ---------------------------
; Waits for keypress
; Destroys: AH
wait_for_key	proc
		mov  ah, 0
		int  16h
		
		ret
		endp


; Draws text specified in Current_Settings
draw_text	proc
		push	si cx bx
		xor	cx, cx
		mov	si, offset Current_Settings.FR_STR
		mov	cl, byte ptr [Current_Settings.FR_STR_LEN]

		mov	al, byte ptr [Current_Settings.FR_WIDTH]
		sub	al, cl
		mov	ah, byte ptr [Current_Settings.FR_HEIGHT]
		shr	al, 1
		shr	ah, 1
		add	al, byte ptr [Current_Settings.FR_START_X]
		add	ah, byte ptr [Current_Settings.FR_START_Y]
		
		push	cx
		mov	cx, ax
		call	pos_to_pixel
		mov	di, ax		
		pop	cx

		call	get_color
		
@@text_loop:
		lodsb
		cmp	ax, '\'
		je	@@newline
@@newline_cont:
		
		stosw
		loop	@@text_loop

		pop	bx cx si
		ret
	
@@newline:
		
		jmp @@newline_cont

		endp


; Draws the frame
; Input:	Current_Settings
; Output:	None
; Destroys:	BX
draw_frame	proc
		mov cl, byte ptr [Current_Settings.FR_START_X]
		mov ch, byte ptr [Current_Settings.FR_START_Y]
		mov dl, byte ptr [Current_Settings.FR_WIDTH]
		mov dh, byte ptr [Current_Settings.FR_HEIGHT]

		add dh, ch

		call draw_line
		inc ch
		add si, 3

frame_loop:
		call draw_line
		inc ch
		cmp ch, dh
		jl frame_loop

		add si, 3
		call draw_line


		ret
		endp



; Sets color accoring to Current_Settings
; Input: None
get_color	proc
		push	bx
		xor	ax, ax

		mov	al, byte ptr [Current_Settings.FR_SELECTED_STYLE]
		mov	bh, SIZE FRAME_STYLE
		mul	bh
		mov	bx, offset styles			
		add	bx, ax							; bx = style_list + selected * sizeof(frame_style)

		xor	ax, ax
		mov	ah, byte ptr [bx + FRAME_STYLE.ST_COLOR]

		pop	bx
		ret
		endp



; Sets SI according to Current_Settings
get_chars	proc
		push	ax bx
		xor	ax, ax

		mov	al, byte ptr [Current_Settings.FR_SELECTED_STYLE]
		mov	bh, SIZE FRAME_STYLE
		mul	bh
		mov	bx, offset styles			
		add	bx, ax							; bx = style_list + selected * sizeof(frame_style)
		add	bx, FRAME_STYLE.ST_CHARMAP
		mov	si, bx

		pop	bx ax
		ret
		endp


; Draws line
; Input:	(CL, CH) (x,y) - starting pos, si - style ptr, dl - len
; Destroys:	BX, AX, DI
draw_line	proc
		push cx
		push dx
		push si

		call pos_to_pixel
		mov di, ax		; di - gfx memory ptr

		xor cx, cx
		mov cl, dl		; setup for loop ch = len - 2
		dec cl
		dec cl

		cld
		call get_color

		lodsb
		stosw

		lodsb
	rep	stosw

		lodsb
		stosw

		pop si
		pop dx
		pop cx
		ret
		endp

; Waits
; Destroys: ah, cx, dx
sleep		proc
		mov ah, 86h
		mov cx, 001eh		; 2 second wait
		mov dx, 8480h
		int 15h			; bios wait 

		ret
		endp

		
; Sets up graphics and es to point to video memory
; Output: ES - gfx segment, SI - frame style ptr
; Destroys: AX
init_gfx	proc
		xor ah, ah
		mov ax, GFX_MODE
		int 10h			

		mov si, GFX_MEM_SEGMENT
		mov es, si

		ret
		endp


; Input: position - ch - X, cl - Y
; Output: ax - graphics memory offset
; ax = (row * 80 + col) * 2
; Destroys: BX, AX
pos_to_pixel	proc 
		mov al, ch
		mov ah, 0	; ax = row
		
		mov bl, 80	; ax = row * 80
		mul bl
		
		mov bl, cl
		xor bh, bh
		add ax, bx	; ax = row * 80 + col

		shl ax, 1 	; * 2	
		
		ret
		endp


; Input: AL - return code
; Destroys: AX
; This function does not return!
exit		proc
		mov ah, 4ch		
		int 21h
		endp

.data
	Current_Settings	FRAME_SETTINGS <0, 7, 40, 10, 2>
styles:
	user_style		FRAME_STYLE <>
	frame_style1		FRAME_STYLE <"123456789", 07h>
	frame_style2		FRAME_STYLE <"+-+| |+-+", 70h>

END Start

