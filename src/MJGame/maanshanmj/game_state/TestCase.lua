-- 2016.10.21 ptrjeffrey 
-- 测试用例,一个瞬时状态，主要看输出对不对
-- 测内容
local MJConst = require("mj_core.MJConst")
local MJPile = require("mj_core.MJPile")
local CountHuType = require("CountHuType")
local HuTypeConst = require("HuTypeConst")
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
    self:test()

end

function TestCase:onExit()
end

function TestCase:test()
    --self:testAlgorithm()
    self:testGameOver()
end


--- 通用算法 对对胡、七对、杠开、大吊车、压绝、门清、四核、 省略
function TestCase:testAlgorithm()
    self:testZhiFan()
    self:testYiSe()
    self:testTiaoLong()
    self:testSixShun()
    self:testThreeInHand()
    self:testThreeInPile()
    self:testDoublePu()
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
function TestCase:testZhiFan()
    local tempHuType = CountHuType.new()
    tempHuType:setParams(
        1, 
        self.gameProgress, 
        nil, 
        nil,
        false, true, 4)
    local player = self.gameProgress.playerList[1]
    local cards = {MJConst.Wan1, MJConst.Tong2, MJConst.Tiao3, MJConst.Wan4, MJConst.Tong1, MJConst.Zi1, 
        MJConst.Wan1, MJConst.Zi5, MJConst.Tiao3, MJConst.Zi6, MJConst.Wan1, MJConst.Zi1,
        MJConst.Zi2,} 
    local newCard = MJConst.Zi2
    for _,card in pairs(cards) do 
        player:addHandCard(card)
    end 
    player:addNewCard(newCard)
    tempHuType:calculate()
    tempHuType:calcZhiFan()
    local zhiFanPoint = tempHuType:getZhiFanPoint()
    assert(zhiFanPoint == 4," test zhifan fail.")
    LOG_DEBUG("test zhifan ok.")
    player:clear()
    
    cards = {MJConst.Wan1, MJConst.Wan1, MJConst.Wan1, MJConst.Wan4, MJConst.Wan1, MJConst.Wan1, 
        MJConst.Wan1, MJConst.Zi5, MJConst.Wan1, MJConst.Zi6, MJConst.Wan1, MJConst.Zi1,
        MJConst.Zi2,}
    newCard = MJConst.Wan1
    for _,card in pairs(cards) do 
        player:addHandCard(card)
    end 
    player:addNewCard(newCard)

    tempHuType:calcZhiFan()
    local zhiFanPoint = tempHuType:getZhiFanPoint()
    assert(zhiFanPoint == 7," test zhifan fail.")
    LOG_DEBUG("test zhifan ok.")
    player:clear()    
end

function TestCase:testYiSe()
    local tempHuType = CountHuType.new()
    tempHuType:setParams(
        1, 
        self.gameProgress, 
        nil, 
        nil,
        false, true, 4)
    local player = self.gameProgress.playerList[1]
    local cards = {MJConst.Wan1, MJConst.Wan1, MJConst.Wan1, MJConst.Wan1, MJConst.Wan1, MJConst.Wan1, 
        MJConst.Wan1, MJConst.Wan1, MJConst.Wan1, MJConst.Wan1, MJConst.Wan1, MJConst.Wan1,
        MJConst.Wan1,} 
    local newCard = MJConst.Wan1
    for _,card in pairs(cards) do 
        player:addHandCard(card)
    end 
    player:addNewCard(newCard)   
    assert(HuTypeConst.kHuType.kQingYiSe == tempHuType:getYiSeHuType(), "清一色 fail.")
    LOG_DEBUG("清一色 ok.")
    player:clear()
    
    cards = {MJConst.Wan1, MJConst.Wan1, MJConst.Wan1, MJConst.Wan1, MJConst.Wan1, MJConst.Wan1, 
        MJConst.Wan1, MJConst.Wan1, MJConst.Wan1, MJConst.Wan1, MJConst.Wan1, MJConst.Wan1,
        MJConst.Zi1,} 
    newCard = MJConst.Zi1
    for _,card in pairs(cards) do 
        player:addHandCard(card)
    end 
    player:addNewCard(newCard)   
    assert(HuTypeConst.kHuType.kHunYiSe == tempHuType:getYiSeHuType(), "混一色 fail.")
    LOG_DEBUG("混一色 ok.")
    player:clear()
      
    cards = {MJConst.Zi1, MJConst.Zi2, MJConst.Zi3, MJConst.Zi4, MJConst.Zi5, MJConst.Zi6, 
        MJConst.Zi7, MJConst.Zi1, MJConst.Zi2, MJConst.Zi3, MJConst.Zi4, MJConst.Zi5,
        MJConst.Zi1,} 
    newCard = MJConst.Zi1
    for _,card in pairs(cards) do 
        player:addHandCard(card)
    end 
    player:addNewCard(newCard)   
    assert(HuTypeConst.kHuType.kZiYiSe == tempHuType:getYiSeHuType(), "风一色 fail.")
    LOG_DEBUG("风一色 ok.")
    player:clear()    
