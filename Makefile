ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
SPECTRANET_INDEX_C_SOURCES=$(wildcard src/*.c)
SPECTRANET_INDEX_C_OBJECTS=$(SPECTRANET_INDEX_C_SOURCES:.c=_c.o)
SPECTRANET_INDEX_ASM_SOURCES=$(wildcard src/*.asm)
SPECTRANET_INDEX_ASM_OBJECTS=$(SPECTRANET_INDEX_ASM_SOURCES:.asm=_asm.o)
SPECTRANET_INDEX_INSTALLER_C_SOURCES=$(wildcard installer/*.c)
SPECTRANET_INDEX_INSTALLER_C_OBJECTS=$(SPECTRANET_INDEX_INSTALLER_C_SOURCES:.c=_c.o)
SPECTRANET_INDEX_INSTALLER_ASM_SOURCES=$(wildcard installer/*.asm)
SPECTRANET_INDEX_INSTALLER_ASM_OBJECTS=$(SPECTRANET_INDEX_INSTALLER_ASM_SOURCES:.asm=_asm.o)
INCLUDES=-I$(ROOT_DIR)/include/spectranet -I$(ROOT_DIR)/src
FONTLIB_SOURCES=$(wildcard font/*.asm)
JUST_PRINT:=$(findstring n,$(MAKEFLAGS))

ifneq (,$(JUST_PRINT))
	PHONY_OBJS := yes
	CC = gcc
	LD = ar
	FAKE_DEFINES = -D__LIB__="" -D__CALLEE__="" -D__FASTCALL__=""
	FAKE_INCLUDES = -I/usr/local/share/z88dk/include
	CFLAGS = $(FAKE_DEFINES) -nostdinc $(INCLUDES) $(FAKE_INCLUDES)
	SPECTRANET_INDEX_FLAGS = -o build/SPECTRANET_INDEX
	SPECTRANET_INDEX_INSTALLER_FLAGS = -o build/SPECTRANET_INDEX
else
	CC = zcc
	LD = zcc
	CFLAGS = +zx $(DEBUG) $(INCLUDES)
	LINK_FLAGS = -L$(ROOT_DIR)/libs
	SPECTRANET_INDEX_BIN_FLAGS = -startup=31 --no-crt -subtype=bin
	SPECTRANET_INDEX_INSTALLER_BIN_FLAGS =
	LDFLAGS = +zx $(DEBUG) $(LINK_FLAGS)
	SPECTRANET_INDEX_FLAGS = -create-app
	SPECTRANET_INDEX_INSTALLER_FLAGS = -create-app
endif

all: spectranet-index-installer spectranet-index

build/spectranet-index: build/fontlib__.bin.zx7 $(SPECTRANET_INDEX_C_OBJECTS) $(SPECTRANET_INDEX_ASM_OBJECTS)
	$(LD) $(LDFLAGS) $(SPECTRANET_INDEX_BIN_FLAGS) -o build/spectranet-index $(SPECTRANET_INDEX_FLAGS) $(SPECTRANET_INDEX_C_OBJECTS) $(SPECTRANET_INDEX_ASM_OBJECTS)

build/spectranet-index-installer: spectranet-index $(SPECTRANET_INDEX_INSTALLER_C_OBJECTS) $(SPECTRANET_INDEX_INSTALLER_ASM_OBJECTS)
	$(LD) $(LDFLAGS) $(SPECTRANET_INDEX_INSTALLER_BIN_FLAGS) -o build/spectranet-index-installer $(SPECTRANET_INDEX_INSTALLER_FLAGS) $(SPECTRANET_INDEX_INSTALLER_C_OBJECTS) $(SPECTRANET_INDEX_INSTALLER_ASM_OBJECTS)

build:
	mkdir -p $@

build/fontlib__.bin.zx7:
	$(CC) $(CFLAGS) $(FONTLIB_SOURCES) -o build/fontlib --no-crt -subtype=bin -create-app
	z88dk-zx7 build/fontlib__.bin

include/spectranet:
	@mkdir -p include/spectranet

libs:
	mkdir -p $@

spectranet-index: build build/spectranet-index

spectranet-index-installer: build build/spectranet-index-installer
	cp build/spectranet-index-installer tnfs/install.bin

%_c.o: %.c
	$(CC) $(CFLAGS) -o $@ -c $<

%_asm.o: %.asm
	$(CC) $(CFLAGS) -o $@ -c $<

get-size:
	@cat build/spectranet-index.map | sed -n "s/^\\([a-zA-Z0-9_]*\\).*= .\([A-Z0-9]*\) ; \([^,]*\), .*/\2,\1,\3/p" | sort | python3 tools/symbol_sizes.py

deploy:
	ethup 192.168.88.61 build/spectranet-index__.bin

clean:
	@rm -rf build/*
	@rm -f src/*.o
	@rm -f installer/*.o
	@rm -f tnfs/install.bin

.PHONY: clean get-size deploy

ifeq ($(PHONY_OBJS),yes)
.PHONY: $(SPECTRANET_INDEX_SOURCES)
endif
