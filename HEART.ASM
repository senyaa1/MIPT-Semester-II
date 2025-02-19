.model tiny
.386
.387

SCREEN_WIDTH	equ 320d
SCREEN_HEIGHT	equ 200d
VIDEO_MODE	equ 13h
GFX_MEM		equ 0a000h
CHAR_WIDTH	equ 8d
CHAR_HEIGHT	equ 8d

VERTEX_CNT	equ 100d
COLOR		equ 0ch
TEXT_COLOR	equ 0fh
BG_COLOR	equ 00h
DELAY		equ 3000h

CURVE_FACTOR	equ 0.05
STEP_X		equ 0.005
STEP_Y		equ 0.025
FOV_ANGLE	equ 256.0
DIST		equ 4.2
Z_LENGTH	equ 0.15

Vector3	STRUC
	X	dd ?
	Y	dd ?
	Z	dd ?
Vector3	ENDS

Screen2D	STRUC
	SC_X	dw ?
	SC_Y	dw ?
Screen2D	ENDS


.code
org 100h


; ---------------------------------------
; Entrypoint
Start:
	call	init_gfx
	call	init_heart

	call	draw

	call	exit_0



; ---------------------------------------
; Waits for DELAY microseconds
; INPUT:	None
; OUTPUT:	None
; DESTROYS:	None
render_delay	proc
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
; Clears the screen for mode 13h
; INPUT:	None
; OUTPUT:	None
; DESTROYS:	None
clear_screen	proc
		push	ax cx di

		cld
		mov	di, SCREEN_WIDTH * CHAR_HEIGHT
		mov	al, BG_COLOR
		mov	ah, BG_COLOR
		mov	cx, (SCREEN_WIDTH * (SCREEN_HEIGHT - (2 * CHAR_HEIGHT))) / 2d		; amount of operations (/2 since storing words) - 2 since not clearing text
	rep	stosw

		pop	di cx ax
		ret
		endp


; ---------------------------------------
; Renders text specified in SI or 13h GFX mode
; INPUT:	SI - ptr to the string, CL - string length
; OUTPUT:	Text on the screen
; DESTROYS:
render_text	proc		
	mov	dl, SCREEN_WIDTH / CHAR_WIDTH
	sub	dl, cl
	shr	dl, 1
	@@char_loop:
		lodsb

		mov	dh, 0	
		mov	bh, 0		
		mov	ah, 02h		; SetCursorPosition
		int	10h

		mov	bl, TEXT_COLOR
		mov	ah, 0Eh		; Teletype
		int	10h

		mov	dh, (SCREEN_HEIGHT / CHAR_HEIGHT) - 1
		mov	bh, 0		
		mov	ah, 02h		; SetCursorPosition
		int	10h

		mov	bl, TEXT_COLOR
		mov	ah, 0Eh		; Teletype
		int	10h
		
		inc	dl
		loop	@@char_loop

		ret
		endp



; ---------------------------------------
; Rendering macro
; INPUT:	FROM - starting pos array, TO - destination pos array
; OUTPUT:	Renders lines on the screen according to the arguments provided
; DESTROYS:	AX BX CX SI DI
RENDER		macro	FROM, TO
		LOCAL	@@render_loop

		mov	cx, 1d
@@render_loop:
		mov	ax, cx
		inc	ax
		mov	bx, VERTEX_CNT
		call	modulo			; DX = (i + 1) % vertex_cnt (next)

		mov	di, offset FROM
		mov	ax, dx
		mul	word ptr [SCREEN2D_SZ]
		add	di, ax			; si = proj_front + dx * sz 

		mov	si, offset TO
		mov	ax, cx
		mul	word ptr [SCREEN2D_SZ]
		add	si, ax			; di = proj_front + cx * sz 

		xor	ax, ax
		mov	al, COLOR
		call	draw_line		; draw(proj_front[i], proj_front[i + 1 % n])

		inc	cx
		cmp	cx, VERTEX_CNT - 1
		jl	@@render_loop
		
		endm


; ---------------------------------------
; Main drawing procedure 
; INPUT:	ES - video segment, heart_front (GLOBAL VAR) - heart vertices
; OUTPUT:	Renders graphical representation of heart on the screen
; DESTROYS:	AX BX CX DX SI DI
draw		proc
	mov	si, offset STRING
	mov	cl, byte ptr [STRING_LEN]
	call	render_text

