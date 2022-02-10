#include "text.h"
#include <arch/zx/spectrum.h>
#include <string.h>

extern void text_ui_write(const char* buf, uint16_t buflen) __CALLEE__;

void text_ui_write_at(uint8_t x, uint8_t y, const char* buf, uint8_t buflen) __CALLEE__
{
    text_x = x;
    text_y = y;
    text_ui_write(buf, buflen);

    uint8_t* c = zx_cxy2aaddr(x, y);
    memset(c, text_color, (buflen >> 1) + (buflen & 0x01));
}