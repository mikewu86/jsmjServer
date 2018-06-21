-- 2016.9.26 ptrjeffrey 
-- 游戏进行状态

local MJConst = require("mj_core.MJConst")
local MJCancelMgr = require("mj_core.MJCancelMgr")
local PlayerGrabMgr = require("mj_core.PlayerGrabMgr")
local GamePlaying = class("GamePlaying")
local CountHuType = require("CountHuType")
local HuTypeConst = require("HuTypeConst")

local kSubStatePlaying = 1

-- 玩家可操作原因
local kNoGrab = 1   ---当前无人和玩家抢牌 操作生效
local kHighPriority = 2 -- 玩家操作优先级比别人高 操作生效
local kTimeOut = 3 ---超时到，系统给予玩家的操作 操作生效

local kWaitPlayTimeOut = 15 * 100 -- default.
local kWaitTingPlayTimeOut = 3 * 100
local kWaitGrabTimeOut = 10 * 100
local kTuoGuanTimeOut  = 3  * 100
local kBuHuaTimeOut    = 0.5 * 100

local kRemoveCards = 0
local kAddCards   = 1

local kSkynetKipTime = 100

-- 及时结算花数
local kAGHua = 3
local kMGHua = 6 -- 面下杠也按照明杠计算
local kOutFourContinueSameCardHua = 6
local kHGHua = 12

function GamePlaying:ctor(gameProgress, stateId)
    self.gameProgress = gameProgress
    self.stateId = stateId
    self.opTimeoutHandle = -99999
    self.curTurn = -1
    self.playerGrabMgr = PlayerGrabMgr.new(gameProgress.maxPlayerCount)
    self.mjCancelMgr = MJCancelMgr.new()
    self.playerCanDoMap = {}
    self.unitCoin = gameProgress.unitCoin
    self.maxPlayerCount = gameProgress.maxPlayerCount
    self.testPlayerNeedCard = {} -- map: key = pos, card = cardbyte.
    self.isQiangGanging = false

    self.countHuType = CountHuType.new()

    kWaitPlayTimeOut = gameProgress.room.roundTime * kSkynetKipTime

end

function GamePlaying:onEntry(args)
    -- self:gotoNextState({isLiuJu = true})
    self.gameProgress.curGameState = self
    self.subState = kSubStatePlaying
    -- 简化变量名
    self.mjWall = self.gameProgress.mjWall
    self.playerList = self.gameProgress.playerList
    -- --dump(self.playerList, "playing player")
    self.operHistory = self.gameProgress.operHistory
    self.riverCardList = self.gameProgress.riverCardList
    --- 设置当前庄家操作
    self.curTurn = self.gameProgress.banker
    self.gameProgress:setCurOperatorPos(self.curTurn)
    self.playerGrabMgr:clear()
    self.mjCancelMgr:clear()
    self.playerCanDoMap = {}
    self.waitPlayHandle = nil   -- 等待玩家出牌超时
    self.waitGrabHandle = nil   -- 等待玩家抢牌超时
    self.isQiangGanging = false -- 是否在抢杠中
    --
    self:checkMyOper(self.curTurn)
    self.OperationTimeOut = self.gameProgress.room.roundTime * 100 --- 发送操作后超时时间
end

