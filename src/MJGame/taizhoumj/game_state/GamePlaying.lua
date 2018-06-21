-- 2016.9.26 ptrjeffrey 
-- 游戏进行状态
local MJConst = require("mj_core.MJConst")
local MJCard = require("mj_core.MJCard")
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

local kPersecent = 100  -- 1秒时长
local kWaitPlayTimeOut = 15 * kPersecent -- default.
local kWaitGrabTimeOut = 10 * kPersecent
local kTuoGuanTimeOut  = 3  * kPersecent
local kBuHuaTimeOut    = 0.5 * kPersecent

local kRemoveCards = 0
local kAddCards   = 1

local kSkynetKipTime = kPersecent

-- 及时结算花数
local kAGHua = 3
local kMGHua = 6 -- 面下杠也按照明杠计算
local kOutFourContinueSameCardHua = 6
local kHGHua = 12


function GamePlaying:ctor(gameProgress, stateId)
    self.gameProgress = gameProgress
    self.stateId = stateId
    self.opTimeoutHandle = -99999
    self.playerGrabMgr = PlayerGrabMgr.new(gameProgress.maxPlayerCount)
    self.mjCancelMgr = MJCancelMgr.new()
    self.playerCanDoMap = {}
    self.unitCoin = gameProgress.unitCoin
    self.maxPlayerCount = gameProgress.maxPlayerCount
    self.testPlayerNeedCard = {} -- map: key = pos, card = cardbyte.
    self.isQiangGanging = false
    self.multiHuPos = {}

    self.countHuType = CountHuType.new()
    self.lastOutCardPos = -1

    kWaitPlayTimeOut = 1 * kPersecent

end

function GamePlaying:onEntry(args)
    -- self:gotoNextState({isLiuJu = true})
    self.gameProgress.curGameState = self
    self.multiHuPos = {}
    self.subState = kSubStatePlaying
    -- 简化变量名
    self.mjWall = self.gameProgress.mjWall
    self.playerList = self.gameProgress.playerList
    -- dump(self.playerList, "playing player")
    self.operHistory = self.gameProgress.operHistory
    self.riverCardList = self.gameProgress.riverCardList
    --- 设置当前庄家操作
    self.gameProgress:setCurOperatorPos(self.gameProgress.banker)
    self.playerGrabMgr:clear()
    self.mjCancelMgr:clear()
    self.playerCanDoMap = {}
    self.waitPlayHandle = nil   -- 等待玩家出牌超时
    self.waitGrabHandle = nil   -- 等待玩家抢牌超时
    self.isQiangGanging = false -- 是否在抢杠中
    self.countHuType:clearAutoHuFlag()
    self:checkMyOper(self.gameProgress.banker, true)
    self.OperationTimeOut = self.gameProgress.room.roundTime * 100 --- 发送操作后超时时间
end

function GamePlaying:checkSelfHu(turn)
    local bHu = false
    local player = self.playerList[turn]
    if player == nil then
        return bHu
    end
    if player:canSelfHu() or player:canSelfHuQiDui() then
        self.countHuType:setParams(
        turn, 
        self.gameProgress, 
        nil, 
        nil,
        false)
        self.countHuType:calculate()       
        if self:isKa(player, nil) == true then
            bHu = true
        end
    end
    return bHu
end

-- 找出这张牌一共出现过多少次
function GamePlaying:getCardShowedCount(byteCard)
    local cnt = 0
    for _, player in pairs(self.playerList) do
        cnt = cnt + player:getCardCountInPile(byteCard)
    end
    for _, river in pairs(self.riverCardList) do
        cnt = cnt + river:getCardCount(byteCard)
    end
    return cnt
end

