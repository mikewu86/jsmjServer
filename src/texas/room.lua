--
-- Author: Liuq
-- Date: 2016-04-20 00:34:48
--
local skynet = require "skynet"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

local baseroom = require "base.baseroom"
local PokerPlayer = require "PokerPlayer"
local room = class("room", baseroom)
local GameLogic = require "GameLogic"
local roomSng = require "roomSng"

local roomType = tonumber(...)
room.REQUEST = {}    --游戏逻辑命令

function room:ctor()
	self.super:ctor()
	self.ROOMVERSION = "2016051201"
	self.host = sprotoloader.load(1):host "package"
	self.send_request = self.host:attach(sprotoloader.load(2))
end

--room初始化
function room:onInit()
	LOG_DEBUG("room roomType is:%d", self.roomType)
	self.gameLogic = GameLogic.new(self, self.roomid, self.unitcoin)
end

--定时器事件
function room:OnGameTimer()
	self.gameLogic:OnGameTimer()
end

function room:newGamePlayer()
	LOG_DEBUG("room:newGamePlayer() call")
	--做在座位上的，需要new一个pokerplayer出来	
	local player = PokerPlayer.new()
	return player
end

function room:onEnterRoom(_player)
	--可在此处理额外的进入房间后的动作
	self.gameLogic:onEnterRoom(_player)
	
end

--游戏服务器关闭时调用
function room:onShutdown()
	--普通场需要保存当前状态
	if self.roomType == RoomConstant.RoomType.Common then
		LOG_INFO("server going shutdown, save chips")
		--将用户手中的筹码存盘
		for uid, player in pairs(self.players) do
			player:exchangeOutChips()
		end
	end
end

--掉线重入了，恢复游戏场景
function room:onUserCutBack(_player)
	self.gameLogic:onUserCutBack(_player)
end

function room:LeaveRoom(uid)
	--先找游戏中的玩家
	local player = self:getPlayingPlayerByUid(uid)
	if not player then
		player = self.players[uid]
	else
	
	end
		
	if player then
		--退码
		player:exchangeOutChips()
	end
end

-- 游戏开始函数,当满足room开始条件的时候会由基类调用到这个函数，表示游戏开始了
function room:GameStart()
	LOG_DEBUG(string.format("room:%d game is start", self.roomid))
	self.gameLogic:GameStart(self.playingPlayers)
	
end

function room:onPlayerOperation(_pos, _op, _data)
	LOG_DEBUG("onPlayerOperation  pos:%d op:%d", _pos, _op)
	return self.gameLogic:onPlayerOperation(_pos, _op, _data)
end

-- 游戏自身的网络消息
-- 玩家操作
function room.REQUEST:playerOperationRes(uid, data)
	LOG_DEBUG("recv user playerOperationRes msg, uid:"..uid)
	local player = self.playingPlayers[uid]
	
	self:onPlayerOperation(player:getDeskPos(), data.Operation, data.RaiseAmount)
end

skynet.start(function()
	local roomInstance
	if roomType == RoomConstant.RoomType.Common then
		roomInstance = room.new()
	elseif roomType == RoomConstant.RoomType.SNG then
		roomInstance = roomSng.new()
	end
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = roomInstance.CMD[command]
		skynet.ret(skynet.pack(f(roomInstance, ...)))
	end)
end)