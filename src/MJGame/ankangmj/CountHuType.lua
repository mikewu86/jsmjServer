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
    self.ishu = false
    self.gangfan = 0
    self.hufan = 0
    self.HuCount = 0
end

function CountHuType:setParams(pos, gameProgress, huCard, fangPaoPos, isQiangGang, isZiMo, isHu, HuCount, isLiuJu, winPos)
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
    self.isHu = isHu
    self.HuCount = HuCount
    self.isLiuJu = isLiuJu
    self.winPos = winPos
end

function CountHuType:clearAutoHuFlag()
    self.isAutoHu = false
    self.isBaoPai = false
    self.baoPaiPos = nil
    self.songGang = false
    self.songGangPos = nil
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

    huDetails.pos = self.pos
    huDetails.describe = ''
    local gangKai = 0

    local daHuList = nil
    -- 填充当前的胡牌类型
    -- local innerFill = function(huType, _huDetails)
    --     self:fillDetial(_huDetails, huType)
    --     hua = hua + huTypeMap[huType].fan
    --     if table.keyof(HuTypeConst.kDaHuTypeList, huType) ~= nil then
    --         bDaHu = true
    --     end
    -- end
    
    -- 自摸
    if self.isZiMo then
        --innerFill(HuTypeConst.kHuType.kHu, huDetails)then
        if self.isHu then
            huDetails.describe = huDetails.describe..'自摸3分;'
            hua = hua + 3
        else
            huDetails.describe = huDetails.describe..'自摸-1分;'
            hua = hua - 1
        end
    end

    -- 抢杠
    if self.isQiangGang then
        if self.isHu then
            huDetails.describe = huDetails.describe..'抢杠3分;'
            hua = hua + 3
        elseif self.pos == self.fangPaoPos then
            local HuFans = 3 * self.HuCount
            huDetails.describe = huDetails.describe..'被抢杠-'..HuFans..'分;'
            hua = hua - HuFans
        end
    end

    local mDianGang = 0
    local mJieGang = 0

    -- 明杠
    local mGangCount = self:getMGangCount()
    if mGangCount > 0 then
        --huDetails.describe = huDetails.describe..'明杠'..mGangCount..'分;'
        mJieGang = mJieGang + mGangCount * 3
    end

    -- 碰杠
    local pGangCount = self:getMXGangCount()
    if self.isQiangGang and self.pos == self.fangPaoPos then
        pGangCount = pGangCount - 1
    end
    if pGangCount > 0 then
        --huDetails.describe = huDetails.describe..'碰杠'..pGangCount..'分;'
        mJieGang = mJieGang + pGangCount * 3
    end

    -- 暗杠
    local aGangCount = self:getAGangCount()
    if aGangCount > 0 then
        --huDetails.describe = huDetails.describe..'暗杠'..aGangCount..'分;'
        mJieGang = mJieGang + aGangCount * 6
    end

    if mJieGang > 0 then
        huDetails.describe = huDetails.describe..'接杠'..mJieGang..'分;'
        hua = hua + mJieGang
    end

    -- 被明杠
    local mDainCount = self:getDianGangCount()
    if mDainCount > 0 then
        mDianGang = mDianGang + mDainCount * 3
    end

    -- 被暗杠
    local mBAnGangCount = self:getOtherAGangCount()
    if mBAnGangCount > 0 then
        mDianGang = mDianGang + mBAnGangCount * 2
    end

    -- 被碰杠
    local mBPGangCount = self:getOtherMXGangCount()
    if self.isQiangGang and self.pos ~= self.fangPaoPos then
        mBPGangCount = mBPGangCount - 1
    end
    if mBPGangCount > 0 then
        mDianGang = mDianGang + mBPGangCount * 1
    end

    if mDianGang > 0 then
        huDetails.describe = huDetails.describe..'点杠-'..mDianGang..'分;'
        hua = hua - mDianGang
    end
    
    self:baoPao()

    -- 中码
    if self.isLiuJu ~= true and self.winPos ~= nil then
        if self.isHu then
            local ZhaMa = self.gameProgress.ZhaMaFen[self.pos]
            if ZhaMa > 0 then
                ZhaMa = ZhaMa * 3
                huDetails.describe = huDetails.describe..'中码'..ZhaMa..'分;'
                hua = hua + ZhaMa
            end
        else
            if self.isQiangGang then
                if self.fangPaoPos == self.pos then
                    local ZhaMa = 0
                    for _, pos in pairs(self.winPos) do 
                        ZhaMa = ZhaMa + self.gameProgress.ZhaMaFen[pos]
                    end
                    ZhaMa = ZhaMa * 3
                    if ZhaMa > 0 then
                        huDetails.describe = huDetails.describe..'中码-'..ZhaMa..'分;'
                        hua = hua - ZhaMa
                    end
                end
            else
                local ZhaMa = 0
                for _, pos in pairs(self.winPos) do 
                    ZhaMa = ZhaMa + self.gameProgress.ZhaMaFen[pos]
                end
                if ZhaMa > 0 then
                    huDetails.describe = huDetails.describe..'中码-'..ZhaMa..'分;'
                    hua = hua - ZhaMa
                end
            end
        end
    end

    self.huDetails = huDetails
    self.fan = hua
    return huDetails,gangKai
end

-- 获取所有的花数，包括自摸的
function CountHuType:getTotalFan()
    local fan = self.fan
    return fan