-- 检查自己的操作
function GamePlaying:checkMyOper(turn, checkOp)
    local player = self.playerList[turn]
    if player then
        self:clearCanDoMap()  -- 清空所有人的操作
        if false == player:hasNewCard() then
            return nil
        else
            self.playerGrabMgr:clear()
            local operMap = {}   -- 操作和牌的对照
            local operList = {}  -- 纯操作
            local mustHu = false
            -- 出牌
            table.insert(operList, MJConst.kOperPlay)
            operMap[MJConst.kOperPlay] = {}
            local cancel = false
            local bHu = false
            local tipList = nil
            self.gameProgress:sendMustPlayCards(turn)

            if player.isTing then
                self.countHuType:setParams(
                turn, 
                self.gameProgress, 
                nil, 
                nil,
                self.isQiangGang)
                self.countHuType:calculate()
                    -- 胡牌
                if true == player:canSelfHu() and self:isKa(player,nil) then
                    bHu = true
                end

                if bHu then
                    if true == checkOp then 
                        table.insert(operList, MJConst.kOperHu)
                        operMap[MJConst.kOperHu] = {player.newCard}
                        mustHu = true
                    end
                end
            else
                -- 初步筛选能胡的牌，智能提示
                local canTingNodes = player:getCanTingCards()
                if #canTingNodes > 0 then
                    tipList = self:checkHuCondition(canTingNodes, turn)
                    if #tipList > 0 then
                        operMap[MJConst.kOperAITip] = tipList
                        operMap[MJConst.kOperTing] = tipList
                        table.insert(operList, MJConst.kOperTing)
                    end
                end
            end
            if true == checkOp and mustHu == false then
                -- 暗杠
                local anGangCardList = player:getAnGangCardList(player.isTing)
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
            -- 数据放入可操作玩家
            self.playerGrabMgr:addCanDoItem(turn, table.copy(operList))
            self.playerGrabMgr:setPos(turn)
            self.playerCanDoMap[turn] = operMap
            -- send to client
            local tipData = {}
            for k, v in pairs(operMap) do
                if k == MJConst.kOperAITip then -- 提示的内容不加入
                else
                    tipData[k] = table.copy(v)
                end
            end
            self.gameProgress:sendMsgSetOperationTipCardsNotify(turn, tipData, tipList)
            self.playerCanDoMap[turn].operList = table.copy(operList)
            local operListCopy = table.copy(operList)
            self:removeTingPlayOp(player, operListCopy, MJConst.kOperPlay)
            -- 等待玩家操作
            if self.countHuType.isAutoHu or mustHu == true then
                self.gameProgress:deleteTimeOut(self.waitPlayHandle)
                self.playerGrabMgr:playerDoGrab(turn, MJConst.kOperHu, player.newCard)
                self:doHu(turn, player.newCard)
                return
            else
                local seq = self.gameProgress:incOperationSeq()
                self.gameProgress:broadcastMsgPlayerOperationReq(seq, turn, MJConst.getOpsValue(operListCopy))
                self.gameProgress:deleteTimeOut(self.waitPlayHandle)
            end
            self:autoPlayCard(player, operListCopy)
        end
    else
        return nil
    end
end

-- 卡
function GamePlaying:isKa(player,huCard)
    if huCard == nil then
        huCard = player:getNewCard()
    end
    if huCard == nil then
        return false
    end
    local card = MJCard.new({byte = huCard})
    if card.suit == MJConst.kMJSuitZi then
        return false
    end
    if card.point < 3 or card.point > 8 then
        return false
    end

    local canHuCards = player:getCanHuCardList()
    local countMap = player:transHandCardsToCountMap(false)
    if #canHuCards == 1 then
        countMap[huCard + 1] = countMap[huCard + 1] - 1
        countMap[huCard - 1] = countMap[huCard - 1] - 1
        if countMap[huCard + 1] < 0 or
            countMap[huCard - 1] < 0 then
            return false
        end
        return player.mjMath:canHu(countMap)
    end
    
    return false
end

