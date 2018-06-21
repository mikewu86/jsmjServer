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
    self.daDiaoche = false
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
    self.daDiaoche = false
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

    huDetails.pos = self.pos
    huDetails.describe = ''
    local gangKai = 0

    local daHuList = nil
    -- 填充当前的胡牌类型
    local innerFill = function(huType, _huDetails)
        self:fillDetial(_huDetails, huType)
        hua = hua + huTypeMap[huType].fan
        if table.keyof(HuTypeConst.kDaHuTypeList, huType) ~= nil then
            bDaHu = true
        end
    end
      
    --天胡
    if self:isTianHu() == true then
        innerFill(HuTypeConst.kHuType.kTianHu, huDetails)
    --地胡
    elseif self:isDiHu() == true then
        innerFill(HuTypeConst.kHuType.kDiHu, huDetails)
    end

    -- 杠开
    if self:isGangKai() then
        if self.player:hasBaiDa(self.gameProgress.baiDa, true) == 0 then
            -- 无花杠开
            innerFill(HuTypeConst.kHuType.kWuHuaGangKai, huDetails)
        else
            -- 有花杠开
            innerFill(HuTypeConst.kHuType.kYouHuaGangKai, huDetails)
        end
        if self.player:checkChuKe(self.gameProgress.baiDa) then
            -- 出壳杠开
            innerFill(HuTypeConst.kHuType.kChuKeGangKai, huDetails)
        end
    end

    -- 大吊车
    if self:isDaDiaoChe() then
        self.daDiaoche = true
        if self.player:hasBaiDa(self.gameProgress.baiDa, true) ~= 0 then
            innerFill(HuTypeConst.kHuType.kYouHuaDaDiao, huDetails)
        else
            if self.isZiMo == true then
                innerFill(HuTypeConst.kHuType.kWuHuaDaDiao, huDetails)
            else
                --捉冲
                if self.fangPaoPos ~= nil and self.fangPaoPos ~= 0 then
                    innerFill(HuTypeConst.kHuType.kZhuoChong, huDetails)
                end
            end       
        end
    end

    -- 飘杠
    local riverCardsList = self.riverCardList[self.pos]:getRiverCardsList()
    if #riverCardsList > 1 then
        if riverCardsList[#riverCardsList] == self.gameProgress.baiDa and self:isGangKai() then
            -- huDetails.describe = huDetails..describe..'飘杠;'
            -- hua = hua * 4
            innerFill(HuTypeConst.kHuType.kPiaoGang, huDetails)
        end
    end

    -- 飘花次数
    -- local piaoNums = self.gameProgress:getPiaoHuaStatus(self.pos)
    -- local multi = math.pow(2, piaoNums)
    -- huDetails.describe = huDetails.describe..'飘花X'..multi..';'
    -- hua = hua * multi

    -- 有花出壳(飘花)
    if self.player:hasBaiDa(self.gameProgress.baiDa) == 1 and self.player:checkChuKe(self.gameProgress.baiDa) then
        local riverCardsList = self.riverCardList[self.pos]:getRiverCardsList()
        -- 如果所出的最后一张牌是搭牌,就是飘花
        -- dump(riverCardsList[#riverCardsList], "riverCardsList[#riverCardsList]")
        -- dump(self.gameProgress.baiDa, "self.gameProgress.baiDa")
        if riverCardsList[#riverCardsList] == self.gameProgress.baiDa then
            innerFill(HuTypeConst.kHuType.kPiaoHua, huDetails)
        end
    -- 三花飘花
    elseif self.player:hasBaiDa(self.gameProgress.baiDa) == 2 and self.player:checkChuKe(self.gameProgress.baiDa) then
        local riverCardsList = self.riverCardList[self.pos]:getRiverCardsList()
        if riverCardsList[#riverCardsList] == self.gameProgress.baiDa then
            innerFill(HuTypeConst.kHuType.kSanHuaPiaoHua, huDetails)
        end
    -- 四花飘花
    elseif self.player:hasBaiDa(self.gameProgress.baiDa) == 3 and self.player:checkChuKe(self.gameProgress.baiDa) then
        local riverCardsList = self.riverCardList[self.pos]:getRiverCardsList()
        if riverCardsList[#riverCardsList] == self.gameProgress.baiDa then
            innerFill(HuTypeConst.kHuType.kSiHuaPiaoHua, huDetails)
        end
    end

    -- 杠飘计算
    if self.gameProgress.gangPiao[self.pos] > 0 then
        local times = math.pow(2, self.gameProgress.gangPiao[self.pos])
        huDetails.describe = huDetails.describe..'杠飘 '..5 * times..';'
        hua = hua + 5 * times
        table.insert(self.huTypeList, HuTypeConst.kHuType.kGangPiao)
    end

    --出壳
    if self.player:checkChuKe(self.gameProgress.baiDa) then
        if hua <= 0 then
            innerFill(HuTypeConst.kHuType.kChuKe, huDetails)
        end
    end
    -- 自摸
    if self.isZiMo == true then
        if hua <= 0 then
            innerFill(HuTypeConst.kHuType.kHu, huDetails)
        end
    end

    --天胡地胡不翻倍
    if self:isTianHu() == false and self:isDiHu() == false then
        -- 三花直接胡
        if self.player:hasBaiDa(self.gameProgress.baiDa) == 3 then
            huDetails.describe = huDetails.describe..'三花X2;'
            hua = hua * 2
            table.insert(self.huTypeList, HuTypeConst.kHuType.kSanHua)
        end

        -- 四花直接胡
        if self.player:hasBaiDa(self.gameProgress.baiDa) == 4 then
            huDetails.describe = huDetails.describe..'四花X4;'
            hua = hua * 4
            table.insert(self.huTypeList, HuTypeConst.kHuType.kSiHua)
        end
    end

    -- 骰子同点,上一局流局
    if self.gameProgress.m_bBaoZi then
        huDetails.describe = huDetails.describe..'豹子X2;'
        hua = hua * 2
    end
    if self.gameProgress.hengFan then
        huDetails.describe = huDetails.describe..'横翻X2;'
        hua = hua * 2
    end

    --self:baoPao()

    -- 抢杠送杠*3
    -- if self.isQiangGang then
    --     huDetails.describe = huDetails.describe..'抢杠X3;'
    -- end

    self.huDetails = huDetails
    self.fan = hua
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

    -- 抢杠翻3倍，一家付
    if self.isQiangGang then
        fan = math.ceil(fan * 3)
    end
    -- if self.gameProgress.roomRuleMap['sz_playrule_haoqi'] then
    --     if self:isQiDui() then
    --         local qiDuiType = self:getQiDuiType()
    --         if qiDuiType ~= 0 then
    --             fan = math.ceil(fan * 2)
    --         end
    --     end
    -- end

    -- if self.gameProgress.roomRuleMap['ks_playrule_baozi'] then
    --     if self.gameProgress.m_bNextDiZero or self.gameProgress.m_bBaoZi then
    --         fan = math.ceil(fan * 2) -- 豹子滴零翻倍
    --     end
    -- end

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
dump(self.player.cardList, "cardList")
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