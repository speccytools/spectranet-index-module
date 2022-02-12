#include "records.h"
#include <string.h>

void records_init()
{
    *name_info.search = 0;
    name_info.offset = 0;
    name_info.page = 0;
    name_info.record_count = 0;
    name_info.free_mem = name_info.mem;
    name_info.free_mem_remaining = FREE_MEM_BUFFER_SIZE;
    name_info.indexes_count = 0;
    name_info.first_record = NULL;
    name_info.last_record = NULL;
}

void search()
{
    memset(name_info.results, 0, sizeof(name_info.results));

    struct record_t** next_result = name_info.results;
    uint8_t results_found = MAX_RESULTS;
    uint8_t skip = name_info.offset;

    struct record_t* record = name_info.first_record;
    while (record)
    {
        if (*name_info.search)
        {
            if (strstr(record->host, name_info.search))
            {
                goto found;
            }

            if (record->title && strstr(record->title, name_info.search))
            {
                goto found;
            }

            if (record->tags && strstr(record->tags, name_info.search))
            {
                goto found;
            }

            goto skip;
        }

found:
        if (skip == 0)
        {
            *next_result++ = record;
            results_found--;
            if (results_found == 0)
            {
                break;
            }
        }
        else
        {
            skip--;
        }
skip:
        record = record->next;
    }
}

static void* _alloc(uint8_t size) __FASTCALL__
{
    if (size > name_info.free_mem_remaining)
    {
        return 0;
    }

    void* result = (void*)name_info.free_mem;
    name_info.free_mem += size;
    name_info.free_mem_remaining -= size;

    return result;
}

char* _strdup(const char* from) __FASTCALL__
{
    if (from == NULL)
    {
        return NULL;
    }
    char* res = _alloc(strlen(from) + 1);
    if (res == NULL)
    {
        return NULL;
    }
    strcpy(res, from);
    return res;
}

void add_index(const char* host) __FASTCALL__
{
    if (host == NULL)
    {
        return;
    }

    for (uint8_t i = 0; i < name_info.indexes_count; i++)
    {
        if (strcmp(name_info.indexes[i].host, host) == 0)
        {
            // we already have such index
            return;
        }
    }

    if (name_info.indexes_count >= MAX_INDEXES)
    {
        return;
    }

    struct record_index_t* i = &name_info.indexes[name_info.indexes_count++];
    i->resolved = 0;
    strcpy(i->host, host);
}

struct record_t* find_record(const char* host) __FASTCALL__
{
    struct record_t* record = name_info.first_record;

    while (record)
    {
        if (strcmp(record->host, host) == 0)
        {
            return record;
        }

        record = record->next;
    }

    return NULL;
}

struct record_t* add_record(enum record_type_t type, const char* host) __CALLEE__
{
    if (host == NULL)
    {
        return NULL;
    }

    struct record_t* record = find_record(host);

    if (record != NULL)
    {
        record->type = type;
        return record;
    }

    record = (struct record_t*)_alloc(sizeof(struct record_t));
    if (record == NULL)
    {
        return NULL;
    }

    name_info.record_count++;
    record->type = type;
    record->host = _strdup(host);
    record->title = NULL;
    record->tags = NULL;
    record->next = NULL;

    if (name_info.last_record == NULL)
    {
        name_info.first_record = record;
    }
    else
    {
        name_info.last_record->next = record;
    }


    name_info.last_record = record;

    return record;
}