-- 检查其他人的操作
function GamePlaying:checkOtherOper(turn, byteCard, _bGrabGang)
    local hasGrab = false
    self.playerGrabMgr:clear()
    self.playerGrabMgr:setPos(turn)  -- 当前被抢牌的位置
    self:clearCanDoMap()
    self.multiHuPos = {}
    local pos = turn
    local autoHuPos = nil
    local mustHu = false
    if self.gameProgress:checkPlayersHuaInHand() == 1 then
        return hasGrab,autoHuPos, mustHu
    end
    for i = 1, self.gameProgress.maxPlayerCount - 1 do  -- 仅允许除出牌人以外的人抢牌
        pos = self.gameProgress:nextPlayerPos(pos)
        local operMap = {}   -- 操作和牌的对照
        local operList = {}  -- 纯操作
        local player = self.playerList[pos]
        local cancel = false
        if player.isTing then
            -- 胡牌 之前有漏胡过的就不能再胡同一张牌了
            if not self.mjCancelMgr:isCancelOper(pos, MJConst.kOperHu, nil) then
                if true == player:canHu(byteCard) and self:isKa(player,byteCard) then
                    LOG_DEBUG("can hu")
                    self.countHuType:setParams(
                        pos, 
                        self.gameProgress, 
                        byteCard, 
                        turn,
                        self.isQiangGang)
                    self.countHuType:calculate()
                    local bHu = true
                    if bHu then
                        if self.countHuType.isAutoHu then
                             autoHuPos = pos
                        end
                        table.insert(operList, MJConst.kOperHu)
                        operMap[MJConst.kOperHu] = {byteCard}
                        table.insert(self.multiHuPos, pos)
                        mustHu = true
                    end
                end
            end
        else
            if false == _bGrabGang then 
                -- 碰 之前有漏碰过的就不能再胡同一张牌了
                if not self.mjCancelMgr:isCancelOper(pos, MJConst.kOperPeng, byteCard) then
                    if player:canPeng(byteCard) then
                        local tingNodes = player:getCanTingCards({byteCard, byteCard})
                        if #tingNodes > 0 or self.gameProgress:checkPengOnce() == 0 then
                            LOG_DEBUG("can peng")
                            table.insert(operList, MJConst.kOperPeng)
                            operMap[MJConst.kOperPeng] = {byteCard}
                            cancel = true
                        end
                    end
                end
            end
        end
        if false == _bGrabGang and mustHu == false then
                    -- 明杠
            if player:canGang(byteCard, player.isTing) then
                LOG_DEBUG("can gang")
                table.insert(operList, MJConst.kOperMG)
                operMap[MJConst.kOperMG] = {byteCard}
                cancel = true
            end
        end
        -- 取消操作
        if cancel then
            LOG_DEBUG("can cancel")
            table.insert(operList, MJConst.kOperCancel)
            operMap[MJConst.kOperCancel] = {}
        end

        if #operList > 0 then
            -- 数据放入可操作玩家
            self.playerGrabMgr:addCanDoItem(pos, table.copy(operList))

            -- send to client 需要拷贝一份数据出来，以免影响原来的数据
            local tipData = {}
            for k, v in pairs(operMap) do
                tipData[k] = table.copy(v)
            end
            -- 先显示玩家可操作的动作
            if mustHu == false then
                self.gameProgress:sendMsgSetOperationTipCardsNotify(pos, tipData)
                local seq = self.gameProgress:incOperationSeq()
                self.gameProgress:broadcastMsgPlayerOperationReq(seq, pos, MJConst.getOpsValue(operList))
            end
            hasGrab = true
        end
        self.playerCanDoMap[pos] = operMap
        self.playerCanDoMap[pos].operList = operList
    end
    return hasGrab, autoHuPos, mustHu
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

