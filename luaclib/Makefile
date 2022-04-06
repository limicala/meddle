SKYNET_BUILD_PATH ?= ../skynet

include $(SKYNET_BUILD_PATH)/platform.mk

SHARED_FLAGS = -g -O2 -Wall -I$(LUA_INC) -I$(SKYNET_SRC) -I$(SKYNET_LUALIB_SRC) -D_GNU_SOURCE
CFLAGS = -std=gnu99 $(SHARED_FLAGS)
LUA_INC ?= $(SKYNET_BUILD_PATH)/3rd/lua
SKYNET_SRC ?= $(SKYNET_BUILD_PATH)/skynet-src
SKYNET_LUALIB_SRC ?= $(SKYNET_BUILD_PATH)/lualib-src

all: \
	cjson.so \
	lfs.so

cjson.so:
	cd lua-cjson && $(MAKE) LUA_INCLUDE_DIR=../$(LUA_INC) TARGET=../cjson.so
lfs.so:
	cd luafilesystem && $(MAKE) LUA_INC=-I../$(LUA_INC) && $(MAKE) install LUA_LIBDIR=../../luaclib
clean :
	rm -f *.so
