.model tiny
.386
.387

SCREEN_WIDTH	equ 640d
SCREEN_HEIGHT	equ 480d
VERTEX_CNT	equ 40d

VIDEO_MODE	equ 13h
GFX_MEM		equ 0a100h

Vector3	STRUC
	X	dd ?
	Y	dd ?
	Z	dd ?
Vector3	ENDS

Vector2	STRUC
	X	dd ?
	Y	dd ?
Vector2	ENDS

.code
org 100h

Start:
	call	init_gfx
	call	init_heart


	call	wait_for_key
	call	exit_0

; ---------------------------------------
; Calculate the heart shape and fill heartFront, heartBack vertex array
; INPUT:	None
; OUTPUT:	
; DESTROYS:	
init_heart	proc
		int 3
		push	cx dx
		xor	dx, dx
		mov	cx, VERTEX_CNT

		mov	word ptr [cnt], cx 
@@heart_loop:
		mov	word ptr [i], dx
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
		fstp	dword ptr [curve_x]		; x1 * sin^3(t) * factor

		fld	dword ptr [curve_t]
		fcos

		fld	dword ptr [curve_t]
		fimul	word ptr [curve_param_y3]
		fcos

		fld	dword ptr [curve_t]
		fimul	word ptr [curve_param_y5]
		fcos; st(0)


		fld	dword ptr [curve_t]
		fimul	word ptr [curve_param_y6]	
		fcos					; st(0)

		inc	dx
		loop	@@heart_loop


		pop	dx cx
		int 3
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
; INPUT:	SI - Vector3 ptr, DI - Vector2 ptr
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
		fild	word ptr [SCREEN_WIDTH_HALVED]
		fmulp	st(1), st(0)
		faddp	st(1), st(0)		; projected.x = (vector.x * factor + width/2)
		fstp	dword ptr [DI.X]

		fld	dword ptr [SI.Y]
		fchs
		fld	dword ptr [factor]
		fild	word ptr [SCREEN_HEIGHT_HALVED]
		fmulp	st(1), st(0)
		faddp	st(1), st(0)		; projected.y = (-vector.y * factor + height/2)
		fstp	dword ptr [DI.Y]
		
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
; INPUT:	SI - Vector3 ptr, DI - PTR to resulting Vector2, angle (GLOBAL VAR)
; OUTPUT:	Outputs the rotated vector into the ptr provided in DI register
; DESTROYS:	None
rotate_x	proc
		push	es si di
		push	ds
		pop	es

		movsw		    ; can't use movsd since running in 16-bit mode
		movsw		    ; rotated.x = vector.x

		call	cache_trig

		fld	dword ptr [SI.Y]
		fld	dword ptr [cached_angle_cos]
		fmulp   st(1), st(0)			; st(0) - y * cos(angle)
		fld	dword ptr [SI.Z]
		fld	dword ptr [cached_angle_sin]
		fmulp	st(1), st(0)			
		fchs					; st(0) - -(z * sin(angle))
		faddp	st(1), st(0)			
		fstp	dword ptr [DI.Y]		; rotated.y = y * cos(angle) - z * sin(angle)

		fld	dword ptr [SI.Y]
		fld	dword ptr [cached_angle_sin]
		fmulp   st(1), st(0)			; st(0) - y * cos(angle)
		fld	dword ptr [SI.Z]
		fld	dword ptr [cached_angle_cos]
		fmulp	st(1), st(0)			
		faddp	st(1), st(0)			
		fstp	dword ptr [DI.Z]		; rotated.z = y * sin(angle) + z * cos(angle)

		pop	di si es
		ret
		endp


; ---------------------------------------
; Rotates Vector3 around Y axis by applying a rotation matrix
; INPUT:	SI - Vector3 ptr, DI - PTR to resulting Vector2, angle (GLOBAL VAR)
; OUTPUT:	Outputs the rotated vector into the ptr provided in DI register
; DESTROYS:	None
rotate_y	proc
		push	es si di
		push	ds
		pop	es
	   
		add	si, Y
		add	di, Y
		movsw		    ; can't use movsd since running in 16-bit mode
		movsw		    ; rotated.y = vector.y
		sub	si, Y
		sub	di, Y

		call	cache_trig

		fld	dword ptr [SI.X]
		fld	dword ptr [cached_angle_cos]
		fmulp   st(1), st(0)			; st(0) - y * cos(angle)
		fld	dword ptr [SI.Z]
		fld	dword ptr [cached_angle_sin]
		fmulp	st(1), st(0)			
		fchs					; st(0) - -(z * sin(angle))
		faddp	st(1), st(0)			
		fstp	dword ptr [DI.X]		; rotated.x = x * cos(angle) - z * sin(angle)

		fld	dword ptr [SI.Y]
		fld	dword ptr [cached_angle_sin]
		fmulp   st(1), st(0)			; st(0) - y * cos(angle)
		fld	dword ptr [SI.Z]
		fld	dword ptr [cached_angle_cos]
		fmulp	st(1), st(0)			
		faddp	st(1), st(0)			
		fstp	dword ptr [DI.Z]		; rotated.z = y * sin(angle) + z * cos(angle)

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
	heartFront	Vector3 VERTEX_CNT dup(?)
	heartBack	Vector3 VERTEX_CNT dup(?)

	factor		dd  ?
END Start

