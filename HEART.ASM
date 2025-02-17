.model tiny
.386
.387

SCREEN_WIDTH	equ 320d
SCREEN_HEIGHT	equ 200d
VERTEX_CNT	equ 100d

VIDEO_MODE	equ 13h
GFX_MEM		equ 0a100h

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
;	call	init_heart

	mov	si, offset p1
	mov	di, offset p2
	call	draw_line

	; int 3
	; mov	si, offset heartFront
	; mov	di, offset testProjected
	; call	project
	; int 3

;	call	draw

	call	wait_for_key
	call	exit_0


	p1	Screen2D	<20d, 10d>
	p2	Screen2D	<100d, 70d>


; ---------------------------------------
; Main drawing procedure
; INPUT:	
; OUTPUT:	
; DESTROYS:	
draw		proc
	
@@main_loop:
	xor	bx, bx
		int 3
	@@projection_loop:
			mov	si, offset heartFront 
			mov	ax, bx
			mul	word ptr [VECTOR3_SZ]
			add	si, ax			
			mov	di, offset vFront
			call	copy_vector3		; vFront = heartFront[i]

;			mov	si, di
;			call	rotate_y		; vFront = rotateY(vFront, angle)
;			mov	si, di
;			call	rotate_x		; vFront = rotateX(vFront, angle)

			mov	di, offset projFront
			mov	ax, bx
			mul	word ptr [SCREEN2D_SZ]
			add	di, ax			; di = projFront + bx * sz 

			call	project

			inc	bx
			cmp	bx, VERTEX_CNT
			jle	@@projection_loop
	
		int 3
	; Render lines
	xor	cx, cx
	@@render_loop:
		mov	ax, cx
		inc	ax
		mov	bx, VERTEX_CNT
		call	modulo			; DX = (i + 1) % vertex_cnt (next)

		mov	si, offset projFront
		mov	ax, cx
		mul	word ptr [SCREEN2D_SZ]
		add	si, ax			; di = projFront + cx * sz 

		xor	ax, ax
		mov	al, 0ch
		call	draw_point		; draw(projFront[i])


		inc	cx
		cmp	cx, VERTEX_CNT
		jl	@@render_loop
	
		ret
;	jmp @@main_loop

	ret

	vFront	Vector3 ?
	vBack	Vector3 ?
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
; INPUT:	SI - p1 (Screen2D), DI - p2 (Screen2D)
; OUTPUT:	None
; DESTROYS:	
draw_line	proc
;plotLine(x0, y0, x1, y1)
;    dx = x1 - x0
;    dy = y1 - y0
;    D = 2*dy - dx
;    y = y0
;
;    for x from x0 to x1
;        plot(x, y)
;        if D > 0
;            y = y + 1
;            D = D - 2*dx
;        end if
;        D = D + 2*dy

;
;	p1	Screen2D	<20d, 10d>
;	p2	Screen2D	<100d, 70d>
;
		int 3

		mov	ax, word ptr [DI.SC_X]
		sub	ax, word ptr [SI.SC_X]	; AX = dx = p2.x - p1.x

		jge	@@dont_swap_points		
		xchg	si, di
		neg	ax

@@dont_swap_points:
		mov	bx, word ptr [DI.SC_Y]
		sub	bx, word ptr [SI.SC_Y]	
		shl	bx, 1			; BX = 2dy = 2 * (p2.y - p1.y)

		mov	dx, bx
		sub	dx, ax			; D = 2dy - dx
		shl	ax, 1			; dx *= 2	
		
		push	si
		mov	cx, word ptr [SI.SC_Y]	; y = p1.y
		mov	si, offset cur_coords
		mov	word ptr [SI.SC_Y], cx
		pop	si

		mov	cx, word ptr [SI.SC_X]	; x = p1.x
		mov	si, offset cur_coords

		int 3

