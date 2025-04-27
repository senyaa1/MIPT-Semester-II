#include <immintrin.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "hash_table.h"
#include "data.h"
#include "list.h"


#define AVX_WORD_SZ 32
const size_t HASH_TABLE_SZ = 1000;


__attribute__((always_inline)) inline static __m256i get_ymm_key(char *key, size_t len)
{
	char aligned_buf[32] = {};
	memcpy(aligned_buf, key, len % 32);
	__m256i key_ymm = _mm256_loadu_si256((__m256i const *)aligned_buf);
	return key_ymm;
}

__attribute__((always_inline)) static inline table_val_t *table_get_key_ymm(hash_table_t *table, __m256i key_ymm)
{
	size_t idx = hash_crc32(key_ymm) % table->size;
	list_t *bucket = &table->buckets[idx];
	list_elem_t *entry = list_begin(bucket);

	while (entry)
	{
		if (avx2_wmemcmp(entry->data.key, key_ymm))
			return &entry->data.val;
		entry = list_next(bucket, entry);
	}
	entry_t new_entry = {
		.key = key_ymm,
		.val = 0
	};

	list_insert_head(bucket, new_entry);

	return &list_begin(bucket)->data.val;
}

__attribute__((noinline)) table_val_t *table_get_key(hash_table_t *table, char *key, size_t len)
{
	__m256i key_ymm = get_ymm_key(key, len);
	return table_get_key_ymm(table, key_ymm);
}

//
// __attribute__((noinline)) void table_remove_key(hash_table_t *table, char *key, size_t len)
// {
// 	size_t idx = table->hash_function(key) % table->size;
// 	entry_t *entry = table->buckets[idx];
// 	entry_t *prev = 0;
//
// 	while (entry)
// 	{
// 		if (memcmp(entry->key, key, (len + 1) * sizeof(char)) == 0)
// 		{
// 			if (prev)
// 				prev->next = entry->next;
// 			else
// 				table->buckets[idx] = entry->next;
//
// 			free(entry);
// 			return;
// 		}
//
// 		prev = entry;
// 		entry = entry->next;
// 	}
// }
//
hash_table_t table_init(uint32_t sz)
{
	// hash_table_t table = {
	//     .size = sz, .hash_function = hash_crc32, .buckets = aligned_malloc(sz * sizeof(entry_t *))};
	hash_table_t table = {.size = sz, .buckets = calloc(sz, sizeof(list_t))};

	for (uint32_t i = 0; i < sz; i++)
		list_ctor(&table.buckets[i], 32);
	return table;
}

__attribute__((noinline)) hash_table_t build_table_from_text(char *text)
{
	hash_table_t table = table_init(HASH_TABLE_SZ);

	uint32_t len = strlen(text);

	char word[AVX_WORD_SZ] = {0};
	int cur_word_len = 0;

	for (uint32_t i = 0; i < len; i++)
	{
		if (text[i] == '\n')
		{
			// printf("%s\n", word);
			word[cur_word_len] = 0;
			(*table_get_key(&table, word, cur_word_len))++;

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
			total++;
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

	// for (size_t i = 0; i < to_print; i++)
	// 	printf("%2zu. %-*s : %u\n", i + 1, max_len, (char*)&arr[i]->key, arr[i]->val);

	free(arr);
}

float table_load_factor(hash_table_t *table)
{
	size_t total = 0;
	for (uint32_t i = 0; i < table->size; i++)
	{
		list_t *bucket = &table->buckets[i];

		for (entry_t *e = list_begin(bucket); e; e = list_next(bucket, e))
			total++;
	}

	return (float)total / table->size;
}
