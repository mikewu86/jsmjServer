-- 2016.10.21 ptrjeffrey 
-- 测试用例,一个瞬时状态，主要看输出对不对
-- 测内容
local MJConst = require("mj_core.MJConst")
local MJPile = require("mj_core.MJPile")

local TestCase = class("TestCase")

function TestCase:ctor(gameProgress, stateId)
    self.gameProgress = gameProgress
    self.stateId = stateId
    self.playerList = gameProgress.playerList
    self.riverCardList = gameProgress.riverCardList
end

function TestCase:onEntry(args)
    self.gameProgress.curGameState = self
    ---先通知客户端游戏状态
    local seq = self.gameProgress:incOperationSeq()
    -- 做测试条件
    self:giveHandCard1()
    self:test(
    {isLiuJu = false, 
    isZiMo = false,
    fangPaoPos = 3,
    winnerPosList = {1},
    --huCard = MJConst.Zi3,
    isQiangGang = false })
end

function TestCase:onExit()
end

function TestCase:test(args)
    local endState =self.gameProgress.gameStateList[self.gameProgress.kGameEnd]
    endState:initCountHuType(args)
    endState:calculate(args)
end

function TestCase:gotoNextState(args)
    self.gameProgress.gameStateList[self.gameProgress.kGameBegin]:onEntry(args)
end

-- 来自客户端的消息
function TestCase:onClientMsg(_pos, _pkg)
end

-- 有玩家离开时要下庄
function TestCase:onPlayerLeave(uid)
    self.gameProgress.banker = -1
end

function TestCase:onPlayerReady()
end

function TestCase:onPlayerComin(_player)
    local pos = _player:getDeskPos()
    local uid = _player:getUid()
    local money = _player:getMoney()
    if nil ~= self.gameProgress.playerList[pos] then
        self.gameProgress.playerList[pos]:setUid(uid)
        self.gameProgress.playerList[pos]:setMoney(money)
        self.gameProgress.playerList[pos]:setDeskPos(pos)
        self.gameProgress.playerList[pos]:setAgent(_player:getAgent())
        self.gameProgress.playerList[pos]:setClientFD(_player:getClientFD())
    end
end

function TestCase:onUserCutBack(_pos)
end

-- 测试包牌
function TestCase:giveHandCard1()
    -- 要胡的玩家
    local player = self.playerList[1]
    player.cardList = {
         MJConst.Zi3
    }
    player.newCard = MJConst.Zi3
    -- 碰杠的牌
    local byteCard = MJConst.Zi4
    local pile = MJPile.new()
    pile:setPile(3, {byteCard, byteCard, byteCard}, true, 2, MJConst.kOperPeng)
    table.insert(player.pileList, pile)

    byteCard = MJConst.Zi3
    local pile = MJPile.new()
    pile:setPile(3, {byteCard, byteCard, byteCard}, true, 2, MJConst.kOperPeng)
    table.insert(player.pileList, pile)

    byteCard = MJConst.Tong1
    local pile = MJPile.new()
    pile:setPile(4, {byteCard, byteCard, byteCard, byteCard}, true, 1, MJConst.kOperAG)
    table.insert(player.pileList, pile)

    byteCard = MJConst.Tong2
    local pile = MJPile.new()
    pile:setPile(4, {byteCard, byteCard, byteCard, byteCard}, true, 1, MJConst.kOperAG)
    table.insert(player.pileList, pile)

    table.insert(player.huaList, MJConst.Zi5)
end

function TestCase:giveHandCard()
    -- 要胡的玩家
    local player = self.playerList[1]
    player.cardList = {
         MJConst.Wan1, MJConst.Wan2, MJConst.Wan3, 
         MJConst.Wan4, MJConst.Wan5, MJConst.Wan6,  
         MJConst.Wan7, MJConst.Wan8, MJConst.Wan9, 
         MJConst.Zi3, MJConst.Zi4, MJConst.Zi4, MJConst.Zi4    
    }
    -- 碰杠的牌
    -- for byteCard = MJConst.Wan1, MJConst.Wan4 do
    --     local pile = MJPile.new()
    --     pile:setPile(3, {byteCard, byteCard, byteCard}, true, 4, MJConst.kOperPeng)
    --     table.insert(player.pileList, pile)
    -- end

    -- 要胡的玩家
    self.playerList[2].cardList = {
        MJConst.Tiao1, MJConst.Tiao1, MJConst.Tiao1, 
        MJConst.Tong1, MJConst.Tong2, MJConst.Tong3,
        MJConst.Zi1, MJConst.Zi1, MJConst.Zi1,
        MJConst.Wan6,
    }
    self.playerList[2].huaList = {MJConst.Zi4, MJConst.Zi5,
    MJConst.Zi5, MJConst.Zi5}
    -- 添加碰牌
    local pile = MJPile.new()
    local byteCard = MJConst.Wan1
    pile:setPile(3, {byteCard, byteCard, byteCard}, true, 1, MJConst.kOperPeng)
    table.insert(self.playerList[2].pileList, pile)
    -- 放炮的玩家
end

return TestCase