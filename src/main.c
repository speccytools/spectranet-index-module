#include "extern.h"
#include <strings.h>
#include <arch/zx/spectrum.h>
#include "records.h"
#include "text.h"
#include "version.h"

enum resolve_record_key_t {
    RESOLVE_KEY_TYPE = 0,
    RESOLVE_KEY_HOST,
    RESOLVE_KEY_TITLE,
    RESOLVE_KEY_TAGS,
    RESOLVE_KEY_INDEX,
    RESOLVE_KEY_TNFS,
    RESOLVE_KEY_VERSION,
    RESOLVE_KEY_UNKNOWN
};

#define RECORD_KEYS_MAX (RESOLVE_KEY_TAGS + 1)

static const char* KEYMAP[] = {
    "type", "host", "title", "tags", "index", "tnfs", "version", NULL
};

static uint8_t lookup_key(const char* key) __z88dk_fastcall
{
    for (uint8_t i = 0; KEYMAP[i]; i++)
    {
        if (strcmp(KEYMAP[i], key) == 0)
        {
            return i;
        }
    }

    return RESOLVE_KEY_UNKNOWN;
}

void resolve()
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

                const char* values[RECORD_KEYS_MAX];
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

                        enum resolve_record_key_t k = lookup_key(key);
                        values[k] = value;
                    }

                    sdata += len + 1;
                } while (semicolon);

                const char* tt = values[RESOLVE_KEY_TYPE];
                enum resolve_record_key_t ttv = lookup_key(tt);

                switch (ttv)
                {
                    case RESOLVE_KEY_INDEX:
                    {
                        add_index(values[RESOLVE_KEY_HOST]);
                        unresolved = 1;
                        break;
                    }
                    case RESOLVE_KEY_TNFS:
                    {
                        struct record_t* new_record = add_record(RECORD_TYPE_TNFS, values[RESOLVE_KEY_HOST]);
                        if (new_record)
                        {
                            new_record->title = _strdup(values[RESOLVE_KEY_TITLE]);
                            new_record->tags = _strdup(values[RESOLVE_KEY_TAGS]);
                        }
                        break;
                    }
                    case RESOLVE_KEY_VERSION:
                    {
                        if (strcmp(VERSION, values[RESOLVE_KEY_TITLE]))
                        {
                            strcpy(name_info.tnfs_update, values[RESOLVE_KEY_HOST]);
                        }
                        break;
                    }
                }

                data += txt_len + 1;
            }

            current_index->resolved = 1;
        }
    }
    while (unresolved);
}

void render()
{
    text_pagein();
    text_color = INK_GREEN | PAPER_BLACK | BRIGHT;
    text_ui_write(UI_XY(0, 0), "SPECTRANET INDEX");

    if (*name_info.tnfs_update)
    {
        text_color = INK_BLACK | PAPER_YELLOW | BRIGHT;
        text_ui_write(UI_XY(9, 0), "[U] MOD.UPD.AVAIL.");
    }

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
        text_ui_write(UI_XY(0, 23), "[N]ext page [P]rev page [S]earch");
    }

    {
        char records[16] = {0};
        strcpy(records, "R:");
        sitoa(records + 2, name_info.record_count);

        text_ui_write(UI_XY(24, 0), records);
    }

    if (name_info.page)
    {
        char pg[16] = {0};
        strcpy(pg, "Page: ");
        sitoa(pg + 6, name_info.page + 1);

        text_ui_write(UI_XY(19, 0), pg);
    }

    struct record_t** record = name_info.results;
    if (*record == NULL)
    {
        text_color = INK_RED | PAPER_BLACK | BRIGHT;
        text_ui_write(UI_XY(10, 11), "No (more) results");
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

uint8_t process_key(char key) __FASTCALL__
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
        case 'u':
        {
            if (*name_info.tnfs_update)
            {
                strcpy(name_info.tnfs_load, name_info.tnfs_update);
                return 0;
            }
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
