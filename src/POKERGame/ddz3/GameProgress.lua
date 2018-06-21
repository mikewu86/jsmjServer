local PokerConst = require("poker_core.PokerConst")
local PokerCardPool = require("poker_core.PokerCardPool")
local PokerPlayer = require("DDZ3Player")
local PokerRiver  = require("poker_core.PokerRiver")

-- 游戏状态模块
local WaitBegin = require("game_state.WaitBegin")
local GameBegin = require("game_state.GameBegin")
local GamePlaying = require("game_state.GamePlaying")
local GameEnd = require("game_state.GameEnd")
local TestCase = require('game_state.TestCase')

local GameProgress = class("GameProgress")

function GameProgress:ctor(room, roomId,unitCoin)
    self.room = room
    self.roomId = roomId
    self.unitCoin = unitCoin
    self.operationSeq = 0
    self.landLordPos = -1        -- 地主
    self.maxPlayerCount = 3   -- 最大玩家数
    self.outCards = {}
    self.PokerCardPool = PokerCardPool.new()    -- 牌池类
    self.playerList = {}                    -- 玩家列表
    self.riverCardList = {}                 -- 河牌列表
    for i=1, self.maxPlayerCount do
        local player = PokerPlayer.new(i)
        local river = PokerRiver.new()
        self.playerList[i] = player
        self.riverCardList[i] = river
        self.playerSetDouble[i] = 1  -- 玩家加倍分数的table
    end
-- dump(self.playerList, "分配玩家")
    -- 游戏状态
    self.kWaitBegin   = 1
    self.kGameBegin   = 2
    self.kGamePlaying = 3
    self.kGameEnd     = 4
    self.kTestCase    = 5   -- 单元测试模块

    self.gameStateList = {
        [self.kWaitBegin] = WaitBegin.new(self, self.kWaitBegin),
        [self.kGameBegin] = GameBegin.new(self, self.kGameBegin),
        [self.kGamePlaying] = GamePlaying.new(self, self.kGamePlaying),
        [self.kGameEnd] = GameEnd.new(self, self.kGameEnd),
        [self.kTestCase] = TestCase.new(self, self.kTestCase)
    }

    self.curGameState = self.gameStateList[1];
    -- self.curGameState = self.gameStateList[5];  -- 测试用
    self.curGameState:onEntry()  -- 进入到当前的游戏状态
end

function GameProgress:clear()
    LOG_DEBUG("GameProgress:clear")
    self.operationSeq = 0
    self.landLord = -1
    for i = 1, self.maxPlayerCount do
        self.playerList[i]:reset()
        self.riverCardList[i]:clear()
        self.playerSetDouble[i] = 1
    end
    self.outCards = {}
end

--------------- 系统事件 ----------------------
function GameProgress:onEnterRoom(_player)
    self.curGameState:onPlayerComin(_player)
end

function GameProgress:LeaveRoom(uid)
    self.curGameState:onPlayerLeave(uid)
end

function GameProgress:onPlayerReady()
    self.curGameState:onPlayerReady()
end

function GameProgress:onUserCutBack(_pos)
	self.curGameState:onUserCutBack(_pos)
end

function GameProgress:GameStart(_players)
    self.curGameState:onExit()
	self.curGameState = self.gameStateList[self.kGameBegin]
    self.curGameState:onEntry()
end

-- 来自客户端的消息
function GameProgress:onClientMsg(_pos, _pkg)
    self.curGameState:onClientMsg(_pos, _pkg)
end

function GameProgress:addHandCardNotifyReq(_pos, _cards)
    local pkg = {}
    pkg.OperationSeq = self:incOperationSeq()
    pkg.Pos = _pos
    pkg.Cards = _cards
    self.room:sendMsgToSeat(_pos, "addHandCardNotifyReq", pkg)
end

-- 底牌
function GameProgress:baseCardNotify(_cards)
    local pkg = {}
    pkg.OperationSeq = self:incOperationSeq()
    pkg.Cards = _cards
    self.room:broadcastMsg("baseCardNotify", pkg)
end

