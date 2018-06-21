-- 2016.10.11 ptrjeffrey
-- 计算胡牌的类型,每款麻将游戏单独一份文件
local MJConst = require("mj_core.MJConst")
local MJCard = require("mj_core.MJCard")
local HuTypeConst = require("HuTypeConst")

local CountHuType = class('CountHuType')
require("CalcMJTou")
-- 有没有胡牌类型
function CountHuType:hasHuType(huType)
    if table.keyof(self.huTypeList, huType) ~= nil then
        return true
    end
    return false
end

function CountHuType:ctor()
    self.isBaoPai = false
    self.baoPaiPos = nil
end

function CountHuType:setParams(pos, gameProgress, huCard, fangPaoPos, isQiangGang, isZiMo, zhuangPos)
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
    self.isBaoPai = false
    self.baoPaiPos = -1
    self.zhuangPos = zhuangPos or 1
    self:clearAutoHuFlag()
end

function CountHuType:clearAutoHuFlag()
    self.isAutoHu = false
end

-- 填充胡牌详细结构， 
-- 参数 huDetails 要被填充的表
-- huTypeName 牌型名称 huaCount 花数
function CountHuType:fillDetial(huDetails, huType)
    local cfg = HuTypeConst.huTypeMap[huType]
    if cfg then
        huDetails.describe = huDetails.describe..cfg.name..cfg.descrip..';'
        -- local item = {pos = self.pos, 
        -- huastr = cfg.name, 
        -- countstr = cfg.descrip}
        -- table.insert(huDetails, item)
        table.insert(self.huTypeList, huType)
    end
end

-- 计算详细胡牌类型
function CountHuType:calculate()
    local huDetails = {}  -- 胡牌详细信息
    self.huTypeList = {}  -- 所有胡牌类型的列表
    if self.pos == nil or self.player == nil then
        LOG_DEBUG('-- no pos or no player --')
        return huDetails
    end
    local huTypeMap = HuTypeConst.huTypeMap  -- 胡牌对照表 
    local hua = 0

    local bMengQing = false

    huDetails.pos = self.pos
    huDetails.describe = ''

    local daHuList = nil
    -- 填充当前的胡牌类型
    local innerFill = function(huType, _huDetails)
        self:fillDetial(_huDetails, huType)
        hua = hua + huTypeMap[huType].fan
    end
    
    innerFill(HuTypeConst.kHuType.kHu, huDetails)

    -- 清一色，混一色,缺门
    local yiSeType = self:getYiSeType()
    if yiSeType == 2 then
        innerFill(HuTypeConst.kHuType.kQingYiSe, huDetails)
    elseif yiSeType == 3 then
        innerFill(HuTypeConst.kHuType.kHunYiSe, huDetails)
    -- elseif yiSeType == 1 then
    --     innerFill(HuTypeConst.kHuType.kZiYiSe, huDetails)
    end

    -- 对对胡
    if self:isDuiduiHu() then
        innerFill(HuTypeConst.kHuType.kDuiDuiHu, huDetails)
    end
    if self:calcRaoDa() then
        innerFill(HuTypeConst.kHuType.kRaoDa, huDetails)
     end
    -- 杠开
    if self:isGangKai() then
        innerFill(HuTypeConst.kHuType.kGangKai, huDetails)
    end
    local bMenFeng = false

    if self:isMenFeng() == true then
        bMenFeng = true
        innerFill(HuTypeConst.kHuType.kMenFeng, huDetails)
    end

    local arrowMke = self:calcMPengCount(bMenFeng)
    local normMG = self:calcMGangCount(bMenFeng)
    local normMXG = self:calcMXGangCount()
    local agSum = self:calcAGangCount()

    if arrowMke > 0 then
        huDetails.describe = huDetails.describe..'箭牌'..(arrowMke* 1)..'台;'
        hua = hua + arrowMke * 1
    end

--     -- 明杠
     if normMG > 0 then
         huDetails.describe = huDetails.describe..'明杠'..normMG..'台;'
         hua = hua + normMG * 1
     end

     -- 面下杠
     if normMXG > 0 then
         huDetails.describe = huDetails.describe..'转弯杠'..(normMXG * 2)..'台;'
         hua = hua + normMXG * 2
     end
     
