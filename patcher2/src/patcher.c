#include <stdlib.h>

#include "fs.h"

static size_t JNE_OFFSET = 0x28;
static char JNE = 0x75;
static char JE = 0x74;

// password for parol2: "r pEnte"

int patch(const char* filename)
{
	size_t size = 0;
	char* file_buf = read_file(filename, &size);
	if(!file_buf)
		return 1;
	if(file_buf[JNE_OFFSET] != JNE)	// already patched
		return 1;

	file_buf[JNE_OFFSET] = JE;	// invert branch

	write_file(filename, file_buf, size);
	return 0;
}


