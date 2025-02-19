.model tiny
.386
.code
org 100h


PSP_CMDLINE_LEN_OFFSET	equ	80h
PSP_CMDLINE_OFFSET	equ	81h
GFX_MEM_SEGMENT		equ	00b800h 
GFX_MODE		equ	3h
DELAY			equ	04444h

FRAME_SETTINGS STRUC
	FR_START_X		db 15
	FR_START_Y		db 5 
	FR_WIDTH		db 25
	FR_HEIGHT		db 10 
	FR_DYNAMIC		db 1
	FR_SELECTED_STYLE	db 2
	FR_STR_LEN		db 0
	FR_STR			db 128d dup(?)
FRAME_SETTINGS ENDS


FRAME_STYLE STRUC
	ST_COLOR		db 0ch
	ST_CHARMAP		db 9 dup(?)
FRAME_STYLE ENDS

; TODO:
;	pair up with the graphical frame

Start:		
		call	init_gfx

		call	parse_cmdline
		call	get_chars

		mov	ah, byte ptr [Current_Settings.FR_DYNAMIC]
		test	ah, ah
		jz	@@static
		call	draw_dynamic
	@@static:
		call	draw_frame 

		call	draw_text

		call	wait_for_key

		xor	al, al
		call	exit


; ---------------------------------------
; Waits for DELAY microseconds
; INPUT:	DELAY (MACRO CONSTANT)
; OUTPUT:	None
; Destroys::	None
dynamic_delay	proc
		push	ax cx dx

		xor	cx, cx
		xor	ax, ax
		mov	ah, 86h
		mov	dx, DELAY
		int	15h
		
		pop	dx cx ax
		ret
		endp


; ---------------------------------------
; Renders frame dynamically
; INPUT:	Current_Settings (GLOBAL VAR)
; OUTPUT:	Frame on the screen
; Destroys:	AX BX CX DX
draw_dynamic	proc
		mov	dl, byte ptr [Current_Settings.FR_WIDTH]
		mov	cl, dl
		shr	cl, 1
		add	cl, byte ptr [Current_Settings.FR_START_X]	; cl = width / 2 + start_x

		mov	dh, byte ptr [Current_Settings.FR_HEIGHT]
		mov	ch, dh
		shr	ch, 1
		add	ch, byte ptr [Current_Settings.FR_START_Y]	; ch = height / 2 + start_y

		mov	al, 2
		mov	ah, 2
@@dynamic_loop:	
		mov	byte ptr [Current_Settings.FR_WIDTH], al
		mov	byte ptr [Current_Settings.FR_START_X], cl
		mov	byte ptr [Current_Settings.FR_HEIGHT], ah
		mov	byte ptr [Current_Settings.FR_START_Y], ch
		call	draw_frame 

		call	dynamic_delay

		cmp	ah, dh
		je	@@dont_inc_y
		inc	ah
		inc	ah	; ah += 2
		dec	ch	; ch--;
	@@dont_inc_y:

		cmp	al, dl
		je	@@dont_inc_x
		inc	al
		inc	al	; al += 2
		dec	cl	; cl--;
	@@dont_inc_x:
		
		xor     bx, bx
		xor     bh, ah
		xor     bh, dh
		xor	bl, al
		xor	bl, dl
		test	bx, bx	; exit loop if ah == dx && al == dl

		jnz	@@dynamic_loop

		ret
		endp


; ---------------------------------------
; Converts string to int, iterates over the string, until it finds non-numeric character
; INPUT:	SI - ptr to the string
; OUTPUT:	BX - converted integer
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

parse_cmdline proc
		push    es
		mov     dx, ds
		mov     es, dx

		xor     dx, dx
		mov     dl, byte ptr ds:[PSP_CMDLINE_LEN_OFFSET]
		mov     si, PSP_CMDLINE_OFFSET
		add     dx, si                ; DX = end pointer of the command line
		inc     si                    ; Skip length byte

		mov     di, offset Current_Settings

	@@read_loop:
	@@skip_whitespace:
		cmp     si, dx
		jae     @@done_parsing        ; no more characters
		cmp     byte ptr [si], ' '
		jne     @@token_found
		inc     si
		jmp     @@skip_whitespace

	@@token_found:
		mov     bl, byte ptr [si]
		cmp     bl, ''''              ; If we see a quote, then parse a string
		je      @@parse_string

		call    strtod
		mov     byte ptr [di], bl     ; store the parsed integer into the structure
		inc     di                    ; advance destination for next integer
		jmp     @@read_loop

	@@parse_string:	
		inc     si		; Skip the opening quote 
		push	di

		mov     cl, byte ptr [Current_Settings.FR_STR_LEN]
		cmp     cl, 0
		je      @@text_not_written    ; if FR_STR_LEN==0, copy into FR_STR
		mov     di, offset user_style.ST_CHARMAP 		; Otherwise, copy into user_style.ST_CHARMAP:
		jmp     @@copy_loop
	@@text_not_written:
		mov     di, offset Current_Settings.FR_STR
		mov	ch, 1                 ; start our counter at 1
		
	@@copy_loop:			; Copy until closing quote
		mov     al, [si]
		cmp     al, ''''
		je      @@end_copy
		mov     es:[di], al
		inc     di
		inc     ch
		inc     si
		jmp	@@copy_loop
	@@end_copy:
		mov     cl, byte ptr [Current_Settings.FR_STR_LEN]
		cmp     cl, 0
		pop	di
		jne     @@get_color    ;	if FR_STR_LEN==0, copy length into FR_STR_LEN, otherwise expect color for custom style
		mov     byte ptr [Current_Settings.FR_STR_LEN], ch
		inc     si                    
		jmp     @@read_loop

	@@done_parsing:
		pop     es
		ret

	@@get_color:
		inc	si
		call	hexstrtod
		mov	byte ptr [user_style.ST_COLOR], bl
		jmp	@@done_parsing
		endp


