-- 2016.9.26 ptrjeffrey 
-- 游戏开始状态
-- 选庄，掷骰子，拿手牌，并补花
local MJConst = require("mj_core.MJConst")

local GameBegin = class("GameBegin")
local kDiceNumber = 0
local kBanker     =  1
local kRoundTime  = 7

local kRemoveCards = 0
local kAddCards   = 1
local kCardsMax   = 2

local kSendCardTime = 50
local kDiceTime     = 250

local kSubStateReady = 0
local kSubStatePlaying = 1

--- 相关状态枚举
local kStatusGame = 6
local kStatusBiXiaHu  = 8
 --- 游戏状态
 local kStatusReady = 0
 local kStatusPlaying = 1
 local kStatusOver = 2
 
 --- 抢牌超时时间
 local kGrabTime = 10

function GameBegin:ctor(gameProgress, stateId)
    self.gameProgress = gameProgress
    self.stateId = stateId
    self.subState = kSubStatePlaying
end

-- 掷骰子
function GameBegin:onDice()
    local dice1 = math.random(1, 6)
    local dice2 = math.random(1, 6)
    local operSeq = self.gameProgress:getOperationSeq()
        
    self.gameProgress:broadcastPlayerClientNotify(
        operSeq,
        kDiceNumber, {dice1, dice2})

    self.gameProgress:broadcastPlayerClientNotify(
        operSeq,
        kRoundTime, 
    {self.gameProgress.room.roundTime, kGrabTime})
    
    -- 发送游戏状态变化
    -- self.subState = kStatusPlaying
    -- operSeq = self.gameProgress:getOperationSeq()
    -- self.gameProgress:broadcastPlayerClientNotify(
    --     operSeq,
    --     kStatusGame,
    --     {self.subState}
    -- )
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
            v:addHandCard(self.mjWall:getFrontCard())
        end
    end
    self.playerList[self.gameProgress.banker]:addNewCard(self.mjWall:getFrontCard())
    --dump(self.playerList, "dealHandCards.")
end

-- 新的拿手牌
function GameBegin:dealHandCardsNew()
    self:dealHandCards()
    self:buHuaNew()
end

function GameBegin:buHuaNew()
    for k, v in pairs(self.playerList) do
        while(v:hasHua()) do
            local huaByteCard = v:getHua()
            v:addHuaWithoutHis(huaByteCard)
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

function GameBegin:clearAllOperList()
    for k, v in pairs(self.playerList) do
        v:clearOperList()
    end
end
------- 系统事件 --------
function GameBegin:onEntry(args)
    self.gameProgress.curGameState = self
    
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
    pkg.huaList ={{}, {}, {} ,{}}
    for i, v in pairs(playerList) do
        pkg.huaList[i].cards = v:getHuaListForClient()
    end
    self.gameProgress:sendMsgToUidNotifyEachPlayerCards(_pos, pkg)
    -- 发送牌池牌数
    self.gameProgress:broadCastWallDataCountNotify()
    -- 发送当前掉线玩家
    -- self.gameProgress:deleteCutUserByPos(pos)
    -- self.gameProgress:broadcastCutUserList()
    self.gameProgress:sendTotalScore(_uid)

    -- 发送嘎分
    for pos = 1,self.gameProgress.maxPlayerCount do
        if self.gameProgress.isShangGa == false then
           self.gameProgress:broadcastPlayerShangGa(0, pos, 0) 
        else
            if self.gameProgress.gaList[pos] then
                self.gameProgress:broadcastPlayerShangGa(1, pos, self.gameProgress.gaList[pos])
            end
        end
    end
    
    local operSeq = self.gameProgress:getOperationSeq()
end

function GameBegin:gotoNextState()
    self:clearAllOperList()
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