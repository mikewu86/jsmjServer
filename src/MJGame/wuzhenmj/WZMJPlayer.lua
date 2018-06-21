local BasePlayer = require("mj_core.MJPlayer")
local MJConst = require("mj_core.MJConst")
local MJCard = require("mj_core.MJCard")
-------------------------------------------------------------
--  WZMJPlayer
local WZMJPlayer = class("WZMJPlayer", BasePlayer)

function WZMJPlayer:ctor(maxCardCount, pos, isDiaoDa)
    self.super.ctor(self, maxCardCount, pos)
    self.huaList = {}       --- 玩家手里的花牌
    self.constHuaList = {}  --- 游戏配置的哪些是花牌
    self.huaGangList = {}   --- 玩家手里的花杠
    self.isDiaoDa = isDiaoDa or 0
end

function WZMJPlayer:setConstHuaList(huaList)
    self.constHuaList = huaList
end

function WZMJPlayer:clear()
    self.super.clear(self)
end

function WZMJPlayer:reset()
    self:clear()
    self.huaList = {}
    self.huaGangList = {}
end

-- 手里有没有花
function WZMJPlayer:hasHua()
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

function WZMJPlayer:addHua(byteCard)
    table.insert(self.huaList, byteCard)
    self.justDoOper = MJConst.kOperBuHua
    table.insert(self.opHistoryList, self.justDoOper)
end

function WZMJPlayer:addHuaWithoutHis(byteCard)
    table.insert(self.huaList, byteCard)
end

function WZMJPlayer:clearOpList()
    self.opHistoryList = {}
end

-- 返回一张花牌
function WZMJPlayer:getHua()
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

function WZMJPlayer:getHuaList()
    return self.huaList
end

function WZMJPlayer:getCardsForNums(_step)
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
function WZMJPlayer:getSuitCountInHandWithBaida(suit, bIncludeNewCard,baida)
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

function WZMJPlayer:getCardNumInHua(_cardByte)
    local sum = 0
    for _, v in pairs(self.huaList) do 
        if v == _cardByte then
            sum = sum + 1
        end
    end
    return sum
end

function WZMJPlayer:isHuaGang(_cardByte)
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

function WZMJPlayer:getHuaGangNum()
    local huaGangSum = #self.huaGangList
    return huaGangSum
end

-- 手牌中有没有百搭牌，有的话返回数量，没有返回0
function WZMJPlayer:hasBaiDa(_baiDa)
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
function WZMJPlayer:clone()
    local player = WZMJPlayer.new(self.maxCardCount, self.myPos)
    player.cardList = self:getHandCardsCopy()
    player.newCard = self.newCard
    player.pileList = self:getPileCopy()
    player.huaList = table.copy(self.huaList)
    player.constHuaList = self.constHuaList
    return player
end

return WZMJPlayer