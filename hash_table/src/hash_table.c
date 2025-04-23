#include <assert.h>
#include <immintrin.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

#include "hash_table.h"

extern uint32_t crc32_hw(uint32_t crc, const void *buf, size_t len);

uint32_t crc32(const void *data, size_t len)
{
	return crc32_hw(0xFFFFFFFF, data, len) ^ 0xFFFFFFFF;
}


const size_t HASH_TABLE_SZ = 5000;

__attribute__((noinline)) static size_t hash_crc32(wchar_t *str)
{
	return (size_t)crc32(str, wcslen(str));
}

__attribute__((noinline)) static void recursively_free(entry_t *entry)
{
	if (!entry)
		return;

	recursively_free(entry->next);
	free(entry);
}


__attribute__((noinline)) table_val_t *table_insert_key(hash_table_t *table, wchar_t *key, size_t len)
{
	size_t idx = table->hash_function(key) % table->size;
	entry_t *head = table->buckets[idx];

	entry_t *entry = head;
	while (entry)
	{
		// update existing
		if(memcmp(entry->key, key, (len + 1) * sizeof(wchar_t)) == 0)
		{
			return &entry->val;
		}

		entry = entry->next;
	}

	// not found, create new entry
	entry_t *new_entry = calloc(1, sizeof(entry_t));
	memcpy(new_entry->key, key, 32 * sizeof(wchar_t));
	new_entry->next = head;
	table->buckets[idx] = new_entry;
	return &new_entry->val;
}


__attribute__((noinline)) table_val_t *table_get_key(hash_table_t *table, wchar_t *key, size_t len)
{
	size_t idx = table->hash_function(key) % table->size;
	entry_t *entry = table->buckets[idx];

	while (entry)
	{
		if(memcmp(entry->key, key, (len + 1) * sizeof(wchar_t)) == 0)
			return &entry->val;

		entry = entry->next;
	}
	return 0;
}


__attribute__((noinline)) void table_remove_key(hash_table_t *table, wchar_t *key, size_t len)
{
	size_t idx = table->hash_function(key) % table->size;
	entry_t *entry = table->buckets[idx];
	entry_t *prev = 0;

	while (entry)
	{
		if(memcmp(entry->key, key, (len + 1) * sizeof(wchar_t)) == 0)
		{
			if (prev)
				prev->next = entry->next;
			else
				table->buckets[idx] = entry->next;

			free(entry->key);
			free(entry);
			return;
		}

		prev = entry;
		entry = entry->next;
	}
}

hash_table_t table_init(size_t sz)
{
	hash_table_t table = {.buckets = calloc(sz, sizeof(entry_t *)), .hash_function = hash_crc32, .size = sz};
	return table;
}

static int max_len = 0;
__attribute__((noinline)) hash_table_t build_table_from_text(wchar_t *text)
{
	hash_table_t table = table_init(HASH_TABLE_SZ);

	size_t len = wcslen(text);


	wchar_t word[32] = {0};
	int cur_word_len = 0;

	for (size_t i = 0; i < len; i++)
	{
		if (text[i] == L' ')
		{
			word[cur_word_len] = 0;
			(*table_insert_key(&table, word, cur_word_len))++;

			if (cur_word_len > max_len)
				max_len = cur_word_len;
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
	for (size_t i = 0; i < table->size; i++)
		recursively_free(table->buckets[i]);
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
	for (size_t i = 0; i < table->size; i++)
	{
		for (entry_t *e = table->buckets[i]; e; e = e->next)
			total++;
	}

	if (total == 0)
		return;

	entry_t **arr = calloc(total, sizeof(entry_t *));
	size_t idx = 0;
	for (size_t i = 0; i < table->size; i++)
	{
		for (entry_t *e = table->buckets[i]; e; e = e->next)
			arr[idx++] = e;
	}

	qsort(arr, total, sizeof(entry_t *), cmp_entry_val_desc);

	size_t to_print = top_n < total ? top_n : total;
	wprintf(L"Top %zu words:\n", to_print);
	for (size_t i = 0; i < to_print; i++)
		wprintf(L"%2zu. %-*ls : %llu\n", i + 1, max_len, arr[i]->key, (unsigned long long)arr[i]->val);

	free(arr);
}

float table_load_factor(hash_table_t *table)
{
	size_t total = 0;
	for (size_t i = 0; i < table->size; i++)
	{
		for (entry_t *e = table->buckets[i]; e; e = e->next)
			total++;
	}

	return (float)total / table->size;
}
