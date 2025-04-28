#include <locale.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <wchar.h>

#include "fs.h"
#include "hash_table.h"

const char* TEXT_PATH = "/home/senyaa/ded/MIPT-Semester-II/hash_table/voyna_i_mir.txt";

int main(int argc, char **argv)
{
	setlocale(LC_CTYPE, "");

	// if (argc != 2)
	// {
	// 	fprintf(stderr, "Usage: ./hash_table [path to text]\n");
	// 	return -1;
	// }
	//
	char *text = 0;
	if (!read_file(TEXT_PATH, &text))
	{
		fprintf(stderr, "Unable to read text file!\n");
		return -1;
	}

	hash_table_t table = build_table_from_text(text);

	for(size_t i = 0; i < 50000000; i++)
	{
		table_get_key(&table, "asdasd", 5);
	}

	// table_print_top(&table, 10);

	table_free(&table);

	free(text);
	return 0;
}
