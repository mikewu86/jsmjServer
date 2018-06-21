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
end

function CountHuType:clearAutoHuFlag()
    self.isAutoHu = false
    self.isBaoPai = false
    self.baoPaiPos = nil
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
        dump(self.pos)
        return huDetails
    end
    local huTypeMap = HuTypeConst.huTypeMap  -- 胡牌对照表 
    local hua = 0

    local bDaHu = false
    local bMengQing = false
    local isGangkai = 0

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

    if #self.player.huaList > 0 then
        -- 硬花数
        huDetails.describe = huDetails.describe..'花牌'..#self.player.huaList..'花;'
        hua = hua + #self.player.huaList
    end

    -- 清一色，混一色
    local yiSeType = self:getYiSeType()
    if yiSeType == 2 then
        innerFill(HuTypeConst.kHuType.kQingYiSe, huDetails)
    elseif yiSeType == 3 then
        innerFill(HuTypeConst.kHuType.kHunYiSe, huDetails)
    end

    -- 七对不算门清

    if self:isQiDui() then
        innerFill(HuTypeConst.kHuType.kQiDui, huDetails)
    else
        -- 门清
        if self:isMengQing() then
            innerFill(HuTypeConst.kHuType.kMengQing, huDetails)
        end
    end

    -- 对对胡
    if self:isDuiDuiHu() then
        innerFill(HuTypeConst.kHuType.kDuiDuiHu, huDetails)
    end

    -- 无花果
    if #self.player.huaList == 0 then
        innerFill(HuTypeConst.kHuType.kWuHuaGuo, huDetails)
    end

    -- 一条龙
    if self:isYiTiaoLong() then
        innerFill(HuTypeConst.kHuType.kYiTiaoLong, huDetails)
    end

    -- -- 杠牌
    -- local gangCount = self:getGangCount()
    -- if gangCount > 0 then
    --     huDetails.describe = huDetails.describe..'杠'..gangCount..'花;'
    --     hua = hua + gangCount
    -- end

    -- -- 风杠
    -- local fengGangCount = self:getFengGangCount()
    -- if fengGangCount > 0 then
    --     fengGangCount = fengGangCount * 2
    --     huDetails.describe = huDetails.describe..'风杠'..fengGangCount..'花;'
    --     hua = hua + fengGangCount
    -- end

    -- -- 风碰
    -- local fengPengCount = self:getFengPengCount()
    -- if fengPengCount > 0 then
    --     huDetails.describe = huDetails.describe..'风碰'..fengPengCount..'花;'
    --     hua = hua + fengPengCount
    -- end

    -- 花数翻倍
    -- 杠开
    if self:isGangKai() then
        isGangkai = 1
        huDetails.describe = huDetails.describe..'杠后开花 X 2;'
        table.insert(self.huTypeList, HuTypeConst.kHuType.kGangKai)
        hua = hua * 2
    end

    -- 豪七
    if self:isQiDui() then
        local qiDuiType = self:getQiDuiType()
        if qiDuiType == 1 then
            huDetails.describe = huDetails.describe..'豪华七对 X 2;'
            table.insert(self.huTypeList, HuTypeConst.kHuType.kHQiDui)
            hua = hua * 2
        elseif qiDuiType == 2 then
            huDetails.describe = huDetails.describe..'超豪华七对 X 4;'
            table.insert(self.huTypeList, HuTypeConst.kHuType.kHQiDui)
            hua = hua * 4
        elseif qiDuiType == 3 then
            huDetails.describe = huDetails.describe..'超超豪华七对 X 6;'
            table.insert(self.huTypeList, HuTypeConst.kHuType.kHQiDui)
            hua = hua * 6
        end
    end

    -- 全球独钓
    if self:isDaDiaoChe() then
        huDetails.describe = huDetails.describe..'大吊车 X 2;'
        table.insert(self.huTypeList, HuTypeConst.kHuType.kDaDiaoChe)
        hua = hua * 2
    end

    -- 天胡
    if self:isTianHu() then
        huDetails.describe = huDetails.describe..'天胡 X 4;'
        table.insert(self.huTypeList, HuTypeConst.kHuType.kTianHu)
        hua = hua * 4
    end

    -- 地胡
    -- if self:isDiHu() then
    --     huDetails.describe = huDetails.describe..'地胡 X 2;'
    --     table.insert(self.huTypeList, HuTypeConst.kHuType.kDiHu)
    --     hua = hua * 2
    -- end

    -- 天听
    -- if self:isTianTing() then
    --     huDetails.describe = huDetails.describe..'天听 X 2;'
    --     table.insert(self.huTypeList, HuTypeConst.kHuType.kTianTing)
    --     hua = hua * 2
    -- end

    -- self:baoPao()

    -- -- 抢杠
    -- if self.isQiangGang then
    --     huDetails.describe = huDetails.describe..'抢杠 X 2;'
    --     table.insert(self.huTypeList, HuTypeConst.kHuType.kQiangGang)
    --     hua = hua * 2
    -- end

    -- 杠冲
    if self:isGangChong() then
        huDetails.describe = huDetails.describe..'杠冲 X 2;'
        table.insert(self.huTypeList, HuTypeConst.kHuType.kGangChong)
        hua = hua * 2
    end

    -- if self.gameProgress.roomRuleMap['sz_playrule_bzdl'] then
        if self.gameProgress.m_bNextDiZero and self.gameProgress.m_bBaoZi then
            huDetails.describe = huDetails.describe..'豹子 X 2;'
            hua = hua * 2
        elseif self.gameProgress.m_bNextDiZero then
            huDetails.describe = huDetails.describe..'豹子 X 2;'
            hua = hua * 2
        elseif self.gameProgress.m_bBaoZi then 
            huDetails.describe = huDetails.describe..'豹子 X 2;'
            hua = hua * 2
        end
    -- end

    self.huDetails = huDetails
    self.fan = hua
    return huDetails,isGangkai
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

    -- 抢杠翻3倍，一家付
    -- if self.isQiangGang then
    --     fan = math.ceil(fan * 3)
    -- end

    return fan
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

    if #self.player.pileList > 0 then
        return false
    end

    -- 必须不是自摸
    if self.player:hasNewCard() == true then
        return false
    end

    return true
