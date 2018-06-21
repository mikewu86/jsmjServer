-- 2016.9.26 ptrjeffrey 
-- 游戏流程文件
-- 包含所有逻辑和数据,以及状态

local MJConst = require("mj_core.MJConst")
local PlayerGrabMgr = require("mj_core.PlayerGrabMgr")
local MJWall = require("mj_core.MJWall")
local MJPlayer = require("HFMJPlayer")
local MJRiver  = require("mj_core.MJRiver")
local OperHistory = require("mj_core.MJOpHistory")

-- 游戏状态模块
local WaitBegin = require("game_state.WaitBegin")
local GameBegin = require("game_state.GameBegin")
local GamePlaying = require("game_state.GamePlaying")
local HaiLao = require("game_state.HaiLao")
local GameEnd = require("game_state.GameEnd")
local TestCase = require('game_state.TestCase')

-- 机器人出牌分析类
local MJAnalys   = require("MJCommon.basemjanalys")

local GameProgress = class("GameProgress")

local kHuaGang = 6    -- 花杠，扣其他玩家花数

function GameProgress:ctor(room, roomId,unitCoin)
    self.room = room
    self.roomId = roomId
    self.unitCoin = unitCoin
    self.operationSeq = 0
    self.banker = -1          -- 庄
    self.reBanker = 1         -- 连庄基数
    self.turn   = -1          -- 当前轮到
    self.justGangPos = -1     -- 刚刚操作位置
    self.playedCount = 0      -- 共打出
    self.lastOper = MJConst.kOperNull   -- 最后操作类型
    self.maxPlayerCount = 4             -- 最大玩家数
    self.playerGrabMgr = PlayerGrabMgr.new(self.maxPlayerCount)
    self.operHistory = OperHistory.new()
    self.isZiMo = false
    self.isPlayerLeave = false
    self.lastPlayCard = MJConst.kCardNull  -- 刚刚打出的牌
    local wallConfig = {                 --牌墙配置
        0, 4, 4, 4, 4, 4, 4, 4, 0,
        0, 4, 4, 4, 4, 4, 4, 4, 0,
        0, 4, 4, 4, 4, 4, 4, 4, 0,
        0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0
    }
    self.mjWall = MJWall.new(wallConfig)    -- 牌墙类
    self.playerList = {}                    -- 玩家列表
    self.riverCardList = {}                 -- 河牌列表
    self.huaList = {}
    -- for i = MJConst.Zi5, MJConst.Hua8 do
    --     table.insert(self.huaList, i)
    -- end
    for i=1, self.maxPlayerCount do
        local player = MJPlayer.new(14, i)
        player:setConstHuaList(self.huaList)
        local river = MJRiver.new()
        self.playerList[i] = player
        self.riverCardList[i] = river
    end
-- dump(self.playerList, "分配玩家")
    -- 游戏状态
    self.kWaitBegin   = 1
    self.kGameBegin   = 2
    self.kGamePlaying = 3
    self.kHaiLao      = 4
    self.kGameEnd     = 5
    self.kTestCase    = 6   -- 单元测试模块

    self.gameStateList = {
        [self.kWaitBegin] = WaitBegin.new(self, self.kWaitBegin),
        [self.kGameBegin] = GameBegin.new(self, self.kGameBegin),
        [self.kGamePlaying] = GamePlaying.new(self, self.kGamePlaying),
        [self.kHaiLao] = HaiLao.new(self, self.kHaiLao),
        [self.kGameEnd] = GameEnd.new(self, self.kGameEnd),
        [self.kTestCase] = TestCase.new(self, self.kTestCase)
    }

    self.curGameState = self.gameStateList[1];
    --self.curGameState = self.gameStateList[6];  -- 测试用
    self.curGameState:onEntry()  -- 进入到当前的游戏状态
end