; ---------------------------------------
; Converts a hex string to int.
; INPUT:	SI - pointer to the null-terminated string
; OUTPUT:	BX - converted integer
; Destroys:	None 
hexstrtod	proc
		push    ax cx dx         
		xor     bx, bx     

	@@next_char:
		lodsb              
		cmp     al, '0'
		jb      @@check_upper    ; if AL < '0', not a digit, => letters
		cmp     al, '9'
		jbe     @@process_num

	@@check_upper:
		; 'A' to 'F'
		cmp     al, 'A'
		jb      @@check_lower    ; if AL < 'A', not valid
		cmp     al, 'F'
		jbe     @@process_upper

	@@check_lower:
		; 'a' to 'f'
		cmp     al, 'a'
		jb      @@exit           ; if AL < 'a', not a hex digit
		cmp     al, 'f'
		jbe     @@process_lower
		jmp     @@exit           ; not a valid hex digit

	@@process_num:
		; '0'..'9'
		mov     cx, ax  
		mov     ax, bx         ; AX = current total
		mov     dx, 16d
		mul     dx             
		mov     bx, ax         ; BX = previous total * 16
		mov     ax, cx        
		sub     ax, '0'        ; Convert ASCII to numeric value (0-9)
		add     bx, ax         ; Add the digit value to total
		jmp     @@next_char

	@@process_upper:
		; 'A'..'F'
		mov     cx, ax         ; original character in CX
		mov     ax, bx
		mov     dx, 16d
		mul     dx
		mov     bx, ax
		mov     ax, cx
		sub     ax, 'A'
		add     ax, 10
		add     bx, ax
		jmp     @@next_char

	@@process_lower:
		; 'a'..'f'
		mov     cx, ax         ; original character in CX
		mov     ax, bx
		mov     dx, 16d
		mul     dx
		mov     bx, ax
		mov     ax, cx
		sub     ax, 'a'        
		add     ax, 10         
		add     bx, ax
		jmp     @@next_char

	@@exit:
		pop     dx cx ax
		ret
		endp
	

; ---------------------------------------
; Waits for a keypress
; INPUT:	None
; OUTPUT:	None
; DESTROYS:	AH 
wait_for_key	proc
		mov  ah, 0
		int  16h
		ret
		endp

; ---------------------------------------
; Calculates the length of a line provided (line ends with \)
; INPUT:	SI - the string itself, CX - length
; OUTPUT:	AX - length
; DESTROYS:	None
line_len	proc
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


; ---------------------------------------
; Gets amount of newlines in the text (cnt of \)
; INPUT:	SI - string, CX - length
; OUTPUT:	DH - amount of lines
; DESTROYS:	None
get_line_cnt	proc
		push	di cx ax

		push	es
		mov	dx, ds
		mov	es, dx
		mov	di, si

		xor	dh, dh

		xor	ax, ax
		mov	al, '\'		; iterate until \
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


; ---------------------------------------
; Draws multi-line text (terminated with \) specified in Current_Settings
; INPUT:	None
; OUTPUT:	None
; DESTROYS:	None
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


; ---------------------------------------
; Draws single line at specified offset
; INPUT:	SI - string start, DH - offset, DL - Line Length
; OUTPUT:	None
; DESTROYS:	DI
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


; ---------------------------------------
; Draws the frame
; INPUT:	Current_Settings
; OUTPUT:	None
; Destroys:	AX BX CX DX
draw_frame	proc
		pusha
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

		popa
		ret
		endp


; ---------------------------------------
; Sets color accoring to Current_Settings
; INPUT:	Current_Settings
; OUTPUT:	Color
; DESTROYS:	AX
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



; ---------------------------------------
; Sets SI according to Current_Settings
; INPUT:	Current_Settings
; OUTPUT:	SI
; Destroys:	None
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


; ---------------------------------------
; Draws line
; INPUT:	(CL, CH) (x,y) - starting pos, si - style ptr, dl - len
; OUTPUT:	Line on a screen
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

		lodsb			; copy edge syms and the central line sym
	rep	stosw

		lodsb
		stosw

		pop si
		pop dx
		pop cx
		ret
		endp

		
; ---------------------------------------
; Sets up graphics and es to point to video memory
; INPUT:	None
; OUTPUT:	ES - gfx segment, SI - frame style ptr
; Destroys:	AX
init_gfx	proc
		xor ah, ah
		mov ax, GFX_MODE
		int 10h			

		mov si, GFX_MEM_SEGMENT
		mov es, si

		ret
		endp


; ---------------------------------------
; INPUT:	position - ch - X, cl - Y (CX)
; OUTPUT:	AX - graphics memory offset
;		ax = (row * 80 + col) * 2
; DESTROYS:	BX
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


; ---------------------------------------
; INPUT:	AL - return code
; OUTPUT:	None
; DESTROYS:	AX
; WARNING:	This function does not return!
exit		proc
		mov ah, 4ch		
		int 21h
		endp

.data
	Current_Settings	FRAME_SETTINGS <20, 6, 40, 10, 1>
styles:
	user_style		FRAME_STYLE <>
	frame_style1		FRAME_STYLE <70h, "+-+| |+-+">
	frame_style2		db 1bh, 0c9h, 0cdh, 0bbh, 0bah, 20h, 0bah, 0c8h, 0cdh, 0bch
	frame_style3		db 1bh, 0dah, 0c4h, 0bfh, 0b3h, 20h, 0b3h, 0c0h, 0c4h, 0d9h

END Start