-- 检查自己的操作
function GamePlaying:checkMyOper(turn)
    local player = self.playerList[turn]
    if player then
        if false == player:hasNewCard() then
            return nil
        else
            self.playerGrabMgr:clear()
            local operMap = {}   -- 操作和牌的对照
            local operList = {}  -- 纯操作
            local sendOperMap = {}
            -- 出牌
            table.insert(operList, MJConst.kOperPlay)
            operMap[MJConst.kOperPlay] = {}
            local cancel = false
            -- 胡牌
            if player:canSelfHu() or player:canSelfHuQiDui() then
                table.insert(operList, MJConst.kOperHu)
                operMap[MJConst.kOperHu] = {player.newCard}
                cancel = true
            end
            --dump(player.isPrevTing, 'my player.isPrevTing = ')
            --dump(player.isTing, 'my player.isTing = ')
            if not player.isTing then
                -- 听牌
                local canTingNodes = player:getCanTingCards()
                --dump(canTingNodes, ' canTingNodes = ')
                if #canTingNodes > 0 then
                    operMap[MJConst.kOperTing] = canTingNodes
                    table.insert(operList, MJConst.kOperTing)
                    cancel = true
                end
                -- 暗杠
                local anGangCardList = player:getAnGangCardList()
                if #anGangCardList > 0 then
                    table.insert(operList, MJConst.kOperAG)
                    operMap[MJConst.kOperAG] = anGangCardList
                    cancel = true
                end
                -- 面下杠
                local mxGangCardList = player:getMXGangCardList()
                if #mxGangCardList > 0 then
                    table.insert(operList, MJConst.kOperMXG)
                    operMap[MJConst.kOperMXG] = mxGangCardList
                    cancel = true
                end
            end
            -- 取消操作
            if cancel then
                table.insert(operList, MJConst.kOperCancel)
                operMap[MJConst.kOperCancel] = {}
            end
            -- --dump(operList, "check my op operList")
            -- 数据放入可操作玩家
            self.playerGrabMgr:addCanDoItem(turn, operList)
            self.playerGrabMgr:setPos(turn)
            self.playerCanDoMap[turn] = operMap
            -- self.playerCanDoMap[turn].canTingNodes = canTingNodes
            -- send to client
            local tipData = {}
            for k, v in pairs(operMap) do
                if k == MJConst.kOperTing then
                    tipData[k] = {}
                    for k1, v1 in pairs(operMap[MJConst.kOperTing]) do
                        table.insert(tipData[k], v1.playCard)
                    end
                else
                    tipData[k] = table.copy(v)
                end
            end
            -- 计算出胡的牌大概胡多少番
            if operMap[MJConst.kOperTing] then
                -- 备份当前玩家手牌。因为后面要对当前玩家进行操作
                local handCards = player:getHandCardsCopy()
                local newCard = player.newCard
                --dump(handCards, 'handCards = ')
                for _, tingNode in pairs(operMap[MJConst.kOperTing]) do
                    tingNode.fans = {}
                    player:pushNewCardToHand()
                    player:delHandCard(tingNode.playCard)    -- 删除可以出的牌
                    for k1, _new in pairs(tingNode.huCards) do
                        player.newCard = _new
                        self.countHuType:setParams(turn, self.gameProgress, nil, nil, self.isQiangGang)
                        self.countHuType:calculate()
                        table.insert(tingNode.fans, self.countHuType:getTotalFan())
                    end
                    -- 还原当前玩家手牌
                    player.cardList = table.clone(handCards)
                    player.newCard = newCard
                end
            end
            self.gameProgress:sendMsgSetOperationTipCardsNotify(turn, tipData, operMap[MJConst.kOperTing])
            self.playerCanDoMap[turn].operList = operList
            -- --dump(operList, "checkMyOper operList")
            local seq = self.gameProgress:incOperationSeq()
            -- 等待玩家操作
            if self.countHuType.isAutoHu then
                self.gameProgress:deleteTimeOut(self.waitPlayHandle)
                self:doHu(turn, player.newCard)
                return
            else
                self.gameProgress:broadcastMsgPlayerOperationReq(seq, turn, true, MJConst.getOpsValue(operList))
                self.gameProgress:deleteTimeOut(self.waitPlayHandle)
                local timeOut = kWaitPlayTimeOut
                if player.isTing then   -- 听牌玩家出牌时间只有3秒
                    timeOut = kWaitTingPlayTimeOut
                end
                self.waitPlayHandle = self.gameProgress:setTimeOut(kWaitPlayTimeOut,
                function()
                    -- local playCard = MJConst.transferNew2OldCardList[player.newCard]
                    self.waitPlayHandle = nil
                    self:onPlayCard(turn, {card = player.newCard})
                end, nil)
            end
        end
    else
        return nil
    end
end