function GameProgress:clear()
    LOG_DEBUG("GameProgress:clear")
    self.operationSeq = 0
    self.turn   = -1
    self.justGangPos = -1
    self.playedCount = 0
    self.lastOper = MJConst.kOperNull
    self.isZiMo = false
    for i = 1, self.maxPlayerCount do
        self.playerList[i]:reset()
        self.riverCardList[i]:clear()
    end
    self.operHistory:clear()
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

--
function GameProgress:broadcastPlayerClientNotify(_operSeq, _type,  _args)
    local pkg = {}
    pkg.OperationSeq = _operSeq
    pkg.NotifyType = _type
    pkg.Params = _args
    self.room:broadcastMsg("playerClientNotify", pkg)
end

function GameProgress:huaGangNumNotify(_operSeq,_pos, _num, _money)
    local pkg = {}
    pkg.Pos = _pos
    pkg.Num = _num
    pkg.Money = _money
    pkg.OperationSeq =  _operSeq
    self.room:broadcastMsg("huaGangNumNotify", pkg)
end

-- 发送消息时需要把cards转为客户端的值
function GameProgress:opBuHuaHandCardNotify(_operSeq, _pos, _cards, _op)
    -- LOG_DEBUG(string.format("-- opBuHuaHandCardNotify --%d, %d, %d", _operSeq, _pos, _op))
    for k, v in pairs(self.playerList) do
        local pkg = {}
        pkg.OperationSeq = opSeq
        pkg.Pos = _pos
        pkg.Op = _op
        pkg.Cards = {}
        if v:getDeskPos() ~= _pos then
            for i, card in pairs(_cards) do
                table.insert(pkg.Cards, 0)
            end
        else
            for i, card in pairs(_cards) do
                table.insert(pkg.Cards, MJConst.fromNow2OldCardByteMap[card])
            end
        end
        self.room:sendMsgToUid(v:getUid(), "opBuHuaHandCardNotify", pkg)
    end
end

function GameProgress:opHandCardNotify(_seq, _pos, _cards, _op)
    for k, v in pairs(self.playerList) do
        local pkg = {}
        pkg.OperationSeq = _seq
        pkg.Pos = _pos
        pkg.Op = _op
        pkg.Cards = {}

        for i, card in pairs(_cards) do
            if v:getDeskPos() ~= _pos then 
                table.insert(pkg.Cards, 0)
            else
                table.insert(pkg.Cards, MJConst.fromNow2OldCardByteMap[card])
            end
        end
        self.room:sendMsgToUid(v:getUid(), "opHandCardNotify", pkg)
    end
end
   
function GameProgress:broadcastMsgAddPengCards(_seq, _selfPos, _chuPos, _card)
    local pkg = {}
    pkg.OperationSeq = _seq
    pkg.SelfPos = _selfPos
    pkg.ChuPos = _chuPos
    pkg.Card = MJConst.fromNow2OldCardByteMap[_card]
    self.room:broadcastMsg("addPengCards", pkg)
end

function GameProgress:broadcastMsgAddGangCards(_seq, _selfPos, _chuPos, _card, _Coin)
    local pkg = {}
    pkg.OperationSeq = _seq
    pkg.SelfPos = _selfPos
    pkg.ChuPos = _chuPos
    pkg.Card = MJConst.fromNow2OldCardByteMap[_card]
    -- pkg.Coin = _Coin
    self.room:broadcastMsg("addGangCards", pkg)
end

function GameProgress:broadcastMsgFideGangMoney(_seq, _selfPos, _chuPos, _Coin)
    local pkg = {}
    pkg.OperationSeq = _seq
    pkg.GangSelfPos = _selfPos
    pkg.GangChuPos = _chuPos
    pkg.Money = _Coin
    self.room:broadcastMsg("fideGangMoney", pkg)
end

function GameProgress:broadCastMsgOpOnDeskOutCard(_seq, _op, _pos, _card)
    local pkg = {}
    pkg.OperationSeq = _seq
    pkg.Op = _op
    pkg.Pos = _pos
    pkg.Card = MJConst.fromNow2OldCardByteMap[_card]
    self.room:broadcastMsg("opOnDeskOutCard", pkg)

