--
-- Author: Liuq
-- Date: 2016-04-16 02:08:43
--
--package.path = "./src/protocol/?.lua;" .. package.path

local skynet = require "skynet"
local sprotoparser = require "sprotoparser"
local sprotoloader = require "sprotoloader"
local proto = require "protowapper"

skynet.start(function()
	proto.load("majiang")
	sprotoloader.save(proto.c2s, 1)
	sprotoloader.save(proto.s2c, 2)

	-- don't call skynet.exit() , because sproto.core may unload and the global slot become invalid
end)