@@main_loop:
	fld	dword ptr [angle_x]		; increment the rotation angle
	fadd	dword ptr [angle_step_x]
	fstp	dword ptr [angle_x]

	fld	dword ptr [angle_y]
	fadd	dword ptr [angle_step_y]
	fstp	dword ptr [angle_y]

	xor	bx, bx
	@@projection_loop:
						; project front face
		mov	si, offset heart_front 
		mov	ax, bx
		mul	word ptr [VECTOR3_SZ]
		add	si, ax			
		mov	di, offset vec_front
		call	copy_vector3		; vec_front = heart_front[i]

		mov	si, di
		call	rotate_y		
		call	rotate_x		; vec_front = rotateX(vec_front, angle)

		mov	di, offset proj_front
		mov	ax, bx
		mul	word ptr [SCREEN2D_SZ]
		add	di, ax			; di = proj_front + bx * sz 
		call	project

						; project back face
		mov	si, offset heart_front 
		mov	ax, bx
		mul	word ptr [VECTOR3_SZ]
		add	si, ax			
		mov	di, offset vec_back
		call	copy_vector3		; vec_back = heart_front[i]

		fld	dword ptr [di.Z]
		fchs
		fstp	dword ptr [di.Z]	; vec_back.Z = -vec_back.Z

		mov	si, di
		call	rotate_y	
		call	rotate_x		; vec_back = rotateX(vec_front, angle)

		mov	di, offset proj_back
		mov	ax, bx
		mul	word ptr [SCREEN2D_SZ]
		add	di, ax			; di = proj_back + bx * sz 
		call	project


		inc	bx
		cmp	bx, VERTEX_CNT
		jle	@@projection_loop
	
	call	clear_screen

	RENDER	proj_front, proj_front
	RENDER	proj_back, proj_back
	RENDER	proj_front, proj_back

	call	render_delay


	mov	ah, 1h		;  check for keystroke
	int	16h
	jnz	@@exit		; if ZF=1 => exit

	jmp	@@main_loop

@@exit:
	ret
	endp


; ---------------------------------------
; Converts X Y to pixel position
; INPUT:	SI - Screen2D ptr
; OUTPUT:	DI - GFX ptr
; DESTROYS:	None
pos_to_pixel	proc
		push	ax bx dx
		
		mov	ax, word ptr [SI.SC_Y]			; pos = y * width + x
		mov	bx, SCREEN_WIDTH
		mul	bx
		add	ax, word ptr [SI.SC_X]
		mov	di, ax

		pop	dx bx ax
		ret
		endp


; ---------------------------------------
; Draws a point on a screen
; INPUT:	SI - Screen2D projection coords
; OUTPUT:	None
; DESTROYS:	None
draw_point	proc
		push	ax di
		call	pos_to_pixel

		stosb

		pop	di ax
		ret
		endp


