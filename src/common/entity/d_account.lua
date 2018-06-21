--
-- Author: Liuq
-- Date: 2016-04-19 16:59:33
--
local UserSingleEntity = require "UserSingleEntity"

local EntityType = class("d_account", UserSingleEntity)

function EntityType:ctor()
	EntityType.super.ctor(self)
	self.tbname = "GameUser"
end

return EntityType.new()