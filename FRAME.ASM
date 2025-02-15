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
	FR_STR			db "amogus is \it is\ really real"
	FR_STR_LEN		db 30
FRAME_SETTINGS ENDS


FRAME_STYLE STRUC
	ST_CHARMAP		db 9 dup(?)
	ST_COLOR		db ?
FRAME_STYLE ENDS

; TODO:
;	opening animation
;	properly parse arguments
;	parse string
;	parse custom styles
;	double-borded style
;	bg

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
		int 3
		xor	ax, ax
		mov	al, ' '				; Skip whitespaces
		cld
@@read_loop:
		mov	cx, -1 
	repe	scasb

		call	strtod				; BX now has the parsed integer
		mov	byte ptr [di], bl
		inc	di

			
		cmp	si, dx
		jle	@@read_loop
		
		pop	es
		int 3
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


; Calculates the length of a line provided (line ends with \)
; Input:	SI - the string itself, CX - length
; Output:	AX - length
; Destroys:	None
line_len		proc
		push	es cx di

		push	ds
		pop	es

		mov	di, si

		xor	ax, ax
		mov	al, '\'				
		cld

	repne	scasb
	
		sub	di, si
		dec	di
		mov	ax, di

		pop	di cx es
		ret
		endp

;		Gets amount of newlines in the text (cnt of \)
; Input:	SI - string, CX - length
; Output:	DH - amount of lines
; Destroys:	None
get_line_cnt	proc
		push	di cx ax

		push	es
		mov	dx, ds
		mov	es, dx
		mov	di, si

		xor	dh, dh

		xor	ax, ax
		mov	al, '\'				
		cld

@@line_cnt_loop:
		scasb
		je @@line_cnt_count
		loop @@line_cnt_loop
	
		pop	es
		pop	ax cx di
		ret

@@line_cnt_count:
		inc	dh
		loop @@line_cnt_loop
		endp


;		Draws multi-line text (terminated with \) specified in Current_Settings
; Input:	None
; Output:	None
; Destroys:	None
draw_text	proc
		push	cx ax dx
		xor	cx, cx
		xor	ax, ax
		xor	dx, dx

		mov	si, offset Current_Settings.FR_STR
		mov	cl, byte ptr [Current_Settings.FR_STR_LEN]
		
		call	get_line_cnt					; calculate offset - (height - lines / 2)
		sub	dh, byte ptr [Current_Settings.FR_HEIGHT]
		neg	dh
		shr	dh, 1
		sub	dh, 1

		cld
@@line_loop:
		call	line_len
		sub	cl, al		; cl - leftover strlen
					; al - current terminated line len
		test	al, al
		jz	@@line_exit

		mov	dl, al
		call	draw_text_line

		add	si, ax
		inc	dh		; skip to newline
		inc	si		; skip one symbol (\)
		dec	cl

		test	cl, cl
		jz	@@line_exit

		jmp	@@line_loop

@@line_exit:


		pop	dx ax cx
		ret
		endp


;		Draws single line at specified offset
; Input:	SI - string start, DH - offset, DL - Line Length
; Output:	None
; Destroys:	DI
draw_text_line	proc
		push	di ax si cx bx

		mov	cl, dl

		mov	al, byte ptr [Current_Settings.FR_WIDTH]
		sub	al, cl
		shr	al, 1							
		add	al, byte ptr [Current_Settings.FR_START_X]		; (width - strlen) / 2 + start_x

		add	ah, dh							
		add	ah, byte ptr [Current_Settings.FR_START_Y]		; offset + start_y + 1
		inc	ah
		
		push	cx
		mov	cx, ax
		call	pos_to_pixel
		mov	di, ax		
		pop	cx

		call	get_color

@@text_loop:
		lodsb
		stosw
		loop	@@text_loop

		pop	bx cx si ax di
		ret
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


; Input: position - ch - X, cl - Y (CX)
; Output: AX - graphics memory offset
; ax = (row * 80 + col) * 2
; Destroys: BX
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
	Current_Settings	FRAME_SETTINGS <15, 15, 40, 10, 2>
styles:
	user_style		FRAME_STYLE <>
	frame_style1		FRAME_STYLE <"123456789", 07h>
	frame_style2		FRAME_STYLE <"+-+| |+-+", 70h>

END Start