end

-- 门清
function CountHuType:isMengQing()
    if #self.player.pileList > 0 then
        return false
    end
    return true
end

-- 无花果
function CountHuType:isWuHuaGuo()
    local realHuaNum = table.size(self.player.huaList)
    if realHuaNum == 0 then
        return true
    end
    return false
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
    -- 去掉百搭
    
    local suitCountList = {}
    local suitCount = 0
    for suit = MJConst.kMJSuitWan, MJConst.kMJSuitZi do
        suitCount = self.player:getSuitCountInHandWithBaida(suit,true,self.gameProgress.baiDa)
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

-- 送杠
function CountHuType:isSongGang()
    local len = #self.player.opHistoryList
    if len > 1 then
        local justDoOper = 0
        for i=1,#self.player.opHistoryList do
            justDoOper = self.player.opHistoryList[len - i]
            if justDoOper ~= MJConst.kOperBuHua then
                break
            end
        end
        if justDoOper == MJConst.kOperMG then
            local pos = self.player.pileList[#self.player.pileList].from
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

    if #self.player.pileList > 0 then
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
    if self.mjWall:getCanGetCount() <= 0 and 
    self.player:hasNewCard() == true then
        return true
    end
    return false
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

-- 风碰
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

-- 风胡别人的牌三张
function CountHuType:getFengHuKeCount()
    local sum = 0
    local huCard = self.huCard
    if huCard == nil then
        return sum
    end
    -- 手中的风
    local countMap = self.player:transHandCardsToCountMap(false)
    countMap[huCard] = countMap[huCard] + 1
    if huCard >= MJConst.Zi1 and huCard <= MJConst.Zi4 and countMap[huCard] == 3 then
        sum = sum + 1
    end
    return sum
end

--明杠
function CountHuType:getMGangCount()
    local sum = 0
    local pileList = self.player.pileList
    for k,v in pairs(pileList) do
        if v.operType == MJConst.kOperMG then
            if v.cardList[1] < MJConst.Zi1 or v.cardList[1] > MJConst.Zi4 then
                sum = sum + 1
            end
        end
    end
    
    return sum
end

--点杠
function CountHuType:getDianGangCount()
    local sum = 0
    for i = 1, 4 do
        local player = self.playerList[i]
        local pileList = player.pileList
        for k,v in pairs(pileList) do
            if v.operType == MJConst.kOperMG 
                and v.from == self.pos then
                sum = sum + 1
            end
        end
    end

    return sum
end

--面下杠
function CountHuType:getMXGangCount()
    local sum = 0
    local pileList = self.player.pileList
    for k,v in pairs(pileList) do
        if v.operType == MJConst.kOperMXG then
            sum = sum + 1
        end
    end
    
    return sum
end

--其他人面下杠
function CountHuType:getOtherMXGangCount()
    local sum = 0
    for i = 1, 4 do
        local player = self.playerList[i]
        local pileList = player.pileList
        for k,v in pairs(pileList) do
            if v.operType == MJConst.kOperMXG 
                and i ~= self.pos then
                    sum = sum + 1
            end
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

--其他人暗杠
function CountHuType:getOtherAGangCount()
    local sum = 0
    for i = 1, 4 do
        local player = self.playerList[i]
        local pileList = player.pileList
        for k,v in pairs(pileList) do
            if v.operType == MJConst.kOperAG 
                and i ~= self.pos then
                    sum = sum + 1
            end
        end
    end
    return sum
end

--风明杠
function CountHuType:getFengMGangCount()
    local sum = 0
    local pileList = self.player.pileList
    for k,v in pairs(pileList) do
        if v.operType == MJConst.kOperMG then
            if v.cardList[1] >= MJConst.Zi1 and v.cardList[1] <= MJConst.Zi4 then
                sum = sum + 1
            end
        end
    end
    
    return sum
end


--风碰杠
function CountHuType:getFengPGangCount()
    local sum = 0
    local pileList = self.player.pileList
    for k,v in pairs(pileList) do
        if v.operType == MJConst.kOperMXG then
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

function CountHuType:getHuaGang()
    local sum = 0

    for _cardByte = MJConst.Zi1,MJConst.Baida do
        local cardNum = self.player:getCardNumInHua(_cardByte)
        if cardNum >= 4 then
            sum = sum + 1
        end
    end
    -- 春夏秋冬
    local huaNum = 0
    for _cardByte = MJConst.Hua1,MJConst.Hua4 do
        local cardNum = self.player:getCardNumInHua(_cardByte)
        if cardNum == 1 then
            huaNum = huaNum + 1
        end
    end
    if huaNum == 4 then
        sum = sum + 1
    end
    -- 梅兰竹菊
    huaNum = 0
    for _cardByte = MJConst.Hua5,MJConst.Hua8 do
        local cardNum = self.player:getCardNumInHua(_cardByte)
        if cardNum == 1 then
            huaNum = huaNum + 1
        end
    end
    if huaNum == 4 then
        sum = sum + 1
    end
    -- 财神猫老鼠聚宝盆
    huaNum = 0
    for _cardByte = MJConst.Cai,MJConst.Shu do
        local cardNum = self.player:getCardNumInHua(_cardByte)
        if cardNum == 1 then
            huaNum = huaNum + 1
        end
    end
    if huaNum == 4 then
        sum = sum + 1
    end

    return sum
end

return CountHuType