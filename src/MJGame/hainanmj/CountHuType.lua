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

-- 有没有可以胡的牌型
function CountHuType:hasCanHuType()
    for k, huType in pairs(HuTypeConst.kCanHuTypeList) do
        if self:hasHuType(huType) then
            return true
        end
    end
    return false
end

function CountHuType:ctor()
    self.baoPaiPos = nil
end

function CountHuType:reset()
    self.huTypeList = {}
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
    self.jiang = nil
    if self.player:canSelfHu() or self.player:canHu(self.huCard) then
        self.jiang = self.player.mjMath.jiang
    end
end

-- 填充胡牌详细结构， 
-- 参数 huDetails 要被填充的表
-- huTypeName 牌型名称 huaCount 花数
function CountHuType:fillDetial(huDetails, huType)
    table.insert(self.huTypeList, huType)  --胡牌类型先加入列表，海南麻将里有隐藏的类型，不显示
    local cfg = HuTypeConst.huTypeMap[huType]
    if cfg then
        huDetails.describe = huDetails.describe..cfg.name..' '..cfg.descrip..';'
    end
end

-- 计算详细胡牌类型
function CountHuType:calculate()
    self.baoPaiPos = nil
    local huDetails = {}  -- 胡牌详细信息
    self.huTypeList = {}  -- 所有胡牌类型的列表
    if self.pos == nil or self.player == nil then
        LOG_DEBUG('-- no pos or no player --')
        return huDetails
    end
    local huTypeMap = HuTypeConst.huTypeMap  -- 胡牌对照表 
    local hua = 1
    huDetails.pos = self.pos
    huDetails.describe = ''
    local isGangkai = 0

    local daHuList = nil
    -- 填充当前的胡牌类型
    local innerFill = function(huType, _huDetails)
        self:fillDetial(_huDetails, huType)
        if huTypeMap[huType] then
            hua = hua * huTypeMap[huType].fan
        end
    end
    
    -- 胡牌
    innerFill(HuTypeConst.kHuType.kHu, huDetails)
    -- 七对,豪华七对，超豪华，超超豪华
    if self:isQiDui() then
        local qiDuiType = self:getQiDuiType()
        if qiDuiType == 0 then
            innerFill(HuTypeConst.kHuType.kQiDui, huDetails)
        else
            innerFill(HuTypeConst.kHuType.kHQiDui, huDetails)
        end
    end
    -- 天胡，地胡,海底
    if self:isTianHu() then
        if self.pos == self.gameProgress.banker then
            innerFill(HuTypeConst.kHuType.kTianHu, huDetails)
        else
            innerFill(HuTypeConst.kHuType.kDiHu, huDetails)
        end
    elseif self:isHaiDi() then
        innerFill(HuTypeConst.kHuType.kHaiDi, huDetails)
    end
    -- 门清
    if self:isMengQing() then
        innerFill(HuTypeConst.kHuType.kMengQing, huDetails)
    end
    -- 13幺
    if self:is13Yao() then
        innerFill(HuTypeConst.kHuType.k13Yao, huDetails)
    end
    -- 清一色，混一色
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
    -- 大小杠开
    if self:isGangKai() then
        isGangkai = 1
        innerFill(HuTypeConst.kHuType.kGangKai, huDetails)
    elseif self:isXiaoGangKai() then
        isGangkai = 2
        innerFill(HuTypeConst.kHuType.kXGangKai, huDetails)
    end
    -- 自己风位
    if self:isMyFengKe() then
        innerFill(HuTypeConst.kHuType.kMyFengKe, huDetails)
    end
    -- 箭牌
    if self:isJiaKe() then
        innerFill(HuTypeConst.kHuType.kJianKe, huDetails)
    end
    -- 花对位
    if self:isHuaDuiWei() then
        innerFill(HuTypeConst.kHuType.kDuiWei, huDetails)
    end
    --有眼
    if self:is258Jiang() then
        innerFill(HuTypeConst.kHuType.kDuiWei, huDetails)
    end
    -- 全顺
    if self:isAllShun() then
        innerFill(HuTypeConst.kHuType.kQuanShun, huDetails)
    end
    -- 有杠
    if self:hasGang() then
        innerFill(HuTypeConst.kHuType.kHasGang, huDetails)
    end

    -- 计算包牌
    if self.isZiMo then
        huDetails.describe = huDetails.describe..'自摸;'       
    end

    self.huDetails = huDetails
    self.fan = hua
    return huDetails,isGangkai
