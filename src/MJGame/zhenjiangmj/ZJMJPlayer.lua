local BasePlayer = require("mj_core.MJPlayer")
local MJConst = require("mj_core.MJConst")
-------------------------------------------------------------
--  ZJMJPlayer
local ZJMJPlayer = class("ZJMJPlayer", BasePlayer)

function ZJMJPlayer:ctor(maxCardCount, pos)
    self.super.ctor(self, maxCardCount, pos)
    self.huaList = {}       --- 玩家手里的花牌
    self.constHuaList = {}  --- 游戏配置的哪些是花牌
    self.huaGangList = {}   --- 玩家手里的花杠
end

function ZJMJPlayer:setConstHuaList(huaList)
    self.constHuaList = huaList
end

function ZJMJPlayer:clear()
    self.super.clear(self)
end

function ZJMJPlayer:reset()
    self:clear()
    self.huaList = {}
    self.huaGangList = {}
end

-- 手里有没有花
function ZJMJPlayer:hasHua()
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

function ZJMJPlayer:addHua(byteCard)
    table.insert(self.huaList, byteCard)
    self.justDoOper = MJConst.kOperBuHua
    table.insert(self.opHistoryList, self.justDoOper)
end

-- 返回一张花牌
function ZJMJPlayer:getHua()
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

function ZJMJPlayer:getHuaList()
    return self.huaList
end

function ZJMJPlayer:getCardsForNums(_step)
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

function ZJMJPlayer:getCardNumInHua(_cardByte)
    local sum = 0
    for _, v in pairs(self.huaList) do 
        if v == _cardByte then
            sum = sum + 1
        end
    end
    return sum
end

function ZJMJPlayer:isHuaGang(_cardByte)
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

function ZJMJPlayer:getHuaGangNum()
    local huaGangSum = #self.huaGangList
    return huaGangSum
end

-- 手牌中有没有百搭牌，有的话返回数量，没有返回0
function ZJMJPlayer:hasBaiDa(_baiDa)
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

-- 能否胡
function ZJMJPlayer:canHu(byteCard, _baiDa, _noUseBaiDa)
    if self:hasNewCard() then
        return false
    end
    if _noUseBaiDa then
        local countMap = self:transHandCardsToCountMap(false)
        countMap[byteCard] = countMap[byteCard] + 1
        return self.mjMath:canHu(countMap)
    end
    local countMap = self:transHandCardsToCountMap(false)
    countMap[byteCard] = countMap[byteCard] + 1
    local cpyMap = table.copy(countMap)
    local baiDaNum = self:hasBaiDa(_baiDa)
    -- 有百搭牌，则对计算map重新修改
    if baiDaNum ~= 0 then
        cpyMap[0] = cpyMap[0] + baiDaNum
        cpyMap[_baiDa] = cpyMap[_baiDa] - baiDaNum
    end
    return self.mjMath:canHu(cpyMap)
end

-- 能否胡七对
function ZJMJPlayer:canHuQiDui(byteCard, _baiDa, _noUseBaiDa)
    if self:hasNewCard() then
        return false
    end
    if _noUseBaiDa then
        local countMap = self:transHandCardsToCountMap(false)
        countMap[byteCard] = countMap[byteCard] + 1
        return self.mjMath:canHu(countMap)
    end
    local countMap = self:transHandCardsToCountMap(false)
    countMap[byteCard] = countMap[byteCard] + 1
    local cpyMap = table.copy(countMap)
    local baiDaNum = self:hasBaiDa(_baiDa)
    -- 有百搭牌，则对计算map重新修改
    if baiDaNum ~= 0 then
        cpyMap[0] = cpyMap[0] + baiDaNum
        cpyMap[_baiDa] = cpyMap[_baiDa] - baiDaNum
    end
    return self.mjMath:canHuQiDui(cpyMap)
end