-- 检查其他人的操作
function GamePlaying:checkOtherOper(turn, byteCard)
    local hasGrab = false
    self.playerGrabMgr:clear()
    self.playerGrabMgr:setPos(turn)  -- 当前被抢牌的位置

    local pos = turn
    local autoHuPos = nil
    for i = 1, self.gameProgress.maxPlayerCount - 1 do  -- 仅允许除出牌人以外的人抢牌
        pos = self.gameProgress:nextPlayerPos(pos)
        local operMap = {}   -- 操作和牌的对照
        local operList = {}  -- 纯操作
        local player = self.playerList[pos]
        local cancel = false
        -- 胡牌 之前有漏胡过的就不能再胡同一张牌了
        if not self.mjCancelMgr:isCancelOper(pos, MJConst.kOperHu, byteCard) then
            if true == player:canHu(byteCard) or true == player:canHuQiDui(byteCard) then
                --LOG_DEBUG("can hu")
                if self.countHuType.isAutoHu then
                    autoHuPos = pos
                end
                table.insert(operList, MJConst.kOperHu)
                operMap[MJConst.kOperHu] = {byteCard}
                cancel = true
            end
        end
        --dump(player.isPrevTing, 'otherOper player.isPrevTing = ')
        --dump(player.isTing, 'otherOper player.isTing = ')
        if not player.isTing then
            -- 明杠
            if player:canGang(byteCard) then
                --LOG_DEBUG("can gang")
                table.insert(operList, MJConst.kOperMG)
                operMap[MJConst.kOperMG] = {byteCard}
                cancel = true
            end
            -- 碰 之前有漏碰过的就不能再胡同一张牌了
            if not self.mjCancelMgr:isCancelOper(pos, MJConst.kOperPeng, byteCard) then
                if player:canPeng(byteCard) then
                    --LOG_DEBUG("can peng")
                    table.insert(operList, MJConst.kOperPeng)
                    operMap[MJConst.kOperPeng] = {byteCard}
                    cancel = true
                end
            end
            -- 吃
            if pos == self.gameProgress:prevPlayerPos(turn) then
                local chiTypeList = player:getCanChiType(byteCard)
                if #chiTypeList > 0 then
                    for k, chiType in pairs(chiTypeList) do
                        table.insert(operList, chiType)
                        operMap[chiType] = {byteCard}
                    end
                    cancel = true
                end
            end
        end
        -- 取消操作
        if cancel then
            --LOG_DEBUG("can cancel")
            table.insert(operList, MJConst.kOperCancel)
            operMap[MJConst.kOperCancel] = {}
        end
        -- 数据放入可操作玩家
        self.playerGrabMgr:addCanDoItem(pos, table.copy(operList))
        self.playerCanDoMap[pos] = operMap
        -- send to client 需要拷贝一份数据出来，以免影响原来的数据
        local tipData = {}
        for k, v in pairs(operMap) do
            tipData[k] = table.copy(v)
        end
        self.playerCanDoMap[pos].operList = operList
        -- 先显示玩家可操作的动作
        if #operList > 1 then
            self.gameProgress:sendMsgSetOperationTipCardsNotify(pos, tipData)
            local seq = self.gameProgress:incOperationSeq()
            self.gameProgress:broadcastMsgPlayerOperationReq(seq, pos, true, MJConst.getOpsValue(operList))
            hasGrab = true
        end
    end
    if true == hasGrab then
        self.gameProgress:deleteTimeOut(self.waitGrabHandle)
        self.waitGrabHandle = self.gameProgress:setTimeOut(kWaitGrabTimeOut,
        function()
            self:grabEnd()
        end, nil)
    end
    return hasGrab, autoHuPos
end

-- 拿新牌
function GamePlaying:getNewCard()

end


function GamePlaying:onExit()
end

function GamePlaying:onPlayerComin(_player)
end

function GamePlaying:onPlayerLeave(uid)
end

function GamePlaying:onPlayerReady()
end

