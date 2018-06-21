local BasePlayer = require("mj_core.MJPlayer")
local MJConst = require("mj_core.MJConst")
-------------------------------------------------------------
--  NJMJPlayer
local MAANSHMJPlayer = class("MAANSHMJPlayer", BasePlayer)

function MAANSHMJPlayer:ctor(maxCardCount, pos)
    self.super.ctor(self, maxCardCount, pos)
    self.huaList = {}       --- 玩家手里的花牌
    self.constHuaList = {}  --- 游戏配置的哪些是花牌
    self.huaGangList = {}   --- 玩家手里的花杠
    self.baseScores = {}    --- 玩家手里的分数
    self.extraFans = 0
    self.waMo = 0
    self.pingMo = 0
    self.index = -1
    self.subScore = 0
end

function MAANSHMJPlayer:setConstHuaList(huaList)
    self.constHuaList = huaList
end

function MAANSHMJPlayer:clear()
    self.super.clear(self)
end

function MAANSHMJPlayer:reset()
    self:clear()
    self.huaList = {}
    self.huaGangList = {}
end

function MAANSHMJPlayer:updatePlayerScore(score)
    if self.baseScores[self.index] ~= nil then
        self.baseScores[self.index] = score + self.baseScores[self.index] 
    end
    --dump(self.baseScores, "self.baseScores[self.index]")
end

function MAANSHMJPlayer:updatePlayerExtraFan(score)
    self.extraFans = score + self.extraFans
end

function MAANSHMJPlayer:getPlayerExtraFan()
    return self.extraFans
end

function MAANSHMJPlayer:getPlayerScore()
    local score = self.baseScores[self.index] or -1 
    return score
end

function MAANSHMJPlayer:incBaseCnt()
    self.index = self.index + 1
end

function MAANSHMJPlayer:getTotalScore()
    local score = 0 - self.subScore
    for _, num in pairs(self.baseScores) do 
        score = num + score
    end
    return score
end

function MAANSHMJPlayer:initBaseScores(num, baseScore)
    for i = 1, num do 
        self.baseScores[i] = baseScore
    end
    self.index = 1
    self.subScore  = num * baseScore
end

function MAANSHMJPlayer:getBaseScores()
    local scores = table.clone(self.baseScores)
    return scores
end

-- 手里有没有花
function MAANSHMJPlayer:hasHua()
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

function MAANSHMJPlayer:addHua(byteCard)
    table.insert(self.huaList, byteCard)
    self.justDoOper = MJConst.kOperBuHua
    table.insert(self.opHistoryList, self.justDoOper)
end

function MAANSHMJPlayer:clearOpList()
    self.opHistoryList = {}
end
-- 返回一张花牌
function MAANSHMJPlayer:getHua()
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

function MAANSHMJPlayer:getHuaList()
    return self.huaList
end

function MAANSHMJPlayer:getCardsForNums(_step)
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

function MAANSHMJPlayer:getCardNumInHua(_cardByte)
    local sum = 0
    for _, v in pairs(self.huaList) do 
        if v == _cardByte then
            sum = sum + 1
        end
    end
    return sum
end

function MAANSHMJPlayer:isHuaGang(_cardByte)
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

function MAANSHMJPlayer:getHuaGangNum()
    local huaGangSum = #self.huaGangList
    return huaGangSum
end

function MAANSHMJPlayer:transCanHUCardsToCountMap(_huCard)
    local map = self:transHandCardsToCountMap(true)
    for _, data in pairs(self.pileList) do 
        if MJConst.kOperPeng == data.operType then
            local keyCard = data.cardList[1]
            map[keyCard] = map[keyCard] + 3
        end
    end
    if nil ~= _huCard then
        map[_huCard] = map[_huCard] + 1 
    end
    return map
end

-- 生成一个新对象
function MAANSHMJPlayer:clone()
    local player = MAANSHMJPlayer.new(self.maxCardCount, self.myPos)
    player.cardList = self:getHandCardsCopy()
    player.newCard = self.newCard
    player.pileList = self:getPileCopy()
    player.huaList = table.copy(self.huaList)
    player.constHuaList = self.constHuaList
    return player
end

function MAANSHMJPlayer:updateZimoNum(wamo, pingmo)
    if wamo == true then
        self.waMo = self.waMo + 1
    end

    if pingmo == true then
        self.pingMo = self.pingMo  + 1
    end
    dump(self.waMo, "self.waMo")
    dump(self.pingMo, "self.waMo")
end

function MAANSHMJPlayer:getZimoNum()
    return self.waMo, self.pingMo
end

return MAANSHMJPlayer