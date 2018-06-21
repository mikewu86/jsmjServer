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
    self.dui3Zui = false
    self.dui3ZuiPos = nil
end

function CountHuType:setParams(pos, gameProgress, huCard, fangPaoPos, isQiangGang, isZiMo, awardFan)
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
    self.awardFan = awardFan
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
        huDetails.describe = huDetails.describe..cfg.name..' '..cfg.descrip..';'
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

-- 包牌情况3 被同一人连续碰杠在次，再对出任何一次，则送3嘴的人包
function CountHuType:baoPao3(pileList, noAnGangPileList, fromList, anGangCount)
    if #noAnGangPileList >= 3 then
        -- 送3次的人包牌
        if fromList[1] == fromList[2] and 
           fromList[2] == fromList[3] then
           self.dui3ZuiPos = fromList[1]   -- 更改放炮玩家为包牌玩家
           self.dui3Zui = true
           self.isBaoPai = true
           self.baoPaiPos = fromList[1]
           if #pileList == 4 then
                self.isAutoHu = true
           end
           return true
        end
        if #noAnGangPileList == 4 then
            if fromList[3] == fromList[4] and 
                fromList[2] == fromList[3] then
                self.dui3ZuiPos = fromList[2]   -- 更改放炮玩家为包牌玩家
                self.isAutoHu = true
                self.dui3Zui = true
                self.isBaoPai = true
                self.baoPaiPos = fromList[2]
                return true
            end
        end
    end
    return false
end

-- 计算包牌 情况的顺序代表包牌判断的优先级
function CountHuType:calulateBaoPai()
    self.isBaoPai = false
    self.baoPaiPos = nil
    self.dui3Zui = false
    self.dui3ZuiPos = nil
    -- 包牌都在碰杠出来的牌上做文章
    local pileList = self.player.pileList 
    -- 没有暗杠的List
    local noAnGangPileList = {}
    local fromList = {}
    for k, v in pairs(pileList) do
        if v.operType ~= MJConst.kOperAG then
            table.insert(noAnGangPileList, v)
            table.insert(fromList, v.from)
        end
    end

    -- 暗杠的次数
    local anGangCount = #pileList - #noAnGangPileList

    -- 根据优先级判断
    if self:baoPao3(pileList, noAnGangPileList, fromList, anGangCount) then
        return
    end
end