; ---------------------------------------
; Draws a line between 2 points using Bresenham's line algorithm
; INPUT:	SI - p1 (Screen2D), DI - p2 (Screen2D), byte COLOR (global var)
; OUTPUT:	None
; DESTROYS:	None
draw_line	proc
		pusha

		mov	ax, word ptr [DI.SC_X]
		sub	ax, word ptr [SI.SC_X]		; AX =  p2.x - p1.x
		
		mov	word ptr [line_sx], 1
		cmp	ax, 0
		jg	@@positive_sx
		mov	word ptr [line_sx], -1

	@@positive_sx:	
		mov	dx, ax   
		sar	dx, 15  
		xor	ax, dx 
		sub	ax, dx				; ax=abs(ax)
		mov	word ptr [line_dx], ax

		mov	bx, word ptr [DI.SC_Y]		; BX = = p2.y - p1.y
		sub	bx, word ptr [SI.SC_Y]	

		mov	word ptr [line_sy], 1
		cmp	bx, 0
		jg	@@positive_sy
		mov	word ptr [line_sy], -1

	@@positive_sy:
		mov	dx, bx   
		sar	dx, 15  
		xor	bx, dx 
		sub	bx, dx			
		neg	bx				; bx=-abs(dy)
		mov	word ptr [line_dy], bx

		mov	cx, ax 
		add	cx, bx			
		mov	word ptr [line_error], cx		; error = dx + dy

		push	es di
		push	ds
		pop	es				; es = ds
		mov	di, offset cur_coords
		movsw
		movsw
		mov	si, offset cur_coords		; copy SI to cur_coords and set SI to it
		pop	di es
		

	@@line_loop:
		push	ax
		mov	ax, COLOR
		call	draw_point
		pop	ax

		mov	cx, word ptr [di.SC_X]
		xor	cx, word ptr [si.SC_X]
		mov	dx, word ptr [di.SC_Y]
		xor	dx, word ptr [si.SC_Y]
		or	cx, dx
		test	cx, cx				; compare x0 == x1 && y0 == y1
		jz	@@loop_end
	
		mov	dx, word ptr [line_error]
		shl	dx, 1				; error2 = 2 * error

		cmp	dx, bx	; error2 >= dy
		jl	@@dont_inc_x

		add	word ptr [line_error], bx	; error += dy
		mov	cx, word ptr [line_sx]
		add	word ptr [si.SC_X], cx		; x0 += sx
	@@dont_inc_x:

		cmp	dx, ax	; error2 <= dx
		jg	@@dont_inc_y

		add	word ptr [line_error], ax	; error += dx
		mov	cx, word ptr [line_sy]
		add	word ptr [si.SC_Y], cx		; y0 += sy
	@@dont_inc_y:
		jmp	@@line_loop
	@@loop_end:

		popa
		ret
		endp


; ---------------------------------------
; Gets division modulo
; INPUT:	AX - dividend, BX - divisor
; OUTPUT:	DX - modulo
; DESTROYS:	None
modulo		proc
		push	cx
		xor	dx, dx
		div	bx
		pop	cx
		ret
		endp



; ---------------------------------------
; Copies DWORD
; INPUT:	ES:SI, DI
; OUTPUT:	Copies from DS:SI to DS:DI
; DESTROYS:	SI DI
copy_dword	proc
		push	ax es
		push	ds
		pop	es

		lodsw
		stosw
		lodsw
		stosw

		pop	es ax
		ret
		endp


; ---------------------------------------
; Copies Vector3
; INPUT:	ES:SI, DI
; OUTPUT:	Copies vector3 from DS:SI to DS:DI
; DESTROYS:	None
copy_vector3	proc
		push	si di
	
		call	copy_dword
		call	copy_dword
		call	copy_dword

		pop	di si
		ret
		endp


; ---------------------------------------
; Copies Screen2D
; INPUT:	ES:SI, DI
; OUTPUT:	Copies vector2 from DS:SI to DS:DI
; DESTROYS:	None
copy_screen2d	proc
		push	si di
		call	copy_dword
		push	di si
		ret
		endp


; ---------------------------------------
; Calculate the heart shape and fill heart_front vertex array
; INPUT:	None
; OUTPUT:	Initializes heart_front Vector3 array with heart vertices
; DESTROYS:	None
init_heart	proc
		push	cx dx si di bx

		xor	bx, bx
		mov	cx, VERTEX_CNT

