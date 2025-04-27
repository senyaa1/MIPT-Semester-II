#pragma once

#include <immintrin.h>
#include <stdbool.h>
#include <stdint.h>

#include "data.h"
#include "list.h"

typedef struct hash_table
{
	list_t *buckets;
	uint32_t size;
	// uint32_t (*hash_function)(__m256i);
} hash_table_t;

__attribute__((always_inline)) inline static int avx2_wmemcmp(__m256i a, __m256i b)
{
	__m256i cmp = _mm256_cmpeq_epi8(a, b);

	if (_mm256_movemask_epi8(cmp) != -1)
		return 0;
	return 1;
}

extern uint32_t hash_crc32(__m256i key);

hash_table_t table_init(uint32_t sz);
hash_table_t build_table_from_text(char *text);
void table_free(hash_table_t *table);
void table_print_top(hash_table_t *table, size_t top_n);
float table_load_factor(hash_table_t *table);
table_val_t *table_get_key(hash_table_t *table, char *key, size_t len);
void table_remove_key(hash_table_t *table, char *key);
