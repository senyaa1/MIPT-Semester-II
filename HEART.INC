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
DELAY		equ 2000h

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

global	draw_heart:proc