function GamePlaying:onUserCutBack(_pos)
    local playingPlayers = self.gameProgress.room.playingPlayers
    local playerList = {}
    local riverList = self.gameProgress.riverCardList
    local pkg = {}
    for uid, player in pairs(playingPlayers) do 
        local pos = player:getDeskPos()
        playerList[pos] = player
    end
    local playerList2 = self.gameProgress.playerList
    ---init need info
    pkg.zhuangPos = self.gameProgress.banker
    pkg.gameStatus = self.subState
    pkg.myPos = _pos
    pkg.roundTime = self.gameProgress.room.roundTime
    pkg.grabTime =  kWaitGrabTimeOut / 100
    --1. playerData
    pkg.Player1 = playerList[1]:getPlayerInfo()
    pkg.Player2 = playerList[2]:getPlayerInfo()
    -- 2. handCards
    pkg.handCards1 = playerList2[1]:getCardsForNums()
    pkg.handCards2 = playerList2[2]:getCardsForNums()
    --3.getFlowerCnt
    pkg.flowerCardsCount1 = #playerList2[1]:getHuaList()
    pkg.flowerCardsCount2 = #playerList2[2]:getHuaList()
    --4.outCards --- MJRiver 
    pkg.outCards1 = MJConst.transferNew2OldCardList(riverList[1]:getRiverCardsList())
    pkg.outCards2 = MJConst.transferNew2OldCardList(riverList[2]:getRiverCardsList())
    --5.pengcards -- 
    pkg.pengGang1 = playerList2[1]:getPileListForClient()
    pkg.pengGang2 = playerList2[2]:getPileListForClient()
    self.gameProgress:sendMsgToUidNotifyEachPlayerCards(_pos, pkg)
    ---7. 剩余牌数
    self.gameProgress:broadCastWallDataCountNotify()
    -- 8 当前已听牌玩家
    local pkg = {}
    pkg.OperationSeq = self.gameProgress:getOperationSeq()
    pkg.posList = {}
    for k, player in pairs(playerList2) do
        if player.isTing then
            table.insert(pkg.posList, player.myPos)
        end
    end
    self.gameProgress:sendMsgToSeat(_pos, "tingPos", pkg)
end

function GamePlaying:gotoNextState(args)
    self.gameProgress:deleteTimeOut(self.waitPlayHandle)
    self.gameProgress:deleteTimeOut(self.waitGrabHandle)
    self.gameProgress.gameStateList[self.gameProgress.kGameEnd]:onEntry(args)
end

-- 来自客户端的消息
-- 判定玩家是否有此操作权限
function GamePlaying:onClientMsg(_pos, _pkg)
    -- --dump(_pkg, "onClientMsg")
    local opPlayer = self.gameProgress.playerList[_pos]
    if MJConst.kOperPlay == _pkg.operation then
	    _pkg.card = MJConst.fromOld2NowCardByteMap[_pkg.card_bytes]
        self:onPlayCard(_pos, _pkg)
    elseif MJConst.kOperSyncData == _pkg.operation then -- 同步
        self:playerOpeartionSyncData(_pos)
    elseif MJConst.kOperTestNeedCard == _pkg.operation then --- 测试阶段玩家要牌
        self:onTestNeedCard(_pos, _pkg.card_bytes)
    else  -- 胡碰杠取消操作
        _pkg.card = MJConst.fromOld2NowCardByteMap[_pkg.card_bytes]
        self:onGrabCard(_pos, _pkg)
    end
end

--- private funtion
function GamePlaying:timeOutHandle()
    ----LOG_DEBUG("timeout to continue.")
end

function GamePlaying:deleteTimeOut(_handle)
    self.gameProgress:deleteTimeOut(_handle)
end


function GamePlaying:isPlayerOpExist(_player, _pos, _pkg)
    local bTfRet, newOp = _player:transferOld2New(_pkg.operation)
    if false == bTfRet then
        ----LOG_DEBUG("_pkg.operation invalid")
        return false
    end
    if nil ~= _pkg.card_bytes then
        _pkg.card_bytes = MJConst.fromOld2NowCardByteMap[_pkg.card_bytes]
    end

    local bRet, opType = _player:checkOperaiton(newOp, _pkg.card_bytes)
    if false == bRet then
        ----LOG_DEBUG(string.format("player invalid op:%d  pos:%d", newOp, _pos))
        return false
    end 
    _pkg.operation = opType
    return true
end

