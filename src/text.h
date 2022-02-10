#ifndef TEXT_H
#define TEXT_H

#include <stdint.h>

extern uint8_t text_x;
extern uint8_t text_y;
extern uint8_t text_color;

extern void text_pagein();
extern void text_ui_write_at(uint8_t x, uint8_t y, const char* buf, uint8_t buflen) __CALLEE__;

#endif