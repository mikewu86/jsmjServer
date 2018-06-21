-- 2016.10.11 ptrjeffrey
-- 计算胡牌的类型,每款麻将游戏单独一份文件
local MJConst = require("mj_core.MJConst")
local MJCard = require("mj_core.MJCard")
require("MJUtils.CalcMJTou")
local HuTypeConst = require("HuTypeConst")

local CountHuType = class('CountHuType')
local function transferCardMap(cards, filterCards)
    local cardmap = {} 
    for i=0, MJConst.Zi7 do
        cardmap[i] = 0
    end
    for _,card in pairs(cards) do 
        cardmap[card] = cardmap[card] + 1
    end

    for _,card in pairs(filterCards) do 
        if cardmap[card] > 0 then
            cardmap[card] = cardmap[card] - 1
        end
    end
    return cardmap
end
-- 有没有胡牌类型
function CountHuType:hasHuType(huType)
    if table.keyof(self.huTypeList, huType) ~= nil then
        return true
    end
    return false
end

function CountHuType:ctor()
end

function CountHuType:setParams(pos, gameProgress, huCard, fangPaoPos, isQiangGang, isZiMo)
    self.pos = pos
    self.player = gameProgress.playerList[pos]
    self.playerList = gameProgress.playerList
    self.gameProgress = gameProgress
    self.mjWall = gameProgress.mjWall
    self.riverCardList = gameProgress.riverCardList
    self.huCard = huCard  -- 要胡的牌，为空时说明是自摸
    self.fangPaoPos = fangPaoPos -- 放炮人的位置
    self.isQiangGang = isQiangGang -- 是不是抢杠
    self.isZiMo = isZiMo
    self:clearAutoHuFlag()
    self.isKuaiZhao = false
end

function CountHuType:clearAutoHuFlag()
    self.isAutoHu = false
end

-- 填充胡牌详细结构， 
-- 参数 huDetails 要被填充的表
-- huTypeName 牌型名称 huaCount 花数
function CountHuType:fillDetial(huDetails, huType, num)
    local cfg = HuTypeConst.huTypeMap[huType]
    if cfg then
        if num == nil then
            huDetails.describe = huDetails.describe..cfg.name..cfg.descrip..';'
        else
            huDetails.describe = huDetails.describe..cfg.name..'X'..(num*cfg.fan)..';'
        end
        -- local item = {pos = self.pos, 
        -- huastr = cfg.name, 
        -- countstr = cfg.descrip}
        -- table.insert(huDetails, item)
        table.insert(self.huTypeList, huType)
    end
end

