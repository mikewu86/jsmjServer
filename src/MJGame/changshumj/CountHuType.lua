-- 2016.10.11 ptrjeffrey
-- 计算胡牌的类型,每款麻将游戏单独一份文件
local MJConst = require("mj_core.MJConst")
local MJCard = require("mj_core.MJCard")
local HuTypeConst = require("HuTypeConst")

local CountHuType = class('CountHuType')

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
    self.songGang = false
    self.songGangPos = nil
end

function CountHuType:setParams(pos, gameProgress, huCard, fangPaoPos, isQiangGang, isZiMo, awardFan, barHeadType)
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
    self.awardFan = awardFan or {0, 0, 0, 0}
    self.barHeadType = barHeadType
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

-- 包牌 抢杠
function CountHuType:baoPao()
    if self.isQiangGang then
        self.baoPaiPos = self.fangPaoPos   -- 更改放炮玩家为包牌玩家
        self.isBaoPai = true
        return true
    end
    return false
end

-- 计算详细胡牌类型
function CountHuType:calculate()
    local huDetails = {}  -- 胡牌详细信息
    self.huTypeList = {}  -- 所有胡牌类型的列表
    if self.pos == nil or self.player == nil then
        LOG_DEBUG('-- no pos or no player --')
        --dump(self.pos)
        return huDetails
    end
    local huTypeMap = HuTypeConst.huTypeMap  -- 胡牌对照表 
    local hua = 0

    huDetails.pos = self.pos
    huDetails.describe = ''
    local gangKai = 0
    local daHuList = nil
    -- 填充当前的胡牌类型
    local innerFill = function(huType, _huDetails)
        self:fillDetial(_huDetails, huType)
        hua = hua + huTypeMap[huType].fan
    end
    --- hu feng card specail handle.
    if self:calcHuOtherFeng(self.huCard) == 0 then
        innerFill(HuTypeConst.kHuType.kHu, huDetails)
    else
        innerFill(HuTypeConst.kHuType.kHuOtherZi, huDetails)
    end
    -- 硬花数
    local realHuaNum = table.size(self.player.huaList)
    if realHuaNum > 0 then
        huDetails.describe = huDetails.describe.."花牌"..realHuaNum..'花;'
        hua = hua + realHuaNum
    end
    local qiDuiHu = false
    if self.gameProgress.roomRuleMap and  self.gameProgress.roomRuleMap.cz_playrule_7dui == true then
        if self:isQiDui() then
            local qiDuiType = self:getQiDuiType()
            if qiDuiType ~= 0 then
                innerFill(HuTypeConst.kHuType.kHQiDui, huDetails)
            else
                innerFill(HuTypeConst.kHuType.kQiDui, huDetails)
            end
            qiDuiHu = true
        end
    end
    if qiDuiHu == false then
        -- 门清
        if self:isMengQing() == 1 then
            innerFill(HuTypeConst.kHuType.kMengQing, huDetails)
        end
    end
    -- end
    -- 清一色，混一色,缺门
    local yiSeType = self:getYiSeType()
    if yiSeType == 2 then
        innerFill(HuTypeConst.kHuType.kQingYiSe, huDetails)
    elseif yiSeType == 3 then
        innerFill(HuTypeConst.kHuType.kHunYiSe, huDetails)
    elseif yiSeType == 1 then
        innerFill(HuTypeConst.kHuType.kZiYiSe, huDetails)
    end
    -- 对对胡
    if self:isDuiDuiHu() then
        innerFill(HuTypeConst.kHuType.kDuiDuiHu, huDetails)
    end
    -- 杠开
    if self:isGangKai() then
        innerFill(HuTypeConst.kHuType.kGangKai, huDetails)
        gangKai = 1
    end


    local windMKe = self:calcMPengCount()
    local windAKe = self:calcPengCountInHand()
    local windMG, normMG = self:calcMGangCount()

    if windMKe > 0 then
        huDetails.describe = huDetails.describe..'风刻'..(windMKe* 1)..'花;'
        hua = hua + windMKe * 1
    end
