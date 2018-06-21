-- 2016.9.26 ptrjeffrey 
-- 游戏流程文件
-- 包含所有逻辑和数据,以及状态

local MJConst = require("mj_core.MJConst")
local PlayerGrabMgr = require("mj_core.PlayerGrabMgr")
local MJWall = require("mj_core.MJWall")
local MJPlayer = require("HNMJPlayer")
local MJRiver  = require("mj_core.MJRiver")
local OperHistory = require("mj_core.MJOpHistory")

-- 游戏状态模块
local WaitBegin = require("game_state.WaitBegin")
local GameBegin = require("game_state.GameBegin")
local GamePlaying = require("game_state.GamePlaying")
local ShangGa = require("game_state.ShangGa")
local GameEnd = require("game_state.GameEnd")
local TestCase = require('game_state.TestCase')
local CTempData = require(".tempData")
-- 机器人出牌分析类
local MJAnalys   = require("MJCommon.basemjanalys")
local BaoMgr = require(".BaoMgr")
local GameProgress = class("GameProgress")

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
    self.isFaFen = false
    self.lastPlayCard = MJConst.kCardNull  -- 刚刚打出的牌
    self.cutUserList = {}               -- 存储的是玩家的ID
    self.kHuaGangType = 0
    self.kSiTongType = 1
    self.kSiGenType = 2

    self.lastGaList = {0,0,0,0}
    self.gaFenList = {0,1,2,3,5}
    self.gaList = {-1, -1, -1, -1}

    local wallConfig = {                 --牌墙配置
        4, 4, 4, 4, 4, 4, 4, 4, 4,
        4, 4, 4, 4, 4, 4, 4, 4, 4,
        4, 4, 4, 4, 4, 4, 4, 4, 4,
        4, 4, 4, 4, 4, 4, 4,
        1, 1, 1, 1, 1, 1, 1, 1,
    }
    self.mjWall = MJWall.new(wallConfig)    -- 牌墙类
    self.playerList = {}                    -- 玩家列表
    self.riverCardList = {}                 -- 河牌列表
    self.huaList = {}
    -- self.gaList = {}
    self.baoMgr = BaoMgr.new() -- 包牌列表
    for i = MJConst.Hua1, MJConst.Hua8 do
        table.insert(self.huaList, i)
    end

    for i=1, self.maxPlayerCount do
        local player = MJPlayer.new(14, i)
        player:setConstHuaList(self.huaList)
        local river = MJRiver.new()
        self.playerList[i] = player
        self.riverCardList[i] = river
        -- self.gaList[i] = 0
    end
    
    -- dump(self.playerList, "分配玩家")
    -- 游戏状态
    self.kWaitBegin   = 1
    self.kShangGa     = 2
    self.kGameBegin   = 3
    self.kGamePlaying = 4
    self.kGameEnd     = 5
    self.kTestCase    = 6   -- 单元测试模块

    self.gameStateList = {
        [self.kWaitBegin] = WaitBegin.new(self, self.kWaitBegin),
        [self.kShangGa] = ShangGa.new(self, self.kShangGa),
        [self.kGameBegin] = GameBegin.new(self, self.kGameBegin),
        [self.kGamePlaying] = GamePlaying.new(self, self.kGamePlaying),
        [self.kGameEnd] = GameEnd.new(self, self.kGameEnd),
        [self.kTestCase] = TestCase.new(self, self.kTestCase)
    }

    self.curGameState = self.gameStateList[1];
    self.roundCount = 1
    self.roundScoreList = {}   -- 每局的分数
    self.roundGangScoreList = {} -- 每局的杠分
    self.roundFaScoreList = {}  --每局的罚分
    self.roundHuaHuScoreList = {} -- 每局的花胡分
    self.roomRuleMap = {
       ['hn_playrule_youfan'] = false,   -- 有番
       ['hn_playrule_wufan'] = false,   -- 无番
       ['hn_extrarule1_zx'] = false,   -- 庄闲
       ['hn_extrarule1_lz'] = false,   -- 连庄
       ['hn_extrarule1_ljzf'] = false,   -- 流局算分
       ['hn_extrarule1_hh'] = false,   -- 花胡
       ['hn_extrarule1_fgj'] = false,   -- 防勾脚
       ['hn_extrarule1_sg'] = false,   -- 上嘎
       ['hn_playrule2_zysg'] = false,   -- 自由上嘎
    }
    self.isYouFan = false   -- 是不是有番
    self.isZhuangXian = false   -- 庄闲
    self.isLiangZhuang = false
    self.isLiuJuSuanFen = false
    self.isHuaHu = false
    self.isFangGouJiao = false  -- 
    self.isShangGa = false  -- 是不是比下胡
    self.isFreeGa = false
    self.bankerCount = 1  -- 连庄次数
    self.tempData = CTempData.new(self.maxPlayerCount)
    self:createGameRule()
    -- self.curGameState = self.gameStateList[5];  -- 测试用
    self.curGameState:onEntry()  -- 进入到当前的游戏状态
