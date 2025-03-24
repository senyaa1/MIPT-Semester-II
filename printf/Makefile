# CC=gcc
# CFLAGS=-D _DEBUG -Wall

CC=gcc
LDFLAGS=
AS=nasm
ASFLAGS=-f elf64
CFLAGS=-D _DEBUG -ffast-math -ggdb3 -no-pie
# CFLAGS=-D _DEBUG -ffast-math -ggdb3 -std=c++17 -O0 -Wall -Wextra -Weffc++ -Waggressive-loop-optimizations -Wc++14-compat -Wmissing-declarations -Wcast-align -Wchar-subscripts -Wconditionally-supported -Wconversion -Wctor-dtor-privacy -Wempty-body -Wfloat-equal -Wformat-nonliteral -Wformat-security -Wformat-signedness -Wformat=2 -Winline -Wlogical-op -Wnon-virtual-dtor -Wopenmp-simd -Woverloaded-virtual -Wpacked -Wpointer-arith -Winit-self -Wredundant-decls -Wshadow -Wstrict-null-sentinel -Wstrict-overflow=2 -Wsuggest-attribute=noreturn -Wsuggest-final-methods -Wsuggest-final-types -Wsuggest-override -Wswitch-default -Wswitch-enum -Wsync-nand -Wundef -Wunreachable-code -Wunused -Wuseless-cast -Wvariadic-macros -Wno-literal-suffix -Wno-missing-field-initializers -Wno-narrowing -Wno-old-style-cast -Wno-varargs -Wstack-protector -fcheck-new -fsized-deallocation -fstack-protector -fstrict-overflow -flto-odr-type-merging -fno-omit-frame-pointer -Wlarger-than=8192 -Wstack-usage=8192 -pie -fPIE -Werror=vla -fsanitize=address,alignment,bool,bounds,enum,float-cast-overflow,float-divide-by-zero,integer-divide-by-zero,leak,nonnull-attribute,null,object-size,return,returns-nonnull-attribute,shift,signed-integer-overflow,undefined,unreachable,vla-bound,vptr

NAME=printf
SRCDIR=src
OUTDIR=bin

${OUTDIR}/${NAME}: ${OUTDIR}/printf.o ${OUTDIR}/main.o
	${CC} ${CFLAGS} $^ -o $@

${OUTDIR}/main.o: ${SRCDIR}/main.c 
	${CC} -c -o $@ $^ ${LDFLAGS} ${CFLAGS}

${OUTDIR}/printf.o: ${SRCDIR}/printf.s
	${AS} ${ASFLAGS} $^ -o $@

main: ${OUTDIR}/${NAME}

prepare:
	mkdir -p ${OUTDIR} 

clean:
	rm -rf ${OUTDIR}/*

all: prepare clean main

.PHONY: all

