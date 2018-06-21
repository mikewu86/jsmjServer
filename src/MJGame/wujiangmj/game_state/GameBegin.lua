-- 2016.9.26 ptrjeffrey 
-- 游戏开始状态
-- 选庄，掷骰子，拿手牌，并补花
local MJConst = require("mj_core.MJConst")

local GameBegin = class("GameBegin")
local kDiceNumber = 0
local kBanker     =  1
local kRoundTime  = 7
local kBaiDaCard  = 9

local kRemoveCards = 0
local kAddCards   = 1
local kCardsMax   = 2

local kSendCardTime = 50
local kDiceTime     = 250

local kSubStateReady = 0
local kSubStatePlaying = 1

--- 相关状态枚举
local kStatusGame = 6

local kStatusBaozi = 8

 --- 游戏状态
 local kStatusReady = 0
 local kStatusPlaying = 1
 local kStatusOver = 2
 
 --- 抢牌超时时间
 local kGrabTime = 10

function GameBegin:ctor(gameProgress, stateId)
    self.gameProgress = gameProgress
    self.stateId = stateId
    self.subState = kSubStateReady
end

-- 掷骰子
function GameBegin:onDice()
    local dice1 = math.random(1, 6)
    local dice2 = math.random(1, 6)

    self.gameProgress.m_bDiZero = false
    -- local firstPos = self.mjWall:getFrontIndex()
    local endPos = self.mjWall:getBackIndex()
    -- --- first dice calc endPos
    -- self.mjWall:setFrontIndex(dice2 * 2 + firstPos)
    -- --- second dice calc startPos
    -- self.mjWall:setBackIndex(endPos - dice1 * 2 - 1)
    if dice1 == dice2 then
        if self.gameProgress.roomRuleMap.wj_playrule_baozi == true then
            self.gameProgress.m_bDiZero = true
        end
    end
    local getRet, baidDaCard =  self.mjWall:canGetIndexCard(endPos - dice1 * 2 - 1)
    if getRet == true then
        self.mjWall:takeIndexCard(endPos - dice1 * 2 - 1)
    end
    local operSeq = self.gameProgress:getOperationSeq()
    self.gameProgress:broadcastPlayerClientNotify(
        operSeq,
        kDiceNumber, {dice1, dice2})

    --- send baida card.
    self.gameProgress:broadcastPlayerClientNotify(operSeq,
        kBaiDaCard, {MJConst.fromNow2OldCardByteMap[baidDaCard]})

    self.gameProgress:broadcastPlayerClientNotify(
        operSeq,
        kRoundTime,
    {self.gameProgress.room.roundTime, kGrabTime})
    
        -- 发送游戏状态变化
    self.subState = kStatusPlaying

    self.gameProgress:broadcastPlayerClientNotify(
        operSeq,
        kStatusGame,
        {self.subState}
    )
    
    --- set player daCard
    for pos = 1, self.gameProgress.maxPlayerCount do 
        self.gameProgress.playerList[pos]:setDaCard(baidDaCard)
    end
    self.gameProgress:broadcastBaoziZero(operSeq)
    return {dice1, dice2}
end

-- 选庄
function GameBegin:chooseBanker(dices)
    if self.gameProgress.banker == -1 then
        local sum = dices[1] + dices[2]
        self.gameProgress.banker = math.mod(sum, 4) + 1
    end

    local operSeq = self.gameProgress:incOperationSeq()
    self.gameProgress:broadcastPlayerClientNotify(
        operSeq,
        kBanker, 
    {self.gameProgress.banker})

    return self.gameProgress.banker
end

-- 拿手牌
function GameBegin:dealHandCards()
    for k, v in pairs(self.playerList) do
        for i = 1, 13 do
            local card = self.mjWall:getFrontCard()
            v:addHandCard(card)
            if v.daCard == card then
                v:addDaCard(card)
            end        
        end
    end
    local newCard = self.mjWall:getFrontCard()
    self.playerList[self.gameProgress.banker]:addNewCard(newCard)
    if self.playerList[self.gameProgress.banker].daCard == newCard then
        self.playerList[self.gameProgress.banker]:addDaCard(newCard)
    end
