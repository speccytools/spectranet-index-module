#include "extern.h"
#include <strings.h>
#include "records.h"

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

            char* data = 0x1000;
            char* ptr = resolve_txt_records(current_index->host);

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

void modulecall()
{
    records_init();
    add_index("index.speccytools.org");
    resolve();

    struct record_t* record = name_info.first_record;
    while (record)
    {
        print42("HOST ");
        print42(record->host);
        print42("TITLE ");
        print42(record->title);
        print42("\n");
        record = record->next;
    }
}