-- 计算详细胡牌类型
function CountHuType:calculate()
    self.isBaoPai = false
    self.baoPaiPos = nil
    local huDetails = {}  -- 胡牌详细信息
    self.huTypeList = {}  -- 所有胡牌类型的列表
    if self.pos == nil or self.player == nil then
        LOG_DEBUG('-- no pos or no player --')
        return huDetails
    end
    local huTypeMap = HuTypeConst.huTypeMap  -- 胡牌对照表 
    local hua = 0
    local fanBei = 1
    local calcKa = self.gameProgress:checkCalcKa()
    local bDaHu = false
    local bMengQing = false

    huDetails.pos = self.pos
    huDetails.describe = ''

    local daHuList = nil
    -- 填充当前的胡牌类型
    local innerFill = function(huType, _huDetails, _num)
        self:fillDetial(_huDetails, huType, _num)
        fanBei = fanBei * huTypeMap[huType].fan
        if _num ~= nil then
            fanBei = fanBei * _num
        end
        if table.keyof(HuTypeConst.kDaHuTypeList, huType) ~= nil then
            bDaHu = true
        end
    end
    local aGangCount = self:getAGangCount()
    -- 卡数
    -- 胡牌
    if calcKa == 1 then
        if self.isZiMo then
            hua = hua + 20
            huDetails.describe = huDetails.describe..'自摸20卡;'
        else
            hua = hua + 10
            huDetails.describe = huDetails.describe..'点炮10卡;'
        end

        -- 硬花数
        huDetails.describe = huDetails.describe.."花"..#self.player.huaList..'卡;'
        hua = hua + #self.player.huaList
        
        -- 卡张
        local kaZhangValue = self:getKaZhang()
        huDetails.describe = huDetails.describe..kaZhangValue..'卡张;'
        hua = hua + kaZhangValue

        -- 明杠
        local mGangCount = self:getMGangCount()
        if mGangCount > 0 then
            huDetails.describe = huDetails.describe..'明杠'..mGangCount..'卡;'
            hua = hua + mGangCount * 1
        end
        -- 暗杠
        if aGangCount > 0 then
            huDetails.describe = huDetails.describe..'暗杠'..(aGangCount*2)..'卡;'
            hua = hua + aGangCount * 2
        end
    end

    -- 倍数
    if aGangCount > 0 then
        local agangBei = 1
        for i = 1, aGangCount do
            agangBei = agangBei * 2
        end
        huDetails.describe = huDetails.describe..'暗杠X'..(agangBei)..";"
        fanBei = fanBei * agangBei
    end
    -- 门清
    if self:isMengQing() then
        innerFill(HuTypeConst.kHuType.kMenQing, huDetails)
    end
    -- 碰碰胡
    if self:isDuiDuiHu() then
        if self:isZhaoZhaoHu() == 1 then
            innerFill(HuTypeConst.kHuType.kZhaoZhaoHu, huDetails)
        else
            innerFill(HuTypeConst.kHuType.kDuiDuiHu, huDetails)           
        end
    end
    local gangkai = self:isGangKai()
    -- 杠开
    if gangkai == 1 then
        innerFill(HuTypeConst.kHuType.kGangKai, huDetails)
    end
    -- 拐之
    if self:isGuaiZhi() then
        innerFill(HuTypeConst.kHuType.kGuaiZhi, huDetails)
    end
    -- 绝之
    if self:isJueZhi() then
        innerFill(HuTypeConst.kHuType.kJueZhi, huDetails)
    end
    -- 超长
    if self:isChaoChang() then
        innerFill(HuTypeConst.kHuType.kChaoChang, huDetails)
    end
    -- 超短
    if self:isChaoDuan() then
        innerFill(HuTypeConst.kHuType.kChaoDuan, huDetails)
    end
    local sCount = self:isSiTong()
    -- 四同
    if sCount > 0 then
        innerFill(HuTypeConst.kHuType.kSiTong, huDetails, sCount)
    end
    -- 挖之
    if self:isWaZhi() then
        innerFill(HuTypeConst.kHuType.kWaZhi, huDetails)
    end
    -- 无花
    if self:isWuHuaGuo() then
        innerFill(HuTypeConst.kHuType.kWuHua, huDetails)
    end
    -- 直听
    if self:isZhiTing() then
        innerFill(HuTypeConst.kHuType.kZhiTing, huDetails)
    end
    -- 四拖一
    if self:isSTuoYi() then
        innerFill(HuTypeConst.kHuType.kSTuoYi, huDetails)
    end
    -- 铲底
    if self:isHaiDi() then
        innerFill(HuTypeConst.kHuType.kChanDi, huDetails)
    end

    if self:isSameSuit() == 1 then
        innerFill(HuTypeConst.kHuType.kSameSuit, huDetails)
    end

    self.huDetails = huDetails
    local upLimit = self.gameProgress:getUpLimit()
    if upLimit > 0 then
        if fanBei > upLimit then
            fanBei = upLimit
        end 
    end
    if hua == 0 then
        if fanBei == 1 then
            huDetails.describe = huDetails.describe..'平胡'..'X1;'
        end
        self.fan = fanBei
    else
        self.fan = hua * fanBei
    end
    return huDetails, gangkai
end

-- 获取所有的花数，包括自摸的
function CountHuType:getTotalFan()
    local fan = self.fan
    if nil == fan then
        LOG_DEBUG("before getTotalFan ,do calculate")
        fan = 0
    end
    return fan
end

