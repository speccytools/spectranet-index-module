#ifndef EXTERN_H
#define EXTERN_H

#include <stdint.h>

extern void sitoa(char* a, uint8_t i) __FASTCALL__ __CALLEE__;
extern void print42(const char* s) __FASTCALL__;
extern void search_into(char* buffer) __FASTCALL__;
extern char* resolve_txt_records(const char* query) __FASTCALL__;

#endif