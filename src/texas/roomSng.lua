--
-- Author: Liuq
-- Date: 2016-04-20 00:34:48
--
local skynet = require "skynet"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

local baseroom = require "base.baseroom"
local PokerPlayer = require "PokerPlayer"
local roomSng = class("roomSng", baseroom)
local GameLogic = require "GameLogic"

roomSng.REQUEST = {}    --游戏逻辑命令

function roomSng:ctor()
	self.super:ctor()
	self.ROOMVERSION = "2016051201"
	self.host = sprotoloader.load(1):host "package"
	self.send_request = self.host:attach(sprotoloader.load(2))
end

--room初始化
function roomSng:onInit()
	LOG_DEBUG("room roomType is:%d", self.roomType)
	self.gameLogic = GameLogic.new(self, self.roomid, self.unitcoin)
end

--定时器事件
function roomSng:OnGameTimer()
	self.gameLogic:OnGameTimer()
	local currentTimeStamp = skynet.now()   --精度 1/100秒
	local levelupTimeoutTime = self.levelupTimeoutTime
	if nil ~= levelupTimeoutTime and 0 ~= levelupTimeoutTime then
		if currentTimeStamp > levelupTimeoutTime then
			self:onLevelupTimeout()
		end
	end

end

--SNG模式下定时升底注
function roomSng:onLevelupTimeout()
	LOG_DEBUG("onLevelupTimeout call")
	self.levelupTimeoutTime = self.levelupTimeoutTime + SNGConfig.LevelInterval * 100
	--封顶
	if SNGConfig.SBBets[self.sngMode.level + 1] then
		self.sngMode.level = self.sngMode.level + 1
		
		LOG_DEBUG("当前sng level:%d", self.sngMode.level)
	
		local blindUpgradeNotify = {}
		blindUpgradeNotify.SBBets = SNGConfig.SBBets[self.sngMode.level]
		blindUpgradeNotify.BBBets = 2 * blindUpgradeNotify.SBBets
		
		--广播给客户端
		self:broadcastMsg("blindUpgradeNotify", blindUpgradeNotify)
	end
end

function roomSng:newGamePlayer()
	LOG_DEBUG("roomSng:newGamePlayer() call")
	--做在座位上的，需要new一个pokerplayer出来	
	local player = PokerPlayer.new()
	return player
end

function roomSng:onEnterRoom(_player)
	--可在此处理额外的进入房间后的动作
	self.gameLogic:onEnterRoom(_player)
	
end

--游戏服务器关闭时调用
function roomSng:onShutdown()
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
function roomSng:onUserCutBack(_player)
	self.gameLogic:onUserCutBack(_player)
end

function roomSng:LeaveRoom(uid)
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
function roomSng:GameStart()
	LOG_DEBUG(string.format("room:%d game is start", self.roomid))
	self.gameLogic:GameStart(self.playingPlayers)
	self.sngMode = {}
	self.sngMode.level = 1
	self.levelupTimeoutTime = SNGConfig.LevelInterval * 100
end

function roomSng:onPlayerOperation(_pos, _op, _data)
	LOG_DEBUG("onPlayerOperation  pos:%d op:%d", _pos, _op)
	return self.gameLogic:onPlayerOperation(_pos, _op, _data)
end

-- 游戏自身的网络消息
-- 玩家操作
function roomSng.REQUEST:playerOperationRes(uid, data)
	LOG_DEBUG("recv user playerOperationRes msg, uid:"..uid)
	local player = self.playingPlayers[uid]
	
	self:onPlayerOperation(player:getDeskPos(), data.Operation, data.RaiseAmount)
end

return roomSng
--[[
skynet.start(function()
	local roomInstance = roomSng.new()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = roomInstance.CMD[command]
		skynet.ret(skynet.pack(f(roomInstance, ...)))
	end)
end)
]]