@@heart_loop:
		mov	word ptr [heart_i], bx
		fild	word ptr [heart_vertex_cnt]
		fldpi
		fldpi
		faddp	st(1), st(0)
		fild	word ptr [heart_i]
		fmulp	st(1), st(0)				; 2 * pi * i
		fdivrp	st(1), st(0)
		fst	dword ptr [curve_t]			; (2 * pi * i) / vertex_cnt

		fsin
		fld	st(0)
		fmul	st(1), st(0)
		fmul						; sin^3(x)
		fimul	word ptr [curve_param_x1]
		fld	dword ptr [curve_scale]
		fmulp						; x1 * sin^3(t) * factor

		mov	ax, bx
		mul	word ptr [VECTOR3_SZ]
		add	ax, offset heart_front
		mov	di, ax
		fstp	dword ptr [di]


		fld	dword ptr [curve_t]
		fcos					
		fimul	word ptr [curve_param_y1]		; y1 * cos(t)

		fld	dword ptr [curve_t]
		fimul	word ptr [curve_param_y3]
		fcos					
		fimul	word ptr [curve_param_y2]		; y2 * cos(y3t)

		fsubp	st(1), st(0)				; y1*cos(t) - y2 * cos(y3t)

		fld	dword ptr [curve_t]
		fimul	word ptr [curve_param_y5]		
		fcos						
		fimul	word ptr [curve_param_y4]		; y4 * cos(y5t)

		fsubp	st(1), st(0)				; y1*cos(t) - y2*cos(3t) - y4 * cos(y5t)

		fld	dword ptr [curve_t]
		fimul	word ptr [curve_param_y6]	
		fcos						; cos(y6t)

		fsubp	st(1), st(0)				; y1*cos(t) - y2*cos(3t) - y4 * cos(y5t) - cos(y6t)

		fld	dword ptr [curve_scale]
		fmulp


		mov	ax, bx
		mul	word ptr [VECTOR3_SZ]
		add	ax, offset heart_front.Y
		mov	di, ax
		fstp	dword ptr [di]


		mov	ax, bx
		mul	word ptr [VECTOR3_SZ]
		add	ax, offset heart_front.Z
		mov	di, ax
		mov	si, offset depth
		call	copy_dword				; copy Z

		inc	bx
		cmp	bx, VERTEX_CNT
		jnz	@@heart_loop

		pop	bx di si dx cx
		ret	
		endp


; ---------------------------------------
; Projects a 3D vector into screen coords
; INPUT:	SI - Vector3 ptr, DI - Screen2D ptr
; OUTPUT:	Outputs the projected vector into the ptr provided in DI register
; DESTROYS:	None
project		proc	
		fld	dword ptr [fov]		
		fld	dword ptr [distance]
		fld	dword ptr [SI.Z]	; st(0) - z; st(1) - distance; st(2) - fov
		faddp	st(1), st(0)
		fdivp	st(1), st(0)
		fstp    dword ptr [factor]      ; factor = fov / (distance + vector.z)

		fld	dword ptr [SI.X]
		fld	dword ptr [factor]
		fmul
		fild	word ptr [SCREEN_WIDTH_HALVED]
		faddp	st(1), st(0)		; projected.x = (vector.x * factor + width/2)

		fistp	word ptr [DI.SC_X]

		fld	dword ptr [SI.Y]
		fchs
		fld	dword ptr [factor]
		fmul
		fild	word ptr [SCREEN_HEIGHT_HALVED]
		faddp	st(1), st(0)		; projected.y = (-vector.y * factor + height/2)

		fistp	word ptr [DI.SC_Y]
		ret
		endp


; ---------------------------------------
; Caches sin and cos values for the current angle var
; INPUT:	BX - angle ptr
; OUTPUT:	cached_angle_sin (GLOBAL VAR), cached_angle_cos (GLOBAL_VAR)
; DESTROYS:	None
cache_trig	proc
		fld	dword ptr [bx]
		fsincos
		fstp	dword ptr [cached_angle_cos]
		fstp	dword ptr [cached_angle_sin]

		ret
		endp



; ---------------------------------------
; Rotates Vector3 around X axis by applying a rotation matrix
; INPUT:	SI - Vector3 ptr, DI - PTR to resulting Vector3, angle (GLOBAL VAR)
; OUTPUT:	Outputs the rotated vector into the ptr provided in DI register
; DESTROYS:	None
rotate_x	proc
		push	bx es si di
		push	ds
		pop	es
	
		mov	bx, offset angle_x
		call	cache_trig

		fld	dword ptr [SI.Y]
		fld	dword ptr [cached_angle_cos]
		fmulp   st(1), st(0)			; st(0) - y * cos(angle)
		fld	dword ptr [SI.Z]
		fld	dword ptr [cached_angle_sin]
		fmulp	st(1), st(0)			
		fchs					; st(0) - -(z * sin(angle))
		faddp	st(1), st(0)			

		fld	dword ptr [SI.Y]
		fld	dword ptr [cached_angle_sin]
		fmulp   st(1), st(0)			; st(0) - y * sin(angle)
		fld	dword ptr [SI.Z]
		fld	dword ptr [cached_angle_cos]
		fmulp	st(1), st(0)			
		faddp	st(1), st(0)			

		fstp	dword ptr [DI.Z]		; rotated.z = y * sin(angle) + z * cos(angle)
		fstp	dword ptr [DI.Y]		; rotated.y = y * cos(angle) - z * sin(angle)
		call	copy_dword			; rotated.x = x

		pop	di si es bx
		ret
		endp


