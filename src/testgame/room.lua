--
-- Author: Liuq
-- Date: 2016-04-20 00:34:48
--
local skynet = require "skynet"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

local baseroom = require "base.baseroom"

local room = class("room", baseroom)

room.REQUEST = {}    --游戏逻辑命令

function room:ctor()
	self.super:ctor()
	
	self.host = sprotoloader.load(1):host "package"
	self.send_request = self.host:attach(sprotoloader.load(2))
end

-- 游戏开始函数,当满足room开始条件的时候会由基类调用到这个函数，表示游戏开始了
function room:GameStart()
	skynet.error(string.format("room:%d game is start", self.roomid))
end

-- 游戏自身的网络消息
function room.REQUEST:playcard(uid, data)
	print("recv user playcard msg, uid:"..uid)
	local tbtest = {}
	table.insert(tbtest, {fa = "fa1", fb = 1})
	table.insert(tbtest, {fa = "fa2", fb = 2})
	local playcardNotify = { uid = uid, card = data.card, testa = tbtest}
	
	self:broadcastMsg("playcardNotify", playcardNotify)
	
	skynet.error("brocast user playcard ok!")
end

skynet.start(function()
	local roomInstance = room.new()
	--dump(roomInstance)
	skynet.dispatch("lua", function(_,_, command, ...)	
		local f = roomInstance.CMD[command]
		skynet.ret(skynet.pack(f(roomInstance, ...)))
	end)
end)