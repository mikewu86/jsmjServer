local BasePlayer = require("mj_core.MJPlayer")
local MJConst = require("mj_core.MJConst")
local MJCard = require("mj_core.MJCard")
-------------------------------------------------------------
--  HZMJPlayer
local TingNode = class("TingNode")
function TingNode:ctor(playCard, huCardList, isDiaoDa)
    self.playCard = playCard
    self.huCardList = huCardList
    self.isDiaoDa = isDiaoDa or 0
end

local HZMJPlayer = class("HZMJPlayer", BasePlayer)

function HZMJPlayer:ctor(maxCardCount, pos, isDiaoDa)
    self.super.ctor(self, maxCardCount, pos)
    self.huaList = {}       --- 玩家手里的花牌
    self.constHuaList = {}  --- 游戏配置的哪些是花牌
    self.huaGangList = {}   --- 玩家手里的花杠
    self.isDiaoDa = isDiaoDa or 0
end

function HZMJPlayer:setConstHuaList(huaList)
    self.constHuaList = huaList
end

function HZMJPlayer:clear()
    self.super.clear(self)
end

function HZMJPlayer:reset()
    self:clear()
    self.huaList = {}
    self.huaGangList = {}
end

-- 手里有没有花
function HZMJPlayer:hasHua()
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

function HZMJPlayer:addHua(byteCard)
    table.insert(self.huaList, byteCard)
    self.justDoOper = MJConst.kOperBuHua
    table.insert(self.opHistoryList, self.justDoOper)
end

function HZMJPlayer:addHuaWithoutHis(byteCard)
    table.insert(self.huaList, byteCard)
end

-- 返回一张花牌
function HZMJPlayer:getHua()
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

function HZMJPlayer:getHuaList()
    return self.huaList
end

function HZMJPlayer:getCardsForNums(_step)
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

-- 某种牌在明牌中数量去掉百搭
function HZMJPlayer:getSuitCountInHandWithBaida(suit, bIncludeNewCard,baida)
    local sum = 0
    local cards = self:getHandCardsCopy()
    for k, v in pairs(cards) do
        if v ~= baida then
            local card = MJCard.new({byte = v})
            if card.suit == suit then
                sum = sum + 1
            end
        end
    end

    if bIncludeNewCard then
        if self:hasNewCard() then
            if self.newCard ~= baida then
                local card = MJCard.new({byte = self.newCard})
                if card.suit == suit then
                    sum = sum + 1
                end
            end
        end
    end
    return sum
end

function HZMJPlayer:getCardNumInHua(_cardByte)
    local sum = 0
    for _, v in pairs(self.huaList) do 
        if v == _cardByte then
            sum = sum + 1
        end
    end
    return sum
end

