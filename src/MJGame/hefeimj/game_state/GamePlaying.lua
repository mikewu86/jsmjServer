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
local kWaitGrabTimeOut = 10 * 100
local kTuoGuanTimeOut  = 3  * 100
local kBuHuaTimeOut    = 0.5 * 100

local kHaiLaoWait      = 2 * 100

local kRemoveCards = 0
local kAddCards   = 1

local kSkynetKipTime = 100

-- 及时结算花数
-- local kAGHua = 4
-- local kMGHua = 6 -- 面下杠也按照明杠计算
local kOutFourContinueSameCardHua = 6
-- local kHGHua = 12

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
    self:checkMyOper(self.gameProgress.banker)
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
            -- 出牌
            table.insert(operList, MJConst.kOperPlay)
            operMap[MJConst.kOperPlay] = {}
            local cancel = false
            -- 胡牌
            if player:canSelfHu() or player:canSelfHuQiDui() then
                self.countHuType:setParams(
                turn, 
                self.gameProgress, 
                nil, 
                nil,
                self.isQiangGang)
                self.countHuType:calculate()
                -- local bHu = false
                -- if #player.huaList >= 4 then
                --     bHu = true
                -- else -- 小于4硬花，看有没有大胡
                --     if self.countHuType:hasHuType(HuTypeConst.kHuType.kMengQing) then
                --         bHu = true
                --     else
                --         for k, huType in pairs(HuTypeConst.kDaHuTypeList) do
                --             if self.countHuType:hasHuType(huType) then
                --                 bHu = true
                --                 break
                --             end
                --         end
                --     end
                -- end
                -- if bHu then
                table.insert(operList, MJConst.kOperHu)
                operMap[MJConst.kOperHu] = {player.newCard}
                cancel = true
                -- end
            end
            -- 暗杠
            local anGangCardList = player:getAnGangCardList()
            if #anGangCardList > 0 then
                table.insert(operList, MJConst.kOperAG)
                operMap[MJConst.kOperAG] = anGangCardList
                cancel = true
            end
            -- -- 面下杠
            -- local mxGangCardList = player:getMXGangCardList()
            -- if #mxGangCardList > 0 then
            --     table.insert(operList, MJConst.kOperMXG)
            --     operMap[MJConst.kOperMXG] = mxGangCardList
            --     cancel = true
            -- end
            -- 取消操作
            if cancel then
                table.insert(operList, MJConst.kOperCancel)
                operMap[MJConst.kOperCancel] = {}
            end
            -- dump(operList, "check my op operList")
            -- 数据放入可操作玩家
            self.playerGrabMgr:addCanDoItem(turn, operList)
            self.playerGrabMgr:setPos(turn)
            self.playerCanDoMap[turn] = operMap
            -- send to client
            local tipData = {}
            for k, v in pairs(operMap) do
                tipData[k] = table.copy(v)
            end
            self.gameProgress:sendMsgSetOperationTipCardsNotify(turn, tipData)
            self.playerCanDoMap[turn].operList = operList
            -- 等待玩家操作
            if self.countHuType.isAutoHu then
                self.gameProgress:deleteTimeOut(self.waitPlayHandle)
                self.playerGrabMgr:playerDoGrab(turn, MJConst.kOperHu, player.newCard)
                self:doHu(turn, player.newCard)
                return
            else
                local seq = self.gameProgress:incOperationSeq()
                self.gameProgress:broadcastMsgPlayerOperationReq(seq, turn, true, MJConst.getOpsValue(operList))
                self.gameProgress:deleteTimeOut(self.waitPlayHandle)
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
                LOG_DEBUG("can hu")
                self.countHuType:setParams(
                    pos, 
                    self.gameProgress, 
                    byteCard, 
                    turn,
                    self.isQiangGang)
                self.countHuType:calculate()
                -- local bHu = false
                -- if #player.huaList >= 4 then
                --     bHu = true
                -- else -- 小于4硬花，看有没有大胡
                --     if self.countHuType:hasHuType(HuTypeConst.kHuType.kMengQing) then
                --         bHu = true
                --     else
                --         for k, huType in pairs(HuTypeConst.kDaHuTypeList) do
                --             if self.countHuType:hasHuType(huType) then
                --                 bHu = true
                --                 break
                --             end
                --         end
                --     end
                -- end
                -- if bHu then
                if self.countHuType.isAutoHu then
                    autoHuPos = pos
                end
                table.insert(operList, MJConst.kOperHu)
                operMap[MJConst.kOperHu] = {byteCard}
                cancel = true
                -- end
            end
        end
        -- -- 明杠
        -- if player:canGang(byteCard) then
        --     LOG_DEBUG("can gang")
        --     table.insert(operList, MJConst.kOperMG)
        --     operMap[MJConst.kOperMG] = {byteCard}
        --     cancel = true
        -- end
        -- -- 碰 之前有漏碰过的就不能再胡同一张牌了
        -- if not self.mjCancelMgr:isCancelOper(pos, MJConst.kOperPeng, byteCard) then
        --     if player:canPeng(byteCard) then
        --         LOG_DEBUG("can peng")
        --         table.insert(operList, MJConst.kOperPeng)
        --         operMap[MJConst.kOperPeng] = {byteCard}
        --         cancel = true
        --     end
        -- end
        -- 取消操作
        if cancel then
            LOG_DEBUG("can cancel")
            table.insert(operList, MJConst.kOperCancel)
            operMap[MJConst.kOperCancel] = {}
        end

        -- send to client 需要拷贝一份数据出来，以免影响原来的数据
        local tipData = {}
        for k, v in pairs(operMap) do
            tipData[k] = table.copy(v)
        end
        -- 先显示玩家可操作的动作
        if #operList > 1 then
            self.gameProgress:sendMsgSetOperationTipCardsNotify(pos, tipData)
            local seq = self.gameProgress:incOperationSeq()
            self.gameProgress:broadcastMsgPlayerOperationReq(seq, pos, true, MJConst.getOpsValue(operList))
            hasGrab = true
        end
        -- 数据放入可操作玩家
        self.playerGrabMgr:addCanDoItem(pos, table.copy(operList))
        self.playerCanDoMap[pos] = operMap
        self.playerCanDoMap[pos].operList = operList
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
    local playerList = self.gameProgress.playerList
    local riverList = self.gameProgress.riverCardList
    local pkg = {}
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
    self.gameProgress:sendMsgToUidNotifyEachPlayerCards(_pos, pkg)
    ---6. 同步花杠数量
    local seq = self.gameProgress:getOperationSeq()
    local player = playerList[_pos]
    self.gameProgress:huaGangNumNotify(seq, _pos, player:getHuaGangNum(), nil)
    ---7. 剩余牌数
    self.gameProgress:broadCastWallDataCountNotify()
    -- todo...
