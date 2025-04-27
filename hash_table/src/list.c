#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include "hash_table.h"
#include "list.h"


static list_status_t list_increase_alloc(list_t *list)
{
	list_elem_t *new_alloc = (list_elem_t *)realloc(list->elements, list->size * 2 * sizeof(list_elem_t));

	if (!new_alloc)
		return LIST_ERR_ALLOC;

	list->elements = new_alloc;
	list->size *= 2;

	return LIST_OK;
}



static list_status_t list_maybe_increase_alloc(list_t *list)
{
	if (list->cnt < list->size - 1)
		return LIST_OK;

	return list_increase_alloc(list);
}


list_status_t list_ctor(list_t *list, size_t initial_size)
{
	if (!list)
		return LIST_ERR_ARGNULL;
	if (list->elements)
		return LIST_ERR_ALLOC;

	list->size = initial_size;
	list->elements = (list_elem_t *)calloc(list->size + 1, sizeof(list_elem_t));
	list->cnt = 0;

	for (int i = 1; i < initial_size; i++)
	{
		list->elements[i].next = i + 1;
		list->elements[i].prev = 0;
	}

	list->elements[0].next = 0;
	list->elements[0].prev = 0;
	list->elements[0].used = 1;
	list->free = 1;

	return LIST_OK;
}

list_status_t list_dtor(list_t *list)
{
	if (!list)
		return LIST_ERR_ARGNULL;

	free(list->elements);
	memset(list, 0, sizeof(list_t));

	return LIST_OK;
}

list_elem_t *list_next(list_t *list, list_elem_t *elem)
{
	if (elem->next == 0)
		return 0;

	return &list->elements[elem->next];
}

list_elem_t *list_prev(list_t *list, list_elem_t *elem)
{
	if (elem->prev == 0)
		return 0;

	return &list->elements[elem->prev];
}

list_elem_t *list_begin(list_t *list)
{
	return &list->elements[list->elements[0].next];
}

list_elem_t *list_end(list_t *list)
{
	return &list->elements[list->elements[0].prev];
}

list_status_t list_insert_before(list_t *list, int index, list_data_t data)
{
	if (list_maybe_increase_alloc(list))
		return LIST_ERR_ALLOC;

	int insertion_index = list->free;
	list->free = list->elements[insertion_index].next;

	list_elem_t *elem = &list->elements[insertion_index];

	elem->data = data;
	elem->used = true;

	list_elem_t *next = &list->elements[index];
	list_elem_t *prev = &list->elements[next->prev];

	elem->next = index;
	elem->prev = next->prev;

	next->prev = insertion_index;
	prev->next = insertion_index;

	list->cnt++;

	return LIST_OK;
}


list_status_t list_remove_at(list_t *list, int index)
{
	list_elem_t *elem = &list->elements[index];

	list->elements[elem->prev].next = elem->next;
	list->elements[elem->next].prev = elem->prev;

	memset(elem, 0, sizeof(list_elem_t));

	elem->next = list->free;
	list->free = index;

	list->cnt--;

	return LIST_OK;
}

list_status_t list_insert_after(list_t *list, int index, list_data_t data)
{
	return list_insert_before(list, list->elements[index].next, data);
}

list_status_t list_insert_head(list_t *list, list_data_t data)
{
	return list_insert_before(list, list->elements[0].next, data);
}

list_status_t list_insert_tail(list_t *list, list_data_t data)
{
	return list_insert_after(list, list->elements[0].prev, data);
}

list_status_t list_remove_head(list_t *list)
{
	return list_remove_at(list, list->elements[0].next);
}

list_status_t list_remove_tail(list_t *list)
{
	return list_remove_at(list, list->elements[0].prev);
}

int list_find_val(list_t *list, list_data_t val)
{
	int counter = 0;
	int cur = list->elements[0].next, end = list->elements[0].prev;

	while (cur != end)
	{
		cur = list->elements[cur].next;
		if (memcmp(&list->elements[cur].data, &val, sizeof(list_data_t)) == 0)
			return cur;
	}

	return -1;
}

int list_index(list_t *list, int index)
{
	int counter = 0, elem = list->elements[0].next;

	while (elem != list->elements[0].prev)
	{
		counter++;
		if (counter == index)
			return counter;
	}

	return -1;
}
