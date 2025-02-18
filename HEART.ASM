.model tiny
.386
.387

SCREEN_WIDTH	equ 320d
SCREEN_HEIGHT	equ 200d
VERTEX_CNT	equ 100d

VIDEO_MODE	equ 13h
GFX_MEM		equ 0a000h
COLOR		equ 0ch
BG_COLOR	equ 00h

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

Start:
	call	init_gfx
	call	init_heart

	call	draw

	call	wait_for_key
	call	exit_0


	p1	Screen2D	<2d, 2d>
	p2	Screen2D	<30d, 100d>


; ---------------------------------------
; Waits for N microseconds
; INPUT:	None
; OUTPUT:	None
; DESTROYS:	None
delay		proc
		push	ax cx dx

		xor	cx, cx
		xor	ax, ax
		mov	ah, 86h
		mov	dx, 2000h
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
		xor	di, di
		mov	al, BG_COLOR
		mov	ah, BG_COLOR
		mov	cx, (SCREEN_WIDTH * SCREEN_HEIGHT) / 2d		; amount of operations (/2 since storing words)
	rep	stosw

		pop	di cx ax
		ret
		endp


; ---------------------------------------
; Main drawing procedure
; INPUT:	
; OUTPUT:	
; DESTROYS:	
draw		proc
	
@@main_loop:
	xor	bx, bx
	fld	dword ptr [angle_x]
	fadd	dword ptr [angle_step_x]
	fstp	dword ptr [angle_x]

	fld	dword ptr [angle_y]
	fadd	dword ptr [angle_step_y]
	fstp	dword ptr [angle_y]

	@@projection_loop:
			; project front face
			mov	si, offset heartFront 
			mov	ax, bx
			mul	word ptr [VECTOR3_SZ]
			add	si, ax			
			mov	di, offset vFront
			call	copy_vector3		; vFront = heartFront[i]

			mov	si, di
			call	rotate_y		; vFront = rotateY(vFront, angle)
			call	rotate_x		; vFront = rotateX(vFront, angle)

			mov	di, offset projFront
			mov	ax, bx
			mul	word ptr [SCREEN2D_SZ]
			add	di, ax			; di = projFront + bx * sz 

			call	project


			; project back face
			mov	si, offset heartFront 
			mov	ax, bx
			mul	word ptr [VECTOR3_SZ]
			add	si, ax			
			mov	di, offset vBack
			call	copy_vector3		; vBack = heartFront[i]

			fld	dword ptr [di.Z]
			fchs
			fstp	dword ptr [di.Z]	; vBack.Z = -vBack.Z

			mov	si, di
			call	rotate_y		; vBack = rotateY(vFront, angle)
			call	rotate_x		; vBack = rotateX(vFront, angle)

			mov	di, offset projBack
			mov	ax, bx
			mul	word ptr [SCREEN2D_SZ]
			add	di, ax			; di = projBack + bx * sz 

			call	project


			inc	bx
			cmp	bx, VERTEX_CNT
			jle	@@projection_loop
	
	call	clear_screen
	; Render lines
	xor	cx, cx
	@@front_render_loop:
		mov	ax, cx
		inc	ax
		mov	bx, VERTEX_CNT
		call	modulo			; DX = (i + 1) % vertex_cnt (next)

		mov	di, offset projFront
		mov	ax, dx
		mul	word ptr [SCREEN2D_SZ]
		add	di, ax			; si = projFront + dx * sz 

		mov	si, offset projFront
		mov	ax, cx
		mul	word ptr [SCREEN2D_SZ]
		add	si, ax			; di = projFront + cx * sz 

		xor	ax, ax
		mov	al, COLOR
		call	draw_line		; draw(projFront[i], projFront[i + 1 % n])

		inc	cx
		cmp	cx, VERTEX_CNT
		jl	@@front_render_loop


	xor	cx, cx
	@@back_render_loop:
		mov	ax, cx
		inc	ax
		mov	bx, VERTEX_CNT
		call	modulo			; DX = (i + 1) % vertex_cnt (next)

		mov	di, offset projBack
		mov	ax, dx
		mul	word ptr [SCREEN2D_SZ]
		add	di, ax			; si = projBack + dx * sz 

		mov	si, offset projBack
		mov	ax, cx
		mul	word ptr [SCREEN2D_SZ]
		add	si, ax			; di = projBack + cx * sz 

		xor	ax, ax
		mov	al, COLOR
		call	draw_line		; draw(projBack[i], projBack[i + 1 % n])

		inc	cx
		cmp	cx, VERTEX_CNT
		jl	@@back_render_loop


	xor	cx, cx
	@@intertwined_render_loop:
		mov	ax, cx
		inc	ax
		mov	bx, VERTEX_CNT
		call	modulo			; DX = (i + 1) % vertex_cnt (next)

		mov	di, offset projFront
		mov	ax, dx
		mul	word ptr [SCREEN2D_SZ]
		add	di, ax			; si = projBack + dx * sz 

		mov	si, offset projBack
		mov	ax, cx
		mul	word ptr [SCREEN2D_SZ]
		add	si, ax			; di = projBack + cx * sz 

		xor	ax, ax
		mov	al, COLOR
		call	draw_line		; draw(projBack[i], projBack[i + 1 % n])

		inc	cx
		cmp	cx, VERTEX_CNT
		jl	@@intertwined_render_loop
	

	
	

	call	delay
	jmp	@@main_loop

	ret

	vFront	Vector3 <>
	vBack	Vector3 <>
		endp