end

-- 新的拿手牌
function GameBegin:dealHandCardsNew()
    self:dealHandCards()
end

function GameBegin:buHuaNew()
    for k, v in pairs(self.playerList) do
        while(v:hasHua()) do
            local huaByteCard = v:getHua()
            table.insert(v.huaList, huaByteCard)
            local newByteCard = self.mjWall:getFrontCard()
            if not v:delHandCard(huaByteCard) then
                v:delNewCard(huaByteCard)
                v:addNewCard(newByteCard)
            else
                v:addHandCard(newByteCard)
            end
        end
    end
end

function GameBegin:sendHandCardNew()
    for pos, v in pairs(self.playerList) do
        self.gameProgress:sendDealHandCards(pos)
    end
end

-- 发送手牌,需要转换为原来的牌值
function GameBegin:sendHandCard()
    local _end = self.step * 4
    if _end > 13 then
        _end = 13
    end
    local tbBeginHandCardPos = {1, 8, 12, 13} 
    for k, v in pairs(self.gameProgress.playerList) do
        local handCards = v:getHandCards()
        local sendCards = {}
        for i = tbBeginHandCardPos[self.step], _end do
            table.insert( sendCards, handCards[i])
        end
        if _end == 13 and v.myPos == self.gameProgress.banker then
            table.insert(sendCards, v:getNewCard())
        end
        -- 发消息给客户端
        self.gameProgress:opBuHuaHandCardNotify(
            self.gameProgress:getOperationSeq(),
            v.myPos,
            sendCards,
            kAddCards
        )
    end
    
    self.step = self.step + 1
    if _end < 13 then
        self.gameProgress:setTimeOut(kSendCardTime,
        function()
            self:sendHandCard()
        end, nil)
    else
        self.gameProgress:setTimeOut(kSendCardTime,
        function()
            self:buHua()
        end, nil)
    end
end

-- 补花
function GameBegin:buHua()
    for k, v in pairs(self.playerList) do
        while(v:hasHua()) do
            local huaByteCard = v:getHua()
            v:addHua(huaByteCard)
            -- 判断是否为花杠
            -- local bHuaGang = v:isHuaGang(huaByteCard)
            -- if true == bHuaGang then
            --     self.gameProgress:broadCastMsgFideHuaGangMoney(v:getDeskPos(), v:getHuaGangNum())
            -- end

            local huaCardList = v:getHuaList()
            --发送增加花牌数消息
             self.gameProgress:broadcastFlowerCardCountNotify(
                 k, #huaCardList
             )

            local newByteCard = self.mjWall:getFrontCard()
            self.gameProgress:broadCastWallDataCountNotify()
            if not v:delHandCard(huaByteCard) then
                v:delNewCard(huaByteCard)
                v:addNewCard(newByteCard)
            else
                v:addHandCard(newByteCard)
            end

            -- 发消息给客户端
            self.gameProgress:opBuHuaHandCardNotify(
                self.gameProgress:getOperationSeq(),
                v.myPos,
                {huaByteCard},
                kRemoveCards
            )

            self.gameProgress:opBuHuaHandCardNotify(
                self.gameProgress:getOperationSeq(),
                v.myPos,
                {newByteCard},
                kAddCards   
            )
        end
    end
    -- 进入下一流程
    self.gameProgress:setTimeOut(kSendCardTime,
        function()
            self:gotoNextState()
        end, nil)
end

