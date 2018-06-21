-- 2016.9.26 ptrjeffrey 
-- 游戏流程文件
-- 包含所有逻辑和数据,以及状态

local MJConst = require("mj_core.MJConst")
local PlayerGrabMgr = require("mj_core.PlayerGrabMgr")
local MJWall = require("mj_core.MJWall")
local MJPlayer = require("MAANSHMJPlayer")
local MJRiver  = require("mj_core.MJRiver")
local OperHistory = require("mj_core.MJOpHistory")
-- 游戏状态模块
local WaitBegin = require("game_state.WaitBegin")
local GameBegin = require("game_state.GameBegin")
local ExtraBeforePlaying = require("game_state.ExtraBeforePlaying")
local GamePlaying = require("game_state.GamePlaying")
local GameEnd = require("game_state.GameEnd")
local TestCase = require('game_state.TestCase')
local CTempData = require(".tempData")
-- 机器人出牌分析类
local MJAnalys   = require("MJCommon.basemjanalys")

local GameProgress = class("GameProgress")

local kHuaGang = 6    -- 花杠，扣其他玩家花数
local kZimoNum = 1

function GameProgress:ctor(room, roomId,unitCoin)
    self.room = room
    self.roomId = roomId
    self.unitCoin = unitCoin
    self.operationSeq = 0
    self.banker = -1          -- 庄
    self.turn   = -1          -- 当前轮到
    self.justGangPos = -1     -- 刚刚操作位置
    self.playedCount = 0      -- 共打出
    self.lastOper = MJConst.kOperNull   -- 最后操作类型
    self.maxPlayerCount = 4             -- 最大玩家数
    self.playerGrabMgr = PlayerGrabMgr.new(self.maxPlayerCount)
    self.operHistory = OperHistory.new(self)
    self.isZiMo = false
    self.lastPlayCard = MJConst.kCardNull  -- 刚刚打出的牌
    self.m_bDiZero = false
    self.m_bNextDiZero = false
    self.m_bBaoZi = false
    self.cutUserList = {}               -- 存储的是玩家的ID

    local wallConfig = {                 --牌墙配置
        4, 4, 4, 4, 4, 4, 4, 4, 4,
        4, 4, 4, 4, 4, 4, 4, 4, 4,
        4, 4, 4, 4, 4, 4, 4, 4, 4,
        4, 4, 4, 4, 4, 4, 4,
        0, 0, 0, 0, 0, 0, 0, 0
    }
    self.mjWall = MJWall.new(wallConfig)    -- 牌墙类
    self.playerList = {}                    -- 玩家列表
    self.riverCardList = {}                 -- 河牌列表
    self.huaList = {}
    -- for i = MJConst.Zi5, MJConst.Zi5 do
    --     table.insert(self.huaList, i)
    -- end
    self.roomRuleMap = {}
    for _, v in pairs(self.room.fangInfo.RoomRule) do
        if v.IsChecked == true then
            self.roomRuleMap[v["Name"]] = v.IsChecked
        end
    end

    -- self:createGameRule()
    local baseScore = 50
    self.baseZoom = self:calcZoomFan()
    local index = self.room.fangInfo.RoundCount

    self.allBaseScore = baseScore * index
    for i=1, self.maxPlayerCount do
        local player = MJPlayer.new(14, i)
        player:setConstHuaList(self.huaList)
        player:initBaseScores(index, baseScore)
        self.playerList[i] = player

        local river = MJRiver.new()
        self.riverCardList[i] = river
    end
    -- 游戏状态
    self.kWaitBegin   = 1
    self.kGameBegin   = 2
    self.kExtraStatus = 3
    self.kGamePlaying = 4
    self.kGameEnd     = 5
    self.kTestCase    = 6   -- 单元测试模块

    self.gameStateList = {
        [self.kWaitBegin] = WaitBegin.new(self, self.kWaitBegin),
        [self.kGameBegin] = GameBegin.new(self, self.kGameBegin),
        [self.kExtraStatus] = ExtraBeforePlaying.new(self, self.kExtraStatus),
        [self.kGamePlaying] = GamePlaying.new(self, self.kGamePlaying),
        [self.kGameEnd] = GameEnd.new(self, self.kGameEnd),
        [self.kTestCase] = TestCase.new(self, self.kTestCase)
    }

    self.curGameState = self.gameStateList[self.kWaitBegin]
    self.roundCount = 1
    self.roundScoreList = {}   -- 每局的分数
    self.subRoundCount = 1

    self.tempData = CTempData.new(self.maxPlayerCount)

    self.selectedAbandonedSuit = {-1, -1, -1, -1}
    -- self.curGameState = self.gameStateList[5];  -- 测试用
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
    self.selectedAbandonedSuit = {-1, -1, -1, -1}