-- 胡碰杠取消操作
function GamePlaying:onGrabCard(_pos, _pkg)
    ----LOG_DEBUG("GamePlaying:onGrabCard")
    local pkg = _pkg
    local pos = _pos
    local oper = pkg.operation
    local byteCard = pkg.card

    --dump(_pkg, "onGrabCard _pkg")
    if not self.playerGrabMgr:hasOper(pos, oper) then
        ----LOG_DEBUG('-- 玩家没有操作权限 --'..pos)
        -- --dump(pkg)
        return
    end
    local canDoMap = self.playerCanDoMap[pos]
    -- --dump(canDoMap, "onGrabCard canDoMap")
    if canDoMap and canDoMap[oper] then
        if oper == MJConst.kOperTing then  -- 听牌单独处理
            self.playerList[pos]:doPrevTing()
            self.playerGrabMgr:playerDoGrab(pos, oper, 1)
            -- 发送消息
            local seq = self.gameProgress:getOperationSeq()
            self.gameProgress:broadcastTing(seq, pos, true)
            return
        end
        if oper == MJConst.kOperCancel then
            self.playerGrabMgr:playerDoGrab(pos, oper, 1)
            -- 增加玩家的取消抢牌,若是自摸则不处理
            if not self.playerList[pos]:hasNewCard() then
                for _oper, _cardList in pairs(canDoMap) do
                    if _oper == MJConst.kOperPeng or
                       _oper == MJConst.kOperHu then
                        self.mjCancelMgr:addCancelOper(pos, _oper, _cardList[1])
                    end
                end
            end
        else
            if table.keyof(canDoMap[oper], byteCard) ~= nil then
                self.playerGrabMgr:playerDoGrab(pos, oper, byteCard)
                ----LOG_DEBUG("do grab ok.")
            else
                ----LOG_DEBUG("player no has this card:")
                return
            end
        end
        if not self.playerGrabMgr:needWait() then
            ----LOG_DEBUG("exec op.")
            self:grabEnd()            
        else
            ----LOG_DEBUG("waiting... oper.")
        end

    else
        ----LOG_DEBUG("player no this oper:"..oper)
        -- --dump(canDoMap, "canDoMap")
    end
end

-- 玩家点了听以后是否出了无效的牌
function GamePlaying:isPlayCanTingCard(pos, byteCard)
    local canDoMap = self.playerCanDoMap[pos]
    local tingNodes = canDoMap[MJConst.kOperTing]
    --dump(canDoMap, ' isPlayCanTingCard canDoMap = ')
    if not tingNodes then
        return false
    end
    for k, tingNode in pairs(tingNodes) do
        if tingNode.playCard == byteCard then
            return true
        end
    end
    return false
end

-- 出牌
function GamePlaying:onPlayCard(_pos, _pkg)
    ----LOG_DEBUG("on PlayCard")
    local pkg = _pkg
    local pos = _pos
    -- if pkg.OperationSeq ~= self.gameProgress:getOperationSeq() then
    --     ----LOG_DEBUG('-- 玩家的出息索引不正确 --')
    --     return
    -- end
    if not self.playerGrabMgr:hasOper(pos, MJConst.kOperPlay) then
        ----LOG_DEBUG('-- 玩家没有出牌权限 --'..pos)
        return
    end
    local player = self.playerList[pos]
    if not player then
        ----LOG_DEBUG('-- 出牌玩家不存在 --')
        return
    end
    local byteCard = pkg.card
    --dump(player.isPrevTing, 'player.isPrevTing = ')
    --dump(player.isTing, 'player.isTing = ')
    if player.isPrevTing and not player.isTing then
            player:doTing()
            -- 发送消息
            local seq = self.gameProgress:getOperationSeq()
            self.gameProgress:broadcastTing(seq, pos, false)
        if not self:isPlayCanTingCard(_pos, byteCard) then
            local canDoMap = self.playerCanDoMap[_pos]
            local tingNodes = canDoMap[MJConst.kOperTing]
            byteCard = tingNodes[1].playCard
        end
    elseif player.isTing then   -- 听牌玩家只能出新牌
        if byteCard ~= player:getNewCard() then
            byteCard = player:getNewCard()
        end
    end
    if not player:doPlayCard(byteCard) then
        ----LOG_DEBUG('-- 玩家出牌出错 --'..byteCard)
        -- --dump(player.cardList)
        -- --dump(player.newCard)
        return
    end
    self.gameProgress:deleteTimeOut(self.waitPlayHandle)
    self.playerGrabMgr:playerDoGrab(pos, MJConst.kOperPlay, byteCard)
    self.playerCanDoMap[pos] = {}
    self.riverCardList[pos]:pushCard(byteCard)
    local seq = self.gameProgress:incOperationSeq()
    self.gameProgress:opHandCardNotify(seq, pos, {pkg.card}, kRemoveCards)
    self.gameProgress:broadCastMsgOpOnDeskOutCard(seq, kAddCards, pos, pkg.card)


    -- 判断其他玩家是否可以操作
    local hasGrab, autoHuPos = self:checkOtherOper(pos, byteCard)
    if not hasGrab then  -- 继续发牌
        ----LOG_DEBUG("继续发牌")
        -- self.playerGrabMgr:clear()
        self:giveNewCard(self.gameProgress:nextPlayerPos(pos))
    else  -- 等待抢牌
        if autoHuPos ~= nil then
            self:doHu(autoHuPos, byteCard)
        else
            ----LOG_DEBUG("其他玩家操作碰杠胡等")
            self.gameProgress:deleteTimeOut(self.waitGrabHandle)
            self.waitGrabHandle = self.gameProgress:setTimeOut(kWaitGrabTimeOut,
            function()
                self:grabEnd()
            end, nil)
        end
    end
