--
-- Author: Liuq
-- Date: 2016-04-11 13:45:52
--
package.path = "../demo/?.lua;" .. package.path

local skynet = require "skynet"
local sprotoparser = require "sprotoparser"
local sprotoloader = require "sprotoloader"
local proto = require "proto"

skynet.start(function()
	sprotoloader.save(proto.c2s, 1)
	sprotoloader.save(proto.s2c, 2)
	-- don't call skynet.exit() , because sproto.core may unload and the global slot become invalid
end)