--     -- 暗杠
     if agSum > 0 then
         huDetails.describe = huDetails.describe..'暗杠'..(agSum * 3)..'台;'
         hua = hua + agSum * 3
     end


     if self:calcSanCaiShen() then
        innerFill(HuTypeConst.kHuType.kSANCAISHEN, huDetails)
     end

    -- 天胡，地胡,海底
    if self:isTianHu() then
        innerFill(HuTypeConst.kHuType.kTianHu, huDetails)
    elseif self:isDiHu() then
        innerFill(HuTypeConst.kHuType.kDiHu, huDetails)
    end

    if self:isHaiDi() then
        innerFill(HuTypeConst.kHuType.kHaiDi, huDetails)
    end

    if self:isDaDiaoChe() then
        innerFill(HuTypeConst.kHuType.kDaDiaoChe, huDetails)
    end

    if self:isGanQian() == true then
        innerFill(HuTypeConst.kHuType.kGanQian, huDetails)
    end
  
    if self.isQiangGang then
        innerFill(HuTypeConst.kHuType.kQiangGang, huDetails)
    end

    if self:isDiuDa() == true then
        innerFill(HuTypeConst.kHuType.kDiuDa, huDetails)
    end
    
    if self.gameProgress.m_bDiZero == true then
        huDetails.describe = huDetails.describe..'双色子翻倍;'
    end

    self:calcBaoPai()

    self.huDetails = huDetails
    self.fan = math.ceil(hua)
    return huDetails
end

-- 获取所有的花数，包括自摸的
function CountHuType:getTotalFan()
    -- 自摸花数*3
    local fan = self.fan
    if nil == fan then
        LOG_DEBUG("before getTotalFan ,do calculate")
        fan = 0
    end
  
    if self.gameProgress.m_bDiZero == true then
        fan = math.ceil(fan * 2) -- 豹子滴零翻倍
    end
    -- 自摸 番3倍
    if self.isZiMo == true then  
        fan = math.ceil(fan * 3)
    end
    
    return fan
end


-- 1 字一色 2 清一色，3 混一色 0 无色
function CountHuType:getYiSeType()
    local suitCountList = {}
    local suitCount = 0
    for suit = MJConst.kMJSuitWan, MJConst.kMJSuitZi do
        suitCount = self.player:getSuitCountInHand(suit, true)
        suitCount = suitCount + self.player:getSuitCountInPile(suit)
        suitCountList[suit] = suitCount
    end
    suitCount = 0
    for k, v in pairs(suitCountList) do
        if v > 0 then
            suitCount = suitCount + 1
        end
    end
    if suitCount == 1 then  -- 只有一种颜色
        if suitCountList[MJConst.kMJSuitZi] > 0 then
            return 1
        else
            return 2
        end
    elseif suitCount == 2 and suitCountList[MJConst.kMJSuitZi] > 0 then
        return 3
    end
    return 0
end

function CountHuType:isDuiduiHu()
    local countMap = self.player:transHandCardsToCountMap(true,{self.player.daCard})
    if self.huCard ~= nil then
        if self.huCard ~= self.player.daCard then
            countMap[self.huCard] = countMap[self.huCard] + 1
        else
            countMap[0] = countMap[0] + 1
        end
    end
    countMap[0] = 0
    local daCnt = #self.player.daCards
    local pileCnt = #self.player.pileList
    local needPile = 4 - pileCnt
    table.sort(countMap, function(a, b) return a > b end)    
    for card, cnt in pairs(countMap) do 
        if cnt > 3 then
            return false
        end
        local needCard = (needPile > 0 and 3) or 2
        daCnt = daCnt - (needCard - cnt)
        if daCnt < 0  then
            return false
        elseif needPile == 0 then
            if daCnt == 0 then
                return true
            else
                return false
            end
        end
        needPile = needPile - 1
    end
    return false
end

-- 大吊车
function CountHuType:isDaDiaoChe()
    if #self.player.cardList == 1 then
        return true
    end
    return false
end

-- 天胡
function CountHuType:isTianHu()
    local playedCount = 0
    for k, v in pairs(self.riverCardList) do
        if v:getCount() > 0 then
            return false
        end
    end

    if #self.player.pileList > 0 then
        return false
    end

    -- 必须是自摸
    if self.player:hasNewCard() == false then
        return false
    end

    return true
end

-- 地胡
function CountHuType:isDiHu()
    local playedCount = 0
    for k, v in pairs(self.riverCardList) do
        playedCount = v:getCount() + playedCount
    end

    if playedCount ~= 1 then
        return false
    end

    if table.size(self.player.pileList) > 0 then
        return false
    end

    -- 必须不是自摸
    if self.player:hasNewCard() == true then
        return false
    end

    return true
end

-- 海底捞月 只能自摸
function CountHuType:isHaiDi()
    if self.mjWall:getCanGetCount() == 0 and 
    self.isZiMo == true then
        return true
    end
    return false
end

-- 杠开
function CountHuType:isGangKai()
    local len = table.size(self.player.opHistoryList)
    if len > 1 then
        local justDoOper = self.player.opHistoryList[len - 1]
        if justDoOper == MJConst.kOperMG or
        justDoOper == MJConst.kOperAG or
        justDoOper == MJConst.kOperMXG then
            -- 必须是自摸
            if self.player:hasNewCard() == true then
                return true
            else
                return false
            end
        end
    end
    return false