--    -- 风暗碰
    if windAKe > 0 then
        huDetails.describe = huDetails.describe..'风暗刻'..(windAKe* 2)..'花;'
        hua = hua + windAKe * 2
    end

--     -- 明杠
     if normMG > 0 then
         huDetails.describe = huDetails.describe..'明杠'..normMG..'花;'
         hua = hua + normMG * 1
     end

--    -- 风明杠
    if windMG > 0 then
        hua = hua + windMG * 3
        huDetails.describe = huDetails.describe..'风明杠'..(windMG * 3)..'花;'
    end


--
--    -- 风暗杠
    local fAg, normAg = self:calcAGangCount()
    if fAg > 0 then
        hua = hua + fAg * 4
        huDetails.describe = huDetails.describe..'风暗杠'..(fAg * 4) ..'花;'
    end

--     -- 暗杠
     if normAg > 0 then
         huDetails.describe = huDetails.describe..'暗杠'..(normAg * 2)..'花;'
         hua = hua + normAg * 2
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
        -- huDetails.describe = huDetails.describe..'大吊车 X 2;'
    end
    -- if self.isQiangGang then
    --     huDetails.describe = huDetails.describe..'抢杠X3;'
    -- end
    if self.isQiangGang then
        table.insert(self.huTypeList, HuTypeConst.kHuType.kQiangGang)
        huDetails.describe = huDetails.describe..'剃头X3;'
    end

    
    if self.gameProgress.m_bDiZero == true then
        huDetails.describe = huDetails.describe..'豹子翻倍;'
    end

    local barHeadStr = "杠头: "
    if self.barHeadType == 1 then
        barHeadStr = "独龙杠: "
    end
    if self.awardFan ~= nil and self.awardFan[self.pos] > 0 then
        huDetails.describe = huDetails.describe.." "..barHeadStr..self.awardFan[self.pos]..';'
        --hua = hua + self.awardFan[self.pos]
    end

    -- if self.isAutoHu then
    --     LOG_DEBUG(' -- auto Hu --')
    -- end

    self.huDetails = huDetails
    self.fan = math.ceil(hua)
    return huDetails, gangKai
end

-- 获取所有的花数，包括自摸的
function CountHuType:getTotalFan()
    -- 自摸花数*3
    local fan = self.fan
    if nil == fan then
        LOG_DEBUG("before getTotalFan ,do calculate")
        fan = 0
    end
    if self.gameProgress.roomRuleMap.cz_playrule_baozi then
        if self.gameProgress.m_bDiZero == true then
            fan = math.ceil(fan * 2) -- 豹子滴零翻倍
        end
    end
    local barsAward = self.awardFan[self.pos] or 0
    -- 自摸 番3倍
    if self.isZiMo == true then  
        fan = math.ceil(fan * 3) + barsAward * 3
        barsAward = 0
    end
    -- 大吊车翻倍
    -- if self:isDaDiaoChe() then
    --     fan = math.ceil(fan * 2)
    -- end

    -- 抢杠翻3倍，一家付
    if self.isQiangGang then
        fan = math.ceil(fan * 3) + barsAward * 3
        barsAward = 0
    end


    fan = fan + barsAward
    
    return fan
end

-- 门清 1 门清 0 不是门清
function CountHuType:isMengQing()
    dump(self.player.pileList, "self.player.pileList mengqing")
    if #self.player.pileList > 0 then
        for _, pile in pairs(self.player.pileList) do 
            if pile.operType ~= MJConst.kOperAG then
                return 0
            end    
        end
    end
    return 1
end

-- 七对
function CountHuType:isQiDui()
    if self.player:hasNewCard() == true then
        return self.player:canSelfHuQiDui()
    else
        return self.player:canHuQiDui(self.huCard)
    end
end

-- 1 豪华七对 2 超豪华七对 3 超超豪华七对 0 无
function CountHuType:getQiDuiType()
    local huCard = self.huCard
    if huCard == nil then
        huCard = self.player:getNewCard()
    end
    if huCard == nil then
        return 0
    end
    local countMap = self.player:transHandCardsToCountMap(false)
    countMap[huCard] = countMap[huCard] + 1
    local sum = 0
    for k, v in pairs(countMap) do
        if v ==  4 then
            sum = sum + 1
        end
    end
    return sum
