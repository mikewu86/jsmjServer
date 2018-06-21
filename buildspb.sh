#! /bin/sh

BUILD_SPROTO_DIR=../../src/webclient
SRC_SPROTO_PATH=./src/protocol

./skynet/3rd/lua/lua $SRC_SPROTO_PATH/protodumpper.lua $1 $SRC_SPROTO_PATH

cd ./tools/sprotodump/
../../skynet/3rd/lua/lua sprotodump.lua -spb ../../src/protocol/aio_$1.sproto  -o $BUILD_SPROTO_DIR/$1.spb
