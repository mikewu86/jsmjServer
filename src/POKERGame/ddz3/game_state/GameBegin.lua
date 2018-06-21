local PokerConst = require("poker_core.PokerConst")
local PokerCardPool = require("poker_core.PokerCardPool")

local GameBegin = class("GameBegin")

local kSendCardTime = 50
local kCallPointTime = 50
local kGrabLandLordTime = 50
local kSendLandLordCardsTime = 50
local kDoubleScoreTime = 50

local kwaitCallPointTime = 5 * 100  -- 等待叫分
local kwaitGrabLandLordTime = 3 * 100 -- 等待抢地主
local kwaitDoubleScoreTime = 3 * 100 -- 等待加倍

-- playerClientNotify类型
local kStatusGame = 0  -- 游戏状态
local kLandLord = 1  -- 玩家身份

-- 游戏状态值
local kStatusReady = 0
local kStatusPlaying = 1
local kStatusOver = 2

local grabLandLordUpLimit = 3

local ROLE = {
    kNull     = 0,
    kFarmer   = 1,
    kLandLord = 2,
}

function GameBegin:ctor(gameProgress, stateId)
    self.gameProgress = gameProgress
    self.stateId = stateId
    self.subState = kStatusReady
end

function GameBegin:sendHandCards()
    LOG_DEBUG("GameBegin:sendHandCards")
    -- 一张一张循环发牌，直到剩余3张
    while self.cardPool:getCardsCount() > 3 do
        for pos, player in pairs(self.gameProgress.playerList) do
            local card = self.cardPool:popCard()
            player:addHandCard(card)
        end
        self.gameProgress:addHandCardNotifyReq(pos, {card})
    end

    -- 进入叫分流程
    self.gameProgress:setTimeOut(kCallPointTime,
        function()
            self:initCallPointData()
            -- 从1号位开始叫分
            self:callPointReq(self.firstCallPointPos)
        end, nil)
end

function GameBegin:initCallPointData()
    -- 初始化叫分数据
    self.firstCallPointPos = 1
    self.currentCallPointPos = self.firstCallPointPos
    self.maxCallPointPos = -1
    self.callPoint = -1
end

function GameBegin:callPointReq(_pos)
    local player = self.playerList[_pos]
    if nil == player then
        LOG_ERROR("nil player in GameBegin:callPointReq")
        return
    end

    self.waitPlayHandle = self.gameProgress:setTimeOut(kwaitCallPointTime,
                function()
                    self.waitPlayHandle = nil
                    self.gameProgress:playerCallPointReq(_pos)
                    -- 超时默认pass
                    self:playerCallPoint(_pos, {Operation = PokerConst.kOperPass})
                end, nil)
end

function GameBegin:playerCallPoint(_pos, _pkg)
    --  判断是否为当前的玩家
    if _pos ~= self.currentCallPointPos then return end
    
    if _pkg.Operation == PokerConst.kOperCallPoint then
        if _pkg.Param > self.callPoint then
            if _pkg.Param == 3 then
                --  直接当地主了
                self.callPoint = _pkg.Param
                self.maxCallPointPos = _pos
                --  进入抢地主流程
                self.gameProgress:setTimeOut(kGrabLandLordTime,
                    function()
                        self:initGrabLandLordData()
                        self:grabLandLordReq(self.gameProgress:nextPlayerPos(_pos))
                    end, nil)
            else
                self.callPoint = _pkg.Param
                self.maxCallPointPos = _pos
                local nextCallPos = self.gameProgress:nextPlayerPos(_pos)
                if nextCallPos == self.firstCallPointPos then
                    -- 叫分一轮了 开始抢地主
                    self.gameProgress:setTimeOut(kGrabLandLordTime,
                        function()
                            self:initGrabLandLordData()
                            self:grabLandLordReq(self.gameProgress:nextPlayerPos(_pos))
                        end, nil)
                else
                    -- 下一个玩家开始抢分
                    self.currentCallPointPos = nextCallPos
                    self.gameProgress:setTimeOut(kCallPointTime,
                        function()
                            self:callPointReq(self.currentCallPointPos)
                        end, nil)
                end
            end

            processed = true
        end
    elseif _pkg.Operation == PokerConst.kOperPass then
        local nextCallPos = self.gameProgress:nextPlayerPos(_pos)
        if -1 == self.callPoint and nextCallPos == self.firstCallPointPos then
            -- 没人叫分 则重新发牌
            self:onEntry()
        else
            -- 下一个玩家开始抢分
            self.currentCallPointPos = nextCallPos
            self.gameProgress:setTimeOut(kCallPointTime,
                function()
                    self:callPointReq(self.currentCallPointPos)
                end, nil)
        end
    end
