--
-- Author: Liuq
-- Date: 2016-04-20 00:34:48
--
local skynet = require "skynet"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

local baseroom = require "base.baseroom"
local HZMJPlayer = require "HZMJPlayer"
local room = class("room", baseroom)
local TimeManager = require("TimeManager")
local VoteManager = require('VoteManager')
local GameProgress = require("GameProgress")
local MJConst = require("mj_core.MJConst")
local vipRoomComponet = require("vipRoomComponet")

local kPersecent 			= 100  -- 1秒时长
local kRobotTimeOut 		= 2 * kPersecent -- 机器人出牌超时
local kAutoDisbandTimeOut 	= 900 * kPersecent -- 自动解散的时间
-- local roomType = tonumber(...)
room.REQUEST = {}    --游戏逻辑命令


local kRefreshMyFangList = -99


function room:ctor()
	self.super:ctor()
	self.ROOMVERSION = "2016051201"
	self.host = sprotoloader.load(1):host "package"
	self.send_request = self.host:attach(sprotoloader.load(2))
    self.timeMgr = TimeManager.new()
	self.voteMgr = VoteManager.new(self)
	self.vipComponet = vipRoomComponet.new(self, kAutoDisbandTimeOut)
end

function room:stopAutoDisband()
	self.vipComponet:stopAutoDisband()
end

function room:onExit()
	self.timeMgr:clearAllTimeOut()
	self.GameProgress.tempData:clear()
end

function room:deleteAutoDisband()
	self.vipComponet:deleteAutoDisband()
end

function room:setTimeOut(delayMS, callbackFunc, param)
	-- LOG_DEBUG("-- room:setTimeOut --")
	return self.timeMgr:setTimeOut(delayMS, callbackFunc, param)
end

function room:deleteTimeOut(handle)
    -- LOG_DEBUG("-- room:deleteTimeOut --")
	self.timeMgr:deleteTimeOut(handle)
end

--room初始化
function room:onInit()
	LOG_DEBUG("room onInit roomid is:%d", self.roomid)
	--dump(self.fangInfo, 'self.fangInfo = ')
	self.GameProgress = GameProgress.new(self, self.roomid, self.unitcoin)
	self.vipComponet:onInit(self)
end

-- 获取玩家的包房积分
function room:getPlayerVIPScoreBySeat(seatId)
	return self.GameProgress:getPlayerVIPScoreBySeat(seatId)
end

--定时器事件
function room:OnGameTimer()
	self.timeMgr:dealTimeOutEvent()
end

function room:newGamePlayer(_resultSeat, _uid)
	LOG_DEBUG("room:newGamePlayer() call".._resultSeat)
	--做在座位上的，需要new一个pokerplayer出来	
	-- if 0 == _resultSeat then
	-- 	return nil
	-- end
	local player = HZMJPlayer.new()
	return player
end

function room:onEnterRoom(_player)
	LOG_DEBUG("room:onEnterRoom pos:".._player:getDeskPos())
	--可在此处理额外的进入房间后的动作
	if self:isWatcher(_player:getUid()) == 0 then
		self.GameProgress:onEnterRoom(_player)
	end
	self.vipComponet:onEnterRoom(_player)
	if self:isVIPRoom() and self.isVIPLock then
		self:onUserCutBack(_player, nil)
	end
end

function room:onWatcherEnterRoom(_player)
	LOG_DEBUG("room:onWatcherEnterRoom pos:".._player:getDeskPos())
	--可在此处理额外的进入房间后的动作
	self.GameProgress:onWatcherEnterRoom(_player)
	self.vipComponet:onWatcherEnterRoom(_player)
end

--游戏服务器关闭时调用
function room:onShutdown()
end

--掉线重入了，恢复游戏场景
function room:onUserCutBack(_player, cutList)
	if self:isWatcher(_player:getUid()) == 1 then
		-- 暂时不处理旁观玩家
		-- dump(self.watchers, ' self.watchers = ')
		LOG_DEBUG('-- watcher cutback will not deal --')
		return
	end
	LOG_DEBUG("room:onUserCutBack pos:".._player:getDeskPos()..' uid = '.._player:getUid())
	self.GameProgress:onUserCutBack(_player:getDeskPos(), _player.uid)
	self.vipComponet:onUserCutBack(_player, cutList)
	if cutList ~= nil then
		self:broadcastCutUserList(cutList)
	end
end

