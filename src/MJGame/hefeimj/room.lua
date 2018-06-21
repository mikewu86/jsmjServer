--
-- Author: Liuq
-- Date: 2016-04-20 00:34:48
--
local skynet = require "skynet"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

local baseroom = require "base.baseroom"
local HFMJPlayer = require "HFMJPlayer"
local room = class("room", baseroom)
local TimeManager = require("TimeManager")
local GameProgress = require("GameProgress")
local MJConst = require("mj_core.MJConst")

-- local roomType = tonumber(...)
room.REQUEST = {}    --游戏逻辑命令

function room:ctor()
	self.super:ctor()
	self.ROOMVERSION = "2016051201"
	self.host = sprotoloader.load(1):host "package"
	self.send_request = self.host:attach(sprotoloader.load(2))
    self.timeMgr = TimeManager.new()
end

function room:setTimeOut(delayMS, callbackFunc, param)
	LOG_DEBUG("-- room:setTimeOut --")
	return self.timeMgr:setTimeOut(delayMS, callbackFunc, param)
end

function room:deleteTimeOut(handle)
    LOG_DEBUG("-- room:deleteTimeOut --")
	self.timeMgr:deleteTimeOut(handle)
end

--room初始化
function room:onInit()
	LOG_DEBUG("room roomType is:%d", self.roomid)
	self.GameProgress = GameProgress.new(self, self.roomid, self.unitcoin)
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
	local player = HFMJPlayer.new()
	return player
end

function room:onEnterRoom(_player)
	--可在此处理额外的进入房间后的动作
	self.GameProgress:onEnterRoom(_player)
end

--游戏服务器关闭时调用
function room:onShutdown()
end

--掉线重入了，恢复游戏场景
function room:onUserCutBack(_player)
	LOG_DEBUG("room:onUserCutBack pos:".._player:getDeskPos())
	self.GameProgress:onUserCutBack(_player:getDeskPos())
end

function room:LeaveRoom(uid)
	self.GameProgress:LeaveRoom(uid)
end

-- 机器人出牌
function room:completeRobotOutCard(_pos, _pkg)
	self.GameProgress:completeRobotOutCard(_pos, _pkg)
end

-- 游戏开始函数,当满足room开始条件的时候会由基类调用到这个函数，表示游戏开始了
function room:GameStart()
	LOG_DEBUG(string.format("room:%d game is start", self.roomid))
	self.GameProgress:GameStart(self.playingPlayers)
end

-- 游戏自身的网络消息
-- 玩家操作
function room.REQUEST:onPlayerOperation(uid, _pkg)
	LOG_DEBUG("recv user playerOperationRes msg, uid:"..uid)
	local player = self.playingPlayers[uid]
	if nil == player then
		LOG_DEBUG("uid:"..uid.." not in playing.")
		return 
	end
	local playerPos = player:getDeskPos()
	---判断玩家是否为机器人，操作是否为出，如果是 补全出操作
	local bRobot = player:isRobot()
	local op = _pkg.operation
	if true == bRobot  then
		self:setTimeOut(200, function()
								if  MJConst.kOperPlay == op then 
									self:completeRobotOutCard(playerPos, _pkg) 
								end
								dump(_pkg, "completeRobotOutCard pkg")
								return self.GameProgress:onClientMsg(playerPos, _pkg)
								end, nil) 
	else
		--- 处理玩家操作消息
    	return self.GameProgress:onClientMsg(playerPos, _pkg)
	end
end

function room.REQUEST:testMJCardTypeCS(uid, _pkg)
	LOG_DEBUG("room.REQUEST:testMJCardTypeCS")
	local player = self.playingPlayers[uid]
	if nil == player then
		LOG_DEBUG("uid:"..uid.." not in playing.")
	end
	self.GameProgress:testMJCardTypeCS(player:getDeskPos(), _pkg)
end


skynet.start(function()
	local roomInstance = room.new()
	skynet.dispatch("lua", function(_,_, command, ...)	
		local f = roomInstance.CMD[command]
		skynet.ret(skynet.pack(f(roomInstance, ...)))
	end)
end)