-- 卡张点数
function CountHuType:getKaZhang()
    local huCard = self.huCard
    if huCard == nil then
        huCard = self.player:getNewCard()
    end
    local card = MJCard.new({byte = huCard})
    return card.point
end

-- 门清
function CountHuType:isMengQing()
    if #self.player.pileList > 0 then
        for k, pile in pairs(self.player.pileList) do
            if pile.operType ~= MJConst.kOperAG then
                return false
            end
        end
    end
    return true
end

-- 超长
function CountHuType:isChaoChang()
    if #self.player.huaList > 13 then
        return true
    end
    return false
end

-- 超短
function CountHuType:isChaoDuan()
    if #self.player.huaList == 1 then
        return true
    end
    return false
end

-- 四同
function CountHuType:isSiTong()
    if #self.player.huaList < 4 then
        return 0
    end
    local tb = {0,0,0,0,0,0,0,0,0}
    for k,v in pairs(self.player.huaList) do
        local card = MJCard.new({byte = v})
        if card.suit == MJConst.kMJSuitZi then
            tb[card.point] = tb[card.point] + 1
        else
            if card.point < MJConst.kMJPoint5 then
                tb[8] = tb[8] + 1
            else
                tb[9] = tb[9] + 1
            end
        end
    end
    local sum = 0
    for k,v in pairs(tb) do
        if v == 4 then
            sum = sum + 1
        end
    end
    return sum
end

-- 对对胡
function CountHuType:isDuiDuiHu()
    local huCard = self.huCard
    if huCard == nil then
        huCard = self.player:getNewCard()
    end
    if huCard == nil then
        return false
    end
    local jiang = 0
    local ka    = 0
    local countMap = self.player:transHandCardsToCountMap(false)
    countMap[huCard-1] = countMap[huCard-1] - 1
    countMap[huCard+1] = countMap[huCard+1] - 1

    for k, v in pairs(countMap) do
        if v % 3 ~= 0 then
            if v == 2 then
                if jiang == 0 then
                    jiang = 1
                else
                    return false
                end
            else
                return false
            end
        end
    end
    return true
end

-- 杠开
function CountHuType:isGangKai()
    if self.isZiMo == false then
        return 0
    end
    local len = #self.player.opHistoryList
    if len > 1 then
        local justDoOper = self.player.opHistoryList[len - 1]
        if justDoOper == MJConst.kOperMG or
        justDoOper == MJConst.kOperAG or
        justDoOper == MJConst.kOperMXG or
        justDoOper == MJConst.kOperBuHua  then
            return 1
        end
    end
    return 0
end

-- 无花果
function CountHuType:isWuHuaGuo()
    if #self.player.huaList > 0 then
        return false
    end
    return true
end

-- 海底捞月 只能自摸
function CountHuType:isHaiDi()
    if self.mjWall:getCanGetCount() <= 4 and 
    self.isZiMo == true then
        return true
    end
    return false
end

-- 绝之
function CountHuType:isJueZhi()
    local huCard = self.huCard
    if huCard == nil then
        huCard = self.player:getNewCard()
    end
    if huCard == nil then
        return false
    end
    local showCount = 0
    for k, v in pairs(self.playerList) do
        showCount = showCount + v:getCardCountInPile(huCard)
    end
    for k, v in pairs(self.riverCardList) do
        showCount = showCount + v:getCardCount(huCard)
    end

    if self.isZiMo and showCount == 3 then
        return true
    end

    if not self.isZiMo and showCount == 4 then
        return true
    end

    return false
end

