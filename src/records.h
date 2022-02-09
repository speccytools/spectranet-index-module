#ifndef NAME_INFO_H
#define NAME_INFO_H

#include <stdint.h>

#define MAX_INDEXES (8)
#define FREE_MEM_BUFFER_SIZE (16384)

enum record_type_t
{
    RECORD_TYPE_TNFS = 0
};

struct record_index_t
{
    char host[64];
    uint8_t resolved;
};

struct record_t
{
    enum record_type_t type;
    const char* host;
    const char* title;
    const char* tags;
    struct record_t* next;
};

struct name_info_t
{
    uint8_t* free_mem;
    uint16_t free_mem_remaining;
    struct record_index_t indexes[MAX_INDEXES];
    uint8_t indexes_count;
    struct record_t* first_record;
    struct record_t* last_record;
    uint8_t mem[FREE_MEM_BUFFER_SIZE];
};

extern struct name_info_t name_info;

extern char* _strdup(const char* from) __FASTCALL__;

extern void records_init();
extern void add_index(const char* host) __FASTCALL__;
extern struct record_t* find_record(const char* host) __FASTCALL__;
extern struct record_t* add_record(enum record_type_t type, const char* host) __CALLEE__;

#endif