-- 叫分
function GameProgress:playerCallPointReq(_pos)
    local pkg = {}
    pkg.OperationSeq = self:incOperationSeq()
    pkg.Pos = _pos
    self.room:broadcastMsg("playerCallPointReq", pkg)
end

-- 抢地主
function GameProgress:playerGrabLandLordReq(_pos)
    local pkg = {}
    pkg.OperationSeq = self:incOperationSeq()
    pkg.Pos = _pos
    self.room:broadcastMsg("playerGrabLandLordReq", pkg)
end

-- 加倍
function GameProgress:playerDoubleScoreReq()
    local pkg = {}
    pkg.OperationSeq = self:incOperationSeq()
    self.room:broadcastMsg("playerDoubleScoreReq", pkg)
end

-- 出牌
function GameProgress:playerPlayCardReq(_pos, _op)
    local pkg = {}
    pkg.OperationSeq = self:incOperationSeq()
    pkg.Pos = _pos
    pkg.Op = _op
    self.room:sendMsgToSeat(_pos, "playerPlayCardReq", pkg)
end

-- 出牌结果通知所有人
function GameProgress:playerOutCardsRes_All(_op, _pos, _cards)
    local pkg = {}
    pkg.OperationSeq = self:incOperationSeq()
    pkg.Operation = _op
    pkg.Pos = _pos
    pkg.Cards = _cards
    self.room:broadcastMsg("playerOutCardsRes_All", pkg)
end

-- 过牌
function GameProgress:playerPassCardRes_All(_op, _pos)
    local pkg = {}
    pkg.Operation = _op
    pkg.Pos = _pos
    pkg.OperationSeq = self:incOperationSeq()
    self.room:broadcastMsg("playerPassCardRes_All", pkg)
end

-- 游戏结果
function GameProgress:gameResult_All(_times, _money, _remainCards)
    local pkg = {}
    pkg.OperationSeq = self:incOperationSeq()
    pkg.times = _times
    pkg.money = _money
    pkg.RemainHandCards = _remainCards
    self.room:broadcastMsg("gameResult_All", pkg)
end

-- 游戏内的通知
function GameProgress:playerClientNotify(_notifyType, _params)
    local pkg = {}
    pkg.OperationSeq = self:incOperationSeq()
    pkg.NotifyType = _notifyType
    pkg.Params = _params
    self.room:broadcastMsg("playerClientNotify", pkg)
end

-- 玩家身份通知
function GameProgress:playerRoleNotify(_pos, _type)
    local pkg = {}
    pkg.OperationSeq = self:incOperationSeq()
    pkg.Pos = _pos
    pkg.Type = _type
    self.room:sendMsgToSeat(_pos, "playerRoleNotify", pkg)
end

function GameProgress:getOperationSeq()
    return self.operationSeq
end

function GameProgress:incOperationSeq()
    self.operationSeq = self.operationSeq + 1
    return self.operationSeq
end

function GameProgress:setTimeOut(delayMS, callbackFunc, param)
	return self.room:setTimeOut(delayMS, callbackFunc, param)
end

function GameProgress:deleteTimeOut(handle)
	if handle == nil then
        return
    end
    self.room:deleteTimeOut(handle)
end

function GameProgress:nextPlayerPos(pos)
    if pos ~= self.maxPlayerCount - 1 then
        return (pos + 1) % self.maxPlayerCount
    else
        return self.maxPlayerCount
    end
end

--- 更新玩家数据库的钱数
function GameProgress:updatePlayersMoney(_tbMoney, _strJiesuan)
    for pos, money in pairs(_tbMoney) do
        local uid = self.playerList[pos]:getUid()
        local player = self.room.playingPlayers[uid]
        if nil ~= player then
            player:updateMoney(money, _strJiesuan)
        end
    end
end

--- 更新玩家胜负积分
--- updateWinLostDraw 1(win) 2(los) 3(draw)
function GameProgress:updatePlayersSorce(_winPos)
    for uid, player in pairs(self.room.playingPlayers) do 
        if nil == _winPos then
            player:updateWinLostDraw(3, 1)
        elseif player:getDeskPos() == _winPos then
            player:updateWinLostDraw(1, 1)
        else
            player:updateWinLostDraw(2, 1)
        end
    end
end

return GameProgress