end

-- 获取所有的花数，包括自摸的
function CountHuType:getTotalFan()
    -- 自摸花数
    local fan = self.fan
    if nil == fan then
        LOG_DEBUG("before getTotalFan ,do calculate")
        fan = 1
    end
    -- 自摸 没有杠开的时候番倍，有杠开的时候不番倍
    if self.isZiMo == true then
        local isGangKai = false
        local huTypeList = {HuTypeConst.kHuType.kXGangKai, HuTypeConst.kHuType.kGangKai}
        for k, v in pairs(huTypeList) do
            if self:hasHuType(v) then
                isGangKai = true
                break
            end
        end
        if isGangKai == false then
            fan = fan * 2
        end
    end
    return fan
end

-- 天胡
function CountHuType:isTianHu()
    -- 必须是自摸
    if self.player:hasNewCard() == false then
        return false
    end
    local playedCount = 0
    local river = self.riverCardList[self.pos]
    if river:getCount() > 0 then
        return false
    end

    if #self.player.pileList > 0 then
        return false
    end
    return true
end

-- 门清
function CountHuType:isMengQing()
    if #self.player.pileList > 0 then
        return false
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
    local huCard = self:getHuCard()
    if huCard == nil then
        return 0
    end
    -- 不能有吃
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
    -- 结构牌不能有吃
    for k, v in pairs(self.player.pileList) do
        if table.keyof(MJConst.chiList, v.operType) ~= nil then
            return false
        end
    end
    -----------------------------------
    local countMap = self.player:transHandCardsToCountMap(true)
    if self.huCard ~= nil then
        countMap[self.huCard] = countMap[self.huCard] + 1
    end
    if countMap[self.jiang] then
        countMap[self.jiang] = countMap[self.jiang] - 2
    end
    for k, v in pairs(countMap) do
        if v % 3 ~= 0 then
            return false
        end
    end
    return true
end

-- 杠开
function CountHuType:isGangKai()
    local len = #self.player.opHistoryList
    if len > 1 then
        local justDoOper = self.player.opHistoryList[len - 1]
        if table.keyof(MJConst.gangList, justDoOper) ~= nil then
            return true
        end
    end
    return false
end

-- 小杠开
function CountHuType:isXiaoGangKai()
    local len = #self.player.opHistoryList
    if len > 1 then
        local justDoOper = self.player.opHistoryList[len - 1]
        if justDoOper == MJConst.kOperBuHua then
            return true
        end
    end
    return false
end

function CountHuType:getHuCard()
    local huCard = self.huCard
    if huCard == nil then
        huCard = self.player:getNewCard()
    end
    return huCard
end
-- 箭刻
function CountHuType:isJiaKe()
    for k, v in pairs(self.player.pileList) do
        if table.keyof(MJConst.pgList, v.operType) ~= nil then
            if table.keyof(MJConst.jianList, v.cardList[1]) then
                return true
            end
        end
    end

    local huCard = self:getHuCard()
    if huCard == nil then
        return false
    end
    -- 手中牌也要算
    for k, v in pairs(MJConst.jianList) do
        local count = self.player:getCardCountInHand(v, false)
        if table.keyof(MJConst.jianList, huCard) then
            count = count + 1
        end
        if count == 3 then
            return true
        end
    end
    return false
end

function CountHuType:getMyFeng()
    local posForFeng = {}
    local turn = self.gameProgress.banker
    for i = 1, self.gameProgress.maxPlayerCount do
        posForFeng[turn] = MJConst.fengList[i]
        turn = self.gameProgress:nextPlayerPos(turn)
    end
    return posForFeng[self.pos]
end