end

function GamePlaying:gotoNextState(args)
    self.gameProgress:deleteTimeOut(self.waitPlayHandle)
    self.gameProgress:deleteTimeOut(self.waitGrabHandle)
    self.gameProgress.gameStateList[self.gameProgress.kGameEnd]:onEntry(args)
end

function GamePlaying:gotoHaiLaoState(args)
    self.gameProgress:deleteTimeOut(self.waitPlayHandle)
    self.gameProgress:deleteTimeOut(self.waitGrabHandle)
    self.gameProgress.gameStateList[self.gameProgress.kHaiLao]:onEntry(args)
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
        LOG_DEBUG("_pkg.operation invalid")
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
                LOG_DEBUG("player no has this card:")
                return
            end
        end
        if true == self:needWait(oper) then
            LOG_DEBUG("exec op.")
            self:grabEnd()            
        else
            LOG_DEBUG("waiting... oper.")
        end

    else
        LOG_DEBUG("player no this oper:"..oper)
        -- dump(canDoMap, "canDoMap")
    end
end

--- 复写 一炮多响的等待判断
function GamePlaying:needWait(oper)
    local bPowerestWait = self.playerGrabMgr:needWait()
    local bNotWaitHuMore = true
    local bRet = false
    if MJConst.kOperHu  == oper then
        -- 查找胡操作玩家 的数量
        bNotWaitHuMore = false
        local canHuNum = 0
        for _, item in pairs(self.playerGrabMgr.canGrabMgr.itemList) do 
            if nil ~= table.keyof(item.operList, MJConst.kOperHu) then
                canHuNum = canHuNum +1
            end
        end
        if 0 == canHuNum then
            bNotWaitHuMore = true
        end
    end
    bRet = (false == bPowerestWait) and (true == bNotWaitHuMore)
    return bRet
end

