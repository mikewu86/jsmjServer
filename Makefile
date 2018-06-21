include platform.mk

.PHONY: all skynet clean

#PLAT ?= linux
SHARED := -fPIC --shared
LUA_CLIB_PATH ?= luaclib

CFLAGS = -g -O2 -Wall -I/app/src/skynet/3rd/lua -I/app/src/skynet/skynet-src

LUA_CLIB = cjson log websocketnetpack clientwebsocket websocket timestamp

all : skynet
	
all: \
	$(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so)

$(LUA_CLIB_PATH) :
	mkdir $(LUA_CLIB_PATH)
	
$(LUA_CLIB_PATH)/websocketnetpack.so : lualib-src/lua-websocketnetpack.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -Iskynet-src -o $@ 
	
$(LUA_CLIB_PATH)/clientwebsocket.so : lualib-src/lua-clientwebsocket.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -lpthread
	
$(LUA_CLIB_PATH)/websocket.so : lualib-src/lua-websocket.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -lpthread

$(LUA_CLIB_PATH)/log.so : lualib-src/lua-log.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@
	
$(LUA_CLIB_PATH)/cjson.so : | $(LUA_CLIB_PATH)
	cd lualib-src/lua-cjson && $(MAKE) LUA_INCLUDE_DIR=../../skynet/3rd/lua CC=$(CC) CJSON_LDFLAGS="$(SHARED)" && cd ../.. && cp lualib-src/lua-cjson/cjson.so $@

$(LUA_CLIB_PATH)/timestamp.so : lualib-src/lua-timestamp.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@


clean :
	cd skynet && $(MAKE) clean