#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <wchar.h>

#include "fs.h"
#include "hash_table.h"

const char* TEXT_PATH = "/home/senyaa/mipt/ded/hash_table/voyna_i_mir.txt";

int main(int argc, char **argv)
{
	setlocale(LC_CTYPE, "");

	// if (argc != 2)
	// {
	// 	fprintf(stderr, "Usage: ./hash_table [path to text]\n");
	// 	return -1;
	// }
	//
	wchar_t *text = read_file(TEXT_PATH);
	if (!text)
	{
		fprintf(stderr, "Unable to read text file!\n");
		return -1;
	}

	hash_table_t table = build_table_from_text(text);

	printf("load factor: %g\n", table_load_factor(&table));

	for(size_t i = 0; i < 10000; i++)
	{
		table_get_key(&table, L"asdasd");
	}

	table_print_top(&table, 10);

	table_free(&table);

	free(text);
	return 0;
}