end

--------------- 系统事件 ----------------------
function GameProgress:onEnterRoom(_player)
    self.curGameState:onPlayerComin(_player)
    if self:isVIPRoom() then
        self:sendVIPRoomInfo(_player:getUid())
        if self.room.voteMgr:isDisband() then
            self.room.voteMgr:sendVIPErrorMsg(nil, '此房间已解散', 1)
            --出现数据库状态与游戏服务器状态不一致
            self.room:updateFangStatus(kVipRoomState.disband)
        end
    end
end

function GameProgress:sendVIPRoomInfo(uid)
    if self.room.fangInfo and self.room.fangInfo.OwnerUserId then
        local pkg = {}
        if self.isVIPLock then
            pkg.owner = -1
        else
            pkg.owner = self.room.fangInfo.OwnerUserId
        end
        pkg.totalRound = self.room.fangInfo.RoundCount
        pkg.curRound = self.roundCount
        -- if pkg.curRound > pkg.totalRound then
        --     pkg.curRound = pkg.totalRound
        -- end
        pkg.ruleDesc = ''
        for _, v in pairs(self.room.fangInfo.RoomRule) do
            if v.IsChecked then
                if v.Text ~= '房主支付' then
                    pkg.ruleDesc = pkg.ruleDesc..v.Text..';'
                end
                -- table.insert(pkg.ruleDesc, {v.Text})
            end
        end
        pkg.baseScore = self.room.fangInfo.BaseScore
        pkg.roomId = self.room.fangInfo.RoomPassword
        pkg.gameState = self.room.vipRoomState
        pkg.realRoomId = self.room.roomid
        self.room:sendMessage(uid, 'vipRoomInfo', pkg)
    end
end

function GameProgress:LeaveRoom(uid)
    LOG_DEBUG('-- GameProgress:LeaveRoom --')
    self.curGameState:onPlayerLeave(uid)
end

function GameProgress:onWatcherEnterRoom(_player)
    LOG_DEBUG('GameProgress:onWatcherEnterRoom'.._player:getUid())
end

function GameProgress:onPlayerReady()
    self.curGameState:onPlayerReady()
end

function GameProgress:onUserCutBack(_pos, uid)
    LOG_DEBUG('GameProgress:onUserCutBack stateId = '..self.curGameState.stateId)
	self.curGameState:onUserCutBack(_pos, uid)
end


function GameProgress:GameStart(_players)
    if self:isVIPRoom() then
        if self.roundCount == 1 then   -- 包房的第一局记录下当前四个玩家的名字
            self.nicknameList = {}
            for i = 1, self.maxPlayerCount do
                local player = self.room:getPlayingPlayerByPos(i)
                if player then
                    table.insert(self.nicknameList, player.nickname)
                else
                    table.insert(self.nicknameList, 'seat'..i)
                end
            end
            --dump(self.nicknameList, 'self.nicknameList = ')
        end
        if self:isVIPOver(true) then
            LOG_DEBUG('-- This room is game over --'..self.roundCount)
            self.room.voteMgr:sendVIPErrorMsg(nil, '所有局数已打满，请退出', 1)
            self.room:onDisband()
            self.tempData:reset()
            return
        end

        self:sendVIPRoomInfo()

		if self.room.voteMgr:isDisband() then
			self.room.voteMgr:sendVIPErrorMsg(nil, '此房间已解散！', 1)
            return
		end
        if self.room.isVIPLock == false then 
		    self.room.isVIPLock = true
            self.room:stopAutoDisband()
            local roomPlayers = {}
            for _, v in pairs(self.playerList) do
                if v then
                    table.insert( roomPlayers, v:getUid())
                end
            end
            self.room:updateFangStatus(kVipRoomState.playing, roomPlayers)
        end
        self:sendVIPRoomInfo()
        self.room:deleteAutoDisband()
    end
    self.curGameState:onExit()
    LOG_DEBUG('gameStart curRound'..self.roundCount)
	self.curGameState = self.gameStateList[self.kGameBegin]
    self.curGameState:onEntry()
