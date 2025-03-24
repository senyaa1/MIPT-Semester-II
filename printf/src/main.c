#include <stdio.h>

extern int myprintf(const char* fmt, ...);

int main()
{
	int res = printf("printing from c %d %x %o %b\n", 15, 15, 15, 15);
	int res2 = myprintf("printing from asm %d %x %o %b\n", 15, 15, 15, 7);

	printf("test fmt %%c: %c\t%%d: %d\t%%o: %o\t%%s: %s\t%%x: %x\t%%b: %b\t%%: %%\n", 'c', 123, 123, "real", 255, 7);
	myprintf("test fmt %%c: %c\t%%d: %d\t%%o: %o\t%%s: %s\t%%x: %x\t%%b: %b\t%%: %%\n", 'c', 123, 123, "real", 255, 7);

	myprintf("%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n", 10,  10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10);

	return 0;
}

