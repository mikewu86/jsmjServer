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

    -- if self.player:hasBaiDa(self.gameProgress.baiDa) == 0 then
    --     huDetails.describe = huDetails.describe..'无百搭5花;'
    --     hua = hua + 5
    -- else
    --     local isqiDui = self:isQiDui()
    --     if self.player:checkChuKe(self.gameProgress.baiDa,isqiDui) then
    --         huDetails.describe = huDetails.describe..'吊百搭5花;'
    --         hua = hua + 5
    --     end
    -- end

    local huKe =  self:getFengHuKeCount()
    if huKe == 1 then
        huDetails.describe = huDetails.describe..'胡牌6花;'
        hua = hua + 6
    else
        huDetails.describe = huDetails.describe..'胡牌5花;'
        hua = hua + 5
    end

    if #self.player.huaList > 0 then
        -- 硬花数
        huDetails.describe = huDetails.describe..'花牌'..#self.player.huaList..'花;'
        hua = hua + #self.player.huaList
    end

    -- 七对门清互不影响 硬花不翻倍
    -- 七对

    -- 清一色，混一色,缺门
    local yiSeType = self:getYiSeType()
    if yiSeType == 2 then
        innerFill(HuTypeConst.kHuType.kQingYiSe, huDetails)
    elseif yiSeType == 3 then
        innerFill(HuTypeConst.kHuType.kHunYiSe, huDetails)
    end
    -- 对对胡
    if self:isDuiDuiHu() then
        innerFill(HuTypeConst.kHuType.kDuiDuiHu, huDetails)
    end
    -- 杠开
    if self:isGangKai() then
        isGangkai = 1
        innerFill(HuTypeConst.kHuType.kGangKai, huDetails)
    end

    -- 送杠不算门清
    -- 送杠
    local isSong,pos = self:isSongGang()
    if isSong then
        self.songGang = true
        self.songGangPos = pos
        table.insert(self.huTypeList, HuTypeConst.kHuType.kSongGang)
    end

    if self:isQiDui() then
        -- 7对无花加大小门清
        if #self.player.huaList == 0 then
            innerFill(HuTypeConst.kHuType.kDMengQing, huDetails)
            innerFill(HuTypeConst.kHuType.kXMengQing, huDetails)
        else
            innerFill(HuTypeConst.kHuType.kXMengQing, huDetails)
        end
    else
        -- 门清
        local menQingType = self:isMengQing()
        if menQingType == 1 then
            innerFill(HuTypeConst.kHuType.kDMengQing, huDetails)
        elseif menQingType == 2 then
            innerFill(HuTypeConst.kHuType.kXMengQing, huDetails)
        elseif menQingType == 3 then
            innerFill(HuTypeConst.kHuType.kDMengQing, huDetails)
            innerFill(HuTypeConst.kHuType.kXMengQing, huDetails)
        end
    end

    if self.isQiangGang then
        table.insert(self.huTypeList, HuTypeConst.kHuType.kQiangGang)
    end

    -- 风碰
    local fengPengCount = self:getFengPengCount()
    if fengPengCount > 0 then
        huDetails.describe = huDetails.describe..'风碰'..fengPengCount..'花;'
        hua = hua + fengPengCount
    end

    -- 风暗碰
    local fengKeCount = self:getFengKeCount()
    if fengKeCount > 0 then
        fengKeCount = fengKeCount * 2
        huDetails.describe = huDetails.describe..'风暗刻'..fengKeCount..'花;'
        hua = hua + fengKeCount
    end

    -- 风明杠
    local fengMGangCount = self:getFengMGangCount()
    if fengMGangCount > 0 then
        fengMGangCount = fengMGangCount * 3
        huDetails.describe = huDetails.describe..'风明杠'..fengMGangCount..'花;'
        hua = hua + fengMGangCount
    end

    -- 风暗杠
    local fengAGangCount = self:getFengAGangCount()
    if fengAGangCount > 0 then
        fengAGangCount = fengAGangCount * 4
        huDetails.describe = huDetails.describe..'风暗杠'..fengAGangCount..'花;'
        hua = hua + fengAGangCount
    end

    -- 明杠
    local mGangCount = self:getMGangCount()
    if mGangCount > 0 then
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

    -- 天胡，地胡,海底
    if self:isTianHu() then
        innerFill(HuTypeConst.kHuType.kTianHu, huDetails)
    elseif self:isDiHu() then
        innerFill(HuTypeConst.kHuType.kDiHu, huDetails)
    end

    if self:isDaDiaoChe() then
        innerFill(HuTypeConst.kHuType.kDaDiaoChe, huDetails)
    end

    self:baoPao()

    if self:isQiDui() then
        innerFill(HuTypeConst.kHuType.kQiDui, huDetails)
    end

    -- 扎码
    if not self.gameProgress.roomRuleMap.sz_extrarule1_bufan then
        local ZhaMa = self.gameProgress.ZhaMaCount
        if ZhaMa > 0 then
            ZhaMa = ZhaMa * 5
            huDetails.describe = huDetails.describe..'翻牌'..ZhaMa..'花;'
            hua = hua + ZhaMa
        end
    end

    -- 抢杠送杠*3
    if self.isQiangGang then
        huDetails.describe = huDetails.describe..'抢杠X3;'
    end

    local isSong,pos = self:isSongGang()
    if isSong then
        huDetails.describe = huDetails.describe..'包饺子X3;'
    end

    if self.isAutoHu then
        LOG_DEBUG(' -- auto Hu --')
    end

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
    if self.isQiangGang then
        fan = math.ceil(fan * 3)
    end

    return fan
end

-- 门清 1 大门清 2 小门清 3 大小门清0 不是门清
function CountHuType:isMengQing()
    local hualist = self.player:getHuaList()
    -- 软化 风暗刻 暗杠 风暗杠
    local anKe = self:getFengKeCount()*2
    local anGang = self:getAGangCount()*2
    local anFGang = self:getFengAGangCount()*4
    local anhGang = self:getFengHuKeCount()

    local count = #hualist + anKe + anGang + anFGang + anhGang
    if count == 0 then
        if self:getFengPengCount() > 0 then
            return 0
        end
        if self:getFengKeCount() > 0 then
            return 0
        end
        if #self.player.pileList > 0 then
            for k, pile in pairs(self.player.pileList) do
                if pile.operType == MJConst.kOperMG or
                    pile.operType == MJConst.kOperAG or
                    pile.operType == MJConst.kOperMXG then
                    return 0
                end
            end
            return 1
        else
            return 3
        end
    else
        if #self.player.pileList > 0 then
            for k, pile in pairs(self.player.pileList) do
                if pile.operType == MJConst.kOperMG or
                    pile.operType == MJConst.kOperPeng or
                    pile.operType == MJConst.kOperMXG then
                    return 0
                end
            end
        end
        return 2
    end
end

-- 七对
function CountHuType:isQiDui()
    if self.player:hasNewCard() == true then
        return self.player:canSelfHuQiDui({self.gameProgress.baiDa})
    else
        return self.player:canHuQiDui(self.huCard,{self.gameProgress.baiDa})
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

-- 对对胡
function CountHuType:isDuiDuiHu()
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
    if self.mjWall:getCanGetCount() <= 3 and 
    self.isZiMo == true then
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
        if v.operType == MJConst.kOperMG or v.operType == MJConst.kOperMXG then
            if v.cardList[1] < MJConst.Zi1 or v.cardList[1] > MJConst.Zi4 then
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
            if v.cardList[1] < MJConst.Zi1 or v.cardList[1] > MJConst.Zi4 then
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