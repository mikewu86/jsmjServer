-- 2016.9.26 ptrjeffrey 
-- 游戏进行状态
local MJConst = require("mj_core.MJConst")
local MJCancelMgr = require("mj_core.MJCancelMgr")
local PlayerGrabMgr = require("mj_core.PlayerGrabMgr")
local GamePlaying = class("GamePlaying")
local CountHuType = require("CountHuType")
local HuTypeConst = require("HuTypeConst")

local kSubStatePlaying = 1
local kBaiDaCard = 9
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
local kStatusBaozi  = 8

local kSkynetKipTime = kPersecent

-- 及时结算花数
local kAGHua = 3
local kMGHua = 6 -- 面下杠也按照明杠计算
local kOutFourContinueSameCardHua = 6
local kHGHua = 12

local kEnableQiangGang = 1   --- 0 disable 1 enble
local kEnableChong = 0   ---  0 disable 1 enble
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

    kWaitPlayTimeOut = gameProgress.room.roundTime * kSkynetKipTime

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
    player.justDoOper = MJConst.kOperNewCard
    if player:canSelfHu({player.daCard}) then -- or player:canSelfHuQiDui() then
        bHu = true
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

-- 胡牌的条件,不同的游戏需要重写胡牌条件
function GamePlaying:checkHuCondition(limitHua, canTingNodes, turn)
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
                for _, canHudCard in pairs(node.huCardList) do
                    tmpPlayer.newCard = canHudCard
                    -- 检查胡牌花数
                    self.countHuType:setParams(turn, self.gameProgress, nil, nil, false)
                    self.countHuType.player = tmpPlayer
                    self.countHuType:calculate()
                    --local fCount = self:getFlowerCount(tmpPlayer)
                    local huaCount = self.countHuType:getTotalFan()
                    if huaCount >= limitHua then
                        local _left = 4 - self:getCardShowedCount(canHudCard) - player:getCardCountInHand(canHudCard, true)
                        table.insert(_node.huList, {card = canHudCard, fan = self.countHuType:getTotalFan(), left = _left })
                    end
                end
                if #_node.huList > 0 then
                    table.insert(tipNodeList, _node)
                end
            end
        end
    end
    return tipNodeList
end

-- 检查自己的操作
function GamePlaying:checkMyOper(turn, checkOp)
    local player = self.playerList[turn]
    if player then
        if false == player:hasNewCard() then
            return nil
        else
            self.playerGrabMgr:clear()
            local operMap = {}   -- 操作和牌的对照
            local operList = {}  -- 纯操作
            -- 出牌
            table.insert(operList, MJConst.kOperPlay)
            operMap[MJConst.kOperPlay] = {}
            local cancel = false
            local bHu = false
            if true == checkOp then
                -- 胡牌
                if player:canSelfHu({player.daCard}) then
                    bHu = true
                    self.countHuType:setParams(
                    turn, 
                    self.gameProgress, 
                    nil, 
                    nil,
                    false,
                    self.gameProgress.banker)
                    self.countHuType:calculate()
                end
                -- dump(self.countHuType:getTotalFan(), "calc fan....")
                if bHu and  self.countHuType:getTotalFan() > 1 then
                    table.insert(operList, MJConst.kOperHu)
                    operMap[MJConst.kOperHu] = {player.newCard}
                    cancel = true
                end

                -- 暗杠
                --- 目前可以 百搭牌可以暗杠
                local anGangCardList = player:getAnGangCardListWithDa({player.daCard})
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
            -- 初步筛选能胡的牌，智能提示
            local canTingNodes = player:getCanTingCards({player.daCard})
            -- dump(canTingNodes, ' canTingNodes = ')
            local tipList = nil
            if #canTingNodes > 0 then
                tipList = self:checkHuCondition(2, canTingNodes, turn)
                -- dump(tipList, ' tipList = ', 6)
                if #tipList > 0 then
                    operMap[MJConst.kOperAITip] = tipList
                end
            end
            -- dump(operList, "check my op operList")
            -- 数据放入可操作玩家
            self.playerGrabMgr:addCanDoItem(turn, operList)
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
            self.playerCanDoMap[turn].operList = operList
            -- 等待玩家操作
            if self.countHuType.isAutoHu then
                self.gameProgress:deleteTimeOut(self.waitPlayHandle)
                self.playerGrabMgr:playerDoGrab(turn, MJConst.kOperHu, player.newCard)
                self:doHu(turn, player.newCard)
                return
            else
                local seq = self.gameProgress:incOperationSeq()
                self.gameProgress:broadcastMsgPlayerOperationReq(seq, turn, MJConst.getOpsValue(operList))
                self.gameProgress:deleteTimeOut(self.waitPlayHandle)
                -- 去掉自动出牌
                -- self.waitPlayHandle = self.gameProgress:setTimeOut(kWaitPlayTimeOut,
                -- function()
                --     -- local playCard = MJConst.transferNew2OldCardList[player.newCard]
                --     self.waitPlayHandle = nil
                --     self:onPlayCard(turn, {card = player.newCard})
                -- end, nil)
            end
        end
    else
        return nil
    end
