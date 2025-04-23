#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char* read_file(const char* filename, size_t* fileSize) 
{

	FILE* fileptr = fopen(filename, "rb");
	if (fileptr == NULL) 
		return NULL;

	fseek(fileptr, 0, SEEK_END);
	*fileSize = ftell(fileptr);
	rewind(fileptr);

	char* buffer = (char*)calloc(*fileSize, sizeof(char));

	if (buffer == NULL) 
	{
		fclose(fileptr);
		return NULL;
	}

	size_t result = fread(buffer, 1, *fileSize, fileptr);

	if (result != *fileSize) 
	{
		free(buffer);
		fclose(fileptr);
		return NULL;
	}

	fclose(fileptr);
	return buffer;
}

int write_file(const char* filename, const char* buffer, size_t fileSize) 
{
	FILE* fileptr;

	fileptr = fopen(filename, "wb");
	if (fileptr == NULL) {
		return 0;
	}

	size_t result = fwrite(buffer, 1, fileSize, fileptr);

	int success = (result == fileSize);
	fclose(fileptr);
	return success;
}