end

-- 抢牌结束
function GamePlaying:grabEnd()
    self.gameProgress:deleteTimeOut(self.waitGrabHandle)
    self.gameProgress:deleteTimeOut(self.waitPlayHandle)
    local grabNode = self.playerGrabMgr:getPowestNode()  -- 找出最大操作结点
    local pos = self.playerGrabMgr.pos
    if grabNode == nil then   -- 没人抢牌，继续发牌
        ----LOG_DEBUG("grabNode is nil, next player catch card.")
        self:giveNewCard(self.gameProgress:nextPlayerPos(pos))
        return
    else
        -- 成功抢牌玩家的信息
        local oper = grabNode.operList[1]
        pos = grabNode.pos
        local grabedPos = self.playerGrabMgr.pos  -- 被碰杠人的位置
        local byteCard = grabNode.byteCard
        if oper == MJConst.kOperHu then
            self:doHu(pos, byteCard)
        elseif oper == MJConst.kOperPeng then
            if self:doPeng(pos, byteCard, grabedPos) == false then
                self:giveNewCard(self.gameProgress:nextPlayerPos(self.curTurn))
            end
        elseif oper == MJConst.kOperAG then
            self:doAnGang(pos, byteCard, grabedPos)
        elseif oper == MJConst.kOperMG then
            if self:doGang(pos, byteCard, grabedPos) == false then
                self:giveNewCard(self.gameProgress:nextPlayerPos(self.curTurn))
            end
        elseif oper == MJConst.kOperMXG then
            self:doMXGang(pos, byteCard, grabedPos)
        elseif oper == MJConst.kOperLChi or oper == MJConst.kOperMChi or
            oper == MJConst.kOperRChi then
            self:doChi(pos, oper, byteCard, grabedPos)
        elseif oper == MJConst.kOperCancel then
            if self.isQiangGanging == true then  -- 有人被抢杠
                -- 缓存抢杠的信息
                local seq = self.qiangGangInfo.seq
                local tPos = self.qiangGangInfo.pos
                local fromPos = self.qiangGangInfo.from
                local tbMoney = self.qiangGangInfo.money
                self.isQiangGanging = false
                self.qiangGangInfo = {}
            end
            -- 如果当前玩家可以出牌，继续等待
            if table.keyof(self.playerCanDoMap[pos].operList, MJConst.kOperPlay) ~= nil then
                return
            end
            -- 动作取消后，给等待抓牌的人发牌
            self:giveNewCard(self.gameProgress:nextPlayerPos(self.curTurn))
        elseif oper == MJConst.kOperPlay then
            -- 玩家出牌
            self:onPlayCard(pos, {card = byteCard})
        end
    end
end