; ---------------------------------------
; Converts X Y to pixel position
; INPUT:	SI - Screen2D ptr
; OUTPUT:	DI - GFX ptr
; DESTROYS:	None
pos_to_pixel	proc
		push	ax bx dx
		; pos = y * width + x
		mov	ax, word ptr [SI.SC_Y]
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
; Calculate the heart shape and fill heartFront vertex array
; INPUT:	None
; OUTPUT:	
; DESTROYS:	
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
		add	ax, offset heartFront
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
		add	ax, offset heartFront.Y
		mov	di, ax
		fstp	dword ptr [di]


		mov	ax, bx
		mul	word ptr [VECTOR3_SZ]
		add	ax, offset heartFront.Z
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
	fov		    dd  256.0
	distance	    dd  4.0

	angle_x		    dd  0.0
	angle_step_x	    dd  0.02

	angle_y		    dd  0.0
	angle_step_y	    dd  0.01

	depth		    dd	0.25
	curve_scale	    dd	0.05

	cached_angle_sin    dd	?
	cached_angle_cos    dd	?

	SCREEN_WIDTH_HALVED	dw  SCREEN_WIDTH / 2d
	SCREEN_HEIGHT_HALVED	dw  SCREEN_HEIGHT / 2d

	heartFront	Vector3 VERTEX_CNT dup(?)
	projFront	Screen2D VERTEX_CNT dup(?)
	projBack	Screen2D VERTEX_CNT dup(?)


	testProjected	Screen2D <0d, 0d>

	factor		dd  ?
	VECTOR3_SZ	dw	SIZE Vector3
	SCREEN2D_SZ	dw	SIZE Screen2D

	test_point	Screen2D <280d, 15d>

	
	cur_coords	Screen2D ?
	line_dx	dw ?
	line_dy	dw ?
	line_error	dw ?
	line_sx	dw ?
	line_sy	dw ?
	line_error2	dw ?

heart_i		 dw  ?
heart_vertex_cnt dw  VERTEX_CNT

curve_t		dd  ?
curve_param_x1	dw  16

curve_param_y1	dw  13
curve_param_y2	dw  5
curve_param_y3	dw  2
curve_param_y4	dw  2
curve_param_y5	dw  3
curve_param_y6	dw  4
END Start

