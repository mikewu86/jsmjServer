--
-- Author: Liuq
-- Date: 2016-04-20 00:34:48
-- Modifier: Zhangyl
-- Date: 2016-12-30 9:25
--
local skynet = require "skynet"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

local baseroom = require "base.baseroom"
local room = class("room", baseroom)
local Player = require("player")
local Logic = require("logic")
local pokerConst = require("common.pokerConst")
-- local roomType = tonumber(...)
room.REQUEST = {}    --游戏逻辑命令

function room:ctor()
	self.super:ctor()
	self.ROOMVERSION = "2016051201"
	self.host = sprotoloader.load(1):host "package"
	self.send_request = self.host:attach(sprotoloader.load(2))
	-- self.logic = Logic.new()
end

--room初始化
function room:onInit()
	LOG_DEBUG("room roomType is:%d", self.roomid)
	local tbPriority = {pokerConst.k3, pokerConst.k4, pokerConst.k5, pokerConst.k6,
						pokerConst.k7, pokerConst.k8, pokerConst.k9, pokerConst.k10,
						pokerConst.kJ, pokerConst.kQ, pokerConst.kK, pokerConst.kA,
						pokerConst.k2,}

	-- self.logic:init(tbPriority, )
end

--定时器事件
function room:OnGameTimer()
	self.timeMgr:dealTimeOutEvent()
end

function room:newGamePlayer(_resultSeat, _uid)
	LOG_DEBUG("room:newGamePlayer() call")
	--做在座位上的，需要new一个pokerplayer出来	
	if 0 == _resultSeat then
		return nil
	end
	local player = Player.new()
	return player
end

function room:onEnterRoom(_player)
	--可在此处理额外的进入房间后的动作
end

--游戏服务器关闭时调用
function room:onShutdown()
end

--掉线重入了，恢复游戏场景
function room:onUserCutBack(_player)
	LOG_DEBUG("room:onUserCutBack pos:".._player:getDeskPos())
end

function room:LeaveRoom(uid)
end

-- 机器人出牌
function room:completeRobotOutCard(_pos, _pkg)
end

-- 游戏开始函数,当满足room开始条件的时候会由基类调用到这个函数，表示游戏开始了
function room:GameStart()
	LOG_DEBUG(string.format("room:%d game is start", self.roomid))
	-- self.logic:updatePlayerInfo(self.players)
	-- self.logic:start()
end

-- 游戏自身的网络消息
-- 玩家操作
function room.REQUEST:onPlayerOperation(uid, _pkg)
	LOG_DEBUG("recv user playerOperationRes msg, uid:"..uid)

end

skynet.start(function()
	local roomInstance = room.new()
	skynet.dispatch("lua", function(_,_, command, ...)	
		local f = roomInstance.CMD[command]
		skynet.ret(skynet.pack(f(roomInstance, ...)))
	end)
end)