-- 补花，删除花牌，通知客户端
function GamePlaying:buHua(turn)
    local player = self.playerList[turn]
    if  true == player:hasHua() then
        local huaByteCard = player:getHua()
        --LOG_DEBUG('-- buhua --'..huaByteCard)
        player:addHua(huaByteCard)

        local huaCardList = player:getHuaList()
        --发送增加花牌数消息
        self.gameProgress:broadcastFlowerCardCountNotify(
            player.myPos, #huaCardList
        )
        player:delNewCard(huaByteCard)

        -- 发消息给客户端
        self.gameProgress:opBuHuaHandCardNotify(
            self.gameProgress:getOperationSeq(),
            player.myPos,
            {huaByteCard},
            kRemoveCards
        )
        self:giveNewCard(turn)
    else
        --LOG_DEBUG('-- 补花出错，没有花牌 --')
    end
end

function GamePlaying:giveNewCard(turn)
    local player = self.playerList[turn]
    local byteCard = nil
    local byteCard = self.testPlayerNeedCard[turn]
    if nil == byteCard then
        byteCard = self.mjWall:getFrontCard()
    else
        self.testPlayerNeedCard[turn] = nil
    end
    if nil ==  byteCard then
        self:gotoNextState({isLiuJu = true})
        return
    end
    if not player then
        --LOG_DEBUG('-- 玩家不存在，异常结束 -- pos:'..turn)
        self:gotoNextState({isLiuJu = true})
        return
    end
    self.curTurn = turn
    self.mjCancelMgr:clear(turn)  -- 清除掉之前取消的操作
    player:addNewCard(byteCard)
    player.justDoOper = MJConst.kOperNewCard -- 当前动作为拿新牌
    table.insert(player.opHistoryList, player.justDoOper)
    self.gameProgress:opHandCardNotify(
                self.gameProgress:getOperationSeq(),
                turn,
                {byteCard},
                kAddCards
            )
    if player:hasHua() then  -- 0.5秒后补花
        self.gameProgress:setTimeOut(kBuHuaTimeOut, 
        function()
            self:buHua(turn)
        end, nil)
        return
    end
    self.gameProgress:deleteTimeOut(self.waitPlayHandle)
    -- 发送牌池牌数
    self.gameProgress:broadCastWallDataCountNotify()
    self:checkMyOper(turn)
end

function GamePlaying:doPeng(pos, byteCard, grabedPos)
    local player = self.playerList[pos]
    local ret, num = player:doPeng(byteCard, grabedPos)
    if true == ret then
        -- 发送消息， 1.删除玩家手中两张牌 2. 增加碰牌
        local seq = self.gameProgress:incOperationSeq()
        local lCards = {}
        for i = 1, num do 
            table.insert(lCards, byteCard)
        end
        -- 发送消息
        self.gameProgress:opHandCardNotify(seq, pos, lCards, kRemoveCards)
        self.gameProgress:broadcastMsgAddPengCards(seq, pos, grabedPos, byteCard)
        self.riverCardList[grabedPos]:popCard()
        self.gameProgress:broadCastMsgOpOnDeskOutCard(seq, kRemoveCards, grabedPos, byteCard)
        self:checkMyOper(pos)  -- 让这个玩家出牌 
        self.curTurn = pos   
    end
    return ret
end

function GamePlaying:doChi(pos, chiType, byteCard, grabedPos)
    --LOG_DEBUG('-- player doChi --'..pos)
    local player = self.playerList[pos]
    local ret, lCards = player:doChi(byteCard, chiType, grabedPos)
    --dump(ret, ' == ret = ')
    --dump(lCards, ' == lCards = ')
    if ret then
        local seq = self.gameProgress:incOperationSeq()
        local sendCards = {byteCard}
        for k , v in pairs(lCards) do
            table.insert(sendCards, v)
        end
        -- 发送消息
        self.gameProgress:opHandCardNotify(seq, pos, lCards, kRemoveCards)
        self.gameProgress:broadcastMsgAddChiCards(seq, pos, grabedPos, sendCards)
        self.riverCardList[grabedPos]:popCard()
        self.gameProgress:broadCastMsgOpOnDeskOutCard(seq, kRemoveCards, grabedPos, byteCard)
        self:checkMyOper(pos)  -- 让这个玩家出牌 
        self.curTurn = pos
    end
    return ret
end

