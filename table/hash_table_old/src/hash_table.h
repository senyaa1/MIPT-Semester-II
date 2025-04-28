#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "crc32.h"
#include "data.h"
#include "list.h"

typedef struct hash_table
{
	list_t *buckets;
	uint32_t size;
} hash_table_t;

hash_table_t table_init(uint32_t sz);
hash_table_t build_table_from_text(char *text);
void table_free(hash_table_t *table);
table_val_t *table_get_key(hash_table_t *table, char *key);