function room:broadcastCutUserList(cutList)
	local pkg = {}
    pkg.cutUserList = {}
    for _, uid in pairs(cutList) do
        local player = self:getPlayingPlayerByUid(uid)
        if player then
            if table.keyof(pkg.cutUserList, player:getDeskPos()) == nil then
                table.insert(pkg.cutUserList, player:getDeskPos())
            end
        end
    end
    --dump(pkg, '-- broadcastCutUserList = ')
    self:broadcastMsg('notifyUserCut', pkg)
end

function room:onUserCutting(uid, cutList)
	LOG_DEBUG('-- room:onUserCutting --'..uid)
	-- self.GameProgress:onUserCutting(uid)
	self:broadcastCutUserList(cutList)
end

function room:LeaveRoom(uid)
	LOG_DEBUG('-- room:LeaveRoom --')
	self.GameProgress:LeaveRoom(uid)
	self.vipComponet:LeaveRoom(uid)
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

-- 房间解散
function room:onDisband(isGameOver)
	self.GameProgress:onDisband()
	if not self.voteMgr.isdisband then
		self.voteMgr.isdisband = true
	end
	-- 通知相玩关玩刷新房间
	-- LOG_DEBUG('-- room:onDisband 1--')
	self:updateFangOnlineUser(kRefreshMyFangList)
	--退房费
    if #self.GameProgress.roundScoreList == 0 then  -- 没有成绩之前解散允许退房费
        -- LOG_DEBUG('-- room:onDisband() 5--')
        self:refundCard(true)
        -- LOG_DEBUG('-- room:onDisband() 6--')
    end
	if not isGameOver then
		self:updateFangStatus(kVipRoomState.disband)
	end
    -- LOG_DEBUG('-- room:onDisband() 7--')
	-- 请求释放此房间
	skynet.fork(function()
		skynet.call(self.RACEMGR, "lua", "refreshFangList", self.roomid)
	end)
	self:setTimeOut(kRobotTimeOut, function()
		skynet.call(self.RACEMGR, "lua", "requestReleaseRoom", self.roomid)
		-- LOG_DEBUG('-- room:onDisband() 9--')
	end)
	-- LOG_DEBUG('-- room:onDisband() 8--')
end

-- 游戏自身的网络消息
-- 玩家操作
function room.REQUEST:onPlayerOperation(uid, _pkg)
	LOG_DEBUG("recv user playerOperationRes msg, uid:"..uid.." oper:".._pkg.operation)
	local player = self.playingPlayers[uid] or self.players[uid]
	if nil == player then
		LOG_DEBUG("uid:"..uid.." not in playing.")
		return 
	end
	local playerPos = player:getDeskPos()
	---判断玩家是否为机器人，操作是否为出，如果是 补全出操作
	local bRobot = player:isRobot()
	local op = _pkg.operation
	if op == MJConst.kOperTestNeedCard then
		local runType = skynet.getenv("runenv") or "product"
        if runType ~= "develop" then return end
	end
	if true == bRobot  then
		self:setTimeOut(kRobotTimeOut, function()
				if  MJConst.kOperPlay == op then 
					self:completeRobotOutCard(playerPos, _pkg) 
				end
				--dump(_pkg, "completeRobotOutCard pkg")
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
		return
	end
	local pos = player:getDeskPos()
    local runType = skynet.getenv("runenv") or "product"
    if runType ~= "develop" then return end
	local player = self.GameProgress.playerList[pos]
	if nil == player then
		LOG_DEBUG(string.format("pos:%d player invalid.", pos))
		return 
	end

	local cards = MJConst.tranferOld2NewCardList(_pkg.Cards)
	-- 先将当前的数据加入到玩家手中，并判断是否成功
	local bRet, cardsCopy = player:setHandCards(cards)
	local pkg = {}
	pkg.Res = 1
	pkg.Cards = MJConst.transferNew2OldCardList(cardsCopy)
	self:sendMsgToSeat(pos, "testMJCardTypeSC", pkg)
end

-- 收到解散消息
function room.REQUEST:requestVIPDisband(uid, _pkg)
	if not self:isVIPRoom() then
		return
	end
	self.voteMgr:onPlayerDisband(uid, _pkg)
	return true
end

skynet.start(function()
	local roomInstance = room.new()
	skynet.dispatch("lua", function(_,_, command, ...)	
		local f = roomInstance.CMD[command]
		skynet.ret(skynet.pack(f(roomInstance, ...)))
	end)
end)