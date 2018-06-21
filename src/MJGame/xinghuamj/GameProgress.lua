-- 2016.9.26 ptrjeffrey 
-- 游戏流程文件
-- 包含所有逻辑和数据,以及状态
local MJConst = require("mj_core.MJConst")
local PlayerGrabMgr = require("mj_core.PlayerGrabMgr")
local MJWall = require("mj_core.MJWall")
local MJPlayer = require("XHMJPlayer")
local MJRiver  = require("mj_core.MJRiver")
local OperHistory = require("mj_core.MJOpHistory")

-- 游戏状态模块
local WaitBegin = require("game_state.WaitBegin")
local GameBegin = require("game_state.GameBegin")
local GamePlaying = require("game_state.GamePlaying")
local GameEnd = require("game_state.GameEnd")
local TestCase = require('game_state.TestCase')
local CTempData = require(".tempData")
-- 机器人出牌分析类
local MJAnalys   = require("MJCommon.basemjanalys")

local GameProgress = class("GameProgress")

local kHuaGangMoney = 10    -- 花杠，扣其他玩家花数

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
    self.tianTing = false
    self.fengQuan = 0
    self.kHuaGangType = 0
    self.cutUserList = {}               -- 存储的是玩家的ID
    self.roundGangScoreList = {} -- 每局的杠分

    local wallConfig = {                 --牌墙配置
        4, 4, 4, 4, 4, 4, 4, 4, 4,
        4, 4, 4, 4, 4, 4, 4, 4, 4,
        4, 4, 4, 4, 4, 4, 4, 4, 4,
        4, 4, 4, 4, 4, 4, 4,
        1, 1, 1, 1, 1, 1, 1, 1,
        0, 0, 0, 0, 0
    }
    self.mjWall = MJWall.new(wallConfig)    -- 牌墙类
    self.playerList = {}                    -- 玩家列表
    self.riverCardList = {}                 -- 河牌列表
    self.huaList = {}
    for i = MJConst.Zi5, MJConst.Hua8 do
        table.insert(self.huaList, i)
    end
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
    self.roundCount = 1
    self.roundScoreList = {}   -- 每局的分数
    self.roomRuleMap = {
        ['xh_playrule_5huah'] = false,  -- 需5硬花
        ['xh_playrule_dapaih'] = false, -- 需大胡
        ['xh_extrarule1_jhy'] = false,  -- 进园子
        ['xh_extrarule2_100sx'] = false, -- 100
        ['xh_extrarule2_300sx'] = false,  -- 300
        ['xh_extrarule2_500sx'] = false,  -- 500
        ['xh_extrarule1_jd'] = false,   -- 仅打
        ['xh_extrarule2_100fd'] = false, -- 100
        ['xh_extrarule2_300fd'] = false,  -- 300
        ['xh_extrarule2_wx'] = false,  -- 0
    }

    -- 胡牌限制
    self.huaLimit = false
    self.daHuLimit = false
    -- 进园子
    self.isJinYuan = false
    self.yScore = 100
    -- 仅打
    self.isJinDa = false
    self.jScore = 0
    self:createGameRule()

    for i=1, self.maxPlayerCount do
        self.playerList[i]:setLeftMoney(self.yScore)
        self.playerList[i]:setLimitMoney(self.jScore)
    end

    self.tempData = CTempData.new(self.maxPlayerCount)
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
        -- 初始化淌打的限制分
        self.playerList[i]:setLimitMoney(self.jScore)
    end
    self.operHistory:clear()
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

function GameProgress:addFengQuanCount()
    self.fengQuan = self.fengQuan + 1

    local huaList = {}
    for i = MJConst.Zi5, MJConst.Hua8 do
        table.insert(huaList, i)
    end

    if self.fengQuan > 16 then
        self.fengQuan = self.fengQuan - 16
    end

    if self.fengQuan <= 4 then
        table.insert(huaList, MJConst.Zi1)
    elseif self.fengQuan <= 8 then
        table.insert(huaList, MJConst.Zi2)
    elseif self.fengQuan <= 12 then
        table.insert(huaList, MJConst.Zi3)
    elseif self.fengQuan <= 16 then
        table.insert(huaList, MJConst.Zi4)
    end
    for i=1, self.maxPlayerCount do
        self.playerList[i]:setConstHuaList(huaList)
    end

    self:sendFengQuanInfo()

end

function GameProgress:sendFengQuanInfo(uid)
    if self.fengQuan ~= 0 then
        local pkg = {}
        pkg.fType = self.fengQuan
        self.operHistory:addOperHistory("sendFengQuanInfo", pkg)

        if uid ~= nil then
            self.room:sendMsgToUid(uid, 'sendFengQuanInfo', pkg)
        else
            self.room:broadcastMsg('sendFengQuanInfo', pkg)
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
        if pkg.curRound > pkg.totalRound then
            pkg.curRound = pkg.totalRound
        end
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