function GamePlaying:onUserCutBack(_pos, _uid)
    local playerList = self.gameProgress.playerList
    local riverList = self.gameProgress.riverCardList
    local pkg = {}
    pkg.isWatcher = 0
    if self.gameProgress.room.watchers[uid] then
        pkg.isWatcher = 1
    end
    ---init need info
    pkg.zhuangPos = self.gameProgress.banker
    pkg.gameStatus = self.subState
    pkg.myPos = _pos
    pkg.roundTime = self.gameProgress.room.roundTime
    pkg.grabTime =  kWaitGrabTimeOut / 100
    --1. playerData
    pkg.Player1 = playerList[1]:getPlayerInfo()
    pkg.Player2 = playerList[2]:getPlayerInfo()
    pkg.Player3 = playerList[3]:getPlayerInfo()
    pkg.Player4 = playerList[4]:getPlayerInfo() 
    -- 2. handCards
    pkg.handCards1 = playerList[1]:getCardsForNums()
    pkg.handCards2 = playerList[2]:getCardsForNums()
    pkg.handCards3 = playerList[3]:getCardsForNums()
    pkg.handCards4 = playerList[4]:getCardsForNums()
    if 1 ~= _pos then
        pkg.handCards1 = self.gameProgress:fixedZeros(pkg.handCards1) 
    end
    if 2 ~= _pos then
        pkg.handCards2 = self.gameProgress:fixedZeros(pkg.handCards2)     
    end
    if 3 ~= _pos then
        pkg.handCards3 = self.gameProgress:fixedZeros(pkg.handCards3) 
    end
    if 4 ~= _pos then
        pkg.handCards4 = self.gameProgress:fixedZeros(pkg.handCards4)     
    end

    -- 玩家的新牌
    --3.getFlowerCnt
    --4.outCards --- MJRiver 
    pkg.outCards1 = MJConst.transferNew2OldCardList(riverList[1]:getRiverCardsList())
    pkg.outCards2 = MJConst.transferNew2OldCardList(riverList[2]:getRiverCardsList())
    pkg.outCards3 = MJConst.transferNew2OldCardList(riverList[3]:getRiverCardsList())
    pkg.outCards4 = MJConst.transferNew2OldCardList(riverList[4]:getRiverCardsList())
    --5.pengcards -- 
    pkg.pengGang1 = playerList[1]:getPileListForClient()
    pkg.pengGang2 = playerList[2]:getPileListForClient()
    pkg.pengGang3 = playerList[3]:getPileListForClient()
    pkg.pengGang4 = playerList[4]:getPileListForClient()
    pkg.lastOutPos = self.lastOutCardPos
    self.gameProgress:sendMsgToUidNotifyEachPlayerCards(_pos, pkg)

    ---7. 剩余牌数
    self.gameProgress:broadCastWallDataCountNotify()
    -- 8 当前已听牌玩家
    local pkg = {}
    pkg.OperationSeq = self.gameProgress:getOperationSeq()
    pkg.posList = {}
    for k, player in pairs(playerList) do
        if player.isTing then
            table.insert(pkg.posList, player.myPos)
        end
    end
    -- self.gameProgress:sendMsgToSeat(_pos, "tingPos", pkg)
	
    local operMap = self.playerCanDoMap[_pos]
    -- send to client
    if operMap and operMap.operList and #operMap.operList > 0 then
        LOG_DEBUG('-- userCutBack will send operMap')
        local tipData = {}
        for k, v in pairs(operMap) do
            if k ~= 'operList' then
                if k ~= MJConst.kOperAITip then
                    tipData[k] = table.copy(v)
                    if k == MJConst.kOperPlay then
                        self.gameProgress:sendMustPlayCards(_pos)
                    end
                end
            end
        end
        self.gameProgress:sendMsgSetOperationTipCardsNotify(_pos, tipData, operMap[MJConst.kOperAITip])
        local operList = table.copy(operMap.operList)
        self:removeTingPlayOp(self.gameProgress.playerList[_pos], operList, MJConst.kOperPlay)
        self.gameProgress:broadcastMsgPlayerOperationReq(nil, _pos, MJConst.getOpsValue(operList))
    else
        -- LOG_DEBUG('-- cannot send oper Map')
    end
    self.gameProgress:sendAllFlowerCnt(_uid, 0)
    self.gameProgress:sendTotalScore(_uid)
    self.gameProgress:sendVIPRoomInfo(_uid)
    self.gameProgress:syncTing()
    self.gameProgress:sendMustPlayCards(_pos)
end


function GamePlaying:gotoNextState(args)
    self.gameProgress:deleteTimeOut(self.waitPlayHandle)
    self.gameProgress:deleteTimeOut(self.waitGrabHandle)
    self.gameProgress.gameStateList[self.gameProgress.kGameEnd]:onEntry(args)