end

function GameProgress:clear()
    -- LOG_DEBUG("GameProgress:clear")
    self.operationSeq = 0
    self.turn   = -1
    self.justGangPos = -1
    self.playedCount = 0
    self.lastOper = MJConst.kOperNull
    self.isZiMo = false
    self.isFaFen = false
    -- self.lastGaList = {0,0,0,0}
    self.gaList = {-1, -1, -1, -1}

    self.baoMgr:clear()
    for i = 1, self.maxPlayerCount do
        self.playerList[i]:reset()
        self.riverCardList[i]:clear()
        -- self.gaList[i] = 0
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
            dump(self.nicknameList, 'self.nicknameList = ')
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
                    table.insert(roomPlayers, v:getUid())
                end
            end
            self.room:updateFangStatus(kVipRoomState.playing, roomPlayers)
        end
        self:sendVIPRoomInfo()
        self.room:deleteAutoDisband()
    end
    self.curGameState:onExit()
    LOG_DEBUG('gameStart curRound'..self.roundCount)
	self.curGameState = self.gameStateList[self.kShangGa]
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
    -- LOG_DEBUG('-- GameProgress:onDisband() 2--')
	self.curGameState = self.gameStateList[1];
    -- LOG_DEBUG('-- GameProgress:onDisband() 3--')
    self.curGameState:onEntry()
    -- LOG_DEBUG('-- GameProgress:onDisband() 4--')
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

function GameProgress:broadcastBaoPaiType(pos, baoType)
    if baoType == 1 then
        self.isFaFen = true
    end
    local pkg = {}
    pkg.baoType = baoType
    pkg.pos = pos
    self.operHistory:addOperHistory("baoTypeNotify", pkg)
    self.room:broadcastMsg("baoTypeNotify", pkg)
end

-- 可以上的嘎
function GameProgress:broadcastCanShangGa(pos, value)
    local pkg = {}
    pkg.pos = pos
    pkg.value = value
    self.room:sendMsgToSeat(pos, 'canShangGaNotify', pkg)
end

-- 玩家上的嘎
function GameProgress:broadcastPlayerShangGa(isGa, pos, value)
    local pkg = {}
    pkg.isGa = isGa
    pkg.value = value
    pkg.pos = pos
    self.operHistory:addOperHistory("shangGaNotify", pkg)
    self.room:broadcastMsg("shangGaNotify", pkg)
end

function GameProgress:huaGangNumNotify(_operSeq,_pos, _num, _money)
    local pkg = {}
    pkg.Pos = _pos
    pkg.Num = _num
    pkg.Money = _money
    pkg.OperationSeq =  _operSeq
    -- 花杠
    self.operHistory:addOperHistory("huaGangNumNotify", pkg)
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
    pkg.huaList ={{}, {}, {} ,{}}
    for i, player in pairs(self.playerList) do
        local list = player:getHuaListForClient()
        pkg.followers[i] = #list
        pkg.huaList[i].cards = list
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