function GameProgress:getRoundScore()
    local curList = self.roundScoreList[self.roundCount]
    if curList == nil then
        return {0, 0, 0, 0}
    else
        return curList
    end
end

function GameProgress:getRoundGangScore()
    local curList = self.roundGangScoreList[self.roundCount]
    if curList == nil then
        return {0, 0, 0, 0}
    else
        return curList
    end
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
    -- dump(tipNodes, ' tipsNodes = ')
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
    -- if not _noSync then
    self:sendCheckCards(_pos)
    -- end
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
        local tbMoney = {0,0,0,0}
        local siDelMoney = -kHuaGangMoney   * self.unitCoin
        -- if self.isBiXiaHu then
        --     siDelMoney = siDelMoney + siDelMoney
        -- end
        if self.isJinYuan then
            for i = 1, self.maxPlayerCount do
                if i ~= _pos then
                    -- 钱不够付的时候，付掉身上所有的钱
                    if self.playerList[i]:getLeftMoney() + siDelMoney < 0 then
                        tbMoney[i] = -self.playerList[i]:getLeftMoney()
                    else
                        tbMoney[i] = siDelMoney
                    end
                    -- 减负数=加正数
                    tbMoney[_pos] = tbMoney[_pos] - tbMoney[i]
                end
            end
        else
            for i = 1, self.maxPlayerCount do
                if i ~= _pos then
                    if self.jScore > 0 and self.playerList[i]:getLimitMoney() + siDelMoney < 0 then
                        tbMoney[i] = -self.playerList[i]:getLimitMoney()
                    else
                        tbMoney[i] = siDelMoney
                    end
                    -- 减负数=加正数
                    tbMoney[_pos] = tbMoney[_pos] - tbMoney[i]
                end
            end
        end
        --- send money 
        -- self:broadcastMsgHuaGangNumNotify(_pos, _num, siAddMoney)
        self:addRoundGangScore(tbMoney)
        self:updatePlayersMoney(tbMoney, "花杠立即结算")
        self.hasHuaGang = true
        self:broadCastMsgUpdatePlayerData()
    end
end

-- 杠分
function GameProgress:addRoundGangScore(scoreMap)
    local curList = self.roundGangScoreList[self.roundCount]
    for i = 1, self.maxPlayerCount do
        if scoreMap[i] == nil then
            scoreMap[i] = 0
        end
    end
    if self.isJinDa then
        -- 紧打更改上线分
        if self.jScore > 0 then
            for i=1,self.maxPlayerCount do
                self.playerList[i]:addLimitMoney(scoreMap[i])
            end
        end
    end
    if curList == nil then
        self.roundGangScoreList[self.roundCount] = table.copy(scoreMap)
    else
        for idx, v in pairs(curList) do
            curList[idx] = curList[idx] + scoreMap[idx]
        end
    end
    -- dump(self.roundGangScoreList[self.roundCount], ' gang total ')
    -- dump(scoreMap, ' gang cur')
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

function GameProgress:createGameRule()
    for _, v in pairs(self.room.fangInfo.RoomRule) do
        if self.roomRuleMap[v.Name] ~= nil then
            self.roomRuleMap[v.Name] = v.IsChecked

            if v.IsChecked then
                if v.Name == 'xh_extrarule2_100fd' or 
                    v.Name == 'xh_extrarule2_300fd' then
                    -- self.jScore = tonumber(v.Text)
                elseif v.Name == 'xh_extrarule2_100sx' or
                    v.Name == 'xh_extrarule2_300sx' or
                    v.Name == 'xh_extrarule2_500sx' then
                    -- self.yScore = tonumber(v.Text)
                elseif v.Name == 'xh_extrarule2_wx' then
                    -- self.jScore = 0
                elseif v.Name == 'xh_playrule_5huah' then
                    self.huaLimit = true
                    self.daHuLimit = false
                elseif v.Name == 'xh_playrule_dapaih' then
                    self.daHuLimit = true
                    self.huaLimit = false
                elseif v.Name == 'xh_extrarule1_jhy' then
                    self.isJinYuan = true
                    self.isJinDa = false
                elseif v.Name == 'xh_extrarule1_jd' then
                    self.isJinDa = true
                    self.isJinYuan = false
                end
            end

        end
    end
end

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
end