end

function TestCase:testTiaoLong()
    local tempHuType = CountHuType.new()
    tempHuType:setParams(
        1, 
        self.gameProgress, 
        nil, 
        nil,
        false, true, 4)

    local cards = {MJConst.Wan1, MJConst.Wan2, MJConst.Wan3, MJConst.Wan5, MJConst.Wan4, MJConst.Tong1, 
        MJConst.Wan6, MJConst.Wan7, MJConst.Tiao2, MJConst.Wan8, MJConst.Tiao3, MJConst.Wan1,
        MJConst.Zi1,} 
    local newCard = MJConst.Wan9
    table.insert(cards, newCard)   
    local keyCards = {}
    assert(true == tempHuType:isTiaoLong(cards, keyCards), "一天龙 fail.")
    LOG_DEBUG("一条龙 ok.")
    dump(keyCards, "keyCards.")
end

function TestCase:testSixShun()
    local tempHuType = CountHuType.new()
    tempHuType:setParams(
        1, 
        self.gameProgress, 
        nil, 
        nil,
        false, true, 4)

    local cards = {MJConst.Wan1, MJConst.Wan2, MJConst.Wan3, MJConst.Wan5, MJConst.Wan4, MJConst.Tong1, 
        MJConst.Wan6, MJConst.Tong2, MJConst.Tong3, MJConst.Tong4, MJConst.Tong5, MJConst.Tong6,
        MJConst.Zi1,} 
    local newCard = MJConst.Zi2
    table.insert(cards, newCard)   
    local keyCards = {}
    assert(true == tempHuType:isSixShun(cards, keyCards), "六顺 fail.")
    LOG_DEBUG("六顺 ok.")
    dump(keyCards, "keyCards.") 
end

function TestCase:testThreeInHand()
    local tempHuType = CountHuType.new()
    tempHuType:setParams(
        1, 
        self.gameProgress, 
        nil, 
        nil,
        false, true, 4)

    local cards = {MJConst.Wan1, MJConst.Wan1, MJConst.Wan1, MJConst.Wan1, MJConst.Wan4, MJConst.Wan4, 
        MJConst.Wan4, MJConst.Wan5, MJConst.Wan5, MJConst.Wan5, MJConst.Wan6, MJConst.Wan6,
        MJConst.Wan7,} 
    local newCard = MJConst.Wan7
    table.insert(cards, newCard)   

    local bRet,num =  tempHuType:isThreeInHand(cards)
    assert(true == bRet and 3 == num , "三张在手 fail.")
    LOG_DEBUG("三张在手 ok.")     
end

function TestCase:testThreeInPile()
    local tempHuType = CountHuType.new()
    tempHuType:setParams(
        1, 
        self.gameProgress, 
        nil, 
        nil,
        false, true, 4)
    local player = self.gameProgress.playerList[1]
    local pileList = player.pileList
    
    local pile1 = MJPile.new()
    pile1:setPile(3 ,{MJConst.Wan1, MJConst.Wan1, MJConst.Wan1}, false, 2, MJConst.kOperPeng)
    table.insert(pileList, pile1)
    local pile2 = MJPile.new()
    pile2:setPile(3 ,{MJConst.Wan1, MJConst.Wan1, MJConst.Wan1}, false, 2, MJConst.kOperPeng)
    table.insert(pileList, pile2)
    local pile3 = MJPile.new()
    pile3:setPile(3 ,{MJConst.Wan1, MJConst.Wan1, MJConst.Wan1}, false, 2, MJConst.kOperPeng)
    table.insert(pileList, pile3) 

    local bRet,num =  tempHuType:isThreeInPile()
    assert(true == bRet and 3 == num , "三张碰出 fail.")
    LOG_DEBUG("三张碰出 ok.")
    player:clear()
end

