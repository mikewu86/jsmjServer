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
    LOG_DEBUG('-- TestCase:onEntry --')
    self.gameProgress.curGameState = self
    ---先通知客户端游戏状态
    local seq = self.gameProgress:incOperationSeq()
    -- 做测试条件
    --self:test1()
    --self:test2()
    --self:test3()
    --self:test4()
    --self:test5()
    self:test6()
end

function TestCase:onExit()
end

function TestCase:test(args)
    local endState =self.gameProgress.gameStateList[self.gameProgress.kGameEnd]
    endState:onEntry(args)
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

-- 支番，缺门，同番，坎番，4暗刻，3连坎
function TestCase:test1()
    local player = self.playerList[1]
    player.cardList = {
        MJConst.Wan1, MJConst.Wan1, MJConst.Wan1,
        MJConst.Wan2, MJConst.Wan2, MJConst.Wan2,
        MJConst.Wan3, MJConst.Wan3, MJConst.Wan3,
        MJConst.Tiao1, MJConst.Tiao1, MJConst.Tiao1,
        MJConst.Tiao2,
    }
    player:addNewCard(MJConst.Tiao2)
    self:test(
        {isLiuJu = false, 
        isZiMo = true,
        fangPaoPos = -1,
        winnerPosList = {1},
        huCard = nil,
        isQiangGang = false })
end

-- 双暗双铺子，四核，豪华七对，双铺子自摸
function TestCase:test2()
    local player = self.playerList[1]
    player.cardList = {
        MJConst.Wan3, MJConst.Wan4, MJConst.Wan5,
        MJConst.Wan3, MJConst.Wan4, MJConst.Wan5,
        MJConst.Tiao3, MJConst.Tiao4, MJConst.Tiao5,
        MJConst.Tiao3, MJConst.Tiao4, MJConst.Tiao5,
        MJConst.Wan3,
    }
    player:addNewCard(MJConst.Wan3)
    self:test(
        {isLiuJu = false, 
        isZiMo = true,
        fangPaoPos = -1,
        winnerPosList = {1},
        huCard = nil,
        isQiangGang = false })
end

-- 卡，杠后开花
function TestCase:test3()
    local player = self.playerList[1]
    player.cardList = {
        MJConst.Tiao1, MJConst.Tiao2, MJConst.Tiao3,
        MJConst.Tiao4, MJConst.Tiao4, MJConst.Tiao4,
        MJConst.Wan2, MJConst.Wan3,
        MJConst.Tiao5, MJConst.Tiao5,
        MJConst.Tong6, MJConst.Tong6, MJConst.Tong6,
    }
    player:addNewCard(MJConst.Tong6)
    player:doAnGang(MJConst.Tong6, 1)
    player:addNewCard(MJConst.Wan4)
    table.insert(player.opHistoryList, MJConst.kOperPlay)
    self:test(
        {isLiuJu = false, 
        isZiMo = true,
        fangPaoPos = -1,
        winnerPosList = {1},
        huCard = nil,
        isQiangGang = false })
end

-- 10同
function TestCase:test4()
    local player = self.playerList[1]
    player.cardList = {
        MJConst.Tong2,
    }
    local byteCard = MJConst.Wan1
    local pile = MJPile.new()
    pile:setPile(4, {byteCard, byteCard, byteCard, byteCard}, false, 1, MJConst.kOperAG)
    table.insert(player.pileList, pile)

    local byteCard = MJConst.Tiao1
    local pile = MJPile.new()
    pile:setPile(4, {byteCard, byteCard, byteCard, byteCard}, false, 1, MJConst.kOperAG)
    table.insert(player.pileList, pile)

    local byteCard = MJConst.Tong1
    local pile = MJPile.new()
    pile:setPile(4, {byteCard, byteCard, byteCard, byteCard}, false, 1, MJConst.kOperAG)
    table.insert(player.pileList, pile)

    local byteCard = MJConst.Wan2
    local pile = MJPile.new()
    pile:setPile(4, {byteCard, byteCard, byteCard, byteCard}, false, 1, MJConst.kOperAG)
    table.insert(player.pileList, pile)

    player:addNewCard(MJConst.Tong2)
    self:test(
        {isLiuJu = false, 
        isZiMo = true,
        fangPaoPos = -1,
        winnerPosList = {1},
        huCard = nil,
        isQiangGang = false })
end

-- 清一色
function TestCase:test5()
    local player = self.playerList[1]
    player.cardList = {
        MJConst.Wan1, MJConst.Wan2, MJConst.Wan3,
        MJConst.Wan5, MJConst.Wan5, MJConst.Wan5,
        MJConst.Wan4, MJConst.Wan4, MJConst.Wan4,
        MJConst.Wan6, MJConst.Wan6, MJConst.Wan6,
        MJConst.Wan7,
    }
    player:addNewCard(MJConst.Wan7)
    self:test(
        {isLiuJu = false, 
        isZiMo = true,
        fangPaoPos = -1,
        winnerPosList = {1},
        huCard = nil,
        isQiangGang = false })
end

-- 七对
function TestCase:test6()
    local player = self.playerList[1]
    player.cardList = {
        MJConst.Wan1, MJConst.Wan1,
        MJConst.Wan2, MJConst.Wan2,
        MJConst.Tiao1, MJConst.Tiao1,
        MJConst.Tiao3, MJConst.Tiao3,
        MJConst.Wan6, MJConst.Wan6,
        MJConst.Wan8, MJConst.Wan8,
        MJConst.Tong2,
    }
    player:addNewCard(MJConst.Tong2)
    self:test(
        {isLiuJu = false, 
        isZiMo = true,
        fangPaoPos = -1,
        winnerPosList = {1},
        huCard = nil,
        isQiangGang = false })
end

return TestCase