@@line_loop:
		mov	[si.SC_X], cx

		push	ax
		xor	ax, ax
		mov	al, 0ch
		call	draw_point		; set color and draw
		pop	ax

		cmp	dx, 0
		jle	@@less			; D <= 0
		
		push	bx
		mov	bx, word ptr [si.SC_Y]
		inc	bx
		mov	word ptr [si.SC_Y], bx	; y++
		pop	bx
		
		sub	dx, ax			; D -= 2dx
@@less:
		add	dx, bx			; D += 2dy

		cmp	cx, word ptr [DI.SC_X]	; while(x < p2.x)
		jle	@@line_loop
		
		int 3
		ret

	cur_coords	Screen2D ?

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
; Calculate the heart shape and fill heartFront, heartBack vertex array
; INPUT:	None
; OUTPUT:	
; DESTROYS:	
init_heart	proc
		push	cx dx si di bx

		xor	bx, bx
		mov	cx, VERTEX_CNT

		mov	word ptr [cnt], cx 
@@heart_loop:
		mov	word ptr [i], bx
		fild	word ptr [cnt]
		fldpi
		fldpi
		faddp	st(1), st(0)
		fild	word ptr [i]
		fmulp	st(1), st(0); 2 * pi * i
		fdivrp	st(1), st(0)
		fst	dword ptr [curve_t] ; (2 * pi * i) / vertex_cnt

		fsin
		fld	st(0)
		fmul	st(1), st(0)
		fmulp				    
		fimul	word ptr [curve_param_x1]
		fld	dword ptr [curve_scale]
		fmulp
		;fstp	dword ptr [curve_x]		; x1 * sin^3(t) * factor

		mov	ax, bx
		mul	word ptr [VECTOR3_SZ]
		add	ax, offset heartFront.X
		mov	di, ax
		fstp	dword ptr [di]

		fld	dword ptr [curve_t]
		fcos					
		fimul	word ptr [curve_param_y1]

		fld	dword ptr [curve_t]
		fimul	word ptr [curve_param_y3]
		fcos					
		fimul	word ptr [curve_param_y2]
		fsub	st(1), st(0)

		fld	dword ptr [curve_t]
		fimul	word ptr [curve_param_y5]
		fcos					
		fimul	word ptr [curve_param_y4]

		fld	dword ptr [curve_t]
		fimul	word ptr [curve_param_y6]	
		fcos				
		fsub	st(1), st(0)

		fsub	st(1), st(0)
		fld	dword ptr [curve_scale]
		fmulp

		mov	ax, bx
		mul	word ptr [VECTOR3_SZ]
		add	ax, offset heartFront.Y
		mov	di, ax
		fstp	dword ptr [di]
		;fstp	dword ptr [curve_y]


		mov	si, offset depth
		call	copy_dword	; copies Z depth


		inc	bx
		cmp	bx, VERTEX_CNT
		jnz	@@heart_loop


		pop	bx di si dx cx
		ret

i		dw  ?
cnt		dw  ?

curve_t		dd  ?
curve_x		dd  ?
curve_y		dd  ?

curve_param_x1	dw  16

curve_param_y1	dw  13
curve_param_y2	dw  5
curve_param_y3	dw  2
curve_param_y4	dw  2
curve_param_y5	dw  3
curve_param_y6	dw  4
	
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
; INPUT:	angle (GLOBAL VAR)
; OUTPUT:	cached_angle_sin (GLOBAL VAR), cached_angle_cos (GLOBAL_VAR)
; DESTROYS:	None
cache_trig	proc
		fld	dword ptr [angle]
		fsincos
		fstp	dword ptr [cached_angle_sin]
		fstp	dword ptr [cached_angle_cos]

		ret
		endp



