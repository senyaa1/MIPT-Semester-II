PSP_CMDLINE_LEN_OFFSET	equ	80h
PSP_CMDLINE_OFFSET	equ	81h
GFX_MEM_SEGMENT		equ	00b800h 
GFX_MODE		equ	3h
GFX_WIDTH		equ	80d
GFX_HEIGHT		equ	25d
EXPANSION_DELAY		equ	04444h

FRAME_SETTINGS STRUC
	FR_SELECTED_STYLE	db 2
	FR_START_X		db 20
	FR_START_Y		db 6
	FR_WIDTH		db 21
	FR_HEIGHT		db 11
	FR_DYNAMIC		db 1
	FR_STR_LEN		db 0
	FR_STR			db 128d dup(?)
FRAME_SETTINGS ENDS


FRAME_STYLE STRUC
	ST_COLOR		db 0ch
	ST_CHARMAP		db 9 dup(?)
FRAME_STYLE ENDS

global	show_frame:proc
global	restore_buf:proc
global	save_buf:proc
