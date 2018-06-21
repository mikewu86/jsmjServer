local PokerConst = require("poker_core.PokerConst")
require("DDZ3Algorithm")

local GamePlaying = class("GamePlaying")

local kStatusPlaying = 1

local ROLE = {
    kNull     = 0,
    kFarmer   = 1,
    kLandLord = 2,
}

function GamePlaying:ctor(gameProgress, stateId)
    self.gameProgress = gameProgress
    self.stateId = stateId
    self.opTimeoutHandle = -99999
    self.lastOutCardPos = -1
    self.currentOutCardPos = -1
    self.winnerPos = -1
end

function GamePlaying:onEntry(args)
    self.gameProgress.curGameState = self
    self.subState = kStatusPlaying
    self.playerList = self.gameProgress.playerList
    self.outCards = self.gameProgress.outCards
    --- 设置当前庄家操作
    self.currentOutCardPos = self.gameProgress.landLordPos
    self.OperationTimeOut = self.gameProgress.room.roundTime * 100 --- 发送操作后超时时间
    
    -- 地主开始出牌
    self:outCardReq(self.currentOutCardPos)
end

function GamePlaying:outCardReq(_pos)
    if self.currentOutCardPos ~= _pos then
        return
    end
    local player = self.playerList[_pos]
    if player == nil then
        LOG_ERROR("nil player in GamePlaying:outCardReq")
        return
    end
    -- 首次出牌，不能过
    if #self.outCards == 0 then
        self.gameProgress:playerPlayCardReq(_pos, PokerConst.getOpsValue({PokerConst.kOperPlay}))
        self.opTimeoutHandle = self.gameProgress:setTimeOut(self.OperationTimeOut,
            function()
                -- 超时出最后一张，最小牌
                self:playerDoPlayCard(self.currentOutCardPos, player.handCards[#player.handCards])
            end, nil)
    -- 当前请求操作的玩家是最后一次的操作者，等于没人应牌，也不能过
    elseif self.currentOutCardPos == self.outCards[#self.outCards].pos then
        self.gameProgress:playerPlayCardReq(_pos, PokerConst.getOpsValue({PokerConst.kOperPlay}))
        self.opTimeoutHandle = self.gameProgress:setTimeOut(self.OperationTimeOut,
            function()
                -- 超时出最后一张，最小牌
                self:playerDoPlayCard(self.currentOutCardPos, player.handCards[#player.handCards])
            end, nil)
    else
        self.gameProgress:playerPlayCardReq(_pos, PokerConst.getOpsValue({PokerConst.kOperPlay, PokerConst.kOperPass}))
        self.opTimeoutHandle = self.gameProgress:setTimeOut(self.OperationTimeOut,
            function()
                -- 超时默认过牌
                self:playerDoPass(self.currentOutCardPos)
            end, nil)
    end
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
end

function GamePlaying:gotoNextState()
    local args = {}
    local winPos = {}
    table.insert(winPos, self.winnerPos)
    -- 农民胜
    if self.winnerPos ~= self.landLordPos then
        for pos, player in ipairs(self.playerList) do
            -- 另一个农民加到table中
            if player:getRole() == ROLE.kFarmer and pos ~= self.winnerPos then
                table.insert(winPos, pos)
            end
        end
    end

    args.winPos = winPos
    args.playerSetDouble = self.gameProgress.playerSetDouble
    self.gameProgress.gameStateList[self.gameProgress.kGameEnd]:onEntry(args)
end

-- 来自客户端的消息
function GamePlaying:onClientMsg(_pos, _pkg)
    local opPlayer = self.playerList[_pos]
    -- 判断玩家是不是该玩家操作
    if _pos ~= self.currentOutCardPos then
        return
    end
    if _pkg.Operation ~= PokerConst.kOperPlay or _pkg.Operation ~= PokerConst.kOperPass then
        return
    end
    -- 删除超时定时器
    self:deleteTimeOut(self.opTimeoutHandle)
    if _pkg.Operation == PokerConst.kOperPlay then
        self:playerDoPlayCard(_pos, _pkg.Cards)
    elseif _pkg.Operation == PokerConst.kOperPass then
        self:playerDoPass(_pos)
    end
end

function GamePlaying:playerDoPlayCard(_pos, _cards)
    if self.currentOutCardPos ~= _pos then
        return
    end
    local player = self.playerList[_pos]
    if player == nil then
        LOG_ERROR("nil player in GamePlaying:playerDoPlayCard")
        return
    end

    -- 判断出牌是否合法
    if #_cards == 0 then return end
    if not player:hasCards(_cards) then return end

    -- 是否是第一次出牌
    local lastOutCardList = self.outCards[#self.outCards]
    if nil == lastOutCardList or #lastOutCardList == 0 or 
    self.outCards[#self.outCards].pos == self.currentOutCardPos then
        -- 第一次出或无应牌 随便出
        local pockerList = PokerConst.tanslateCardsToValues(_cards)
        local tp = matchPockerType(pockerList)
        if not tp.bFind then
            LOG_ERROR("Invalid out card.")
            dump(_cards)
            return
        end

        -- 加入记录，删除手中牌
        local outCardInfo = table.clone(_cards)
        outCardInfo.pos = player:getDeskPos()
        table.insert(self.outCards, outCardInfo)
        player:removeCards(_cards)

        -- 数据包通知
        self.gameProgress:playerOutCardsRes_All(PokerConst.getOpsValue({PokerConst.kOperPlay}), self.currentOutCardPos, _cards)

        -- 看是否出完了
        if player:getHandCardsCount() == 0 then
            self.winnerPos = _player:getDeskPos()
            self:gotoNextState()
            return
        else
            -- 确定下家并出牌
            self.lastOutCardPos = self.currentOutCardPos
            self.currentOutCardPos = self.gameProgress:nextPlayerPos(self.lastOutCardPos)
            self:outCardReq(self.currentOutCardPos)
        end
    else
        -- 看看是否能应牌
        local lastOutCards = self.outCards[#self.outCards]
        local cardsA = PokerConst.tanslateCardsToValues(_cards)
        local cardsB = PokerConst.tanslateCardsToValues(lastOutCards)
        local cardsAType = matchPockerType(cardsA)
        local cardsBType = matchPockerType(cardsB)
        local bValid, bMore = getMaxPockerType(cardsAType, cardsBType)
        if not bValid then
            dump(_cards)
            return
        end

        if 0 >= bMore then
            LOG_ERROR("Invalid out card")
            dump(_cards)
            return
        end

        -- 加入记录，删除手中牌
        local outCardInfo = table.clone(_cards)
        outCardInfo.pos = player:getDeskPos()
        table.insert(self.outCards, outCardInfo)
        player:removeCards(_cards)

        self.gameProgress:playerOutCardsRes_All(PokerConst.getOpsValue({PokerConst.kOperPlay}), self.currentOutCardPos, _cards)

        -- 看是否出完了
        if  player:getHandCardsCount() == 0 then
            self.winnerPos = _player:getDeskPos()
            self:gotoNextState()
        else
            -- 确定下家并出牌
            self.lastOutCardPos = self.currentOutCardPos
            self.currentOutCardPos = self.gameProgress:nextPlayerPos(self.lastOutCardPos)
            self:outCardReq(self.currentOutCardPos)
        end
    end
end

function GamePlaying:playerDoPass(_pos)
    local player = self.playerList[_pos]
    if player == nil then
        LOG_ERROR("nil player in GamePlaying:playerDoPass")
        return
    end

    self.gameProgress:playerPassCardRes_All(PokerConst.getOpsValue({PokerConst.kOperPass}), self.currentOutCardPos)
    self.lastOutCardPos = self.currentOutCardPos
    self.currentOutCardPos = self.gameProgress:nextPlayerPos(self.lastOutCardPos)
    self:outCardReq(self.currentOutCardPos)
end

--- private funtion
function GamePlaying:timeOutHandle()
    LOG_DEBUG("timeout to continue.")
end

function GamePlaying:deleteTimeOut(_handle)
    self.gameProgress:deleteTimeOut(_handle)
end

return GamePlaying