end

-- 1 字一色 2 清一色，3 混一色 0 无色
function CountHuType:getYiSeType()
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

-- 对对胡
function CountHuType:isDuiDuiHu()
    local hasChi = self:CheckHasChi()
    if hasChi == true then
        return false
    end
    local jiang = 0
    local countMap = self.player:transHandCardsToCountMap(true)
    if self.huCard ~= nil then
        countMap[self.huCard] = countMap[self.huCard] + 1
    end
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

-- 大吊车
function CountHuType:isDaDiaoChe()
    if #self.player.cardList == 1 then
        return true
    end
    return false
end

-- 送杠
function CountHuType:isSongGang()
    local len = table.size(self.player.opHistoryList)
    if len > 1 then
        local justDoOper = self.player.opHistoryList[len - 1]
        if justDoOper == MJConst.kOperMG then
            local pos = self.player.pileList[table.size(self.player.pileList)].from
            return true,pos
        end
    end
    return false,0
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
        justDoOper == MJConst.kOperMXG or 
        justDoOper == MJConst.kOperBuHua then
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
function CountHuType:calcMPengCount()
    local windSum = 0
    local pileList = self.player.pileList

    for k, v in pairs(pileList) do
        if v.operType == MJConst.kOperPeng then
            if v.cardList[1] >= MJConst.Zi1 then
                windSum = windSum + 1
            end
        end
    end

    return windSum
end

-- angang anke in handcards
function CountHuType:calcPengCountInHand()
    -- local windAnKeSum = 0
    -- local windAnGangSum = 0
    -- local arrowAnkeSum = 0
    -- local arrowAnGangSum = 0
    local anKecnt = 0
    -- 手中的风
    local countMap = self.player:transHandCardsToCountMap(true)
    for byteCard, cnt in pairs(countMap) do
        if byteCard >= MJConst.Zi1 then
            if cnt > 2 then
                anKecnt = anKecnt + 1
            end
        end
    end
    return anKecnt
end

 --明杠
 function CountHuType:calcMGangCount()
    --  local mgSum = 0
    --  local mgWindSum = 0
    --  local mgArrowSum = 0
    local windMGang = 0
    local normMGang = 0
     local pileList = self.player.pileList
     for k,v in pairs(pileList) do
         if v.operType == MJConst.kOperMG or v.operType == MJConst.kOperMXG then
             if v.cardList[1] >=  MJConst.Zi1  then
                windMGang = windMGang + 1
            else
                normMGang = normMGang + 1
            end
         end
     end

     --return mgSum, mgWindSum, mgArrowSum
     return windMGang, normMGang
 end

-- angang
 function CountHuType:calcAGangCount()
     local agSum = 0
     local windAgSum = 0
     local pileList = self.player.pileList
     for k,v in pairs(pileList) do
         if v.operType == MJConst.kOperAG then
             if v.cardList[1] >= MJConst.Zi1 then
                 agSum = agSum + 1
             else
                windAgSum = windAgSum + 1
             end
         end
     end
    
     return agSum, windAgSum
 end

function CountHuType:CheckHasChi()
    local hasChi = false
    local pileList = self.player.pileList 
    for k, v in pairs(pileList) do 
        if v.operType == MJConst.kOperLChi or 
            v.operType == MJConst.kOperMChi or 
            v.operType == MJConst.kOperRChi then
            hasChi = true
        end
    end
    return hasChi
end

function CountHuType:calcHuOtherFeng(byteCard)
    local cnt = 0
    if byteCard ~= nil then
        local cardMap = self.player:transHandCardsToCountMap(false)
        if cardMap[byteCard] == nil then
            cardMap[byteCard] = 1
        else
            cardMap[byteCard] = cardMap[byteCard] + 1
        end
        -- dump(cardMap[byteCard], "cardMap")
        if byteCard >= MJConst.Zi1 and byteCard <= MJConst.Zi6 and cardMap[byteCard] == 3 then
            cnt = 1
        end
    end
    return cnt
end

return CountHuType