end

-- 来自客户端的消息
-- 判定玩家是否有此操作权限
function GamePlaying:onClientMsg(_pos, _pkg)
    -- dump(_pkg, "onClientMsg")
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
    LOG_DEBUG("timeout to continue.")
end

function GamePlaying:deleteTimeOut(_handle)
    self.gameProgress:deleteTimeOut(_handle)
end


function GamePlaying:isPlayerOpExist(_player, _pos, _pkg)
    local bTfRet, newOp = _player:transferOld2New(_pkg.operation)
    if false == bTfRet then
        LOG_DEBUG('pos:'.._pos.."_pkg.operation invalid operation:".._pkg.operation)
        return false
    end
    if nil ~= _pkg.card_bytes then
        _pkg.card_bytes = MJConst.fromOld2NowCardByteMap[_pkg.card_bytes]
    end

    local bRet, opType = _player:checkOperaiton(newOp, _pkg.card_bytes)
    if false == bRet then
        LOG_DEBUG(string.format("player invalid op:%d  pos:%d", newOp, _pos))
        return false
    end 
    _pkg.operation = opType
    return true
end

-- 胡碰杠取消操作
function GamePlaying:onGrabCard(_pos, _pkg)
    -- LOG_DEBUG("GamePlaying:onGrabCard")
    local pkg = _pkg
    local pos = _pos
    local oper = pkg.operation
    local byteCard = pkg.card

    local player = self.playerList[pos]
    if not player then
        LOG_DEBUG('-- 操作玩家不存在 --'..pos)
        return
    end      
    -- dump(_pkg, "onGrabCard _pkg")
    if not self.playerGrabMgr:hasOper(pos, oper) then
        LOG_DEBUG('-- 玩家没有操作权限 --'..pos)
        -- dump(pkg)
        return
    end
    local canDoMap = self.playerCanDoMap[pos]
    if canDoMap and canDoMap[oper] then 
        if oper == MJConst.kOperTing then  -- 听牌单独处理
            player:doPrevTing()
            if self.playerCanDoMap[_pos] and self.playerCanDoMap[_pos][oper] then
                self.playerCanDoMap[_pos][oper] = nil
            end
            self.playerGrabMgr:playerDoGrab(pos, oper, 1)
            -- seng ting status
            local seq = self.gameProgress:getOperationSeq()
            self.gameProgress:broadcastTing(seq, pos, true, 0)
            -- send can play card
            self.gameProgress:sendMustPlayCards(pos)
            return
        end
        if oper == MJConst.kOperCancel then
            self.playerGrabMgr:playerDoGrab(pos, oper, 1)
            self:clearCanDoMap(pos)  -- 玩家抢牌以后就清除掉当前的抢牌Map
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
                self:clearCanDoMap(pos)  -- 玩家抢牌以后就清除掉当前的抢牌Map
                LOG_DEBUG("do grab ok.")
            else
                LOG_DEBUG("player no has this card:"..byteCard)
                -- todo 让客户端同步当前状态
                self:onUserCutBack(pos, player:getUid())
                return
            end
        end
        if true == self:needWait(oper) then
            -- LOG_DEBUG("exec op.")
            self:grabEnd()            
        else
            LOG_DEBUG("waiting... oper.")
        end
    else
        -- LOG_DEBUG("player no this oper:"..oper)
        -- dump(canDoMap, "canDoMap")
    end
end

-- 玩家点了听以后是否出了无效的牌
function GamePlaying:isPlayCanTingCard(pos, byteCard)
    local canDoMap = self.playerCanDoMap[pos]
    local tingNodes = canDoMap[MJConst.kOperTing]
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

--- 复写 一炮多响的等待判断
function GamePlaying:needWait(oper)
    local bPowerestWait = self.playerGrabMgr:needWait()
    local bNotWaitHuMore = false
    local bRet = false
    if MJConst.kOperHu  == oper then
        -- 查找胡操作玩家 的数量
        bNotWaitHuMore = true
    end
    bRet = (false == bPowerestWait) or (true == bNotWaitHuMore)
    return bRet