-- 计算详细胡牌类型
function CountHuType:calculate()
    local huDetails = {}  -- 胡牌详细信息
    self.huTypeList = {}  -- 所有胡牌类型的列表
    if self.pos == nil or self.player == nil then
        LOG_DEBUG('-- no pos or no player --')
        dump(self.pos)
        return huDetails
    end
    local huTypeMap = HuTypeConst.huTypeMap  -- 胡牌对照表 
    local hua = 0

    local bDaHu = false
    local bMengQing = false

    huDetails.pos = self.pos
    huDetails.describe = ''

    local daHuList = nil
    -- 填充当前的胡牌类型
    local innerFill = function(huType, _huDetails)
        self:fillDetial(_huDetails, huType)
        hua = hua + huTypeMap[huType].fan
        if table.keyof(HuTypeConst.kDaHuTypeList, huType) ~= nil then
            bDaHu = true
        end
    end
    
    -- 胡牌
    innerFill(HuTypeConst.kHuType.kHu, huDetails)

    -- 硬花数
    huDetails.describe = huDetails.describe..'花牌'..table.size(self.player.huaList)..'花;'
    hua = hua + table.size(self.player.huaList)

    -- 明杠
    local mGangCount = self:getMGangCount()
    if mGangCount > 0 then
        mGangCount = mGangCount * 1
        huDetails.describe = huDetails.describe..'明杠'..mGangCount..'花;'
        hua = hua + mGangCount
    end

    -- 暗杠
    local aGangCount = self:getAGangCount()
    if aGangCount > 0 then
        aGangCount = aGangCount * 2
        huDetails.describe = huDetails.describe..'暗杠'..aGangCount..'花;'
        hua = hua + aGangCount
    end

    -- 风明杠
    local fengMGangCount = self:getFengMGangCount()
    if fengMGangCount > 0 then
        fengMGangCount = fengMGangCount * 2
        huDetails.describe = huDetails.describe..'风明杠'..fengMGangCount..'花;'
        hua = hua + fengMGangCount
    end

    -- 风暗杠
    local fengAGangCount = self:getFengAGangCount()
    if fengAGangCount > 0 then
        fengAGangCount = fengAGangCount * 3
        huDetails.describe = huDetails.describe..'风暗杠'..fengAGangCount..'花;'
        hua = hua + fengAGangCount
    end

    -- 风暗刻
    local fengKeCount = self:getFengKeCount()
    if fengKeCount > 0 then
        fengKeCount = fengKeCount * 1
        huDetails.describe = huDetails.describe..'风暗刻'..fengKeCount..'花;'
        hua = hua + fengKeCount
    end

    -- 天胡，地胡,海底
    -- if self:isTianHu() then
    --     innerFill(HuTypeConst.kHuType.kTianHu, huDetails)
    -- elseif self:isDiHu() then
    --     innerFill(HuTypeConst.kHuType.kDiHu, huDetails)

    -- 门清
    if self:isMengQing() == 1 then
        huDetails.describe = huDetails.describe..'门清X2;'
        hua = hua + hua * 1
        if self:isWuHuaGuo() then
            -- 无花果，不是自摸，花算一半
            if self.isZiMo == false then
                huDetails.describe = huDetails.describe..'无花果放铳X2;'
                hua = hua + hua * 1
            else
                huDetails.describe = huDetails.describe..'无花果X3;'
                hua = hua + hua * 2
            end
        end
        table.insert(self.huTypeList, HuTypeConst.kHuType.kMengQing)
    end

    -- 清一色，混一色,缺门
    local yiSeType = self:getYiSeType()
    if yiSeType == 2 then
        huDetails.describe = huDetails.describe..'清一色X5;'
        hua = hua + hua * 4
        table.insert(self.huTypeList, HuTypeConst.kHuType.kQingYiSe)
    elseif yiSeType == 3 then
        huDetails.describe = huDetails.describe..'混一色X3;'
        hua = hua + hua * 2
        table.insert(self.huTypeList, HuTypeConst.kHuType.kHunYiSe)
    end

    -- 对对胡
    if self:isDuiDuiHu() then
        huDetails.describe = huDetails.describe..'对对胡X3;'
        hua = hua + hua * 2
        table.insert(self.huTypeList, HuTypeConst.kHuType.kDuiDuiHu)
    end

    -- 杠开
    if self:isGangKai() then
        huDetails.describe = huDetails.describe..'杠开X2;'
        hua = hua + hua * 1
        table.insert(self.huTypeList, HuTypeConst.kHuType.kGangKai)
    end

    -- 大吊车
    if self:isDaDiaoChe() then
        -- innerFill(HuTypeConst.kHuType.kDaDiaoChe, huDetails)
        huDetails.describe = huDetails.describe..'大吊车X2;'
        hua = hua + hua * 1
        table.insert(self.huTypeList, HuTypeConst.kHuType.kDaDiaoChe)
    end

    -- 豹子
    if self.gameProgress.roomRuleMap['tc_playrule_baozi'] then
        if self.gameProgress.m_bBaoZi then
            huDetails.describe = huDetails.describe..'豹子X2;'
            hua = hua + hua * 1 -- 豹子翻倍
        end
    end

    self:baoPao()
    -- 计算包牌
    self:calulateBaoPai()
    if true == self.dui3Zui then
        if true == self.isZiMo then
            huDetails.describe = huDetails.describe..'包牌X5;'
        end
    end

    -- 抢杠
    if self.isQiangGang then
        huDetails.describe = huDetails.describe..'抢杠X3;'
    end

    -- if self.gameProgress.roomRuleMap['sz_role_bzdl'] then
    --     if self.gameProgress.m_bNextDiZero then
    --         huDetails.describe = huDetails.describe..'滴零 X 2;'
    --     end

    --     if self.gameProgress.m_bBaoZi then 
    --         huDetails.describe = huDetails.describe..'豹子 X 2;'
    --     end
    -- end

    -- if self.isZiMo then
        -- huDetails.describe = huDetails.describe..'自摸;'       
    -- end

    if self.isAutoHu then
        LOG_DEBUG(' -- auto Hu --')
    end

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
    -- 自摸 番3倍
    if self.isZiMo == true then  
        fan = math.ceil(fan * 3)
    end
    -- 大吊车翻倍
    -- if self:isDaDiaoChe() then
    --     fan = math.ceil(fan * 2)
    -- end

    -- 抢杠翻3倍，一家付
    if self.isQiangGang then
        fan = math.ceil(fan * 3)
    end

    -- if self.gameProgress.roomRuleMap['sz_role_bzdl'] then
    --     if self.gameProgress.m_bNextDiZero then
    --         fan = math.ceil(fan * 2) -- 滴零翻倍
    --     end
    
    --     if self.gameProgress.m_bBaoZi then 
    --         fan = math.ceil(fan * 2) -- 豹子翻倍
    --     end
    -- end

    return fan