-- 四拖一
function CountHuType:isSTuoYi()
    local cardsMap = self.player:transHandCardsToCountMap(true)
    if #self.player.pileList > 0 then
        for k, pile in pairs(self.player.pileList) do
            if pile.operType == MJConst.kOperPeng then
                cardsMap[pile.cardList[1]] = cardsMap[pile.cardList[1]] + 3
            end
        end
    end
    local huCard = self.huCard
    if huCard == nil then
        huCard = self.player:getNewCard()
    else
        cardsMap[huCard] = cardsMap[huCard] + 1
    end
    if huCard == nil then
        return false
    end
    local laseCard = huCard - 1
    local pCount = cardsMap[laseCard]
    if pCount == 4 then
        cardsMap[laseCard] = 0
        cardsMap[huCard] = cardsMap[huCard] - 1
        cardsMap[huCard + 1] = cardsMap[huCard + 1] - 1
        if self.player.mjMath:canHu(cardsMap) == true then
            return true
        else
            cardsMap[laseCard] = 4
            cardsMap[huCard] = cardsMap[huCard] + 1
            cardsMap[huCard + 1] = cardsMap[huCard + 1] + 1
        end
    end

    local nextCard = huCard + 1
    local pCount = cardsMap[laseCard]
    if pCount == 4 then
        cardsMap[nextCard] = 0
        cardsMap[huCard] = cardsMap[huCard] - 1
        cardsMap[huCard - 1] = cardsMap[huCard - 1] - 1
        if self.player.mjMath:canHu(cardsMap) == true then
            return true
        -- else
        --     cardsMap[nextCard] = 4
        --     cardsMap[huCard] = cardsMap[huCard] + 1
        --     cardsMap[huCard - 1] = cardsMap[huCard - 1] + 1
        end
    end
    return false
end

-- 挖之
function CountHuType:isWaZhi()
    local huCard = self.huCard
    if huCard == nil then
        huCard = self.player:getNewCard()
    end
    if huCard == nil then
        return false
    end

    local countMap = self.player:transHandCardsToCountMap(false)
    countMap[huCard] = countMap[huCard] + 1
    if countMap[huCard] > 1 and 
        countMap[huCard + 1] > 1 and 
        countMap[huCard + 1] > 1 then
        countMap[huCard + 1] = countMap[huCard + 1] - 2
        countMap[huCard - 1] = countMap[huCard - 1] - 2
        countMap[huCard] = countMap[huCard] - 2

        if self.player.mjMath:canHu(countMap) == true then
            return true
        end
    end
    return false
end

-- 拐之
function CountHuType:isGuaiZhi()
    local countMap = self.player:transHandCardsToCountMap(true)
    if self.huCard ~= nil then
        countMap[self.huCard] = countMap[self.huCard] + 1
    end
    local jiangCard = calcAndGetJiangTou(countMap)
    if jiangCard == self.huCard or jiangCard == self.player:getNewCard() then
        return true
    end
    return false
end

--明杠
function CountHuType:getMGangCount()
    local sum = 0
    local pileList = self.player.pileList
    for k,v in pairs(pileList) do
        if v.operType == MJConst.kOperMG or v.operType == MJConst.kOperMXG then
            sum = sum + 1
        end
    end
    
    return sum
end

--暗杠
function CountHuType:getAGangCount()
    local sum = 0
    local pileList = self.player.pileList
    for k,v in pairs(pileList) do
        if v.operType == MJConst.kOperAG then
            sum = sum + 1
        end
    end
    
    return sum
end

function CountHuType:isZhiTing()
    return self.player.isZhiTing
end

function CountHuType:isSameSuit()
    local suitCountList = {}
    local suitCount = 0
    for suit = MJConst.kMJSuitWan, MJConst.kMJSuitZi do
        suitCount = self.player:getSuitCountInHand(suit)
        suitCount = suitCount + self.player:getSuitCountInPile(suit)
        suitCountList[suit] = suitCount
    end
    suitCount = 0
    for k, v in pairs(suitCountList) do
        if v > 0 then
            suitCount = suitCount + 1
        end
    end
    if suitCount == 1 and suitCountList[MJConst.kMJSuitZi] == 0 then
        return 1
    end
    return 0
end

function CountHuType:isZhaoZhaoHu()
    local pileList = self.player.pileList
    if #pileList > 0 then
        for _, pile in pairs(pileList) do 
            if pile.operType ~= MJConst.kOperMG and
                pile.operType ~= MJConst.kOperAG and
                pile.operType ~= MJConst.kOperMXG then
                return 0
            end
        end
    end

    return 1
end

return CountHuType