------- 系统事件 --------
function GameBegin:onEntry(args)
    self.gameProgress.curGameState = self
    self.gameProgress:clear()       -- 数据重置

    -- 简化变量名
    self.mjWall = self.gameProgress.mjWall
    self.playerList = self.gameProgress.playerList
    self.operHistory = self.gameProgress.operHistory

    local userList = {}
    for i=1,4 do
        local user = {}
        local data = self.playerList[i]:getPlayerInfo()
        user.uid         = data.uid
        user.nickname    = data.nickname
        user.sex         = data.sex
        user.money       = data.money
        user.sngScore    = data.sngScore
        user.pic_url     = data.pic_url
        user.user_ipaddr = data.user_ipaddr
        user.Pos         = data.Pos
        table.insert(userList,user)
    end

    self.operHistory:setPlayerList(userList)
    self.operHistory:setGameBegin()
    -- 牌墙初始化
    self.mjWall:init()
    self.mjWall:shuffle(3)
    --
    self.step = 1
    local dices = self:onDice()
    -- 同步玩家数据
    self.gameProgress:broadCastMsgUpdatePlayerData()
    -- 发送牌池牌数
    self.gameProgress:broadCastWallDataCountNotify()
    -- send player total score
    self.gameProgress:sendTotalScore()
    -- 发手牌
    self.gameProgress:setTimeOut(kDiceTime,
        function()
            self:chooseBanker(dices)
            self:dealHandCardsNew()
            self:sendHandCardNew()
            self:gotoNextState()
            -- self:dealHandCards()
            -- self:sendHandCard()
            -- 发送牌池牌数
            self.gameProgress:broadCastWallDataCountNotify()
        end, nil)

end

function GameBegin:onExit()
end

function GameBegin:onPlayerComin(_player)

end

function GameBegin:onPlayerLeave(uid)
    -- if self.gameProgress:addCutUserByUid(uid) then
    --     self.gameProgress:broadcastCutUserList()
    -- end
end

function GameBegin:onPlayerReady()
end

-- 在gameBegin中玩家手中牌操作比较复杂，需要根据当前的步骤来发送玩家手中牌。
-- 不用担心出现牌乱的问题， 因为时间片是轮询的，当前步骤self.step已经执行完成了。
--- 先在gamebegin中实现后续将其转入到GameProcess中处理，因为每个状态都会用到此消息处理函数
function GameBegin:onUserCutBack(_pos, uid)
    local playerList = self.gameProgress.playerList
    local pkg = {}
    ---init need info
    pkg.isWatcher = 0
    if self.gameProgress.room.watchers[uid] then
        pkg.isWatcher = 1
    end
    pkg.zhuangPos = self.gameProgress.banker
    pkg.gameStatus = self.subState
    pkg.myPos = _pos
    pkg.roundTime = self.gameProgress.room.roundTime
    pkg.grabTime = kGrabTime
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


    pkg.curOper = self.gameProgress.banker

    self.gameProgress:sendMsgToUidNotifyEachPlayerCards(_pos, pkg)
    -- 发送牌池牌数
    self.gameProgress:broadCastWallDataCountNotify()
    -- 发送当前掉线玩家
    -- self.gameProgress:deleteCutUserByPos(pos)
    -- self.gameProgress:broadcastCutUserList()
    self.gameProgress:sendTotalScore(_uid)
    self.gameProgress:broadcastPlayerClientNotify(self.gameProgress:getOperationSeq(),
        kBaiDaCard, {MJConst.fromNow2OldCardByteMap[playerList[1].daCard]})
    self.gameProgress:broadcastBaoziZero(self.gameProgress:getOperationSeq())
end

function GameBegin:gotoNextState()
    self.gameProgress.gameStateList[self.gameProgress.kGamePlaying]:onEntry()
end

-- 来自客户端的消息
function GameBegin:onClientMsg(_pos, _pkg)
    if MJConst.kOperSyncData == _pkg.operation then -- 同步
        self:playerOpeartionSyncData(_pos)
    end
end

function GameBegin:playerOpeartionSyncData(_pos)
    self:onUserCutBack(_pos)
end

return GameBegin