-- 这个scoreMap是「用户位置，分数」
function GameProgress:addRoundScore(scoreMap)
    local curList = self.roundScoreList[self.roundCount]
    for i = 1, self.maxPlayerCount do
        if scoreMap[i] == nil then
            scoreMap[i] = 0
        end
    end

    if self.isJinYuan then
        if curList == nil then
            self.roundScoreList[self.roundCount] = table.copy(scoreMap)
        else
            for idx, v in pairs(curList) do
                curList[idx] = curList[idx] + scoreMap[idx]
            end
        end
        -- 更新每个玩家剩余分数
        for i = 1, self.maxPlayerCount do
            self.playerList[i]:addLeftMoney(scoreMap[i])
            if self.playerList[i]:getLeftMoney() < 0 then
                LOG_DEBUG('---- jyz player score < 0 pos = '..i)
                self.playerList[i]:setLeftMoney(0)
            end
        end
    else
        if curList == nil then
            self.roundScoreList[self.roundCount] = table.copy(scoreMap)
        else
            for idx, v in pairs(curList) do
                curList[idx] = curList[idx] + scoreMap[idx]
            end
        end
        -- 更新每个玩家剩余分数
        -- for i = 1, self.maxPlayerCount do
        --     self.playerList[i]:addLimitMoney(scoreMap[i])
        --     if self.playerList[i]:getLimitMoney() < 0 then
        --         if self.jScore > 0 then 
        --             LOG_DEBUG('---- ckt player score < 0 pos = '..i)
        --             self.playerList[i]:setLimitMoney(0)
        --         end
        --     end
        -- end
    end
    self:broadcastJYZList()
end

-- 进园子的名单
function GameProgress:broadcastJYZList(uid)
    local pkg = {}
    pkg.posList = {}
    pkg.moneyList = {}
    if self.isJinYuan then
        for i = 1, self.maxPlayerCount do
            table.insert(pkg.moneyList, self.playerList[i]:getLeftMoney())
            if self.playerList[i]:getLeftMoney() <= 0 then
                table.insert(pkg.posList, i)
            end
        end
    else
        pkg.moneyList = self:getTotalScore()
    end
    self.operHistory:addOperHistory("JYZNotifyXHMJ", pkg)
    if uid ~= nil then
        self.room:sendMsgToUid(uid, 'JYZNotifyXHMJ', pkg)
    else
        self.room:broadcastMsg('JYZNotifyXHMJ', pkg)
    end
end

function GameProgress:commitTotalScore()
    local totalScore = self:getTotalScore()
end

function GameProgress:getTotalScore()
    local totalScore = {0, 0, 0, 0}
    if self.isJinYuan then
        for i = 1, #self.playerList do
            totalScore[i] = self.playerList[i]:getLeftMoney()
        end
    else
        for _, curScore in pairs(self.roundScoreList) do
            for i = 1, #curScore do 
                totalScore[i] = totalScore[i] + curScore[i]
            end
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
    if isbegin then
        if self.roundCount > self.room.fangInfo.RoundCount then
            ret = true
        end
    else
        if self.roundCount >= self.room.fangInfo.RoundCount then
            ret = true
        end
    end
    -- 进园子
    if self.isJinYuan then
        local below0Cnt = self:getJYZCount()
        if below0Cnt >= 2 then
            ret = true
        end
    end
    if ret then
        self.room:updateFangStatus(kVipRoomState.gameover)
    end
    return ret
end

function GameProgress:getJYZCount()
    local below0Cnt = 0
    if self.isJinYuan then
        local totalScore = self:getTotalScore()
        for _, score in pairs(totalScore) do
            if score <= 0 then
                below0Cnt = below0Cnt + 1
            end
        end
    end
    return below0Cnt
end

-- 苏州麻将没有四张相同牌判断
-- function GameProgress:prevPlayerPos(pos)
--     local ret = (pos + self.maxPlayerCount - 1) % self.maxPlayerCount
--     if ret == 0 then
--         ret = 4
--     end
--     return ret
-- end

--- 更新玩家数据库的钱数
function GameProgress:updatePlayersMoney(_tbMoney, _strJiesuan)
    if self.room:isVIPRoom() then
        self:addRoundScore(_tbMoney)
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

-- 罚分的消息
function GameProgress:broadcastFaFen(type, pos)
    local pkg = {}
    pkg.fafenType = type
    pkg.pos = pos
    self.operHistory:addOperHistory("fafenNotifyXHMJ", pkg)
    self.room:broadcastMsg('fafenNotifyXHMJ', pkg)
end

function GameProgress:sendTotalScore(_uid)
    -- body
    local pkg = {}
    pkg.userScore = self:getTotalScore()
    if nil == _uid then
        self.room:broadcastMsg('vipTotalScore', pkg)
    else
        self.room:sendMsgToUid(_uid, 'vipTotalScore', pkg)
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
    if pkg.curRound > pkg.totalRound then
        pkg.curRound = pkg.totalRound
    end
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

return GameProgress
