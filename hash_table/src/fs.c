#include <fcntl.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#include "fs.h"

wchar_t *read_file(const char *filename)
{
	FILE *file = fopen(filename, "r");
	if (!file)
		return 0;

	fseek(file, 0, SEEK_END);

	size_t size = ftell(file);
	rewind(file);

	char *buffer = calloc(size + 1, sizeof(char));
	if (!buffer)
	{
		fclose(file);
		return 0;
	}

	size_t bytes_read = fread(buffer, 1, size, file);
	buffer[bytes_read] = '\0';

	size_t wc_size = mbstowcs(NULL, buffer, 0);

	wchar_t *wstr = calloc((wc_size + 1), sizeof(wchar_t));
	if (!wstr)
	{
		free(buffer);
		fclose(file);
		return 0;
	}

	mbstowcs(wstr, buffer, wc_size + 1);

	free(buffer);
	fclose(file);

	return wstr;
}