; ---------------------------------------
; Rotates Vector3 around X axis by applying a rotation matrix
; INPUT:	SI - Vector3 ptr, DI - PTR to resulting Vector3, angle (GLOBAL VAR)
; OUTPUT:	Outputs the rotated vector into the ptr provided in DI register
; DESTROYS:	None
rotate_x	proc
		push	es si di
		push	ds
		pop	es

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
		fmulp   st(1), st(0)			; st(0) - y * cos(angle)
		fld	dword ptr [SI.Z]
		fld	dword ptr [cached_angle_cos]
		fmulp	st(1), st(0)			
		faddp	st(1), st(0)			

		fstp	dword ptr [DI.Z]		; rotated.z = y * sin(angle) + z * cos(angle)
		fstp	dword ptr [DI.Y]		; rotated.y = y * cos(angle) - z * sin(angle)
		call	copy_dword

		pop	di si es
		ret
		endp


; ---------------------------------------
; Rotates Vector3 around Y axis by applying a rotation matrix
; INPUT:	SI - Vector3 ptr, DI - PTR to resulting Vector3, angle (GLOBAL VAR)
; OUTPUT:	Outputs the rotated vector into the ptr provided in DI register
; DESTROYS:	None
rotate_y	proc
		push	es si di
		push	ds
		pop	es

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

		pop	di si es
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
	angle		    dd  0.0
	depth		    dd	0.25
	curve_scale	    dd	0.05

	cached_angle_sin    dd	?
	cached_angle_cos    dd	?

	SCREEN_WIDTH_HALVED	dw  SCREEN_WIDTH / 2d
	SCREEN_HEIGHT_HALVED	dw  SCREEN_HEIGHT / 2d

	; TestVector	Vector3	<1.5, 2.0, 3.0>
