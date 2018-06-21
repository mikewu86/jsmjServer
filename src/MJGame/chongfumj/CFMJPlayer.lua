local BasePlayer = require("mj_core.MJPlayer")
local MJConst = require("mj_core.MJConst")
local MJCard = require("mj_core.MJCard")
-------------------------------------------------------------
local TingNode = class("TingNode")

function TingNode:ctor(playCard, huCardList, isDiaoDa)
    self.playCard = playCard
    self.huCardList = huCardList
    self.isDiaoDa = isDiaoDa or 0
end

--  CFMJPlayer
local CFMJPlayer = class("CFMJPlayer", BasePlayer)

function CFMJPlayer:ctor(maxCardCount, pos)
    self.super.ctor(self, maxCardCount, pos)
    self.huaList = {}       --- 玩家手里的花牌
    self.constHuaList = {}  --- 游戏配置的哪些是花牌
    self.huaGangList = {}   --- 玩家手里的花杠
end

function CFMJPlayer:setConstHuaList(huaList)
    self.constHuaList = huaList
end

function CFMJPlayer:clear()
    self.super.clear(self)
end

function CFMJPlayer:reset()
    self:clear()
    self.huaList = {}
    self.huaGangList = {}
end

-- 手里有没有花
function CFMJPlayer:hasHua()
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

function CFMJPlayer:addHua(byteCard)
    table.insert(self.huaList, byteCard)
    self.justDoOper = MJConst.kOperBuHua
    table.insert(self.opHistoryList, self.justDoOper)
end

function CFMJPlayer:addHuaWithoutHis(byteCard)
    table.insert(self.huaList, byteCard)
end

function CFMJPlayer:clearOpList()
    self.opHistoryList = {}
end

-- 返回一张花牌
function CFMJPlayer:getHua()
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

function CFMJPlayer:getHuaList()
    return self.huaList
end

function CFMJPlayer:getCardsForNums(_step)
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
function CFMJPlayer:getSuitCountInHandWithBaida(suit, bIncludeNewCard,baida)
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

function CFMJPlayer:getCardNumInHua(_cardByte)
    local sum = 0
    for _, v in pairs(self.huaList) do 
        if v == _cardByte then
            sum = sum + 1
        end
    end
    return sum
end

-- function CFMJPlayer:isHuaGang(_cardByte)
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

    -- return false
-- end

function CFMJPlayer:getHuaGangNum()
    local huaGangSum = #self.huaGangList
    return huaGangSum
end

-- 手牌中有没有百搭牌，有的话返回数量，没有返回0
function CFMJPlayer:hasBaiDa(_baiDa, _bIncludeNewCard)
    local baiDaNum = 0
    local handCards = {}
    if _bIncludeNewCard then
        handCards = self:getAllHandCards()
    else
        handCards = self:getHandCards()
    end

    for _, card in ipairs(handCards) do
        if card == _baiDa then
            baiDaNum = baiDaNum + 1
        end
    end
    LOG_DEBUG("pos "..self.myPos.." has "..baiDaNum.." BAIDA")
    return baiDaNum
end

-- 生成一个新对象
function CFMJPlayer:clone()
    local player = CFMJPlayer.new(self.maxCardCount, self.myPos)
    player.cardList = self:getHandCardsCopy()
    player.newCard = self.newCard
    player.pileList = self:getPileCopy()
    player.huaList = table.copy(self.huaList)
    player.constHuaList = self.constHuaList
    return player
end

function CFMJPlayer:getMXGNum()
    local num = 0
    for _, pile in pairs(self.pileList) do
        if MJConst.kOperMXG == pile.operType then
            num = num + 1     
        end
    end
    return num
end

-- 出壳检测
 function CFMJPlayer:checkChuKe(_baiDa, _bIncludeNewCard, isQiDui)
	
    -- if self:hasNewCard() then
    --     return false
    -- end
    local countMap = nil
    if not _bIncludeNewCard then
        countMap = self:transHandCardsToCountMap(false, {_baiDa})
    else
        countMap = self:transHandCardsToCountMap(true, {_baiDa})
    end
    local cpyMap = table.copy(countMap)
    if not isQiDui then
        local huCards = self.mjMath:getCanHuCards(cpyMap)
        if #huCards == 34 then
            return true
        end
    else
        local singleCards = self.mjMath:countSingle(cpyMap)
        local baidaCount = self:hasBaiDa(_baiDa)
        if baidaCount > #singleCards then
            return true
        end
    end

    return false
end

-- function CFMJPlayer:isRemainOneCard(_baiDa)
--     local countMap = self:transHandCardsToCountMap(false)
--     local cpyMap = table.copy(countMap)
--     local baiDaNum = self:hasBaiDa(_baiDa)
--     -- 有百搭牌则减去
--     if baiDaNum ~= 0 then
--         cpyMap[_baiDa] = cpyMap[_baiDa] - baiDaNum
--     end
--     -- 已经成刻或顺的牌去掉
--     for byte, num in pairs(cpyMap) do
--         -- 顺牌
--         if num == 1 then
--             local card = MJConst.fromByteToSuitAndPoint(byte)
--             if card.value == 1 then
--                 if cpyMap[byte + 1] and cpyMap[byte + 1] == 1 and cpyMap[byte + 2] and cpyMap[byte + 2] == 1 then
--                     cpyMap[byte] = cpyMap[byte] - 1
--                     cpyMap[byte + 1] = cpyMap[byte + 1] - 1
--                     cpyMap[byte + 2] = cpyMap[byte + 2] - 1
--                 end
--             elseif card.value == 9 then
--                 if cpyMap[byte - 1] and cpyMap[byte - 1] == 1 and cpyMap[byte - 2] and cpyMap[byte - 2] == 1 then
--                     cpyMap[byte] = cpyMap[byte] - 1
--                     cpyMap[byte - 1] = cpyMap[byte - 1] - 1
--                     cpyMap[byte - 2] = cpyMap[byte - 2] - 1
--                 end
--             else
--                 if cpyMap[byte - 1] and cpyMap[byte - 1] == 1 and cpyMap[byte + 1] and cpyMap[byte + 1] == 1 then
--                     cpyMap[byte - 1] = cpyMap[byte - 1] - 1
--                     cpyMap[byte] = cpyMap[byte] - 1
--                     cpyMap[byte + 1] = cpyMap[byte + 1] - 1
--                 end
--             end
--         end

--         -- 刻牌
--         if num == 3 then
--             cpyMap[byte] = 0
--         end
--     end
--     for byte, num in pairs(cpyMap) do
--         if num > 1 then
--             return false
--         end
--     end
--     return true
-- end

function CFMJPlayer:isRemainOneCard()
    local num = #self:getHandCards()
    if num == 1 then
        return true
    end
    return false
end

-- 获取所有可以听的牌,崇福麻将不能胡七对
function CFMJPlayer:getCanTingCards(baiDaList)
    local ting = self:getTingNormalCards(baiDaList)
    -- local qiDui = self:getTingQiDuiCards(baiDaList)
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
    -- addCanPlayCards(qiDui, canPlayCards)

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
    -- addTingNode(qiDui, ret)
    return ret
end

-- 获取可以听以及可以出的牌
function CFMJPlayer:getTingNormalCards(baiDaList)
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

return CFMJPlayer