-- 自己位置的风碰,风刻，风暗刻
function CountHuType:isMyFengKe()
    local myFeng = self:getMyFeng()
    for k, v in pairs(self.player.pileList) do
        if table.keyof(MJConst.pgList, v.operType) ~= nil then
            if v.cardList[1] == myFeng then
                return true
            end
        end
    end

    local huCard = self:getHuCard()
    if huCard == nil then
        return false
    end
    -- 手中牌也要算
    local count = self.player:getCardCountInHand(myFeng, false)
    if huCard == myFeng then
        count = count + 1
    end
    return count == 3
end
-- 13幺
function CountHuType:is13Yao()
    if self.player:hasNewCard() == true then
        return self.player:canSelfHu13Yao()
    else
        return self.player:canHu13Yao(self.huCard)
    end
end

-- 花牌对位
function CountHuType:isHuaDuiWei()
    local huaPos = {MJConst.Hua1, MJConst.Hua2, MJConst.Hua3, MJConst.Hua4}
    local huaPos1 = {MJConst.Hua5, MJConst.Hua6, MJConst.Hua8, MJConst.Hua7}
    local posForHua = {}
    local turn = self.gameProgress.banker
    for i = 1, self.gameProgress.maxPlayerCount do
        posForHua[turn] = {huaPos[i], huaPos1[i]}
        turn = self.gameProgress:nextPlayerPos(turn)
    end
    local myHua = posForHua[self.pos]
    for k, v in pairs(myHua) do
        if table.keyof(self.player.huaList, v) ~= nil then
            return true
        end
    end
    return false
end

-- 258将 不适合于七对，13幺
function CountHuType:is258Jiang()
    if self.jiang ~= nil then
        local eye = {MJConst.Wan2, MJConst.Wan5, MJConst.Wan8,
        MJConst.Tiao2, MJConst.Tiao5, MJConst.Tiao8,
        MJConst.Tong2, MJConst.Tong5, MJConst.Tong8,}
        return table.keyof(eye, self.jiang) ~= nil
    end
    return false
end

-- 全顺,不适合于七对，13幺
function CountHuType:isAllShun()
    local huCard = self:getHuCard()
    if huCard == nil then
        return false
    end
    if self.jiang == nil then
        return false
    end
    -- 将不能是中发白或自己的风位
    local list = {MJConst.Zi5, MJConst.Zi6, MJConst.Zi7, self:getMyFeng()}
    if table.keyof(list, self.jiang) ~= nil then
        return false
    end
    -- 结构牌不能有碰杠
    for k, v in pairs(self.player.pileList) do
        if table.keyof(MJConst.pgList, v.operType) ~= nil then
            return false
        end
    end
    ------------------只有一张，特殊处理提升速度------------------------------
    if #self.player.cardList == 1 then
        return true
    end
    -----------------------------------------------------
    local countMap = self.player:transHandCardsToCountMap(false)
    countMap[huCard] = countMap[huCard] + 1
    if countMap[self.jiang] then   -- 去掉将
        countMap[self.jiang] = countMap[self.jiang] - 2
    else
        LOG_DEBUG('----wu jiang all shun ---')
    end
    for i = MJConst.Zi1, MJConst.Zi7 do
        if countMap[i] == 3 then
            return false
        end
    end
    -- 所有都可以分成顺子
    for i = MJConst.Wan1, MJConst.Tong7 do
        while countMap[i] > 0 do
            if i % MJConst.kMJPointNull >= MJConst.kMJPoint8 then
                return false
            end
            if countMap[i + 1] > 0 and countMap[i + 2] > 0 then
                countMap[i] = countMap[i] - 1
                countMap[i + 1] = countMap[i + 1] - 1
                countMap[i + 2] = countMap[i + 2] - 1
            else
                return false
            end
        end
    end
    return true
end

-- 海底捞月 只能自摸
function CountHuType:isHaiDi()
    if self.mjWall:getCanGetCount() == 15 and self.player:hasNewCard() == true then
        return true
    end
    return false
end

function CountHuType:hasGang()
    for k, v in pairs(self.player.pileList) do
        if table.keyof(MJConst.gangList, v.operType) ~= nil then
            return true
        end
    end
    return false
end

return CountHuType