function HZMJPlayer:isHuaGang(_cardByte)
    -- local bRet = false

    -- if nil ~= table.keyof(self.huaGangList, _cardByte) then
    --     return bRet
    -- end

    -- local cardNum = self:getCardNumInHua(_cardByte)
    -- if cardNum >= 4 then
    --     table.insert(self.huaGangList, _cardByte)
    --     bRet = true
    -- end

    -- if bRet then
    --     return bRet
    -- end

    -- local innerHasHua = function(constHuaGangList, _cardByte)
    --     local ret = true
    --     if table.keyof(constHuaGangList, _cardByte) ~= nil then
    --         for k, v in pairs(constHuaGangList) do
    --             if table.keyof(self.huaList, v) == nil then
    --                 ret = false
    --                 break
    --             end
    --         end
    --     else
    --         ret = false
    --     end
    --     if true == ret then
    --         table.insert(self.huaGangList, constHuaGangList[#constHuaGangList])
    --     end
    --     return ret
    -- end

    -- -- 春夏秋冬
    -- local constHuaGangList = {MJConst.Hua1, MJConst.Hua2, MJConst.Hua3, MJConst.Hua4}
    -- if nil == table.keyof(self.huaGangList, constHuaGangList[#constHuaGangList]) and 
    --     true == innerHasHua(constHuaGangList, _cardByte) then
    --     return true
    -- end

    -- -- 梅兰竹菊
    -- constHuaGangList = {MJConst.Hua5, MJConst.Hua6, MJConst.Hua7, MJConst.Hua8}
    -- if nil == table.keyof(self.huaGangList, constHuaGangList[#constHuaGangList]) and
    --     true == innerHasHua(constHuaGangList, _cardByte) then
    --     return true
    -- end

    return false
end

function HZMJPlayer:getHuaGangNum()
    local huaGangSum = #self.huaGangList
    return huaGangSum
end

-- 手牌中有没有百搭牌，有的话返回数量，没有返回0
function HZMJPlayer:hasBaiDa(_baiDa)
    local baiDaNum = 0
    local handCards = self:getAllHandCards()
    for _, card in ipairs(handCards) do
        if card == _baiDa then
            baiDaNum = baiDaNum + 1
        end
    end
    LOG_DEBUG("pos "..self.myPos.." has "..baiDaNum.." BAIDA")
    return baiDaNum
end

-- 生成一个新对象
function HZMJPlayer:clone()
    local player = HZMJPlayer.new(self.maxCardCount, self.myPos)
    player.cardList = self:getHandCardsCopy()
    player.newCard = self.newCard
    player.pileList = self:getPileCopy()
    player.huaList = table.copy(self.huaList)
    player.constHuaList = self.constHuaList
    return player
end

-- 获取所有可以听的牌
function HZMJPlayer:getCanTingCards(baiDaList)
    local ting = self:getTingNormalCards(baiDaList)
    local qiDui = self:getTingQiDuiCards(baiDaList)
    local canPlayCards = {}

    -- 先找出可以出的牌
    local addCanPlayCards = function(l, r)
        for k, v in pairs(l) do
            if table.keyof(r, v.playCard) == nil then
                table.insert(r, v.playCard)
            end
        end
    end
    addCanPlayCards(ting, canPlayCards)
    addCanPlayCards(qiDui, canPlayCards)

    -- 合并
    local ret = {}
    for k, v in pairs(canPlayCards) do
        local tingNode = TingNode.new(v, {})
        table.insert(ret, tingNode)
    end

    -- 把l参数的值加到r参数中
    local addTingNode = function(l, r)
        if #l > 0 and #r > 0 then
            for k, v in pairs(l) do
                for _, v1 in pairs(r) do
                    if v.playCard == v1.playCard then
                        for k2, v2 in pairs(v.huCardList) do
                            if table.keyof(v1.huCardList, v2) == nil then
                                table.insert(v1.huCardList, v2)
                            end
                        end
                        if v1.isDiaoDa ~= 1 then
                            v1.isDiaoDa = v.isDiaoDa
                        end
                    end
                end
            end
        end
    end
    addTingNode(ting, ret)
    addTingNode(qiDui, ret)
    return ret
end

-- 获取可以听以及可以出的牌
function HZMJPlayer:getTingNormalCards(baiDaList)
    local ret = {}
    if not self:hasNewCard() then
        return ret
    end
    local countMap = self:transHandCardsToCountMap(true,baiDaList)
    local cpyMap = table.copy(countMap)
    -- dump(countMap, ' countMap')
    for byteCard, count in pairs(countMap) do
        if byteCard > 0 and count > 0 then
            cpyMap[0] = cpyMap[0]+1                  -- 增加一张百搭
            cpyMap[byteCard] = cpyMap[byteCard] - 1  -- 去掉当前手牌
            if self.mjMath:canHu(cpyMap) then
                cpyMap[0] = cpyMap[0] - 1
                local huCards = self.mjMath:getCanHuCards(cpyMap)
                local tingNode = nil
                if #huCards == 34 then
                    tingNode = TingNode.new(byteCard, {MJConst.Baida}, 1)
                else
                    tingNode = TingNode.new(byteCard, huCards, 0)
                end
                table.insert(ret, tingNode)
                cpyMap[byteCard] = cpyMap[byteCard] + 1
            else
                cpyMap[0] = cpyMap[0] - 1
                cpyMap[byteCard] = cpyMap[byteCard] + 1
            end
        end
    end
    return ret
end

-- 可以听七对的牌
function HZMJPlayer:getTingQiDuiCards(baiDaList)
    local ret = {}
    if not self:hasNewCard() or #self.pileList > 0 then
        return ret
    end
    local countMap = self:transHandCardsToCountMap(true,baiDaList)
    local singleCards = self.mjMath:countSingle(countMap)
    local baidaCount = self:hasBaiDa(baiDaList[1])
    local count = #singleCards - baidaCount
    if count == 2 then
        if baidaCount == 0 then
            local tingNode = TingNode.new(singleCards[1], {singleCards[2]},0)
            table.insert(ret, tingNode)
            local tingNode = TingNode.new(singleCards[2], {singleCards[1]},0)
            table.insert(ret, tingNode)
        else
            for k,v in pairs(singleCards) do
                local tb = {}
                for i=1,#singleCards do
                    if singleCards[i] ~= v then
                        table.insert(tb,singleCards[i])
                    end
                end
                local tingNode = TingNode.new(v, tb, 0)
                table.insert(ret, tingNode)
            end
        end
    elseif count == 0 then
        if baidaCount > 0 then
            for k,v in pairs(singleCards) do
                local tingNode = TingNode.new(v, {MJConst.Baida}, 1)
                table.insert(ret, tingNode)
            end
        end
    elseif count < 0 then
        local handCards = self:getAllHandCards()
        for k,v in pairs(handCards) do
            if v ~= MJConst.Baida then
                local tingNode = TingNode.new(v, {MJConst.Baida}, 1)
                table.insert(ret, tingNode)
            end
        end
    end
    return ret
end

return HZMJPlayer