-- 出牌
function GamePlaying:onPlayCard(_pos, _pkg)
    LOG_DEBUG("on PlayCard")
    local pkg = _pkg
    local pos = _pos
    -- if pkg.OperationSeq ~= self.gameProgress:getOperationSeq() then
    --     LOG_DEBUG('-- 玩家的出息索引不正确 --')
    --     return
    -- end
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
        LOG_DEBUG('-- 玩家出牌出错 --'..byteCard)
        -- dump(player.cardList)
        -- dump(player.newCard)
        return
    end
    self.gameProgress:deleteTimeOut(self.waitPlayHandle)
    self.playerGrabMgr:playerDoGrab(pos, MJConst.kOperPlay, byteCard)
    self.playerCanDoMap[pos] = {}
    self.riverCardList[pos]:pushCard(byteCard)
    local seq = self.gameProgress:incOperationSeq()
    self.gameProgress:opHandCardNotify(seq, pos, {pkg.card}, kRemoveCards)
    self.gameProgress:broadCastMsgOpOnDeskOutCard(seq, kAddCards, pos, pkg.card)
    -- -- 判断是不是1个人出四张一样的牌
    -- local river = self.riverCardList[pos]
    -- local playedCount = river:getCardCount(byteCard)
    -- -- LOG_DEBUG('playedCount = '..playedCount)
    -- if playedCount == 4 then  -- 这个玩家罚12花
    --     local sendPkg = {}
    --     sendPkg.Data = {}
    --     for i=1, self.gameProgress.maxPlayerCount do
    --         if i == pos then
    --             table.insert(sendPkg.Data, {pos = i, money = math.ceil(-36 * self.gameProgress.unitCoin)}) 
    --         else
    --             table.insert(sendPkg.Data, {pos = i, money = math.ceil(12 * self.gameProgress.unitCoin)})
    --         end
    --     end
    --     self.gameProgress:broadcastOutCardMoney(sendPkg)
    -- end
    -- -- 判断是不是4个玩家出了一样的牌
    -- local isGeng4 = true
    -- local prevTurn = pos
    -- while (true) do
    --     prevTurn = self.gameProgress:prevPlayerPos(prevTurn)
    --     -- LOG_DEBUG('-- prevTurn = '..prevTurn)
    --     if prevTurn == pos then
    --         break
    --     end
    --     local prevRiver = self.riverCardList[prevTurn]
    --     local count = prevRiver:getCount()
    --     if count > 0 then
    --         if prevRiver.cardList[count] ~= byteCard then
    --             isGeng4 = false
    --             -- LOG_DEBUG('-- is Geng4 1 --')
    --             break
    --         end
    --     else
    --         isGeng4 = false
    --         -- LOG_DEBUG('-- is Geng4 2 --')
    --         break
    --     end
    -- end
    -- if isGeng4 then -- 当前出牌者的下家付钱
    --     local sendPkg = {}
    --     sendPkg.Data = {}
    --     local firstPos = self.gameProgress:prevPlayerPos(pos)
    --     for i=1, self.gameProgress.maxPlayerCount do
    --         if i == firstPos then
    --             table.insert(sendPkg.Data,{pos = i, money = math.ceil(-30 * self.gameProgress.unitCoin)}) 
    --         else
    --             table.insert(sendPkg.Data,{pos = i, money = math.ceil(10 * self.gameProgress.unitCoin)})
    --         end
    --     end
    --     self.gameProgress:broadcastOutCardMoney(sendPkg)
    -- end


    -- 判断其他玩家是否可以操作
    local hasGrab, autoHuPos = self:checkOtherOper(pos, byteCard)
    if not hasGrab then  -- 继续发牌
        LOG_DEBUG("继续发牌")
        -- self.playerGrabMgr:clear()
        -- self:giveNewCard(self.gameProgress:nextPlayerPos(pos))
        if self.mjWall:getCanGetCount() <= 5 then
            self.waitGrabHandle = self.gameProgress:setTimeOut(kHaiLaoWait,
                function()
                    self:giveNewCard(self.gameProgress:nextPlayerPos(pos))
                end, nil)
        else
            self:giveNewCard(self.gameProgress:nextPlayerPos(pos))
        end
    else  -- 等待抢牌
        if autoHuPos ~= nil then
            self.playerGrabMgr:playerDoGrab(autoHuPos, MJConst.kOperHu, byte)
            self:doHu(autoHuPos, byteCard)
        else
            LOG_DEBUG("其他玩家操作碰杠胡等")
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
    dump(grabNode, "PoWestNode")
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
                local seq = self.qiangGangInfo.seq
                local tPos = self.qiangGangInfo.pos
                local fromPos = self.qiangGangInfo.from
                local tbMoney = self.qiangGangInfo.money
                self.gameProgress:broadcastMsgFideGangMoney(seq, tPos, fromPos, self.unitCoin * kMGHua) 
                self.gameProgress:updatePlayersMoney(tbMoney, "立即结算面下杠")
                self.gameProgress:broadCastMsgUpdatePlayerData()
                self.isQiangGanging = false
                self.qiangGangInfo = {}
            end
            -- 如果当前玩家可以出牌，继续等待
            if table.keyof(self.playerCanDoMap[pos].operList, MJConst.kOperPlay) ~= nil then
                return
            end
            -- grabEnd的时候执行操作
            -- 动作取消后，给等待抓牌的人发牌
            self:giveNewCard(self.gameProgress:nextPlayerPos(grabedPos))
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
        LOG_DEBUG('-- buhua --'..huaByteCard)
        player:addHua(huaByteCard)
        -- 判断是否为花杠
        local bHuaGang = player:isHuaGang(huaByteCard)
        dump(bHuaGang,' is huaGang ')
        if true == bHuaGang then
            self.gameProgress:broadCastMsgFideHuaGangMoney(player:getDeskPos(), player:getHuaGangNum())
        end

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
        LOG_DEBUG('-- 补花出错，没有花牌 --')
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
    -- 海捞区，各摸一张
    if self.mjWall:getCanGetCount() <= 4 then
        self.gameProgress:broadCastWallDataCountNotify()
        self:gotoHaiLaoState({turn = turn})
        return
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
    -- if player:hasHua() then  -- 0.5秒后补花
    --     self.gameProgress:setTimeOut(kBuHuaTimeOut, 
    --     function()
    --         self:buHua(turn)
    --     end, nil)
    --     return
    -- end
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
        -- 同步玩家钱数变化
        tbMoney[pos] = money
        tbMoney[grabedPos] = 0 - money
        self.gameProgress:updatePlayersMoney(tbMoney, "立即结算明杠")
        self.gameProgress:broadCastMsgUpdatePlayerData()
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
                self.playerGrabMgr:playerDoGrab(autoHuPos, MJConst.kOperHu, byteCard)
                self:doHu(autoHuPos, byteCard)
            end
        else
            self.gameProgress:broadcastMsgFideGangMoney(seq, pos, fromPos, self.unitCoin * kMGHua) 
            self.gameProgress:updatePlayersMoney(tbMoney, "立即结算面下杠")
            self.gameProgress:broadCastMsgUpdatePlayerData()
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
        -- local money = self.unitCoin * kAGHua
        -- local tbMoney = {}
        -- 发送消息 增加面下杠不需要再发送删除之前碰牌数据，客户端自行处理
        self.gameProgress:opHandCardNotify(seq, pos, lCards, kRemoveCards)
        self.gameProgress:broadcastMsgAddGangCards(seq, pos, grabedPos, byteCard)
        -- self.gameProgress:broadcastMsgFideGangMoney(seq, pos, grabedPos, self.unitCoin * kAGHua) 
        -- -- 更新玩家钱数
        -- for i = 1, self.maxPlayerCount do 
        --     if i == pos then
        --         tbMoney[i] = money * 3
        --     else
        --         tbMoney[i] = 0 - money
        --     end
        -- end
        -- self.gameProgress:updatePlayersMoney(tbMoney, "立即结算暗杠")
        -- self.gameProgress:broadCastMsgUpdatePlayerData()
        if self.mjWall:getCanGetCount() <= 5 then
            self.gameProgress:setTimeOut(kHaiLaoWait,
                function()
                    self:giveNewCard(pos)
                end, nil)
        else
            self:giveNewCard(pos)
        end
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
        local itemList = self.playerGrabMgr.doneGrabMgr.itemList
        for _pos, item in pairs(itemList) do
            if table.keyof(item.operList, MJConst.kOperHu) ~= nil then
                table.insert(posList, _pos)
            end
        end
        local bMoreDian = false
        local canItemList = self.playerGrabMgr.canGrabMgr.itemList 
        for _, item in pairs(canItemList) do 
            if nil ~= table.keyof(item.operList, MJConst.kOperHu) then
                bMoreDian = true
                break
            end
        end
        -- if #posList > 1 or true == bMoreDian then
        --     self.gameProgress.banker = self.playerGrabMgr.pos
        -- else
        --     self.gameProgress.banker = pos         
        -- end
    else
        table.insert(posList, pos)
        -- self.gameProgress.banker = pos
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

return GamePlaying