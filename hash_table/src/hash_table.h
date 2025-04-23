#pragma once

#include <immintrin.h>
#include <stdbool.h>
#include <stdint.h>
#include <wchar.h>

typedef struct entry entry_t;

typedef int32_t table_val_t;

struct entry
{
	wchar_t *key;
	table_val_t val;
	entry_t *next;
};

typedef struct hash_table
{
	entry_t **buckets;
	size_t size;
	size_t (*hash_function)(wchar_t *);
} hash_table_t;

table_val_t *table_insert_key(hash_table_t *table, wchar_t *key);
table_val_t *table_get_key(hash_table_t *table, wchar_t *key);
void table_remove_key(hash_table_t *table, wchar_t *key);
hash_table_t table_init(size_t sz);
hash_table_t build_table_from_text(wchar_t *text);
void table_free(hash_table_t *table);
void table_print_top(hash_table_t *table, size_t top_n);
float table_load_factor(hash_table_t *table);