function TestCase:testDoublePu()
    local tempHuType = CountHuType.new()
    tempHuType:setParams(
        1, 
        self.gameProgress, 
        nil, 
        nil,
        false, true, 4)

    local cards = {MJConst.Wan1, MJConst.Wan1, MJConst.Wan1, MJConst.Wan1, MJConst.Wan2, MJConst.Wan2, 
        MJConst.Wan2, MJConst.Wan2, MJConst.Wan3, MJConst.Wan3, MJConst.Wan3, MJConst.Wan3,
        MJConst.Wan7,} 
    local newCard = MJConst.Wan7
    table.insert(cards, newCard)   

    local tbRes =  tempHuType:calcShuangPu(cards)
    assert(3 == #tbRes[4], "双扑 fail.")
    LOG_DEBUG("双扑 ok")
    dump(tbRes, "tbRes")
end

function TestCase:testGameOver()
    -- self:testGODDH()    
    -- self:testGOQD()
    -- self:testGODP()
    self:testThreeInHand()
end

function TestCase:testGODDH()
    local tempHuType = CountHuType.new()
    tempHuType:setParams(
        1, 
        self.gameProgress, 
        MJConst.Tiao1, 
        2,
        false, false, 4) --- 点炮
    local player = self.gameProgress.playerList[1]
    local cards = {MJConst.Wan1, MJConst.Wan1,MJConst.Wan1,MJConst.Wan4,MJConst.Wan4,MJConst.Wan4,
                    MJConst.Tong1, MJConst.Tong1,MJConst.Tong1,MJConst.Tong4,MJConst.Tong4,MJConst.Tong4,
                    MJConst.Tiao1,}
    local newCard = MJConst.Tiao1
    for _, card in pairs(cards) do 
        player:addHandCard(card)
    end

    local pkg = tempHuType:calculate()
    dump(pkg, "GODDH pkg.")
    player:clear()
end

function TestCase:testGOQD()
    local tempHuType = CountHuType.new()
    tempHuType:setParams(
        1, 
        self.gameProgress, 
        MJConst.Tiao1, 
        2,
        false, false, 4) --- 点炮
    local player = self.gameProgress.playerList[1]
    local cards = {MJConst.Wan1, MJConst.Wan1,MJConst.Wan3,MJConst.Wan3,MJConst.Wan4,MJConst.Wan4,
        MJConst.Tong1, MJConst.Tong1,MJConst.Tong3,MJConst.Tong3,MJConst.Tong4,MJConst.Tong4,
        MJConst.Tiao1,}

    for _, card in pairs(cards) do 
        player:addHandCard(card)
    end

    local pkg = tempHuType:calculate()
    dump(pkg, "GOQD pkg.")
    player:clear()
end

function TestCase:testGODP()
    local tempHuType = CountHuType.new()
    tempHuType:setParams(
        1, 
        self.gameProgress, 
        MJConst.Wan8, 
        2,
        false, false, 4) --- 点炮
    local player = self.gameProgress.playerList[1]
    local cards = {MJConst.Wan1, MJConst.Wan1,MJConst.Wan1,MJConst.Wan1,MJConst.Wan2,MJConst.Wan2,
        MJConst.Wan3, MJConst.Wan3,MJConst.Wan6,MJConst.Wan6,MJConst.Wan7,MJConst.Wan7,
        MJConst.Wan8,}

    for _, card in pairs(cards) do 
        player:addHandCard(card)
    end

    local pkg = tempHuType:calculate()
    dump(pkg, "GODP pkg.")
    player:clear() 
end

function TestCase:testThreeInHand()
    local tempHuType = CountHuType.new()
    tempHuType:setParams(
        1, 
        self.gameProgress, 
        MJConst.Wan8, 
        1,
        true, false, 4) --- 点炮
    local player = self.gameProgress.playerList[1]
    local cards = {MJConst.Wan1, MJConst.Wan1,MJConst.Wan1,MJConst.Wan3,MJConst.Wan4,MJConst.Wan5,
        MJConst.Tong1,MJConst.Tong1,MJConst.Tong5, MJConst.Tong6,MJConst.Tong7,MJConst.Zi7,
        MJConst.Zi7,}

    for _, card in pairs(cards) do 
        player:addHandCard(card)
    end
    player:addNewCard(MJConst.Zi7)
    local pkg = tempHuType:calculate()
    dump(pkg, "GODP pkg.")
    player:clear() 
end

return TestCase