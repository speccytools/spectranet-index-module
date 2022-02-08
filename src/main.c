#include "extern.h"
#include <spectranet.h>
#include <strings.h>


int main()
{
    char* data = 0x1000;
    char* ptr = resolve_txt_records("index.speccytools.org");
    while (data < ptr)
    {
        print42(data);
        print42("\n");
        data += strlen(data) + 1;
    }
}