end

-- peng
function CountHuType:calcMPengCount(bMenFeng)
    local arrowSum = 0
    local pileList = self.player.pileList
    local windCard = self:calcMenFengCard()
    for k, v in pairs(pileList) do
        local card = v.cardList[1]
        if v.operType == MJConst.kOperPeng then
            if v.cardList[1] <= MJConst.Zi7 and v.cardList[1] > MJConst.Zi4 then
                arrowSum = arrowSum + 1
            else
                if  card > MJConst.Tong9 and card < MJConst.Zi5 then
                    if bMenFeng == true and windCard == card then
                        arrowSum = arrowSum + 1  
                    end
                end
            end
        end
    end

    arrowSum = arrowSum + self:calcJianThreeInHand(bMenFeng)

    return arrowSum
end


function CountHuType:calcJianThreeInHand(bMenFeng) 
    local num = 0
    local windCard = self:calcMenFengCard()
    local tbJians = {MJConst.Zi5, MJConst.Zi6, MJConst.Zi7}
    if bMenFeng == true then
        table.insert(tbJians, windCard)
    end

    local cardMap = self.player:transHandCardsToCountMap(true)
    if self.huCard ~= nil then
        cardMap[self.huCard] = cardMap[self.huCard] + 1
    end
    for _, card in pairs(tbJians) do 
        if cardMap[card] > 2 then
            num = num + 1
        end
    end

    return num
end

 --明杠
 function CountHuType:calcMGangCount(bMenFeng)
    local normMGang = 0
    local pileList = self.player.pileList
    local card = -1
    local windCard = self:calcMenFengCard()
    for k,v in pairs(pileList) do
        card = v.cardList[1]
        if v.operType == MJConst.kOperMG then
            if bMenFeng == true and windCard == card then
                normMGang = normMGang + 2
            elseif card > MJConst.Zi4 and card < MJConst.Hua1 then
                normMGang = normMGang + 2
            else
                normMGang = normMGang + 1
            end
        end
    end

    return normMGang
 end

--面下杠
function CountHuType:calcMXGangCount()
    local normMXGang = 0
    local pileList = self.player.pileList
    for k,v in pairs(pileList) do
        if v.operType == MJConst.kOperMXG then
        normMXGang = normMXGang + 1
        end
    end

    return normMXGang
end

-- angang
 function CountHuType:calcAGangCount()
     local agSum = 0
     local pileList = self.player.pileList
     for k,v in pairs(pileList) do
         if v.operType == MJConst.kOperAG then
            agSum = agSum + 1
         end
     end
    
     return agSum
 end


--门风数量
function CountHuType:calcMFCount()
    local count = 0
    local pileList = self.player.pileList
    local cardList = self.player.cardList
    local windCard = MJConst.Zi1 + (4 - (self.zhuangPos - self.pos)) % 4
    for _, pile in pairs(pileList) do
        if pile.cardList[1] == windCard then
            count = count + 1
        end
    end
    for _, hand in pairs(cardList) do
        if hand == windCard then
            count = count + 1
        end
    end

    return count
end

function CountHuType:isMenFeng()
    local pileList = self.player.pileList 
    local windCard = self:calcMenFengCard()
    local bRet = false
    for _, pile in pairs(pileList) do 
        if pile.cardList[1] == windCard then
            bRet = true
            break
        end
    end
    return bRet
end

function CountHuType:isDiuDa()
    return (self.player.hasDa == true and #self.player.daCards < self.player.maxDaNum) 
end

function CountHuType:isGanQian() 
    return (self.player.hasDa == false)
end

function CountHuType:calcBaoPai()
    self.isBaoPai = false
    self.baoPaiPos = -1
    local pileList = self.player.pileList
    local tbPileNum = {0, 0, 0, 0}
    for _, pile in pairs(pileList) do
        if pile.from and pile.from > 0 and pile.from < 5 and pile.from ~= self.pos then
            tbPileNum[pile.from] = tbPileNum[pile.from] + 1
            if tbPileNum[pile.from] > 2 then
                self.isBaoPai = true
                self.baoPaiPos = pile.from
                break
            end
        end
    end
end

function CountHuType:calcSanCaiShen()
    -- HuTypeConst.kHuType.kSANCAISHEN
    local daCards = self.player.daCards
    return #daCards > 2
end

function CountHuType:calcRaoDa()
    --- hu any card.
    return self.player:checkChuKe()
end

function CountHuType:haveZiMoHuType()
    for _, huType in pairs(self.huTypeList) do 
        if table.keyof(HuTypeConst.kZiMoHuTypeList, huType) ~= nil then
            return true
        end 
    end
    return false
end


function CountHuType:calcMenFengCard()
    local windCard = MJConst.Zi1 + (4 - (self.zhuangPos - self.pos)) % 4
    return windCard
end

return CountHuType