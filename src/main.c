#include "extern.h"
#include <strings.h>
#include <arch/zx/spectrum.h>
#include <compress/zx7.h>
#include <stdlib.h>
#include "records.h"
#include "text.h"

enum resolve_record_key_t {
    RESOLVE_KEY_TYPE = 0,
    RESOLVE_KEY_HOST,
    RESOLVE_KEY_TITLE,
    RESOLVE_KEY_TAGS,
    RESOLVE_KEY_UNKNOWN,
    RESOLVE_KEY_MAX
};

static void resolve()
{
    uint8_t unresolved;

    do
    {
        unresolved = 0;

        for (uint8_t i = 0; i < name_info.indexes_count; i++)
        {
            struct record_index_t* current_index = &name_info.indexes[i];
            if (current_index->resolved)
            {
                continue;
            }

            char* ptr = resolve_txt_records(current_index->host);

            char* data = 0x1000;
            while (data < ptr)
            {
                uint8_t txt_len = strlen(data);
                char* sdata = data;

                const char* values[RESOLVE_KEY_MAX];
                memset(values, 0, sizeof(values));

                const char* semicolon;

                do
                {
                    semicolon = strchr(sdata, ';');

                    uint8_t len;
                    if (semicolon == NULL)
                    {
                        len = strlen(sdata);
                    }
                    else
                    {
                        len = semicolon - sdata;
                    }

                    char* equals = strnchr(sdata, len, '=');
                    if (equals)
                    {
                        const char* key = sdata;
                        *equals = 0;
                        const char* value = equals + 1;
                        *(char*)(sdata + len) = 0;

                        enum resolve_record_key_t k;

                        if (strcmp(key, "type") == 0)
                        {
                            k = RESOLVE_KEY_TYPE;
                        }
                        else if (strcmp(key, "title") == 0)
                        {
                            k = RESOLVE_KEY_TITLE;
                        }
                        else if (strcmp(key, "host") == 0)
                        {
                            k = RESOLVE_KEY_HOST;
                        }
                        else if (strcmp(key, "tags") == 0)
                        {
                            k = RESOLVE_KEY_TAGS;
                        }
                        else
                        {
                            k = RESOLVE_KEY_UNKNOWN;
                        }

                        values[k] = value;
                    }

                    sdata += len + 1;
                } while (semicolon);

                const char* tt = values[RESOLVE_KEY_TYPE];
                if (strcmp(tt, "index") == 0)
                {
                    add_index(values[RESOLVE_KEY_HOST]);
                    unresolved = 1;
                }
                else if (strcmp(tt, "tnfs") == 0)
                {
                    struct record_t* new_record = add_record(RECORD_TYPE_TNFS, values[RESOLVE_KEY_HOST]);
                    if (new_record)
                    {
                        new_record->title = _strdup(values[RESOLVE_KEY_TITLE]);
                        new_record->tags = _strdup(values[RESOLVE_KEY_TAGS]);
                    }
                }

                data += txt_len + 1;
            }

            current_index->resolved = 1;
        }
    }
    while (unresolved);
}

void clear()
{
#asm
    ld a, 0
    out (254), a
#endasm
    // clear screen
    memset(0x4000, 0, 6144);
    memset(0x5800, 0, 768);
}

static void render()
{
    clear();
    text_pagein();
    text_color = INK_GREEN | PAPER_BLACK | BRIGHT;
    text_ui_write(UI_XY(0, 0), "SPECTRANET INDEX");
    text_color = INK_WHITE | PAPER_BLACK;

    if (*name_info.search)
    {
        text_color = INK_YELLOW | PAPER_BLACK | BRIGHT;
        text_ui_write(UI_XY(0, 23), "QUERY:");
        text_color = INK_WHITE | PAPER_BLACK;
        text_ui_write(UI_XY(3, 23), name_info.search);
    }
    else
    {
        text_ui_write(UI_XY(0, 23), "[N]ext page [P]rev page [S]earch query");
    }


    {
        char records[16];
        strcpy(records, "Records: ");
        itoa(name_info.record_count, records + 9, 10);

        text_ui_write(UI_XY(24, 0), records);
    }

    if (name_info.page)
    {
        char pg[16];
        strcpy(pg, "Page: ");
        itoa(name_info.page + 1, pg + 6, 10);

        text_ui_write(UI_XY(18, 0), pg);
    }

    struct record_t** record = name_info.results;
    if (*record == NULL)
    {
        text_color = INK_RED | PAPER_BLACK | BRIGHT;
        text_ui_write(UI_XY(10, 11), "No (more) results found");
        return;
    }

    uint8_t y = 2;
    uint8_t index = 0;
    while (*record)
    {
        {
            char num[2];
            num[0] = '0' + index;
            num[1] = 0;
            text_color = INK_GREEN | PAPER_BLACK | BRIGHT;
            text_ui_write(UI_XY(0, y), num);
        }

        if ((*record)->tags)
        {
            text_color = INK_YELLOW | PAPER_BLACK;
            text_ui_write(UI_XY(16, y), (*record)->tags);
        }

        text_color = INK_WHITE | PAPER_BLACK | BRIGHT;
        text_ui_write(UI_XY(1, y++), (*record)->host);

        if ((*record)->title)
        {
            text_color = INK_WHITE | PAPER_BLACK;
            text_ui_write(UI_XY(1, y++), (*record)->title);
        }

        index++;
        record++;
    }
}

static void search_into(char* buffer) __FASTCALL__ __naked
{
#asm
    push hl
    call 0x3E30 ;// CLEAR42
    ld c, 32
    pop de
    call 0x3E6C ;// inputstring
#endasm
}

static uint8_t process_key(char key) __FASTCALL__
{
    switch (key)
    {
        case 'n':
        {
            name_info.offset += MAX_RESULTS;
            name_info.page++;
            break;
        }
        case 'p':
        {
            if (name_info.offset == 0)
            {
                return 1;
            }

            name_info.offset -= MAX_RESULTS;
            name_info.page--;
            break;
        }
        case 's':
        {
            *name_info.search = 0;
            search_into(name_info.search);

            break;
        }
    }

    if (key >= '0' && key <= '9')
    {
        uint8_t index = key - '0';
        if (name_info.results[index])
        {
            strcpy(name_info.tnfs_load, name_info.results[index]->host);
            return 0;
        }
    }

    return 1;
}

static uint8_t loop()
{
    search();
    render();

#asm
key_loop:
    call 0x3E66 ;// getkey
    or a
    jr z, key_loop
    ld h, 0
    ld l, a
    call _process_key
    ld l, a
    and a
    ret z
    call 0x3E69 ;// keyup
#endasm

    return 1;
}

void modulecall()
{
    records_init();
    add_index("index.speccytools.org");
    resolve();

    while (loop()) ;
}