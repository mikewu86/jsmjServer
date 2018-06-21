package.cpath = "luaclib/?.so"

local protobuf = require "protobuf"


protobuf.register_file("protocol/netmsg.pb")