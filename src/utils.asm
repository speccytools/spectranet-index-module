global __debug_framepointer
global _clear42
global _print42

include "../include/spectranet.inc"

defc _print42 = PRINT42
defc INITIAL_SP = 0xFFFF
defc __debug_framepointer = 0x3B00
