--
-- Author: Liuq
-- Date: 2016-04-19 17:52:23
--
local skynet = require "skynet"
local Entity = require "Entity"

-- 定义UserEntity类型
local UserEntity = class("UserEntity", Entity)

function UserEntity:ctor()
	UserEntity.super.ctor(self)
	self.ismulti = false		-- 是否多行记录
	self.type = 2
end

return UserEntity