function GameProgress:broadcastMsgAddPengCards(_seq, _selfPos, _chuPos, _card, baoType)
    local pkg = {}
    pkg.OperationSeq = _seq
    pkg.SelfPos = _selfPos
    pkg.ChuPos = _chuPos
    pkg.Card = MJConst.fromNow2OldCardByteMap[_card]
    pkg.baoType = baoType
    self.operHistory:addOperHistory("addPengCards", pkg)
    self.room:broadcastMsg("addPengCards", pkg)
end

function GameProgress:broadcastMsgAddGangCards(_seq, _selfPos, _chuPos, _card, baoType)
    local pkg = {}
    pkg.OperationSeq = _seq
    pkg.SelfPos = _selfPos
    pkg.ChuPos = _chuPos
    pkg.Card = MJConst.fromNow2OldCardByteMap[_card]
    pkg.baoType = baoType
    self.operHistory:addOperHistory("addGangCards", pkg)
    self.room:broadcastMsg("addGangCards", pkg)
end

function GameProgress:broadcastMsgFideGangMoney(_seq, _selfPos, _chuPos, _Coin)
    local pkg = {}
    pkg.OperationSeq = _seq
    pkg.GangSelfPos = _selfPos
    pkg.GangChuPos = _chuPos
    pkg.Money = _Coin
    -- 杠钱
    self.operHistory:addOperHistory("fideGangMoney", pkg)
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


function GameProgress:broadcastFlowerCardCountNotify(_pos, _count, _card)

    local pkg = {}
    pkg.OperationSeq = self:incOperationSeq()
    pkg.Pos = _pos
    pkg.Count = _count
    pkg.card = MJConst.fromNow2OldCardByteMap[_card]
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

function GameProgress:sendMsgTestMJCardTypeSC(_pos, _res, _cards)
    local pkg = {}
    pkg.Res = _res
    pkg.Cards = MJConst.transferNew2OldCardList(_cards)
    self.room:sendMsgToSeat(_pos, "testMJCardTypeSC", pkg)
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
    -- dump(pkg, ' broadCastMsgUpdatePlayerData ')
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
    -- 花杠
    self.operHistory:addOperHistory("huaGangNumNotify", pkg)
    self.room:broadcastMsg("huaGangNumNotify", pkg)
end

--- 增加花杠消息通知
function GameProgress:broadCastMsgFideHuaGangMoney(_pos, _num)
    if _pos then
        local tbMoney = {0,0,0,0}
        local siDelMoney = -10   * self.unitCoin

        for i = 1, self.maxPlayerCount do
            if i ~= _pos then
                tbMoney[i] = siDelMoney
                -- 减负数=加正数
                tbMoney[_pos] = tbMoney[_pos] - tbMoney[i]
            end
        end
        --- send money 
        -- self:broadcastMsgHuaGangNumNotify(_pos, _num, siAddMoney)
        self:addRoundGangScore(tbMoney)
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

function GameProgress:createGameRule()
    for _, v in pairs(self.room.fangInfo.RoomRule) do
        if self.roomRuleMap[v.Name] ~= nil then
            self.roomRuleMap[v.Name] = v.IsChecked
            if v.IsChecked then
                if v.Name == 'hn_playrule_youfan' then
                    self.isYouFan = true
                elseif v.Name == 'hn_extrarule1_zx' then
                    self.isZhuangXian = true
                elseif v.Name == 'hn_extrarule1_lz' then
                    self.isLiangZhuang = true
                elseif v.Name == 'hn_extrarule1_ljzf' then
                    self.isLiuJuSuanFen = true
                elseif v.Name == 'hn_extrarule1_hh' then
                    self.isHuaHu = true
                elseif v.Name == 'hn_extrarule1_fgj' then
                    self.isFangGouJiao = true
                elseif v.Name == 'hn_extrarule1_sg' then
                    self.isShangGa = true
                elseif v.Name == 'hn_playrule2_zysg' then
                    self.isShangGa = true
                    self.isFreeGa = true
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