end

function GamePlaying:canHuOther(pos, turn, byteCard, isQiangGang)
    local bHu = false
    local player = self.playerList[pos]
    if player == nil then
        return bHu
    end

    if true == player:canHu(byteCard, {player.daCard})  then
        bHu = true
    end
    if self.gameProgress.roomRuleMap['sz_playrule_yzm'] then
        bHu = false
        print('------hua bu gou --')
    end
    return bHu
end

-- 检查其他人的操作
function GamePlaying:checkOtherOper(turn, byteCard, _bGrabGang)
    local hasGrab = false
    self.playerGrabMgr:clear()
    self.playerGrabMgr:setPos(turn)  -- 当前被抢牌的位置
    self.multiHuPos = {}
    local pos = turn
    local autoHuPos = nil
    local bHu = false
    for i = 1, self.gameProgress.maxPlayerCount - 1 do  -- 仅允许除出牌人以外的人抢牌
        bHu = false
        pos = self.gameProgress:nextPlayerPos(pos)
        local operMap = {}   -- 操作和牌的对照
        local operList = {}  -- 纯操作
        local player = self.playerList[pos]
        local cancel = false

        -- 胡牌 之前有漏胡过的就不能再胡同一张牌了
        if not self.mjCancelMgr:isCancelOper(pos, MJConst.kOperHu, nil) and
            _bGrabGang == true then
                --- 没有硬自摸配置或者 硬自摸不使能
                ---self.gameProgress.roomRuleMap.cz_playrule_yzm ~= true then
            if true == player:canHu(byteCard, {player.daCard})  then
                bHu = true
                self.countHuType:setParams(
                    pos,
                    self.gameProgress, 
                    byteCard, 
                    turn,
                    false,
                    self.gameProgress.banker)
                self.countHuType:calculate()
            end

            if bHu and self.countHuType:getTotalFan() > 1 and self.countHuType:haveZiMoHuType() == false then
                if self.countHuType.isAutoHu then
                    autoHuPos = pos
                end
                table.insert(self.multiHuPos, pos)
                table.insert(operList, MJConst.kOperHu)
                operMap[MJConst.kOperHu] = {byteCard}
                cancel = true
            end
        end
        if false == _bGrabGang and byteCard ~= player.daCard then
            -- 明杠
            if player:canGang(byteCard) then
                table.insert(operList, MJConst.kOperMG)
                operMap[MJConst.kOperMG] = {byteCard}
                cancel = true
            end
            -- 碰 之前有漏碰过的就不能再胡同一张牌了
            if not self.mjCancelMgr:isCancelOper(pos, MJConst.kOperPeng, byteCard) then
                if player:canPeng(byteCard) then
                    table.insert(operList, MJConst.kOperPeng)
                    operMap[MJConst.kOperPeng] = {byteCard}
                    cancel = true
                end
            end
        end
        -- 取消操作
        if cancel then
            table.insert(operList, MJConst.kOperCancel)
            operMap[MJConst.kOperCancel] = {}
        end

        if #operList > 1 then
            -- 数据放入可操作玩家
            self.playerGrabMgr:addCanDoItem(pos, table.copy(operList))

            -- send to client 需要拷贝一份数据出来，以免影响原来的数据
            local tipData = {}
            for k, v in pairs(operMap) do
                tipData[k] = table.copy(v)
            end
            -- 先显示玩家可操作的动作
            self.gameProgress:sendMsgSetOperationTipCardsNotify(pos, tipData)
            local seq = self.gameProgress:incOperationSeq()
            self.gameProgress:broadcastMsgPlayerOperationReq(seq, pos, MJConst.getOpsValue(operList))
            hasGrab = true
        end
        self.playerCanDoMap[pos] = operMap
        self.playerCanDoMap[pos].operList = operList
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
    pkg.handCards1 = MJConst.transferNew2OldCardList(playerList[1]:getAllHandCards())
    pkg.handCards2 = MJConst.transferNew2OldCardList(playerList[2]:getAllHandCards())
    pkg.handCards3 = MJConst.transferNew2OldCardList(playerList[3]:getAllHandCards())
    pkg.handCards4 = MJConst.transferNew2OldCardList(playerList[4]:getAllHandCards())
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
    if playerList[_pos]:hasNewCard() then
        pkg.newCard = MJConst.fromNow2OldCardByteMap[playerList[_pos]:getNewCard()]
    else
        pkg.newCard = MJConst.kCardNull
    end

    --3.getFlowerCnt
    pkg.flowerCardsCount1 = #playerList[1]:getHuaList()
    pkg.flowerCardsCount2 = #playerList[2]:getHuaList()
    pkg.flowerCardsCount3 = #playerList[3]:getHuaList()
    pkg.flowerCardsCount4 = #playerList[4]:getHuaList()
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

    pkg.curOper = self.playerGrabMgr:getPos()

    self.gameProgress:sendMsgToUidNotifyEachPlayerCards(_pos, pkg)

    ---7. 剩余牌数
    self.gameProgress:broadCastWallDataCountNotify()
    -- todo...
    local operMap = self.playerCanDoMap[_pos]
    -- send to client
    if operMap and operMap.operList and #operMap.operList > 0 then
        local tipData = {}
        for k, v in pairs(operMap) do
            if k ~= 'operList' then
                if k ~= MJConst.kOperAITip then
                    tipData[k] = table.copy(v)
                end
            end
        end
        self.gameProgress:sendMsgSetOperationTipCardsNotify(_pos, tipData, operMap[MJConst.kOperAITip])
        local operList = operMap.operList
        self.gameProgress:broadcastMsgPlayerOperationReq(nil, _pos, MJConst.getOpsValue(operList))
    else
        -- LOG_DEBUG('-- cannot send oper Map')
    end

    self.gameProgress:sendTotalScore(_uid)
    self.gameProgress:sendVIPRoomInfo(_uid)
    --
    -- self.gameProgress:deleteCutUserByPos(pos)
    -- self.gameProgress:broadcastCutUserList()

    self.gameProgress:broadcastPlayerClientNotify(self.gameProgress:getOperationSeq(),
        kBaiDaCard, {MJConst.fromNow2OldCardByteMap[playerList[1].daCard]})
    self.gameProgress:broadcastBaoziZero(self.gameProgress:getOperationSeq())
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
    --LOG_DEBUG("timeout to continue.")
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
    LOG_DEBUG("GamePlaying:onGrabCard")
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
    -- dump(canDoMap, "onGrabCard canDoMap")
    if canDoMap and canDoMap[oper] then 
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
                LOG_DEBUG("do grab ok.")
            else
                dump(byteCard, "player has no this card.")
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
    if not player:doPlayCard(byteCard) then
        dump(byteCard, '-- 玩家出牌出错 card = ')
        -- todo 让客户端同步当前状态
        self:onUserCutBack(pos, player:getUid())
        return
    end
    self.gameProgress:deleteTimeOut(self.waitPlayHandle)
    self.playerGrabMgr:playerDoGrab(pos, MJConst.kOperPlay, byteCard)
    self.playerCanDoMap[pos] = {}
    self.riverCardList[pos]:pushCard(byteCard)
    local seq = self.gameProgress:incOperationSeq()
    self.gameProgress:opHandCardNotify(seq, pos, {pkg.card}, kRemoveCards)
    self.gameProgress:broadCastMsgOpOnDeskOutCard(seq, kAddCards, pos, pkg.card)
    self.mjCancelMgr:clearPos(pos)
    -- 判断其他玩家是否可以操作
    local hasGrab, autoHuPos = self:checkOtherOper(pos, byteCard, false)
    if not hasGrab then  -- 继续发牌
        -- LOG_DEBUG("继续发牌")
        -- self.playerGrabMgr:clear()
        self:giveNewCard(self.gameProgress:nextPlayerPos(pos))
    else  -- 等待抢牌
        if autoHuPos ~= nil then
            self.playerGrabMgr:playerDoGrab(autoHuPos, MJConst.kOperHu, byteCard)
            self:doHu(autoHuPos, byteCard)
        else
            -- LOG_DEBUG("其他玩家操作碰杠胡等")
            -- self.gameProgress:deleteTimeOut(self.waitGrabHandle)
            -- self.waitGrabHandle = self.gameProgress:setTimeOut(kWaitGrabTimeOut,
            -- function()
            --     self:grabEnd()
            -- end, nil)
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
    if nil ==  byteCard then
        self:gotoNextState({isLiuJu = true})
        return
    end
    if not player then
        LOG_DEBUG('-- 玩家不存在，异常结束 -- pos:'..turn)
        self:gotoNextState({isLiuJu = true})
        return
    end
    self.playerGrabMgr:setPos(turn)
    self.mjCancelMgr:clearPos(turn)  -- 清除掉之前取消的操作
    player:addNewCard(byteCard)
    --player.justDoOper = MJConst.kOperNewCard -- 当前动作为拿新牌
    table.insert(player.opHistoryList, player.justDoOper)    
    self.gameProgress:opHandCardNotify(
                self.gameProgress:getOperationSeq(),
                turn,
                {byteCard},
                kAddCards
            )
    if player.daCard == byteCard then
        player:addDaCard(byteCard)
    end
    self.gameProgress:deleteTimeOut(self.waitPlayHandle)
    -- 发送牌池牌数
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
        -- 发送消息 增加面下杠不需要再发送删除之前碰牌数据，客户端自行处理
        self.gameProgress:opHandCardNotify(seq, pos, lCards, kRemoveCards)
        self.gameProgress:broadcastMsgAddGangCards(seq, pos, fromPos, byteCard)
        -- 检是否有人抢杠
        local hasGrab, autoHuPos = self:checkOtherOper(pos, byteCard, true)
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
        -- 发送消息 增加面下杠不需要再发送删除之前碰牌数据，客户端自行处理
        self.gameProgress:opHandCardNotify(seq, pos, lCards, kRemoveCards)
        self.gameProgress:broadcastMsgAddGangCards(seq, pos, grabedPos, byteCard)
        -- 更新玩家钱数
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
    local alterZhuang = 0
    local zhuangCopy = self.gameProgress.banker
    if not bZiMo then
        posList = table.copy(self.multiHuPos)
    else
        table.insert(posList, pos)
    end
    if #posList > 1 then
        self.gameProgress.banker = self.playerGrabMgr.pos
    else
        self.gameProgress.banker = posList[1]
    end

    LOG_DEBUG("doHU Pos:"..pos.." card:"..byteCard)
    self:gotoNextState({isLiuJu = false, isZiMo = bZiMo,
    fangPaoPos = self.playerGrabMgr.pos,
    winnerPosList = posList,
    huCard = byteCard,
    isQiangGang = self.isQiangGanging,
    zhuangPos = zhuangCopy,
    })
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