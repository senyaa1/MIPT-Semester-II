#define _GNU_SOURCE
#include <locale.h>
#include <pthread.h>
#include <sched.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "fs.h"
#include "hash_table.h"

const char *TEXT_PATH = "voyna_i_mir.txt";

void run_test(char *text)
{
	hash_table_t table = build_table_from_text(text);

	for (size_t i = 0; i < 50000000; i++)
	{
		table_get_key(&table, "asdasd");
	}

	// table_print_top(&table, 10);

	table_free(&table);
}

int main(int argc, char **argv)
{
	setlocale(LC_CTYPE, "");

	char *text = 0;
	if (!read_file(TEXT_PATH, &text))
	{
		fprintf(stderr, "Unable to read text file!\n");
		return -1;
	}

	run_test(text);
	free(text);
	return 0;
}