-- 花胡分
function GameProgress:addRoundHuaHuScore(scoreMap)
    local curList = self.roundHuaHuScoreList[self.roundCount]
    for i = 1, self.maxPlayerCount do
        if scoreMap[i] == nil then
            scoreMap[i] = 0
        end
    end
    if curList == nil then
        self.roundHuaHuScoreList[self.roundCount] = table.copy(scoreMap)
    else
        for idx, v in pairs(curList) do
            curList[idx] = curList[idx] + scoreMap[idx]
        end
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

-- 罚分
function GameProgress:addRoundFaScore(scoreMap)
    local curList = self.roundFaScoreList[self.roundCount]
    for i = 1, self.maxPlayerCount do
        if scoreMap[i] == nil then
            scoreMap[i] = 0
        end
    end
    if curList == nil then
        self.roundFaScoreList[self.roundCount] = table.copy(scoreMap)
    else
        for idx, v in pairs(curList) do
            curList[idx] = curList[idx] + scoreMap[idx]
        end
    end
    -- dump(self.roundFaScoreList[self.roundCount], ' fa total ')
    -- dump(scoreMap, ' fa cur')
end

-- 这个scoreMap是「用户位置，分数」
function GameProgress:addRoundScore(scoreMap)
    local curList = self.roundScoreList[self.roundCount]
    for i = 1, self.maxPlayerCount do
        if scoreMap[i] == nil then
            scoreMap[i] = 0
        end
    end

    if curList == nil then
        self.roundScoreList[self.roundCount] = table.copy(scoreMap)
    else
        for idx, v in pairs(curList) do
            curList[idx] = curList[idx] + scoreMap[idx]
        end
    end
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

function GameProgress:getRoundHuaHuScore()
    local curList = self.roundHuaHuScoreList[self.roundCount]
    if curList == nil then
        return {0, 0, 0, 0}
    else
        return curList
    end
end

function GameProgress:getRoundFaScore()
    local curList = self.roundFaScoreList[self.roundCount]
    if curList == nil then
        return {0, 0, 0, 0}
    else
        return curList
    end
end

function GameProgress:commitTotalScore()
    local totalScore = self:getTotalScore()
end

-- 获取所有局数的总成绩
function GameProgress:getTotalScore()
    local totalScore = {0, 0, 0, 0}
    for _, curScore in pairs(self.roundScoreList) do
        for i = 1, #curScore do 
            totalScore[i] = totalScore[i] + curScore[i]
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

    if ret then
        self.room:updateFangStatus(kVipRoomState.gameover)
    end
    return ret
end

function GameProgress:prevPlayerPos(pos)
    local ret = (pos + self.maxPlayerCount - 1) % self.maxPlayerCount
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
    local curScore = self:getRoundScore()
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
    self.room:broadcastMsg('voteBeforeGameInfo', pkg)
end

function GameProgress:broadcastMsgAddChiCards(_seq, _selfPos, _chuPos, _cards, baoType)
    local pkg = {}
    pkg.OperationSeq = _seq
    pkg.SelfPos = _selfPos
    pkg.ChuPos = _chuPos
    pkg.Card = {}
    pkg.baoType = baoType
    for k, v in pairs(_cards) do
        table.insert(pkg.Card, MJConst.fromNow2OldCardByteMap[v])
    end
    self.operHistory:addOperHistory("addchicards", pkg)
    self.room:broadcastMsg('addchicards', pkg)
end

function GameProgress:getBaseScore(pos)
    local baseScore = 1
    -- 闲庄
    if pos == self.banker then
        if self.isZhuangXian == true then
            baseScore = baseScore + 1
        end
        -- 连庄
        if self.isLiangZhuang == true then
            baseScore = baseScore + self.bankerCount - 1
        end
    end
    return baseScore
end

function GameProgress:addBaoPai(baoType, givePos, doPos)
    self.baoMgr:addBaoPai(baoType, givePos, doPos)
end