end

function GameProgress:getOperationSeq()
    return self.operationSeq
end

function GameProgress:incOperationSeq()
    self.operationSeq = self.operationSeq + 1
    return self.operationSeq
end


function GameProgress:broadcastFlowerCardCountNotify(_pos, _count)

    local pkg = {}
    pkg.OperationSeq = self:incOperationSeq()
    pkg.Pos = _pos
    pkg.Count = _count
    self.room:broadcastMsg("FlowerCardCountNotify", pkg)
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

function GameProgress:sendMsgToUidNotifyEachPlayerCards(_pos, _args)
    _args.OperationSeq = self:getOperationSeq()
    self.room:sendMsgToSeat(_pos, "notifyEachPlayerCards", _args)
end

function GameProgress:setCurOperatorPos(_pos)
    if type(1) ~= type(_pos) then
        return false
    end
    self.playerGrabMgr:setPos(_pos)
    return true
end

function GameProgress:getCurOperatorPos()
    return self.playerGrabMgr:getPos()
end

-- 发送消息到客户端,需要转换，data的key为oper, v为cards
function GameProgress:sendMsgSetOperationTipCardsNotify(_pos, _data)
    local pkg = {}
    pkg.OperationSeq = self:getOperationSeq()
    pkg.Data = {}
    for k, v in pairs(_data) do
        dump(v, "pkg v")
        local lCards = MJConst.transferNew2OldCardList(v)
        table.insert(pkg.Data, {op = k,
            cards = lCards})
    end
    dump(pkg, "sendMsgSetOperationTipCardsNotify")
    self.room:sendMsgToSeat(_pos, "setOperationTipCardsNotify", pkg)
end

function GameProgress:broadcastMsgPlayerOperationReq(_seq, _pos, _hasChu, _opers)
    local pkg = {}
    pkg.OperationSeq = _seq
    pkg.Pos = _pos
    if true == _hasChu then
        pkg.Op = _opers
        self.room:broadcastMsg("playerOperationReq", pkg)
    else
        for siPos, player in pairs(self.playerList) do 
            if _pos == siPos then
                pkg.Op = _opers
            else
                pkg.Op = 0
            end
            self.room:sendMsgToSeat(siPos, "playerOperationReq", pkg)
        end
    end
end

function GameProgress:sendMsgTestMJCardTypeSC(_pos, _res, _cards)
    local pkg = {}
    pkg.Res = _res
    pkg.Cards = MJConst.transferNew2OldCardList(_cards)
    self.room:sendMsgToSeat(_pos, "testMJCardTypeSC", pkg)
end

--- 更新玩家的最新数据
function GameProgress:broadCastMsgUpdatePlayerData()
    local pkg = {}
    pkg.Players = {}
    for pos = 1, self.maxPlayerCount do 
        local uid = self.playerList[pos]:getUid()
        local player = self.room.playingPlayers[uid]
        if nil ~= player then
            pkg.Players[pos] = player:getPlayerInfo()
        end
    end
    self.room:broadcastMsg("updatePlayerData", pkg)
end

--- 发送剩余牌数
function GameProgress:broadCastWallDataCountNotify()
    local pkg = {}
    pkg.OperationSeq =  self:getOperationSeq()
    --- 牌墙数量
    pkg.Num = self.mjWall:getCanGetCount()
    self.room:broadcastMsg("wallDataCountNotify", pkg)
end

function GameProgress:broadcastMsgHuaGangNumNotify(_pos, _num, _money)
    local pkg = {}
    pkg.Pos = _pos
    pkg.Num = _num
    pkg.Money = _money
    pkg.OperationSeq =  self:getOperationSeq()
    self.room:broadcastMsg("huaGangNumNotify", pkg)
end