end

-- 来自客户端的消息
function GameProgress:onClientMsg(_pos, _pkg)
    self.curGameState:onClientMsg(_pos, _pkg)
end

-- 房间解散，进入到Wait状态，不再处理玩家请求
function GameProgress:onDisband()
    -- dump(self.room.vipRoomState,"self.room.vipRoomState ***")
    if self.room.isPlaying == true then
        self:insertVIPRoomRecordByDisband({{},{},{},{}})
    end
    self.room:GameEnd(true)
	self.curGameState = self.gameStateList[1];
    self.curGameState:onEntry()
end

--
function GameProgress:broadcastPlayerClientNotify(_operSeq, _type,  _args)
    local pkg = {}
    pkg.OperationSeq = _operSeq
    pkg.NotifyType = _type
    pkg.Params = _args
    self:addHistoryRoomInfo()
    self.operHistory:addOperHistory("playerClientNotify", pkg)
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
    local _pkg = {}
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
            _pkg = pkg
        end
        -- 补花
        self.room:sendMsgToUid(v:getUid(), "opBuHuaHandCardNotify", pkg)
    end
    self.operHistory:addOperHistory("opBuHuaHandCardNotify", _pkg)
end

function GameProgress:sendDealHandCards(pos)
    local pkg = {}
    pkg.banker = self.banker
    pkg.myHandCards = self.playerList[pos]:getCardsForNums()
    pkg.followers = {}
    for k, player in pairs(self.playerList) do
        table.insert(pkg.followers, #player:getHuaList())
    end
    self.room:sendMsgToSeat(pos, 'dealHandCards', pkg)
    self.operHistory:addOperHistory("dealHandCards", pkg)
end

-- 发送检查牌的消息
function GameProgress:sendCheckCards(pos)
    if self.playerList[pos] then
        local pkg = {}
        pkg.hand_cards = self.playerList[pos]:getCardsForNums()
        self.room:sendMsgToSeat(pos, 'checkHandData', pkg)
    end
end

function GameProgress:opHandCardNotify(_seq, _pos, _cards, _op)
    local _pkg = {}
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

        if v:getDeskPos() == _pos then 
            _pkg = pkg
            -- 在每次需要加减牌之前把整量发过去
            self:sendCheckCards(_pos)
        end
        self.room:sendMsgToUid(v:getUid(), "opHandCardNotify", pkg)
    end
    self.operHistory:addOperHistory("opHandCardNotify", _pkg)
end

function GameProgress:broadcastMsgAddPengCards(_seq, _selfPos, _chuPos, _card)
    local pkg = {}
    pkg.OperationSeq = _seq
    pkg.SelfPos = _selfPos
    pkg.ChuPos = _chuPos
    pkg.Card = MJConst.fromNow2OldCardByteMap[_card]
    self.operHistory:addOperHistory("addPengCards", pkg)
    self.room:broadcastMsg("addPengCards", pkg)
end

function GameProgress:broadcastMsgAddGangCards(_seq, _selfPos, _chuPos, _card, _Coin)
    local pkg = {}
    pkg.OperationSeq = _seq
    pkg.SelfPos = _selfPos
    pkg.ChuPos = _chuPos
    pkg.Card = MJConst.fromNow2OldCardByteMap[_card]
    -- pkg.Coin = _Coin
    self.operHistory:addOperHistory("addGangCards", pkg)
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
    self.operHistory:addOperHistory("opOnDeskOutCard", pkg)
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
    self.operHistory:addOperHistory("FlowerCardCountNotify", pkg)
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
    -- self.operHistory:addOperHistory("notifyEachPlayerCards", _args)
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
function GameProgress:sendMsgSetOperationTipCardsNotify(_pos, _data, tipNodes)
    local pkg = {}
    pkg.OperationSeq = self:getOperationSeq()
    pkg.Data = {}
    for k, v in pairs(_data) do
        --dump(v, "pkg v")
        local lCards = MJConst.transferNew2OldCardList(v)
        table.insert(pkg.Data, {op = k,
            cards = lCards})
    end
    pkg.tingNodes = {}
    --dump(tipNodes, ' tipsNodes = ')
    if tipNodes then
        for k, v in pairs(tipNodes) do
            local item = {}
            item.playCard = MJConst.fromNow2OldCardByteMap[v.playCard]
            item.huInfo = {}
            for _, node in pairs(v.huList) do
                table.insert(item.huInfo, 
                { 
                    huCard = MJConst.fromNow2OldCardByteMap[node.card],
                    fan = node.fan,
                    left = node.left
                })
            end
            table.insert(pkg.tingNodes, item)
        end
    end
    --dump(pkg, "sendMsgSetOperationTipCardsNotify")
    self:sendCheckCards(_pos)
    self.room:sendMsgToSeat(_pos, "setOperationTipCardsNotify", pkg)
end

function GameProgress:broadcastMsgPlayerOperationReq(_seq, _pos, _opers)
    local pkg = {}
    pkg.OperationSeq = _seq
    pkg.Pos = _pos
    pkg.Op = _opers
    -- self.operHistory:addOperHistory("playerOperationReq", pkg)
    self.room:broadcastMsg("playerOperationReq", pkg)
end


--- 更新玩家的最新数据
function GameProgress:broadCastMsgUpdatePlayerData(uid)
    local pkg = {}
    pkg.Players = {}
    local players = self.playerList
    if false == self.room.isVIPLock then
        players = self.room.players
    end
    for _, player in pairs(players) do
        pkg.Players[player:getDeskPos()] = player:getPlayerInfo()
    end
    if nil == uid then
        self.room:broadcastMsg("updatePlayerData", pkg)
    else
        self.room:sendMsgToUid(uid, "updatePlayerData", pkg)
    end
end

--- 发送剩余牌数
function GameProgress:broadCastWallDataCountNotify()
    local pkg = {}
    pkg.OperationSeq =  self:getOperationSeq()
    --- 牌墙数量
    pkg.Num = self.mjWall:getCanGetCount()
    self.operHistory:addOperHistory("wallDataCountNotify", pkg)
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

-- function GameProgress:createGameRule()
--     dump(self.room.fangInfo.RoomRule, "self.room.fangInfo.RoomRule")

-- end

function GameProgress:getRoomRule()
    return self.roomRuleMap
end

function GameProgress:getFangInfo()
    return self.room.fangInfo
end

function GameProgress:isCommonRoom()
    return self.room:isCommonRoom()
end

function GameProgress:isSNGRoom()
    return self.room:isSNGRoom()
end

function GameProgress:isVIPRoom()
    return self.room:isVIPRoom()
end

function GameProgress:getRoundCount()
    return self.roundCount
end

function GameProgress:addRoundCount()
    self.roundCount = self.roundCount + 1
    self.subRoundCount = self.subRoundCount + 1
end

function GameProgress:resetSubRoundCount()
    self.subRoundCount = 0
end

function GameProgress:getSubRoundCount()
    return self.subRoundCount
end

-- 这个scoreMap是「用户位置，分数」
function GameProgress:addRoundScore(scoreMap)
    local map = {}
    table.insert(self.roundScoreList, scoreMap)
end
function GameProgress:getTotalDifen()
    local totalScore = {0, 0, 0, 0}
    local remainNum = 0
    local extra = 0
    local temp = 0
    for pos = 1, self.maxPlayerCount do 
        local player = self.playerList[pos]
        if player ~= nil then
            totalScore[pos] = player:getTotalScore()
            totalScore[pos] = totalScore[pos] * self.baseZoom
            extra = 0
            reaminNum = 0
            if totalScore[pos] < 0 then
                remainNum = math.mod((0 - totalScore[pos]), 10)
                if remainNum >= 5 then
                    extra = -1
                end
            else
                remainNum = math.mod(totalScore[pos], 10)
                if remainNum >= 5 then
                    extra = 1
                end
                remainNum = 0 - remainNum
            end
            temp = (totalScore[pos] + remainNum)/10
            totalScore[pos] = temp  + extra
        end
    end
    return totalScore  
end

function GameProgress:getTotalScore()
    local totalScore = {0, 0, 0, 0}
    local tbDifen = self:getTotalDifen()
    for pos = 1, self.maxPlayerCount do 
        local player = self.playerList[pos]
        if player ~= nil then
            totalScore[pos] = player:getPlayerExtraFan() + tbDifen[pos]
        end
    end
    return totalScore
end

-- 获取玩家的包房积分
function GameProgress:getPlayerVIPScoreBySeat(seatId)
    local totalScore = self:getTotalScore()
    return totalScore[seatId]
end

function GameProgress:isVIPOver(isbegin)
    -- LOG_DEBUG('--self.room.fangInfo.RoundCount = '..self.room.fangInfo.RoundCount)
    -- LOG_DEBUG('-- self.roundCount = '..self.roundCount)
    -- dump(isbegin)
    local ret = false
    local player = self.playerList[1]
    if player:getPlayerScore() < 0 then
        ret = true
    end
    -- end

    -- if isbegin then
    --     if self.roundCount > self.room.fangInfo.RoundCount then
    --         ret = true
    --     end
    -- else
    --     if self.roundCount >= self.room.fangInfo.RoundCount then
    --         ret = true
    --     end
    -- end
    if ret then
        self.room:updateFangStatus(kVipRoomState.gameover)
    end
    return ret
end

--- 更新玩家数据库的钱数
function GameProgress:updatePlayersMoney(_tbMoney, _strJiesuan)
    if self.room:isVIPRoom() then

    elseif self.room:isCommonRoom() then
        for pos, money in pairs(_tbMoney) do
            local uid = self.playerList[pos]:getUid()
            local player = self.room.playingPlayers[uid]

            if nil ~= player then
                player:updateMoney(money, _strJiesuan)
            end
        end
    end
end

function GameProgress:updatePlayerScore(tbscore)
    for pos, score in pairs(tbscore) do
        local player = self.playerList[pos]

        if nil ~= player then
            player:updatePlayerScore(score)
        end
    end
end

function GameProgress:updatePlayerExtraFan(tbExtraFans)
    for pos, score in pairs(tbExtraFans) do
        local player = self.playerList[pos]

        if nil ~= player then
            player:updatePlayerExtraFan(score)
        end
    end
end

function GameProgress:incBaseCnt()
    for pos = 1, self.maxPlayerCount do 
        local player = self.playerList[pos]
        if player ~= nil then
            player:incBaseCnt()
        end
    end
end

--- 更新玩家胜负积分
--- updateWinLostDraw 1(win) 2(los) 3(draw)
function GameProgress:updatePlayersSorce(_winPos)
    if self.room:isVIPRoom() then
        
    elseif self.room:isCommonRoom() then
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
end

function GameProgress:insertVIPRoomRecordByDisband(paixingList)
    local result = {}
    local curScore = {0,0,0,0}
    local operData = self.tempData:getData()
    for idx, player in pairs(self.playerList) do
        local paiXing = {''}
        if paixingList[idx] and (type(paixingList[idx]) == 'string') then
            paiXing = string.split(paixingList[idx], ';')
        end
        local rlt = {
            uid = player.uid, 
            score = curScore[idx],
            paixing = paiXing,
            operData = operData[idx]
            }
        table.insert(result, rlt)
    end
    local record = self.operHistory:getOpHistoryList()
    local ret = self.room:insertVIPRoomRecord(self.roundCount,record,result, operData, {{},{},{},{}})
end

function GameProgress:insertVIPRoomRecord(paixingList, _huCard)
    local result = {}
    local curScore = self.roundScoreList[#self.roundScoreList]
    local operData = self.tempData:getData()
    local paiData = {{},{},{},{}}
    for idx, player in pairs(self.playerList) do
        local paiXing = {''}
        local isHu = false
        if paixingList[idx] and (type(paixingList[idx]) == 'string') then
            paiXing = string.split(paixingList[idx], ';')
            isHu = true
        end
        local rlt = {
            uid = player.uid, 
            score = curScore[idx],
            paixing = paiXing,
            operData = operData[idx]
            }
        paidata = {}
        if isHu then
            paidata.hands = player:getHandCardsCopy()
            paidata.huaCount = #player:getHuaList()
            paidata.pengGang = player:getPileCardsCopy()
            paidata.huCard = _huCard
            paidata.uid = player.uid
        end
        paiData[idx] = paidata
        table.insert(result, rlt)
    end
    -- dump(paiData, ' paiData = ', 6)
    local record = self.operHistory:getOpHistoryList()
    -- self.roundScoreList = {}
    -- LOG_DEBUG('will insert vip room record!')
    local ret = self.room:insertVIPRoomRecord(self.roundCount,record,result, operData, paiData)
    -- local ret = self.room:insertVIPRoomRecord(1, 'test', result)
    --dump(self.roundCount, 'self.roundCount ---------------')
    -- dump(ret, '-- insert room record OK--')
    --dump(self.roundScoreList, '-- roundScoreList-------------- --')
end


function GameProgress:sendTotalScore(_uid)
    local str = ""
    local gapStr = "/"
    for pos = 1, 4 do 
        local player = self.playerList[pos]
        local scores = player:getBaseScores()
        for index, score in pairs(scores) do 
            if index > 1 then
                str =str..gapStr..score
            else
                str = str..score
            end
        end
        str = str..";"
    end

    --body
    local pkg = {}
    pkg.userScore = str
    if nil == _uid then
        self.room:broadcastMsg('vipTotalScoreAH', pkg)
        self.operHistory:addOperHistory('vipTotalScoreAH', pkg)
    else
        self.room:sendMsgToUid(_uid, 'vipTotalScoreAH', pkg)
        self.operHistory:addOperHistory('vipTotalScoreAH', pkg)
    end

end

function GameProgress:fixedZeros(data)
    local temp = {}
    if data ~= nil and type({}) == type(data) then
        for pos, value in pairs(data) do
            if nil ~= value then
                table.insert(temp, 0)
            end
        end
    end
    return temp
end

function GameProgress:addHistoryRoomInfo()
    local pkg = {}
    pkg.totalRound = self.room.fangInfo.RoundCount
    pkg.curRound = self.roundCount

    pkg.ruleDesc = ''
    for _, v in pairs(self.room.fangInfo.RoomRule) do
        if v.IsChecked then
            if v.Text ~= '房主支付' then
                pkg.ruleDesc = pkg.ruleDesc..v.Text..';'
            end
            -- table.insert(pkg.ruleDesc, {v.Text})
        end
    end
    pkg.baseScore = self.room.fangInfo.BaseScore
    pkg.roomId = self.room.fangInfo.RoomPassword
    pkg.gameState = self.room.vipRoomState
    pkg.realRoomId = self.room.roomid
    self.operHistory:addOperHistory('vipRoomInfo', pkg)
end
--eachPlayerCardsNotify 642 {
--    request {
--        OperationSeq 0 : integer
--hand_cards1 1 : *integer
--hand_cards2 2 : *integer
--hand_cards3 3 : *integer
--hand_cards4 4 : *integer
--}
--}
function GameProgress:sendVoteBeforeGameInfo(result)
    if result == 0 then
        return
    end
    for idx, player in pairs(self.playerList) do
        local mgNum = player:getMGNum()
        self.tempData:updateValue(idx, "mingGang", mgNum)
        local agNum = player:getAGNum()
        self.tempData:updateValue(idx, "anGang", agNum)
    end
    -- body
    local pkg = {}
    pkg.OperationSeq = self:getOperationSeq()
    pkg.hand_cards1 = table.copy(self.playerList[1]:getAllHandCards())
    pkg.hand_cards2 = table.copy(self.playerList[2]:getAllHandCards())
    pkg.hand_cards3 = table.copy(self.playerList[3]:getAllHandCards())
    pkg.hand_cards4 = table.copy(self.playerList[4]:getAllHandCards())

    pkg.hand_cards1 = MJConst.transferNew2OldCardList(pkg.hand_cards1)
    pkg.hand_cards2 = MJConst.transferNew2OldCardList(pkg.hand_cards2)
    pkg.hand_cards3 = MJConst.transferNew2OldCardList(pkg.hand_cards3)
    pkg.hand_cards4 = MJConst.transferNew2OldCardList(pkg.hand_cards4)
    pkg.Score = self:getTotalScore()
    pkg.Data = self.tempData:getData()
    pkg.Owner = self.room.fangInfo.OwnerUserId
    pkg.timeValue = os.time()
    self.room:broadcastMsg('voteBeforeGameInfo', pkg)
end

function GameProgress:transferToClientSuit(_suit)
    local suit = -1
    if _suit == 0 then
        suit = 1
    elseif _suit == 1 then
        suit = 3
    elseif _suit == 2 then
        suit = 2
    end
    return suit
end

--- for sync....
function GameProgress:broadCastAbandonSuit(_pos, _suit)
    local clientSuit = {}
    local opSeq = self:getOperationSeq()
    if _pos == nil then
        for pos, value in pairs(self.selectedAbandonedSuit) do
            local pkg = {}
            pkg.OperationSeq = opSeq
            pkg.option = self:transferToClientSuit(value)
            pkg.pos = pos
            self.room:broadcastMsg("setAbandonedSuit", pkg)
            self.operHistory:addOperHistory('setAbandonedSuit', pkg)
        end
    else
        local pkg = {}
        pkg.OperationSeq = opSeq
        pkg.option = self:transferToClientSuit(_suit)
        pkg.pos = _pos
        self.room:broadcastMsg("setAbandonedSuit", pkg)
        self.operHistory:addOperHistory('setAbandonedSuit', pkg)
    end
end

function GameProgress:sendUidCanPlayCards(turn)
    local cards = {}
    if self:isDefinedQ1m() == false then
        return cards
    end
    local player = self.playerList[turn]
    if player == nil then
        return cards
    end
    cards = self:getPlayerFirstCard(turn)

    local pkg = {}
    pkg.OperationSeq = self:getOperationSeq()
    pkg.cards = MJConst.transferNew2OldCardList(cards)
    pkg.uid = player:getUid()
    self.room:sendMsgToUid(player:getUid(), "mustPlayCards", pkg)
    return cards
end

function GameProgress:getPlayerFirstCard(turn)
    local cards = {}
    local player = self.playerList[turn]
    if player == nil then
        return cards
    end
    local aSuit = self.selectedAbandonedSuit[turn]
    local handCards = player:getAllHandCards()
    for _,card in pairs(handCards) do 
        local suit = math.floor(card / MJConst.kMJPointNull)
        if aSuit == suit then
            table.insert(cards, card)
        end
    end
    return cards
end

function GameProgress:broadcastPlayerDataInfo(type, data, pos)
    local pkg = {}
    pkg.OperationSeq = self:getOperationSeq()
    pkg.DataType = type
    pkg.Data = data
    pkg.Pos = pos
    --dump(pkg, "GameProgress:broadcastPlayerDataInfo")
    self.room:broadcastMsg("playerDataInfo", pkg)
    self.operHistory:addOperHistory('playerDataInfo', pkg)
end

function GameProgress:sendPlayersZiMo()
    for pos, player in pairs(self.playerList) do 
        local str = ""
        local wamo, pingmo = player:getZimoNum()
        local str = ""..wamo..";"..pingmo
        print(str.." pos:"..pos)
        self:broadcastPlayerDataInfo(1, str, pos)
    end
end

function GameProgress:showTimer(dir, timeLen)
    local pkg = {}
    pkg.OperationSeq = self:getOperationSeq()
    pkg.Direction = dir or -1
    pkg.Time = timeLen or 10
    self.room:broadcastMsg("timerShow", pkg)
end

function GameProgress:isDefinedQ1m()
    if self.roomRuleMap.mas_playrule_q1m == true then
        return true
    else
        return false
    end
end

function GameProgress:calcZoomFan()
    local zoomFan = 1
    local tbZooms = {
        ["mas_extrarule1_5d"] = 1,
        ["mas_extrarule1_10d"] = 2,
        ["mas_extrarule1_25d"] = 5,
        ["mas_extrarule1_50d"] = 10,
        ["mas_extrarule1_100d"] = 20,
    }
    for name, num in pairs(tbZooms) do 
        if self.roomRuleMap[name] == true then
            zoomFan = num
            break
        end
    end
    return zoomFan
end

return GameProgress