end

function GameBegin:initGrabLandLordData()
    -- 初始化抢地主数据
    self.currentGrabLandLordPos = self.gameProgress:nextPlayerPos(self.maxCallPointPos)
    self.landLordPos = self.maxCallPointPos
    self.cannotGrabPos = {}
    self.grabLandLordScoreMulti = 1
    self.grabLandLordCounts = 0
end

function GameBegin:grabLandLordReq(_pos)
    local player = self.playerList[_pos]
    if nil == player then
        LOG_ERROR("nil player in GameBegin:grabLandLordReq")
        return
    end

    self.waitPlayHandle = self.gameProgress:setTimeOut(kwaitGrabLandLordTime,
                function()
                    self.waitPlayHandle = nil
                    self.gameProgress:playerGrabLandLordReq(_pos)
                    -- 超时默认pass
                    self:playerGrabLandLord(_pos, {Operation = PokerConst.kOperPass})
                end, nil)
end

function GameBegin:playerGrabLandLord(_pos, _pkg)
    local processed = false
    -- 判断是否为当前的玩家
    if _pos ~= self.currentGrabLandLordPos then return end

    if _pkg.Operation == PokerConst.kOperGrabLL then
        -- 抢地主了
        self.landLordPos = _pos

        --  判断下一个抢地主的玩家
        local nextGrabPos = nil
        self.grabLandLordScoreMulti = self.grabLandLordScoreMulti * 2
        -- 判断下一个可以抢地主的位置
        while true do
            nextGrabPos = self.gameProgress:nextPlayerPos(_pos)
            --  判断是否可以进行抢地主操作
            local canGrab = true
            for _, v in ipairs(self.cannotGrabPos) do
                if v == nextGrabPos then
                    canGrab = false
                end
            end

            self:grabLandLordLimit(nextGrabPos)

            -- 下一个玩家可以抢地主,或者已经没有玩家可以抢了
            if canGrab or nextGrabPos == _pos then
                break
            end
        end
        if nextGrabPos == self.landLordPos then --- 只要有人抢永远不成立
            --  没有下个可以抢的了 则发底牌
            self.gameProgress:setTimeOut(kSendLandLordCardsTime,
                function()
                    self:sendLandLordCards()
                end, nil)
        else
            --  下一个玩家抢地主
            self.currentGrabLandLordPos = nextGrabPos
            self.gameProgress:setTimeOut(kGrabLandLordTime,
                function()
                    self:grabLandLordReq()
                end, nil)
        end
    elseif _pkg.Operation == PokerConst.kOperPass then
        --  不抢地主，加入到 cannotGrabPos
        table.insert(self.cannotGrabPos, _pos)
        local nextGrabPos = nil

        while true do
            nextGrabPos = self.gameProgress:nextPlayerPos(_pos)
            --  判断是否可以进行抢地主操作
            local canGrab = true
            -- 如果以前已经放弃，不能再抢地主
            for _, v in ipairs(self.cannotGrabPos) do
                if v == nextGrabPos then
                    canGrab = false
                end
            end

            self:grabLandLordLimit(nextGrabPos)

            if canGrab or nextGrabPos == self.landLordPos then
                break
            end
        end
        -- 叫地主最高的人，没有其他人叫地主了 或者两个人都已经pass了，则进入下一步
        if nextGrabPos == self.landLordPos then
            --  没有下个可以抢的了 则发底牌
            self.gameProgress:setTimeOut(kSendLandLordCardsTime,
                function()
                    self:sendLandLordCards()
                end, nil)
        else
            --  下一个玩家抢地主
            self.currentGrabLandLordPos = nextGrabPos
            self.gameProgress:setTimeOut(kGrabLandLordTime,
                function()
                    self:grabLandLordReq()
                end, nil)
        end
    end