end

-- 杠开
function CountHuType:isGangKai()
    local len = #self.player.opHistoryList
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

-- 天听
function CountHuType:isTianTing()
    if self.gameProgress.tianTing == true then
        return true
    end
    return false
end

-- 杠冲
function CountHuType:isGangChong()
    if self.fangPaoPos and self.fangPaoPos ~= -1 then
        local fangPaoPlayer = self.playerList[self.fangPaoPos]
        local len = #fangPaoPlayer.opHistoryList
        dump(fangPaoPlayer.opHistoryList, "fangPaoPlayer.opHistoryList")
        if len > 1 then
            -- 上一次操作为明杠，暗杠，花杠的放炮
            local justDoOper = fangPaoPlayer.opHistoryList[len - 2]
            if justDoOper == MJConst.kOperMG or
            justDoOper == MJConst.kOperAG or
            justDoOper == MJConst.kOperMXG or
            justDoOper == MJConst.kOperHG then
                return true
            end
        end
    end
    return false
end

function CountHuType:getGangCount()
    local sum = 0
    local pileList = self.player.pileList
    for k,v in pairs(pileList) do
        if v.operType == MJConst.kOperMG or v.operType == MJConst.kOperMXG or v.operType == MJConst.kOperAG then
            if v.cardList[1] < MJConst.Zi1 then
                sum = sum + 1
            end
        end
    end
    
    return sum
end

function CountHuType:getFengGangCount()
    local sum = 0
    local pileList = self.player.pileList
    for k,v in pairs(pileList) do
        if v.operType == MJConst.kOperMG or v.operType == MJConst.kOperMXG or v.operType == MJConst.kOperAG then
            if v.cardList[1] >= MJConst.Zi1 and v.cardList[1] <= MJConst.Zi4 then
                sum = sum + 1
            end
        end
    end
    
    return sum
end

function CountHuType:getFengPengCount()
    local sum = 0
    local pileList = self.player.pileList
    for byteCard = MJConst.Zi1, MJConst.Zi4 do
        for k, v in pairs(pileList) do
            if v:getCardCount(byteCard) == 3 then
                sum = sum + 1
            end
        end
    end
    return sum
end

function CountHuType:isYiTiaoLong()
    local huCard = self.huCard
    if huCard == nil then
        huCard = self.player:getNewCard()
    end
    if huCard == nil then
        return 0
    end
    local countMap = self.player:transHandCardsToCountMap(false)
    local cpyMap = table.copy(countMap)
    cpyMap[huCard] = cpyMap[huCard] + 1

    local bRet = false
    local shunWan = true
    local shunTiao = true
    local shunTong = true

    for i = MJConst.Wan1, MJConst.Wan9 do 
        if cpyMap[i] < 1 then
            shunWan = false
            break
        end
    end

    if shunWan then
        for i = MJConst.Wan1, MJConst.Wan9 do 
            cpyMap[i] = cpyMap[i] - 1
        end
        if self.player.mjMath:canHu(cpyMap) == true then
            bRet = true
        end
    end

    for i = MJConst.Tiao1, MJConst.Tiao9 do 
        if cpyMap[i] < 1 then
            shunTiao = false
            break
        end
    end

    if shunTiao then
        for i = MJConst.Tiao1, MJConst.Tiao9 do 
            cpyMap[i] = cpyMap[i] - 1
        end
        if self.player.mjMath:canHu(cpyMap) == true then
            bRet = true
        end
    end

    for i = MJConst.Tong1, MJConst.Tong9 do 
        if cpyMap[i] < 1 then
            shunTong = false
            break
        end
    end

    if shunTong then
        for i = MJConst.Tong1, MJConst.Tong9 do 
            cpyMap[i] = cpyMap[i] - 1
        end
        if self.player.mjMath:canHu(cpyMap) == true then
            bRet = true
        end
    end
    
    return bRet
end

return CountHuType