; ---------------------------------------
; Rotates Vector3 around Y axis by applying a rotation matrix
; INPUT:	SI - Vector3 ptr, DI - PTR to resulting Vector3, angle (GLOBAL VAR)
; OUTPUT:	Outputs the rotated vector into the ptr provided in DI register
; DESTROYS:	None
rotate_y	proc
		push	bx es si di
		push	ds
		pop	es

		mov	bx, offset angle_y
		call	cache_trig

		fld	dword ptr [SI.X]
		fld	dword ptr [cached_angle_cos]
		fmulp   st(1), st(0)			; st(0) - y * cos(angle)
		fld	dword ptr [SI.Z]
		fld	dword ptr [cached_angle_sin]
		fmulp	st(1), st(0)			
		fchs					; st(0) - -(z * sin(angle))
		faddp	st(1), st(0)			

		fld	dword ptr [SI.Y]
		fld	dword ptr [cached_angle_sin]
		fmulp   st(1), st(0)			; st(0) - y * cos(angle)
		fld	dword ptr [SI.Z]
		fld	dword ptr [cached_angle_cos]
		fmulp	st(1), st(0)			
		faddp	st(1), st(0)			

		fstp	dword ptr [DI.Z]		; rotated.z = y * sin(angle) + z * cos(angle)
		fstp	dword ptr [DI.X]		; rotated.x = x * cos(angle) - z * sin(angle)

		add	si, Y
		add	di, Y
		call	copy_dword
 
		pop	di si es bx
		ret
		endp


; ---------------------------------------
; Sets up video mode and ES register
; INPUT:	None
; OUTPUT:	ES - video segment
; DESTROYS:	AX
init_gfx	proc
		push	GFX_MEM
		pop	es

		xor	ah, ah
		mov	al, VIDEO_MODE
		int	10h

		ret
		endp


; ---------------------------------------
; Exits with exit code 0
; WARNING:	THIS FUNCTION DOES NOT RETURN
; INPUT:	None
; OUTPUT:	None
; DESTROYS::	AX
exit_0		proc
		mov	ah, 4ch
		xor	al, al
		int	21h
		
		endp


; ---------------------------------------
; Waits for keypress
; INPUT:	None
; OUTPUT:	None
; Destroys: AH
wait_for_key	proc
		mov	ah, 0
		int	16h
		ret
		endp


.data
		angle_step_x		dd  STEP_X
		angle_step_y		dd  STEP_Y
		fov			dd  FOV_ANGLE
		distance		dd  DIST
		depth			dd  Z_LENGTH
		curve_scale		dd  CURVE_FACTOR

		curve_param_x1		dw  16d
		curve_param_y1		dw  13d
		curve_param_y2		dw  5d
		curve_param_y3		dw  2d
		curve_param_y4		dw  2d
		curve_param_y5		dw  3d
		curve_param_y6		dw  4d

		heart_front		Vector3 VERTEX_CNT dup(?)
		proj_front		Screen2D VERTEX_CNT dup(?)
		proj_back		Screen2D VERTEX_CNT dup(?)
		cur_coords		Screen2D  ?
		vec_front		Vector3 <>
		vec_back		Vector3 <>
		factor			dd  ?
		line_dx			dw  ?
		line_dy			dw  ?
		line_error		dw  ?
		line_sx			dw  ?
		line_sy			dw  ?
		line_error2		dw  ?
		heart_i			dw  ?
		curve_t			dd  ?
		cached_angle_sin	dd  ?
		cached_angle_cos	dd  ?
		angle_x			dd  0.0
		angle_y			dd  0.0

		SCREEN_WIDTH_HALVED	dw  SCREEN_WIDTH / 2d
		SCREEN_HEIGHT_HALVED	dw  SCREEN_HEIGHT / 2d
		VECTOR3_SZ		dw  SIZE Vector3
		SCREEN2D_SZ		dw  SIZE Screen2D
		heart_vertex_cnt	dw  VERTEX_CNT

		STRING			db "Happy Valentine's Day!!"
		STRING_LEN		db 23
END Start