-- 能否自摸
function ZJMJPlayer:canSelfHu(_baiDa, _noUseBaiDa)
    if not self:hasNewCard() then
        return false
    end
    if _noUseBaiDa then
        local countMap = self:transHandCardsToCountMap(true)
        return self.mjMath:canHu(countMap)
    end
    local countMap = self:transHandCardsToCountMap(true)
    local cpyMap = table.copy(countMap)
    local baiDaNum = self:hasBaiDa(_baiDa)
    -- 有百搭牌，则对计算map重新修改
    if baiDaNum ~= 0 then
        cpyMap[0] = cpyMap[0] + baiDaNum
        cpyMap[_baiDa] = cpyMap[_baiDa] - baiDaNum
    end
    return self.mjMath:canHu(cpyMap)
end

-- 能否自摸七对
function ZJMJPlayer:canSelfHuQiDui(_baiDa, _noUseBaiDa)
    if not self:hasNewCard() then
        return false
    end
    if _noUseBaiDa then
        local countMap = self:transHandCardsToCountMap(true)
        return self.mjMath:canHu(countMap)
    end
    local countMap = self:transHandCardsToCountMap(true)
    local cpyMap = table.copy(countMap)
    local baiDaNum = self:hasBaiDa(_baiDa)
    -- 有百搭牌，则对计算map重新修改
    if baiDaNum ~= 0 then
        cpyMap[0] = cpyMap[0] + baiDaNum
        cpyMap[_baiDa] = cpyMap[_baiDa] - baiDaNum
    end
    return self.mjMath:canHuQiDui(cpyMap)
end

-- 跑搭检测
function ZJMJPlayer:checkPaoDa(_baiDa)
    if self:hasNewCard() then
        return false
    end
    local countMap = self:transHandCardsToCountMap(false)
    local cpyMap = table.copy(countMap)
    local baiDaNum = self:hasBaiDa(_baiDa)
    -- 有百搭牌则减去
    if baiDaNum ~= 0 then
        cpyMap[_baiDa] = cpyMap[_baiDa] - baiDaNum
    else
        -- 没有百搭，则不可能跑搭
        return false
    end
    -- 已经成刻或顺的牌去掉
    for byte, num in pairs(cpyMap) do
        -- 顺牌
        if num == 1 then
            local card = MJConst.fromByteToSuitAndPoint(byte)
            if card.value == 1 then
                if cpyMap[byte + 1] and cpyMap[byte + 1] == 1 and cpyMap[byte + 2] and cpyMap[byte + 2] == 1 then
                    cpyMap[byte] = cpyMap[byte] - 1
                    cpyMap[byte + 1] = cpyMap[byte + 1] - 1
                    cpyMap[byte + 2] = cpyMap[byte + 2] - 1
                end
            elseif card.value == 9 then
                if cpyMap[byte - 1] and cpyMap[byte - 1] == 1 and cpyMap[byte - 2] and cpyMap[byte - 2] == 1 then
                    cpyMap[byte] = cpyMap[byte] - 1
                    cpyMap[byte - 1] = cpyMap[byte - 1] - 1
                    cpyMap[byte - 2] = cpyMap[byte - 2] - 1
                end
            else
                if cpyMap[byte - 1] and cpyMap[byte - 1] == 1 and cpyMap[byte + 1] and cpyMap[byte + 1] == 1 then
                    cpyMap[byte - 1] = cpyMap[byte - 1] - 1
                    cpyMap[byte] = cpyMap[byte] - 1
                    cpyMap[byte + 1] = cpyMap[byte + 1] - 1
                end
            end
        end

        -- 刻牌
        if num == 3 then
            cpyMap[byte] = 0
        end
    end

    --dump(cpyMap, 'cpyMap without keshun')
    -- 比较剩余牌与百搭的数量
    local sum = 0
    for _, num in pairs(cpyMap) do
        sum = sum + num
    end
    if baiDaNum >= sum then
        return true
    end
    return false
end

return ZJMJPlayer