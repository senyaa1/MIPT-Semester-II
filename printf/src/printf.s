global  myprintf 
extern  printf

WRITE           equ 1
STDOUT          equ 1
BUF_SZ          equ 1024
INT_CONVERT_SZ  equ 32

section .text 

; ---------------------------------------
; printf trampoline -> cdecl
myprintf:
                pop     r15             ; pop return addr from stack, so it won't clobber 7-th argument


                push    r9 
                push    r8 
                push    rcx 
                push    rdx 
                push    rsi 
                push    rdi 
                
                call    myprintf_cdecl

                pop     rdi 
                pop     rsi 
                pop     rdx 
                pop     rcx 
                pop     r8 
                pop     r9 

                push    r15
                ret


    
; ---------------------------------------
; Macro that breaks the jmp table case statement
%macro break 0
                add     r10, 8  ; arg++
                inc     rsi 
                jmp     .parse_loop
%endmacro

; ---------------------------------------
; Prints integer converted to specified base
; INPUT:	param 1 - num base
%macro  print_int_base 1
            mov     rcx, %1
            mov     rax, qword [r10]
            jmp     .int_write
%endmacro

; ---------------------------------------
; Macro that calls flush_buf if rdi >= buf_end.
; INPUT:	RDI (length)
%macro  maybe_flush 0 
            cmp     rdi, buf_end
            jb      %%skip_flush
            call    flush_buf
%%skip_flush:
%endmacro



; ---------------------------------------
; printf function, cdecl implementation
; INPUT:        fmt string and values on stack
; OUTPUT:       RAX - number of written chars, -1 if error 
; DESTROYS:     RBX RCX RDX RDI RSI R8 R9 R10 R12
myprintf_cdecl:
                push    rbp
                mov     rbp, rsp
                mov     rsi, [rbp + 16]     ; fmt str

                lea     r10, [rbp + 24]     ; arg 1
                mov     rdi, buf

                xor     r8, r8
                xor     r12, r12

.parse_loop:
                mov     r8b, [rsi]
                test    r8b, r8b  
                jz      .parse_loop_end
                cmp     r8b, '%'
                jne     .print_char

.parse_arg: 
                inc     rsi
                mov     r8b, [rsi]

                cmp     r8b, '%'
                je      .print_char
                cmp     r8b, 'b'
                jl      .invalid
                cmp     r8b, 'x'
                jg      .invalid
                sub     r8b, 'b'
                jmp     qword [printf_switch_table + 8 * r8]

.invalid:
                jmp     .error

.print_char:
                mov     byte [rdi], r8b
                inc     rdi
                inc     rsi
                inc     r12

                maybe_flush
                jmp     .parse_loop

.parse_loop_end:
                cmp     rdi, buf
                je      .skip_flush
                call    flush_buf
.skip_flush:
                mov     rax, r12
                jmp      .no_error  
.error:
                mov     rax, -1
.no_error:

                leave
                ret

.char:
                mov     r9, qword [r10]
                mov     byte [rdi], r9b
                inc     rdi
                inc     r12
                maybe_flush
                break


.str:
                mov     r9, qword [r10]

.str_loop:
                mov     al, byte [r9]
                test    al, al
                jz      .str_loop_end

                mov     byte [rdi], al
                inc     r9 
                inc     rdi
                inc     r12

                maybe_flush
                jmp     .str_loop
.str_loop_end:
                break


.int_write:
                push    rdi
                mov     rdi, int_convert_buf
                call    intToString
                pop     rdi

                mov     r9, int_convert_buf
                call    write_str
                break

.dec_int:                                 ; prepend minus if negative
                mov     r9, qword [r10]

                test    r9, r9
                jns     .positive

                not     r9 
                inc     r9
                mov     byte [rdi], '-'
                inc     rdi  
    .positive:
                mov     rcx, 10
                mov     rax, r9
                jmp     .int_write

.dec_uint:     print_int_base  10
.hex_int:      print_int_base  16
.oct_int:      print_int_base  8
.bin_int:      print_int_base  2


; ---------------------------------------
; slushes buf up to RDI
; INPUT:    RDI = the address up to which flush the buf
; OUTPUT:   buf written in stdout
; DESTROYS: RAX, RDX, RDI = buf, RSI
flush_buf:
                mov     rax, WRITE
                mov     rsi, buf

                mov     rdx, rdi
                sub     rdx, buf         ; rdx = buf size

                mov     rdi, STDOUT
                syscall

                mov     rdi, buf
                ret 

; ---------------------------------------
; Converts int to string 
; INPUT:    RAX - number    RCX - base  RDI - buf ptr
; OUTPUT:   RBX - string len
; DESTROYS: RAX, RBX, RDX, RDI, R9B 
intToString:
                mov     rbx, rdi
.convert_loop:
                xor     rdx, rdx
                div     rcx

                mov     r9b, [hex_alph + rdx]
                mov     byte [rbx], r9b

                inc     rbx
                test    rax, rax
                jnz     .convert_loop
.convert_loop_end:
                mov     byte [rbx], 0
                mov     rax, rdi            ; inversing result
                push    rbx

                dec     rbx
.str_loop_inverse:
                cmp     rdi, rbx
                jge     .str_loop_inverse_end

                mov     r9b, byte [rdi]
                xchg    byte [rbx], r9b 
                mov     byte [rdi], r9b

                inc     rdi
                dec     rbx 

                jmp     .str_loop_inverse

.str_loop_inverse_end:
                pop     rbx
                mov     rdi, rax
                sub     rbx, rdi

                ret 


; ---------------------------------------
; Copies buffers until null found
; INPUT:    R9 - str ptr, RDI - buf ptr
; DESTROYS: RAX RDX RDI RSI R9 R12
write_str:
.write_loop:
                mov     al, byte [r9]
                test    al, al
                jz      .loop_end

                mov     byte [rdi], al
                inc     r9 
                inc     rdi
                inc     r12

                maybe_flush
                jmp     .write_loop
.loop_end:
                ret


section .rodata 
    hex_alph                        db "0123456789abcdef"
    printf_switch_table:
                                    dq myprintf_cdecl.bin_int
                                    dq myprintf_cdecl.char
                                    dq myprintf_cdecl.dec_int
            times 'o' - 'd' - 1     dq myprintf_cdecl.invalid
                                    dq myprintf_cdecl.oct_int
            times 's' - 'o' - 1     dq myprintf_cdecl.invalid
                                    dq myprintf_cdecl.str
            times 'u' - 's' - 1     dq myprintf_cdecl.invalid
                                    dq myprintf_cdecl.dec_uint
            times 'x' - 'u' - 1     dq myprintf_cdecl.invalid
                                    dq myprintf_cdecl.hex_int

section .bss
    int_convert_buf     resb INT_CONVERT_SZ
    buf                 resb BUF_SZ
    buf_end:

