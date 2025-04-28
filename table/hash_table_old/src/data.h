#pragma once

#include <immintrin.h>
#include <stdint.h>

typedef struct entry entry_t;
typedef uint32_t table_val_t;
typedef entry_t list_data_t;

struct entry
{
	char* key;
	table_val_t val;
};
