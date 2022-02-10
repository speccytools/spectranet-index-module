#ifndef TEXT_H
#define TEXT_H

#include <stdint.h>

extern uint8_t text_color;

extern void text_pagein();

/* in order to use this function, spectranet has to be paged in into page A at page 0xC1,
   to do that, use text_pagein above */
extern void text_ui_write(const char* buf, uint8_t x, uint8_t y, uint8_t buflen) __CALLEE__;

#endif