end

function GameBegin:grabLandLordLimit(_pos)
    if self.maxCallPointPos == _pos then
        self.grabLandLordCounts = self.grabLandLordCounts + 1
        if self.grabLandLordCounts >= grabLandLordUpLimit then
            self.gameProgress:setTimeOut(kSendLandLordCardsTime,
                function()
                    self:sendLandLordCards()
                end, nil)
        end
    end
end

function GameBegin:sendLandLordCards()
    -- 发给地主底牌
    self.baseCards = {}
    local player = self.playerList(self.landLordPos)
    if nil == player then
        LOG_ERROR("nil player in GameBegin:sendLandLordCards")
        return
    end
    -- 设置玩家身份
    for pos, player in pairs(self.playerList) do
        if pos == self.landLordPos then
            player:setRole(ROLE.kLandLord)
        else
            player:setRole(ROLE.kFarmer)
        end
    end
    self.gameProgress:playerClientNotify(kLandLord, {self.landLordPos})
    for i = 1, 3 do
        local card = self.cardPool:popCard()
        table.insert(self.baseCards, card)
        player:addHandCard(card)
    end
    -- 发底牌给地主
    self.gameProgress:addHandCardNotifyReq(self.landLordPos, self.baseCards)
    -- 通知底牌给所有玩家
    self.gameProgress:baseCardNotify(self.baseCards)

    self.gameProgress:setTimeOut(kDoubleScoreTime,
                function()
                    self:doubleScoreReq()
                end, nil)
end

function GameBegin:doubleScoreReq()
    self.gameProgress:setTimeOut(kwaitDoubleScoreTime,
                function()
                    self.gameProgress:playerDoubleScoreReq()
                end, nil)
end

function GameBegin:playerDoubleScore(_pos, _pkg)
    LOG_DEBUG("GameBegin:playerDoubleScore")
    local player = self.playerList[_pos]
    if player == nil then
        LOG_ERROR("nil player in GameBegin:playerDoubleScore")
        return
    end
    self.playerSetDouble[_pos] = self.playerSetDouble[_pos] * 2
    self:gotoNextState()
end

------- 系统事件 --------
function GameBegin:onEntry(args)
    self.gameProgress.curGameState = self
    self.gameProgress:clear()       -- 数据重置
    -- 简化变量名
    self.cardPool = self.gameProgress.PokerCardPool
    self.playerList = self.gameProgress.playerList
    self.landLordPos = self.gameProgress.landLordPos
    self.playerSetDouble = self.gameProgress.playerSetDouble
    -- 牌墙初始化
    self.cardPool:init(true)
    self.cardPool:shuffle()
    -- 游戏状态通知
    self.subState = kStatusPlaying
    self.gameProgress:playerClientNotify(kStatusGame, {self.subState})

    -- 发基础牌
    self.gameProgress:setTimeOut(kSendCardTime,
        function()
            self:sendHandCards()
        end, nil)
end

function GameBegin:onExit()
end

function GameBegin:onPlayerComin(_player)

end

function GameBegin:onPlayerLeave(uid)
end

function GameBegin:onPlayerReady()
end

function GameBegin:onUserCutBack(_pos)
end

function GameBegin:gotoNextState()
    self.gameProgress.gameStateList[self.gameProgress.kGamePlaying]:onEntry()
end

-- 来自客户端的消息
function GameBegin:onClientMsg(_pos, _pkg)
    if _pkg.Operation == PokerConst.kOperCallPoint then
        self:playerCallPoint(_pos, _pkg)
    elseif _pkg.Operation == PokerConst.kOperGrabLL then
        self:playerGrabLandLord(_pos, _pkg)
    elseif _pkg.Operation == PokerConst.kOperDoubleScore then
        self:playerDoubleScore(_pos, _pkg)
    end
end

return GameBegin