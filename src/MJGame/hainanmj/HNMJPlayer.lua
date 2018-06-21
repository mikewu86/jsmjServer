local BasePlayer = require("mj_core.MJPlayer")
local MJConst = require("mj_core.MJConst")
-------------------------------------------------------------
--  HNMJPlayer
local HNMJPlayer = class("HNMJPlayer", BasePlayer)
local TingNode = class("TingNode")
function TingNode:ctor(playCard, huCardList)
    self.playCard = playCard
    self.huCardList = huCardList
end

function HNMJPlayer:ctor(maxCardCount, pos)
    self.super.ctor(self, maxCardCount, pos)
    self.huaList = {}       --- 玩家手里的花牌
    self.constHuaList = {}  --- 游戏配置的哪些是花牌
    self.huaGangList = {}   --- 玩家手里的花杠
    self.leftMoney = 100  -- 进园子时要用到
    self.limitMoney = 100 -- 敞开头时用到.无论什么时候此分数不变
    self.newCardList = {} -- 每次摸到的新牌
    -- 19万，19条，19筒 东南西北中发白板，各一张，再来一张胡13幺
    self.yaoList = {MJConst.Wan1, MJConst.Wan9, 
    MJConst.Tiao1, MJConst.Tiao9, MJConst.Tong1,
    MJConst.Tong9}
    for i = MJConst.Zi1, MJConst.Zi7 do
        table.insert(self.yaoList, i)
    end
end

function HNMJPlayer:setLimitScore(money)
    return self.limitMoney
end

function HNMJPlayer:setLeftMoney(money)
    self.leftMoney = money
end

function HNMJPlayer:addLeftMoney(money)
    self.leftMoney = self.leftMoney + money
end

function HNMJPlayer:getLeftMoney()
    return self.leftMoney
end

function HNMJPlayer:setConstHuaList(huaList)
    self.constHuaList = huaList
end

function HNMJPlayer:clear()
    self.super.clear(self)
end

function HNMJPlayer:reset()
    self:clear()
    self.huaList = {}
    self.huaGangList = {}
    self.newCardList = {}
end

function HNMJPlayer:addNewCardList(byteCard)
    table.insert( self.newCardList, byteCard)
end

-- 手里有没有花
function HNMJPlayer:hasHua()
    local cards = self:getHandCards()
    for k, v in pairs(cards) do
        if table.keyof(self.constHuaList, v) then
            return true
        end
    end
    if table.keyof(self.constHuaList, self.newCard) then
        return true
    end
    return false
end

function HNMJPlayer:addHua(byteCard)
    table.insert(self.huaList, byteCard)
    self.justDoOper = MJConst.kOperBuHua
    table.insert(self.opHistoryList, self.justDoOper)
end

-- 返回一张花牌
function HNMJPlayer:getHua()
    local cards = self:getHandCards()
    for k, v in pairs(cards) do
        if table.keyof(self.constHuaList, v) then
            return v
        end
    end
    if table.keyof(self.constHuaList, self.newCard) then
        return self.newCard
    end
    return MJConst.kCardNull
end

function HNMJPlayer:getHuaList()
    return self.huaList
end

function HNMJPlayer:getHuaListForClient()
    local list = {}
    for k, v in pairs(self.huaList) do
        table.insert(list, MJConst.fromNow2OldCardByteMap[v])
    end
    return list
end

function HNMJPlayer:getCardsForNums(_step)
    local siNeedCopyCardNum = 0
    local siStep = _step
    if nil == siStep or siStep > 4 then
        siStep = 4
    end
    local cards = {}
    local cardList = self:getHandCardsCopy()
    if 4 == siStep then
        local bHasNewCard = self:hasNewCard()
        if true == bHasNewCard then
            table.insert(cardList, self:getNewCard())
        end
        siNeedCopyCardNum = #cardList
    else
        siNeedCopyCardNum =  siStep * 4
    end

    for i = 1, siNeedCopyCardNum do 
        table.insert(cards, MJConst.fromNow2OldCardByteMap[cardList[i]])
    end

    return cards 
end

function HNMJPlayer:getCardNumInHua(_cardByte)
    local sum = 0
    for _, v in pairs(self.huaList) do 
        if v == _cardByte then
            sum = sum + 1
        end
    end
    return sum
end

