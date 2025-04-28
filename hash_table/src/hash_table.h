#pragma once

#include <immintrin.h>
#include <stdbool.h>
#include <stdint.h>

#include "data.h"
#include "list.h"
#include "crc32.h"

#define AVX_WORD_SZ 32

typedef struct hash_table
{
	list_t *buckets;
	uint32_t size;
	// uint32_t (*hash_function)(__m256i);
} hash_table_t;

hash_table_t table_init(uint32_t sz);
hash_table_t build_table_from_text(char *text);
void table_free(hash_table_t *table);
void table_print_top(hash_table_t *table, size_t top_n);
table_val_t *table_get_key(hash_table_t *table, char *key, size_t len);
void table_remove_key(hash_table_t *table, char *key);