-- 四跟消息通知
function GameProgress:broadcastOutCardMoney(data)
    self.room:broadcastMsg("fideOutCardMoney", data)
    local tbMoney = {}
    for k, v in pairs(data.Data) do
        table.insert(tbMoney, v.money)
    end
    self:updatePlayersMoney(tbMoney, "出牌罚分")
    self:broadCastMsgUpdatePlayerData()
end
--- 增加花杠消息通知
function GameProgress:broadCastMsgFideHuaGangMoney(_pos, _num)
    if _pos then
        local tbMoney = {}
        local siAddMoney = (kHuaGang * 3)  * self.unitCoin
        local siDelMoney = 0 - (kHuaGang   * self.unitCoin)
        for i = 1, self.maxPlayerCount do
            if i == _pos then
                tbMoney[i] = siAddMoney
            else
                tbMoney[i] = siDelMoney
            end
        end

        --- send money 
        self:broadcastMsgHuaGangNumNotify(_pos, _num, siAddMoney)

        self:updatePlayersMoney(tbMoney, "花杠立即结算")
        
        self:broadCastMsgUpdatePlayerData()
    end
end

function GameProgress:addOpItem(_pos, _opList)
    self.playerGrabMgr:addItem(_pos, _opList)
end

function GameProgress:enableExecOp(pos, oper, byteCard)
    local canDo = self.playerGrabMgr:playerDoGrab(pos, oper, byteCard)
    if false == canDo  then
        LOG_DEBUG("player can't grab")
        return false
    end
    return self.playerGrabMgr:needWait()
end

function GameProgress:clearGrabData()
    self.playerGrabMgr:clearGrabData()
end

function GameProgress:completeRobotOutCard(_pos, _pkg)
    local op = _pkg.operation

    -- 获取所有玩家的数据，计算出牌值
    local player = self.playerList[_pos]
    if nil == player then
        LOG_DEBUG(string.format("pos:%d player invalid.", _pos))
        return 
    end
    _pkg.OperationSeq = self:getOperationSeq()
    local cAnalys = MJAnalys.new()
    local intelligent_level_ = 5
    local showCards = {}
    local outCards = {}
    for pos = 1, 4 do 
        local player = self.playerList[pos] 
        table.insert(showCards, player:getPileCardList())
        table.insert(outCards, self.riverCardList[pos]:getRiverCardsList())
    end
    local willCards, needCards = cAnalys:getPlayCard({level_ =  intelligent_level_, list_ = player:getCardsForNums(),
    outcards_ = outCards, showedcards_ = showCards,
    mychairid_ = _pos})
    _pkg.card_bytes = willCards

end

function GameProgress:nextPlayerPos(pos)
    if pos ~= self.maxPlayerCount - 1 then
        return (pos + 1) % self.maxPlayerCount
    else
        return self.maxPlayerCount
    end
end

function GameProgress:prevPlayerPos(pos)
    local ret = (pos + self.maxPlayerCount + 1) % self.maxPlayerCount
    if ret == 0 then
        ret = 4
    end
    return ret
end

--- 测试使用
function GameProgress:testMJCardTypeCS(pos, _pkg)
    local player = self.playerList[pos]
    if nil == player then
        LOG_DEBUG(string.format("pos:%d player invalid.", pos))
        return 
    end

    local cards = MJConst.tranferOld2NewCardList(_pkg.Cards)
    -- 先将当前的数据加入到玩家手中，并判断是否成功
    local bRet, cardsCopy = player:setHandCards(cards)
    self:sendMsgTestMJCardTypeSC(pos, 1, cardsCopy)
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

-- 连庄次数+1，连庄、荒庄时
function GameProgress:updateRemainBanker()
    self.reBanker = self.reBanker + 1
end

-- 重置连庄，玩家退出、换庄时
function GameProgress:resetRemainBanker()
    self.reBanker = 1
end

-- 获取连庄次数
function GameProgress:getRemainBanker()
    return self.reBanker
end

return GameProgress
