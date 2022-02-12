#ifndef TEXT_H
#define TEXT_H

#include <stdint.h>

extern uint8_t text_color;

extern void text_pagein();

#define UI_XY(x, y) (x + (y * 256))

/* in order to use this function, spectranet has to be paged in into page A at page 0xC1,
   to do that, use text_pagein above */
extern void text_ui_write(uint16_t xy, const char* buf) __FASTCALL__ __CALLEE__;

#endif