;	heartFront	Vector3 VERTEX_CNT dup(?)
heartFront:
Vector3	<0, 0.25, 0.25>
Vector3	<0.000198049, 0.254031, 0.25>
Vector3	<0.00157503, 0.265936, 0.25>
Vector3	<0.00526343, 0.285161, 0.25>
Vector3	<0.0123045, 0.310814, 0.25>
Vector3	<0.0236068, 0.341703, 0.25>
Vector3	<0.0399093, 0.376395, 0.25>
Vector3	<0.0617509, 0.413282, 0.25>
Vector3	<0.0894469, 0.450653, 0.25>
Vector3	<0.123073, 0.486773, 0.25>
Vector3	<0.16246, 0.519959, 0.25>
Vector3	<0.207193, 0.548652, 0.25>
Vector3	<0.256626, 0.57148, 0.25>
Vector3	<0.309896, 0.58731, 0.25>
Vector3	<0.365957, 0.59529, 0.25>
Vector3	<0.423607, 0.594871, 0.25>
Vector3	<0.48153, 0.585815, 0.25>
Vector3	<0.538342, 0.568188, 0.25>
Vector3	<0.592634, 0.54234, 0.25>
Vector3	<0.643022, 0.508866, 0.25>
Vector3	<0.688191, 0.468566, 0.25>
Vector3	<0.726944, 0.422389, 0.25>
Vector3	<0.758238, 0.371376, 0.25>
Vector3	<0.781224, 0.31661, 0.25>
Vector3	<0.795273, 0.259151, 0.25>
Vector3	<0.8, 0.2, 0.25>
Vector3	<0.795273, 0.140048, 0.25>
Vector3	<0.781224, 0.0800514, 0.25>
Vector3	<0.758238, 0.0206151, 0.25>
Vector3	<0.726944, -0.0378178, 0.25>
Vector3	<0.688191, -0.0949594, 0.25>
Vector3	<0.643022, -0.150661, 0.25>
Vector3	<0.592634, -0.20489, 0.25>
Vector3	<0.538342, -0.257697, 0.25>
Vector3	<0.48153, -0.309183, 0.25>
Vector3	<0.423607, -0.359461, 0.25>
Vector3	<0.365957, -0.408622, 0.25>
Vector3	<0.309896, -0.456704, 0.25>
Vector3	<0.256626, -0.503664, 0.25>
Vector3	<0.207193, -0.549366, 0.25>
Vector3	<0.16246, -0.593566, 0.25>
Vector3	<0.123073, -0.63592, 0.25>
Vector3	<0.0894469, -0.675988, 0.25>
Vector3	<0.061751, -0.713256, 0.25>
Vector3	<0.0399093, -0.747158, 0.25>
Vector3	<0.0236068, -0.777113, 0.25>
Vector3	<0.0123045, -0.80255, 0.25>
Vector3	<0.00526343, -0.822946, 0.25>
Vector3	<0.00157503, -0.837858, 0.25>
Vector3	<0.000198048, -0.846947, 0.25>
Vector3	<-5.3452e-22, -0.85, 0.25>
Vector3	<-0.00019805, -0.846946, 0.25>
Vector3	<-0.00157503, -0.837858, 0.25>
Vector3	<-0.00526342, -0.822947, 0.25>
Vector3	<-0.0123045, -0.80255, 0.25>
Vector3	<-0.0236068, -0.777113, 0.25>
Vector3	<-0.0399093, -0.747159, 0.25>
Vector3	<-0.061751, -0.713256, 0.25>
Vector3	<-0.0894469, -0.675988, 0.25>
Vector3	<-0.123073, -0.63592, 0.25>
Vector3	<-0.16246, -0.593566, 0.25>
Vector3	<-0.207193, -0.549366, 0.25>
Vector3	<-0.256626, -0.503664, 0.25>
Vector3	<-0.309896, -0.456704, 0.25>
Vector3	<-0.365957, -0.408622, 0.25>
Vector3	<-0.423607, -0.359461, 0.25>
Vector3	<-0.48153, -0.309183, 0.25>
Vector3	<-0.538342, -0.257697, 0.25>
Vector3	<-0.592634, -0.20489, 0.25>
Vector3	<-0.643022, -0.150661, 0.25>
Vector3	<-0.688191, -0.0949595, 0.25>
Vector3	<-0.726944, -0.0378179, 0.25>
Vector3	<-0.758238, 0.0206151, 0.25>
Vector3	<-0.781224, 0.0800514, 0.25>
Vector3	<-0.795273, 0.140048, 0.25>
Vector3	<-0.8, 0.2, 0.25>
Vector3	<-0.795273, 0.259152, 0.25>
Vector3	<-0.781224, 0.31661, 0.25>
Vector3	<-0.758238, 0.371376, 0.25>
Vector3	<-0.726944, 0.422389, 0.25>
Vector3	<-0.688191, 0.468566, 0.25>
Vector3	<-0.643022, 0.508866, 0.25>
Vector3	<-0.592634, 0.54234, 0.25>
Vector3	<-0.538342, 0.568188, 0.25>
Vector3	<-0.48153, 0.585815, 0.25>
Vector3	<-0.423607, 0.594871, 0.25>
Vector3	<-0.365957, 0.59529, 0.25>
Vector3	<-0.309897, 0.58731, 0.25>
Vector3	<-0.256626, 0.57148, 0.25>
Vector3	<-0.207193, 0.548653, 0.25>
Vector3	<-0.16246, 0.519959, 0.25>
Vector3	<-0.123073, 0.486773, 0.25>
Vector3	<-0.0894469, 0.450653, 0.25>
Vector3	<-0.0617509, 0.413282, 0.25>
Vector3	<-0.0399093, 0.376395, 0.25>
Vector3	<-0.0236068, 0.341703, 0.25>
Vector3	<-0.0123045, 0.310814, 0.25>
Vector3	<-0.00526342, 0.285161, 0.25>
Vector3	<-0.00157503, 0.265936, 0.25>
Vector3	<-0.000198047, 0.254031, 0.25>

	projFront	Screen2D VERTEX_CNT dup(?)
	projBack	Screen2D VERTEX_CNT dup(?)


	testProjected	Screen2D <0d, 0d>

	factor		dd  ?
	VECTOR3_SZ	dw	SIZE Vector3
	SCREEN2D_SZ	dw	SIZE Screen2D

	test_point	Screen2D <280d, 15d>
END Start