function HNMJPlayer:isHuaGang(_cardByte)
    local bRet = false

    if nil ~= table.keyof(self.huaGangList, _cardByte) then
        return bRet
    end

    local cardNum = self:getCardNumInHua(_cardByte)
    if cardNum >= 4 then
        table.insert(self.huaGangList, _cardByte)
        bRet = true
    end

    if bRet then
        return bRet
    end

    local innerHasHua = function(constHuaGangList, _cardByte)
        local ret = true
        if table.keyof(constHuaGangList, _cardByte) ~= nil then
            for k, v in pairs(constHuaGangList) do
                if table.keyof(self.huaList, v) == nil then
                    ret = false
                    break
                end
            end
        else
            ret = false
        end
        if true == ret then
            table.insert(self.huaGangList, constHuaGangList[#constHuaGangList])
        end
        return ret
    end

    -- 春夏秋冬
    local constHuaGangList = {MJConst.Hua1, MJConst.Hua2, MJConst.Hua3, MJConst.Hua4}
    if nil == table.keyof(self.huaGangList, constHuaGangList[#constHuaGangList]) and 
        true == innerHasHua(constHuaGangList, _cardByte) then
        return true
    end

    -- 梅兰竹菊
    constHuaGangList = {MJConst.Hua5, MJConst.Hua6, MJConst.Hua7, MJConst.Hua8}
    if nil == table.keyof(self.huaGangList, constHuaGangList[#constHuaGangList]) and
        true == innerHasHua(constHuaGangList, _cardByte) then
        return true
    end

    return false
end

function HNMJPlayer:getHuaGangNum()
    local huaGangSum = #self.huaGangList
    return huaGangSum
end

function HNMJPlayer:addHuaWithoutHis(byteCard)
    table.insert(self.huaList, byteCard)
end

-- 能否胡13Yao
function HNMJPlayer:canHu13Yao(byteCard,baiDaList)
    if #self.pileList > 0 then
        return false
    end
    local countMap = self:transHandCardsToCountMap(false, baiDaList)
    if table.keyof(self.yaoList, byteCard) == nil then
        return false
    end
    for k, v in pairs(self.yaoList) do
        if countMap[v] ~= 1 then
            return false
        end
    end
    return true
end

function HNMJPlayer:canSelfHu13Yao(baiDaList)
    if not self:hasNewCard() then
        return false
    end
    return self:canHu13Yao(self.newCard, baiDaList)
end

function HNMJPlayer:getTing13YaoNodes(baiDaList)
    local ret = {}
    if not self:hasNewCard() or #self.pileList > 0 then
        return ret
    end
    local countMap = self:transHandCardsToCountMap(true,baiDaList)
    --13幺听牌，把出现过一次的牌都去掉，如果只有一张无用牌，则说明可以听13幺
    local left = 0
    for k, v in pairs(self.yaoList) do
        if countMap[v] > 0 then
            countMap[v] = countMap[v] - 1
            left = left + countMap[v]
            if left > 1 then
                return ret
            end
        else
            return ret
        end
    end
    local pai = self.mjMath:getNotNone(countMap)
    if pai ~= 0 then
        local tingNode = TingNode.new(pai, table.copy(self.yaoList))
        table.insert(ret, tingNode)
    end
    return ret
end

-- 某张牌在明牌中的数量
function HNMJPlayer:getCardCountInPileWithoutAG(byteCard)
    local sum = 0
    for k, v in pairs(self.pileList) do
        if v.operType ~= MJConst.kOperAG then
            sum = sum + v:getCardCount(byteCard)
        end
    end
    return sum
end

-- 获取3道包牌或4道包牌
function HNMJPlayer:getBaoPaiInfo()
    local ret = {type = 0, pos = 0}
    local fromList = {}
    if #self.pileList >= 3 then
        for k, v in pairs(self.pileList) do
            if v.operType ~= MJConst.kOperAG then
                table.insert(fromList, v.from)
            end
        end
        if #fromList > 2 then
            local count = table.count(fromList, fromList[1])
            if count >= 3 then
                ret.type = count
                ret.pos = fromList[1]
            else
                count = table.count(fromList, fromList[2])
                if count == 3 then
                    ret.type = count
                    ret.pos = fromList[2]
                end
            end
        end
    end
    return ret
end

-- 生成一个新对象
function HNMJPlayer:clone()
    local player = HNMJPlayer.new(self.maxCardCount, self.myPos)
    player.cardList = self:getHandCardsCopy()
    player.newCard = self.newCard
    player.pileList = self:getPileCopy()
    player.huaList = table.copy(self.huaList)
    player.constHuaList = self.constHuaList
    return player
end

return HNMJPlayer