function GameProgress:getGaList(pos)
    if self.gaList[pos] == -1 then
        return 0
    else
        return self.gaList[pos]
    end
end

-- 获取花胡类型，0 无，1花胡，2花自摸
function GameProgress:getHuaHuType(pos)
    local player = self.playerList[pos]
    if not player then
        return
    end
    local huaPos = {MJConst.Hua1, MJConst.Hua2, MJConst.Hua3, MJConst.Hua4}
    local huaPos1 = {MJConst.Hua5, MJConst.Hua6, MJConst.Hua8, MJConst.Hua7}
    local huaList = player:getHuaList()
    if self.isHuaHu then
        local cnt = 0
        for k, v in pairs(huaPos) do
            if table.keyof(huaList, v) ~= nil then
                cnt = cnt + 1
            end
        end
        if cnt < 4 then
            cnt = 0
        end
        for k, v in pairs(huaPos1) do
            if table.keyof(huaList, v) ~= nil then
                cnt = cnt + 1
            end
        end
        if cnt >= 4 and cnt < 8 then
            return 1
        elseif cnt == 8 then
            return 2
        end
    else
        local huaCount = #huaList
        if huaCount == 7 then
            return 1
        elseif huaCount == 8 then
            return 2
        end
    end
    return 0
end

function GameProgress:calculateBaoInfo(args, winPos, hasFan)
    self.baoPaiInfo = nil
    -- 检测是否包牌
    local ret = {
        baoType = 0,
        baoPos = 0
    }
    -- 抢杠包牌
    if args.isQiangGang and hasFan == false then
        ret.baoType = 1
        ret.baoPos = args.fangPaoPos
        self.baoPaiInfo = ret
        return
    end

    -- 海底包牌
    local leftWall = self.mjWall:getCanGetCount()
    if leftWall >= 16 and leftWall <= 19 and args.isZiMo == false then
        --放炮的牌是摸到的新牌
        -- if args.huCard == self.playerList[args.fangPaoPos].newCardList[#self.playerList[args.fangPaoPos].newCardList] then
        ret.baoType = 2
        ret.baoPos = args.fangPaoPos
        self.baoPaiInfo = ret
        return
        -- end
    end
    local doItem = self.baoMgr:getDoItem(winPos)
    -- dump(self.baoMgr.list, 'baoList ', 8)
    -- dump(args, ' args = ')
    -- dump(doItem, ' doitem = ')
    if doItem then -- 胡牌的人成3，4道牌
        if doItem.baoType == 3 then  -- 胡牌人成3道牌，若放炮人是喂家，则全包
            if doItem.givePos == args.fangPaoPos then
                ret.baoType = 3
                ret.baoPos = doItem.givePos
                self.baoPaiInfo = ret
                return
            end
        elseif doItem.baoType == 4 then -- 喂包人全包
            ret.baoType = 4
            ret.baoPos = doItem.givePos
            self.baoPaiInfo = ret
            return
        end
    end
     -- 胡牌的人喂了3，4道牌
    local giveList = self.baoMgr:getGiveItemList(winPos)
    local item = nil
    if args.isZiMo then  -- 自摸只有4道
        for k, v in pairs(giveList) do
            if v.baoType == 4 then
                item = v
                break
            end
        end
    else -- 点炮有3道,优先查点炮者，没有再查4道牌
        for k, v in pairs(giveList) do
            if v.doPos == args.fangPaoPos then
                item = v
                break
            end
        end
        if item == nil then
            for k, v in pairs(giveList) do
                if v.baoType == 4 then
                    item = v
                    break
                end
            end
        end
    end
    if item then
        if item.baoType == 3 then
            if args.isZiMo == false then
                ret.baoType = 3
                ret.baoPos = item.doPos
                self.baoPaiInfo = ret
                return
            end
        elseif item.baoType == 4 then
            ret.baoType = 4
            ret.baoPos = item.doPos
            self.baoPaiInfo = ret
            return
        end
    end
end

return GameProgress
