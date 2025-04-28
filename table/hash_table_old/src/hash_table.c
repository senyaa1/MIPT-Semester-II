#include <immintrin.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "data.h"
#include "hash_table.h"
#include "list.h"
#include "crc32.h"

static const size_t HASH_TABLE_SZ = 5000;

__attribute__((noinline)) table_val_t *table_get_key(hash_table_t *table, char *key)
{
	char word[512] = { 0 };
	memcpy(word, key, strlen(key));

	size_t idx = hash_crc32(word) % table->size;

	list_t *bucket = &table->buckets[idx];
	list_elem_t *entry = list_begin(bucket);

	while (entry)
	{
		list_elem_t *next = list_next(bucket, entry);
		if (entry->data.key && (strcmp(entry->data.key, word) == 0))
			return &entry->data.val;

		entry = next;
	}

	entry_t new_entry = {.key = strdup(word), .val = 0};

	list_insert_head(bucket, new_entry);

	return &list_begin(bucket)->data.val;
}

hash_table_t table_init(uint32_t sz)
{
	hash_table_t table = {.size = sz, .buckets = calloc(sz, sizeof(list_t))};

	for (uint32_t i = 0; i < sz; i++)
		list_ctor(&table.buckets[i], 32);

	return table;
}

__attribute__((noinline)) hash_table_t build_table_from_text(char *text)
{
	hash_table_t table = table_init(HASH_TABLE_SZ);

	uint32_t len = strlen(text);

	char word[32] = {0};
	int cur_word_len = 0;

	for (uint32_t i = 0; i < len; i++)
	{
		if (text[i] == '\n')
		{
			word[cur_word_len] = 0;
			table_val_t *cnt = table_get_key(&table, word);
			(*cnt)++;

			cur_word_len = 0;
			continue;
		}

		word[cur_word_len++] = text[i];
	}

	word[cur_word_len] = 0;

	return table;
}

__attribute__((noinline)) void table_free(hash_table_t *table)
{
	for (uint32_t i = 0; i < table->size; i++)
		list_dtor(&table->buckets[i]);
	free(table->buckets);
}


static int cmp_entry_val_desc(const void *a, const void *b)
{
	const entry_t *ea = *(const entry_t *const *)a;
	const entry_t *eb = *(const entry_t *const *)b;

	return (eb->val - ea->val);
}

__attribute__((noinline)) void table_print_top(hash_table_t *table, size_t top_n)
{
	size_t total = 0;
	for (uint32_t i = 0; i < table->size; i++)
	{
		list_t *bucket = &table->buckets[i];

		for (entry_t *e = list_begin(bucket); e; e = list_next(bucket, e))
		{
			total++;
		}
	}

	if (total == 0)
		return;

	entry_t **arr = calloc(total, sizeof(entry_t *));
	size_t idx = 0;
	for (size_t i = 0; i < table->size; i++)
	{
		list_t *bucket = &table->buckets[i];

		for (entry_t *e = list_begin(bucket); e; e = list_next(bucket, e))
			arr[idx++] = e;
	}

	qsort(arr, total, sizeof(entry_t *), cmp_entry_val_desc);

	size_t to_print = top_n < total ? top_n : total;
	printf("Top %zu words:\n", to_print);

	for (size_t i = 0; i < to_print; i++)
		printf("%2zu. %-*s : %u\n", i + 1, 32, (char *)arr[i]->key, arr[i]->val);

	free(arr);
}