end

-- 门清 1 门清 0 不是门清
function CountHuType:isMengQing()
    if table.size(self.player.pileList) > 0 then
        return 0
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

-- 1 字一色 2 清一色，3 混一色 0 无色
function CountHuType:getYiSeType()
    local suitCountList = {}
    local suitCount = 0
    for suit = MJConst.kMJSuitWan, MJConst.kMJSuitZi do
        suitCount = self.player:getSuitCountInHandWithBaida(suit, true, self.gameProgress.baiDa)
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

-- -- 对对胡
-- function CountHuType:isDuiDuiHu()
--     local hasChi = self:CheckHasChi()
--     if hasChi == true then
--         return false
--     end
--     local jiang = 0
--     local countMap = self.player:transHandCardsToCountMap(true)
--     if self.huCard ~= nil then
--         countMap[self.huCard] = countMap[self.huCard] + 1
--     end
--     for k, v in pairs(countMap) do
--         if v % 3 ~= 0 then
--             if v == 2 then
--                 if jiang == 0 then
--                     jiang = 1
--                 else
--                     return false
--                 end
--             else
--                 return false
--             end
--         end
--     end
--     return true
-- end

-- 对对胡
function CountHuType:isDuiDuiHu()
    local hasChi = self:CheckHasChi()
    if hasChi == true then
        return false
    end
    local countMap = self.player:transHandCardsToCountMap(true,{self.gameProgress.baiDa})
    if self.huCard ~= nil then
        if self.huCard ~= self.player.daCard then
            countMap[self.huCard] = countMap[self.huCard] + 1
        else
            countMap[0] = countMap[0] + 1
        end
    end
    countMap[0] = 0
    local daCnt = self.player:hasBaiDa(self.gameProgress.baiDa)
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

-- 大吊车
function CountHuType:isDaDiaoChe()
    if #self.player.cardList == 1 then
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

-- 明杠
function CountHuType:getMGangCount()
    local sum = 0
    local pileList = self.player.pileList
    for k,v in pairs(pileList) do
        if v.operType == MJConst.kOperMG or v.operType == MJConst.kOperMXG then
            if v.cardList[1] < MJConst.Zi1 then
                sum = sum + 1
            end
        end
    end
    
    return sum
end

-- 暗杠
function CountHuType:getAGangCount()
    local sum = 0
    local pileList = self.player.pileList
    for k,v in pairs(pileList) do
        if v.operType == MJConst.kOperAG then
            if v.cardList[1] < MJConst.Zi1 then
                sum = sum + 1
            end
        end
    end
    
    return sum
end

-- 无花果
function CountHuType:isWuHuaGuo()
    if #self.player.huaList > 0 then
        return false
    end
    return true
end

-- 风暗刻
function CountHuType:getFengKeCount()
    local sum = 0
    local huCard = self.player:getNewCard()
    -- 手中的风
    local countMap = self.player:transHandCardsToCountMap(false)
    if huCard ~= nil then
        countMap[huCard] = countMap[huCard] + 1
    end
    for i = MJConst.Zi1, MJConst.Zi4 do
        if countMap[i] == 3 then
            sum = sum + 1
        end
    end
    return sum
end

--风明杠
function CountHuType:getFengMGangCount()
    local sum = 0
    local pileList = self.player.pileList
    for k,v in pairs(pileList) do
        if v.operType == MJConst.kOperMG or v.operType == MJConst.kOperMXG then
            if v.cardList[1] >= MJConst.Zi1 and v.cardList[1] <= MJConst.Zi4 then
                sum = sum + 1
            end
        end
    end
    
    return sum
end

--风暗杠
function CountHuType:getFengAGangCount()
    local sum = 0
    local pileList = self.player.pileList
    for k,v in pairs(pileList) do
        if v.operType == MJConst.kOperAG then
            if v.cardList[1] >= MJConst.Zi1 and v.cardList[1] <= MJConst.Zi4 then
                sum = sum + 1
            end
        end
    end
    return sum
end

return CountHuType