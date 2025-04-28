#include <immintrin.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "data.h"
#include "hash_table.h"
#include "list.h"

#define PREFETCH
#define BRANCH_HINTS

#ifdef BRANCH_HINTS

#define likely(x) __builtin_expect(!!(x), 1)
#define unlikely(x) __builtin_expect(!!(x), 0)

#else

#define likely(x) (x)
#define unlikely(x) (x)

#endif

static const size_t HASH_TABLE_SZ = 4096;

__attribute__((hot)) __attribute__((always_inline)) inline static int avx2_wmemcmp(__m256i a, __m256i b)
{
	unsigned int mask;
	__asm__ volatile("vpcmpeqb %[b], %[a], %%ymm0\n\t"
			 "vpmovmskb %%ymm0, %[mask]\n\t"
			 : [mask] "=r"(mask)
			 : [a] "x"(a), [b] "x"(b)
			 : "ymm0");

	return unlikely(mask == 0xFFFFFFFFu);
}

__attribute__((hot)) __attribute__((always_inline)) inline static __m256i get_ymm_key(char *key, size_t len)
{
	__attribute__((aligned(32))) char aligned_buf[AVX_WORD_SZ] = {};
	memcpy(aligned_buf, key, len % AVX_WORD_SZ);

	__m256i key_ymm = _mm256_load_si256((__m256i const *)aligned_buf);
	return key_ymm;
}

__attribute__((always_inline)) inline static table_val_t *table_get_key_ymm(hash_table_t *table, __m256i key_ymm)
{
	size_t idx = hash_crc32(key_ymm) & (table->size - 1);
#ifdef PREFETCH
	__builtin_prefetch(&table->buckets[idx], 0, 3);
#endif

	list_t *bucket = &table->buckets[idx];
	list_elem_t *entry = list_begin(bucket);

#ifdef BRANCH_HINTS
	if (unlikely(!entry))
	{
		entry_t new_entry = {.key = key_ymm, .val = 0};
		list_insert_head(bucket, new_entry);
		return &list_begin(bucket)->data.val;
	}
#endif

	while (likely(entry))
	{
		list_elem_t *next = list_next(bucket, entry);
#ifdef PREFETCH
		__builtin_prefetch(next, 0, 1);
#endif

		if (unlikely(avx2_wmemcmp(entry->data.key, key_ymm)))
			return &entry->data.val;

		entry = next;
	}

	entry_t new_entry = {.key = key_ymm, .val = 0};

	list_insert_head(bucket, new_entry);

	return &list_begin(bucket)->data.val;
}

__attribute__((noinline)) table_val_t *table_get_key(hash_table_t *table, char *key, size_t len)
{
	__m256i key_ymm = get_ymm_key(key, len);
	return table_get_key_ymm(table, key_ymm);
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

	char word[AVX_WORD_SZ] = {0};
	int cur_word_len = 0;

	for (uint32_t i = 0; i < len; i++)
	{
		if (text[i] == '\n')
		{
			word[cur_word_len] = 0;
			table_val_t *cnt = table_get_key(&table, word, cur_word_len);
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

	for (size_t i = 1; i < to_print; i++)
		printf("%2zu. %-*s : %u\n", i + 1, 32, (char *)&arr[i]->key, arr[i]->val);

	free(arr);
}
