package.path = "./src/global/?.lua;./src/protocol/?.lua;" .. package.path

local protowapper = require("protowapper")

protowapper.dump(arg[1], arg[2].."/aio_"..arg[1]..".sproto")