function GamePlaying:doGang(pos, byteCard, grabedPos)
    local player = self.playerList[pos]
    local ret, num = player:doGang(byteCard, grabedPos)
    if true == ret then
        local lCards = {}
        local seq = self.gameProgress:incOperationSeq()
        for i = 1, num do 
            table.insert(lCards, byteCard)
        end
        -- 发送消息
        local money = self.unitCoin * kMGHua
        local tbMoney = {}
        self.gameProgress:opHandCardNotify(seq, pos, lCards, kRemoveCards)
        self.gameProgress:broadcastMsgAddGangCards(seq, pos, grabedPos, byteCard)
        self.gameProgress:broadcastMsgFideGangMoney(seq, pos, grabedPos, self.unitCoin * kMGHua)
        self.riverCardList[grabedPos]:popCard()
        self.gameProgress:broadCastMsgOpOnDeskOutCard(seq, kRemoveCards, grabedPos, byteCard)
        self:giveNewCard(pos)
    end
    return ret
end

function GamePlaying:doMXGang(pos, byteCard, grabedPos)
    local player = self.playerList[pos]
    local ret, fromPos, num = player:doMXGang(byteCard, grabedPos)
    if true == ret then
        local lCards = {}
        local seq = self.gameProgress:incOperationSeq()
        for i = 1, num do 
            table.insert(lCards, byteCard)
        end
        local money = self.unitCoin * kMGHua
        local tbMoney = {}
        -- 更新玩家钱数
        tbMoney[pos] = money
        tbMoney[fromPos] = 0 - money

        -- 发送消息 增加面下杠不需要再发送删除之前碰牌数据，客户端自行处理
        self.gameProgress:opHandCardNotify(seq, pos, lCards, kRemoveCards)
        self.gameProgress:broadcastMsgAddGangCards(seq, pos, fromPos, byteCard)
        -- 检是否有人抢杠
        local hasGrab, autoHuPos = self:checkOtherOper(pos, byteCard)
        if hasGrab == true then
            self.isQiangGanging = true
            -- 缓存抢杠的信息
            self.qiangGangInfo = {
                seq = seq,
                pos = pos,
                from = fromPos,
                money = tbMoney
            }
            if autoHuPos ~= nil then
                self:doHu(autoHuPos, byteCard)
            end
        else
            self:giveNewCard(pos)
        end
    end
    return ret
end

function GamePlaying:doAnGang(pos, byteCard, grabedPos)
    local player = self.playerList[pos]
    local ret, num =  player:doAnGang(byteCard, grabedPos)
    if true == ret then
        local lCards = {}
        local seq = self.gameProgress:incOperationSeq()
        for i = 1, num do 
            table.insert(lCards, byteCard)
        end
        local money = self.unitCoin * kAGHua
        local tbMoney = {}
        -- 发送消息 增加面下杠不需要再发送删除之前碰牌数据，客户端自行处理
        self.gameProgress:opHandCardNotify(seq, pos, lCards, kRemoveCards)
        self.gameProgress:broadcastMsgAddGangCards(seq, pos, grabedPos, byteCard)
        self:giveNewCard(pos)
    end
    return ret
end

-- 胡牌
function GamePlaying:doHu(pos, byteCard)
    local player = self.playerList[pos]
    local bZiMo = false
    if player:hasNewCard() and player.justDoOper == MJConst.kOperNewCard then
        bZiMo = true
    end
    local posList = {}
    if not bZiMo then
        -- 排查可以一炮多响的玩家
        for _pos, item in pairs(self.playerCanDoMap) do
            if table.keyof(item.operList, MJConst.kOperHu) ~= nil then
                table.insert(posList, _pos)
            end
        end
    else
        table.insert(posList, pos)
    end
    --LOG_DEBUG("doHU Pos:"..pos.." card:"..byteCard)
    self:gotoNextState({isLiuJu = false, isZiMo = bZiMo,
    -- fangPaoPos = self.playerGrabMgr.pos, 
    fangPaoPos = self.curTurn,
    winnerPosList = posList,
    huCard = byteCard,
    isQiangGang = self.isQiangGanging })
end

function GamePlaying:playerOpeartionSyncData(_pos)
    self:onUserCutBack(_pos)
end

function GamePlaying:onTestNeedCard(_pos, _card)
    if nil ~= _card then
        self.testPlayerNeedCard[_pos] = MJConst.fromOld2NowCardByteMap[_card]
    end
end

return GamePlaying