end

-- 出牌
function GamePlaying:onPlayCard(_pos, _pkg)
    LOG_DEBUG("pos:".._pos.." on PlayCard ".._pkg.card)
    local pkg = _pkg
    local pos = _pos
    self.lastOutCardPos = pos
    if not self.playerGrabMgr:hasOper(pos, MJConst.kOperPlay) then
        LOG_DEBUG('-- 玩家没有出牌权限 --'..pos)
        return
    end
    local player = self.playerList[pos]
    if not player then
        LOG_DEBUG('-- 出牌玩家不存在 --')
        return
    end
    local byteCard = pkg.card
    local canPlayCards = player:getCanPlayCards()
    if #canPlayCards > 0 then
        local cardCopy = MJConst.fromNow2OldCardByteMap[byteCard]
        if table.keyof(canPlayCards, cardCopy) == nil then
            self:onUserCutBack(pos, player:getUid())
        end
    end
    if player.isPrevTing == true and player.isTing == false then
        self.gameProgress:broadcastTingAni(_pos)
    end

    player:doTing()
    
    if not player:doPlayCard(byteCard) then
        dump(byteCard, '-- 玩家出牌出错 card = ')
        -- todo 让客户端同步当前状态
        self:onUserCutBack(pos, player:getUid())
        return
    end

    player:calcHuCard()
    
    self.gameProgress:sendMustPlayCards(pos)

    self.gameProgress:deleteTimeOut(self.waitPlayHandle)
    self.playerGrabMgr:playerDoGrab(pos, MJConst.kOperPlay, byteCard)
    self:clearCanDoMap(pos)
    self.riverCardList[pos]:pushCard(byteCard)
    local seq = self.gameProgress:incOperationSeq()
    self.gameProgress:opHandCardNotify(seq, pos, {pkg.card}, kRemoveCards)
    self.gameProgress:broadCastMsgOpOnDeskOutCard(seq, kAddCards, pos, pkg.card)

    -- 判断其他玩家是否可以操作
    local hasGrab, autoHuPos, mustHu = self:checkOtherOper(pos, byteCard, false)
    if not hasGrab then  -- 继续发牌
        -- LOG_DEBUG("继续发牌")
        -- self.playerGrabMgr:clear()
        self:giveNewCard(self.gameProgress:nextPlayerPos(pos))
    else  -- 等待抢牌
        if autoHuPos ~= nil then
            self.playerGrabMgr:playerDoGrab(autoHuPos, MJConst.kOperHu, byteCard)
            self:doHu(autoHuPos, byteCard)
        end
        if mustHu == true then
            self.playerGrabMgr:playerDoGrab(self.multiHuPos[1], MJConst.kOperHu, byteCard)
            self:doHu(self.multiHuPos[1], byteCard)
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
        LOG_DEBUG("grabNode is nil, next player catch card.")
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
                self:giveNewCard(self.gameProgress:nextPlayerPos(grabedPos))
            end
        elseif oper == MJConst.kOperAG then
            self:doAnGang(pos, byteCard, grabedPos)
        elseif oper == MJConst.kOperMG then
            if self:doGang(pos, byteCard, grabedPos) == false then
                self:giveNewCard(self.gameProgress:nextPlayerPos(grabedPos))
            end
        elseif oper == MJConst.kOperMXG then
            self:doMXGang(pos, byteCard, grabedPos)
        elseif oper == MJConst.kOperCancel then
            if self.isQiangGanging == true then  -- 有人被抢杠
                -- 缓存抢杠的信息
                local tPos = self.qiangGangInfo.pos
                self.isQiangGanging = false
                self.qiangGangInfo = {}
                self:giveNewCard(tPos)
                return
            end
            -- 如果当前玩家可以出牌，继续等待
            if table.keyof(self.playerCanDoMap[pos].operList, MJConst.kOperPlay) ~= nil then
                return
            end
            -- 动作取消后，给等待抓牌的人发牌
            self:giveNewCard(self.gameProgress:nextPlayerPos(grabedPos))
        elseif oper == MJConst.kOperPlay then
            -- 玩家出牌
            self:onPlayCard(pos, {card = byteCard})
        end
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
    if byteCard == nil then
        self:gotoNextState({isLiuJu = true})
        return
    end
    if not player then
        LOG_DEBUG('-- player invalid -- pos:'..turn)
        self:gotoNextState({isLiuJu = true})
        return
    end
    self.playerGrabMgr:setPos(turn)
    self.mjCancelMgr:clearPos(turn)  -- 清除掉之前取消的操作
    player:addNewCard(byteCard)
    self.gameProgress:opHandCardNotify(
            self.gameProgress:getOperationSeq(),
            turn,
            {byteCard},
            kAddCards
    )
    if self.mjWall:getCanGetCount() <= 3 then
        self:gotoCycleGiveCard(turn)
        return 
    end
    -- 发送牌池牌数
    self.gameProgress:buHuProcess(player)
    self.gameProgress:broadCastWallDataCountNotify()
    self:checkMyOper(turn, true)
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

        -- 取消漏胡操作
        self.mjCancelMgr:clearPos(pos)
        -- 发送消息
        self.gameProgress:opHandCardNotify(seq, pos, lCards, kRemoveCards)
        self.gameProgress:broadcastMsgAddPengCards(seq, pos, grabedPos, byteCard)

        self.riverCardList[grabedPos]:popCard()
        self.gameProgress:broadCastMsgOpOnDeskOutCard(seq, kRemoveCards, grabedPos, byteCard)
        -- self.gameProgress:sendCheckCards(pos)        
        self:checkMyOper(pos, false)  -- 让这个玩家出牌 
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
        -- 取消漏胡操作
        self.mjCancelMgr:clearPos(pos)
        -- 发送消息
        self.gameProgress:opHandCardNotify(seq, pos, lCards, kRemoveCards)
        self.gameProgress:broadcastMsgAddGangCards(seq, pos, grabedPos, byteCard)
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
        -- 取消漏胡操作
        self.mjCancelMgr:clearPos(pos)
        -- 发送消息 增加面下杠不需要再发送删除之前碰牌数据，客户端自行处理
        self.gameProgress:opHandCardNotify(seq, pos, lCards, kRemoveCards)
        self.gameProgress:broadcastMsgAddGangCards(seq, pos, fromPos, byteCard)
        -- 检是否有人抢杠
        local hasGrab, autoHuPos, mustHu = self:checkOtherOper(pos, byteCard, true)
        if hasGrab == true then
            self.isQiangGanging = true
            -- 缓存抢杠的信息
            self.qiangGangInfo = {
                pos = pos,
            }
            if autoHuPos ~= nil then
                self.playerGrabMgr:playerDoGrab(autoHuPos, MJConst.kOperHu, byteCard)
                self:doHu(autoHuPos, byteCard)
            end
            if mustHu == true then
                self.playerGrabMgr:playerDoGrab(self.multiHuPos[1], MJConst.kOperHu, byteCard)
                self:doHu(self.multiHuPos[1], byteCard)
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
        -- 取消漏胡操作
        self.mjCancelMgr:clearPos(pos)
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
        posList = table.copy(self.multiHuPos)
        if #posList > 1 then
            self.gameProgress.banker = self.playerGrabMgr.pos
        else
            self.gameProgress.banker = pos
        end
    else
        table.insert(posList, pos)
        self.gameProgress.banker = pos
    end

    LOG_DEBUG("doHU Pos:"..pos.." card:"..byteCard)
    self:gotoNextState({isLiuJu = false, isZiMo = bZiMo,
    fangPaoPos = self.playerGrabMgr.pos,
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

-- 胡牌的条件,不同的游戏需要重写胡牌条件
function GamePlaying:checkHuCondition(canTingNodes, turn)
    local tipNodeList = {}
    local player = self.playerList[turn]
    if player then
        local tmpPlayer = player:clone()  -- 生成新对象，避免老对象被污染
        for _, node in pairs(canTingNodes) do
            local removeCard = node.playCard
            local _node = {playCard = removeCard}
            _node.huList = {}
            tmpPlayer.cardList = player:getHandCardsCopy()
            tmpPlayer.newCard = player.newCard
            tmpPlayer:pushNewCardToHand()
            if tmpPlayer:delHandCard(removeCard) then
                for _, canHudCard in pairs(node.huCards) do
                    tmpPlayer.newCard = canHudCard
                    -- 检查胡牌花数
                    self.countHuType:setParams(turn, self.gameProgress, nil, nil, false)
                    self.countHuType.player = tmpPlayer
                    self.countHuType:calculate()

                    local _left = 4 - self:getCardShowedCount(canHudCard) - player:getCardCountInHand(canHudCard, true)
                    table.insert(_node.huList, {card = canHudCard, fan = self.countHuType:getTotalFan(), left = _left })
                end
            end
            if #_node.huList > 0 then
                table.insert(tipNodeList, _node)
            end
        end
    end
    return tipNodeList
end

function GamePlaying:gotoCycleGiveCard(startPos)
    ---1. send one card to each player.
    local pos = startPos
    local playerList = self.gameProgress.playerList
    local byteCard = -1 
    self.gameProgress:deleteTimeOut(self.waitPlayHandle)
    for i = 1, 3 do
        pos = self.gameProgress:nextPlayerPos(pos) 
        byteCard = self.gameProgress.mjWall:getFrontCard()
        self.playerGrabMgr:setPos(pos)
        self.mjCancelMgr:clear(pos)

        if byteCard ~= nil then
            playerList[pos]:addNewCard(byteCard)
            self.gameProgress:opHandCardNotify(
                        self.gameProgress:getOperationSeq(),
                        pos,
                        {byteCard},
                        kAddCards
                    )

            self.gameProgress:broadCastWallDataCountNotify()
        else
            break
        end
    end
    ---2. from startPos to others , checkhu, if cycle check hu, gameover.
    pos = startPos
    local hu = false
    for i = 1, 4 do 
        byteCard = playerList[pos]:getNewCard()
        if playerList[pos].isTing and byteCard < MJConst.Zi1 and byteCard > MJConst.kCardNull then
            self.countHuType:setParams(
            pos, 
            self.gameProgress, 
            nil, 
            nil,
            self.isQiangGang)
            self.countHuType:calculate()
                -- 胡牌
            if true == playerList[pos]:canSelfHu() and self:isKa(playerList[pos],nil) then
                hu = true
                self:doHu(pos, byteCard)
                break
            end
        end
        pos = self.gameProgress:nextPlayerPos(pos)
    end
    ---3. goto liuju
    if not hu then
        self:gotoNextState({isLiuJu = true})
    end
end

function GamePlaying:clearCanDoMap(pos)
    if pos and self.playerCanDoMap[pos] then
        self.playerCanDoMap[pos] = {}
    else
        for i = 1, #self.playerCanDoMap do
            self.playerCanDoMap[i] = {}
        end
    end
end

function GamePlaying:canHuOther(pos, turn, byteCard)
    local bHu = false
    local player = self.playerList[pos]
    if player == nil then
        return bHu
    end
    if true == player:canHu(byteCard) or true == player:canHuQiDui(byteCard) then
        self.countHuType:setParams(
            pos, 
            self.gameProgress, 
            byteCard, 
            turn,
            false)
        self.countHuType:calculate()
        if self:isKa(player, byteCard) == true then
            bHu = true
        end
    end
    return bHu
end

function GamePlaying:removeTingPlayOp(player, opList, op)
    if player.isTing == true then
        table.removeItem(opList, op, true)
    end
end

function GamePlaying:autoPlayCard(player, opList)
    if #opList == 0 and player.isTing == true then
        self.waitPlayHandle = self.gameProgress:setTimeOut(kWaitPlayTimeOut,
        function()
            local playCard = MJConst.fromNow2OldCardByteMap[player.newCard]
            self.waitPlayHandle = nil
            self:onPlayCard(player:getDeskPos(), {card = player.newCard})
        end, nil)
    end
end

return GamePlaying