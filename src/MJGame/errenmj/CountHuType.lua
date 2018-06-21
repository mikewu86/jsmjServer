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
    self.isAutoHu = false
    self.isZiMo = isZiMo

    self.validHuCard = huCard
    if self.validHuCard == nil then
        self.validHuCard = self.player:getNewCard()
    end

    self.handCountMap = self.player:transHandCardsToCountMap(false)
    self.fullCountMap = self.player:transHandCardsToCountMap(false)
    self.fullCountMap[self.validHuCard] = self.fullCountMap[self.validHuCard] + 1
end

-- 填充胡牌详细结构， 
-- 参数 huDetails 要被填充的表
-- huTypeName 牌型名称 huaCount 花数
function CountHuType:fillDetial(huDetails, huType)
    local cfg = HuTypeConst.huTypeMap[huType]
    if cfg then
        huDetails.describe = huDetails.describe..cfg.name..' '..cfg.descrip..';'
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
        -- LOG_DEBUG('-- no pos or no player --')
        -- dump(self.pos)
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
        -- LOG_DEBUG('huType = '..huType)
        self:fillDetial(_huDetails, huType)
        hua = hua + huTypeMap[huType].fan
        if table.keyof(HuTypeConst.kDaHuTypeList, huType) ~= nil then
            bDaHu = true
        end
    end
    
    -- 八仙过海
    if self:isBaXian() then
        innerFill(HuTypeConst.kHuType.kBaXian, huDetails)
    end
    -- 绿一色
    if self:isLvYiSe() then
        innerFill(HuTypeConst.kHuType.kLvYiSe, huDetails)
    end

    -- 九莲宝灯
    if self:isBaoDeng() then
        innerFill(HuTypeConst.kHuType.kBaoDeng, huDetails)
    end

    -- 大小四喜，三风刻
    local fengKeCount = self:getFengKeCount()
    if fengKeCount == 4 then
        innerFill(HuTypeConst.kHuType.kDaSiXi, huDetails)
    elseif fengKeCount == 3 then
        if self:getFengDuiCount() == 1 then
            innerFill(HuTypeConst.kHuType.kXiaoSiXi, huDetails)
        else
            innerFill(HuTypeConst.kHuType.kSanFengKe, huDetails)
        end
    end

    -- 大小三元,2箭刻,箭刻
    local jianKeCount = self:getJianKeCount()
    if jianKeCount == 3 then
        innerFill(HuTypeConst.kHuType.kDaSanYuan, huDetails)
    elseif jianKeCount == 2 then
        if self:getJianDuiCount() == 1 then
            innerFill(HuTypeConst.kHuType.kXiaoSanYuan, huDetails)
        else
            innerFill(HuTypeConst.kHuType.kErJianKe, huDetails)
        end
    elseif jianKeCount == 1 then
        innerFill(HuTypeConst.kHuType.kJianKe, huDetails)
    end

    -- 七对,连七对
    if self:isQiDui() then
        if self:isLianQiDui() then
            innerFill(HuTypeConst.kHuType.kLianQiDui, huDetails)
        else
            innerFill(HuTypeConst.kHuType.kQiDui, huDetails)
        end
    else
        -- 不求人
        if self:isBuQiuRen() then
            innerFill(HuTypeConst.kHuType.kBuQiu, huDetails)
        end
    end
    -- 清一色，混一色,字一色
    local yiSeType = self:getYiSeType()
    if yiSeType == 2 then
        innerFill(HuTypeConst.kHuType.kQingYiSe, huDetails)
    elseif yiSeType == 3 then
        innerFill(HuTypeConst.kHuType.kHunYiSe, huDetails)
    elseif yiSeType == 1 then
        innerFill(HuTypeConst.kHuType.kZiYiSe, huDetails)
    end

    -- 一色4同 一色3同 一般高
    local shunCount = self:getTongCount()
    if shunCount == 4 then
        innerFill(HuTypeConst.kHuType.kSiTong, huDetails)
    elseif shunCount == 3 then
        innerFill(HuTypeConst.kHuType.kSanTong, huDetails)
    elseif shunCount == 2 then
        innerFill(HuTypeConst.kHuType.kYiBanGao, huDetails)
    end

    -- 一色双龙
    if self:isShuangLong() then
        innerFill(HuTypeConst.kHuType.kShuangLong, huDetails)
    end

    -- 双暗刻、三暗刻、四暗刻
    local anKeCount = self:getAnKeCount()
    if anKeCount == 4 then
        innerFill(HuTypeConst.kHuType.kSiAnKe, huDetails)
    elseif anKeCount == 3 then
        innerFill(HuTypeConst.kHuType.kSanAnKe, huDetails)
    elseif anKeCount == 2 then 
        innerFill(HuTypeConst.kHuType.kErAnKe, huDetails)
    end

    -- 天胡，地胡,海底
    if self:isTianHu() then
        innerFill(HuTypeConst.kHuType.kTianHu, huDetails)
    elseif self:isDiHu() then
        innerFill(HuTypeConst.kHuType.kDiHu, huDetails)
    elseif self:isRenHu() then
        innerFill(HuTypeConst.kHuType.kRenHu, huDetails)
    end

    -- 一色四步高, 一色三步
    if self:isSiBuGao() then
        innerFill(HuTypeConst.kHuType.kSiBu, huDetails)
    elseif self:isSanBuGao() then
        innerFill(HuTypeConst.kHuType.kSanBu, huDetails)
    end

    -- 三杠
    local gangCount = self:getGangCount()
    local mgCount = self:getMGangCount()
    if gangCount == 3 then
        innerFill(HuTypeConst.kHuType.kSanGang, huDetails)
    elseif mgCount == 2 then
        innerFill(HuTypeConst.kHuType.kErMingGang, huDetails)
    end

    if self:isQingLong() then
        innerFill(HuTypeConst.kHuType.kQingLong, huDetails)
    end
    
    -- 对对胡
    if self:isDuiDuiHu() then
        innerFill(HuTypeConst.kHuType.kDuiDuiHu, huDetails)
    end
    -- 绝张
    if self:isYaJue() then
        innerFill(HuTypeConst.kHuType.kJue, huDetails)
    end
    -- 杠开
    if self:isGangKai() then
        innerFill(HuTypeConst.kHuType.kGangKai, huDetails)
    end
    -- 全求人
    if self:isDaDiaoChe() then
        innerFill(HuTypeConst.kHuType.kQuan, huDetails)
    end
    
    -- 全带幺
    if self:isQuanYao() then
        innerFill(HuTypeConst.kHuType.kQuanYao, huDetails)
    end
    
    -- 硬花数
    if #self.player.huaList > 0 then
        huDetails.describe = huDetails.describe..'硬花 '..#self.player.huaList..'番;'
        hua = hua + #self.player.huaList
    end

    -- 直立
    if self:isZhiLi() then
        innerFill(HuTypeConst.kHuType.kZhiLi, huDetails)
    end

    -- 幺九刻
    if self:isYaoJiuKe() then
        innerFill(HuTypeConst.kHuType.kYaoJiu, huDetails)
    end

    -- 老少
    if self:isLaoShao() then
        innerFill(HuTypeConst.kHuType.kLaoShao, huDetails)
    end

    -- 
    if self:isLiuLian() then
    end

    -- 断幺九
    if self:isDuan() then
        innerFill(HuTypeConst.kHuType.kDuan, huDetails)
    end

    -- 嵌单、当钓、镶边
    if self:isBian() then
        innerFill(HuTypeConst.kHuType.kBian, huDetails)
    elseif self:isKa() then  -- 有压绝时不再重复计算卡张
        innerFill(HuTypeConst.kHuType.kKa, huDetails)
    elseif self:isDiao() then
        innerFill(HuTypeConst.kHuType.kDiao, huDetails)
        -- 258将
        local ErWuBa = {
            MJConst.Wan2, MJConst.Wan5, MJConst.Wan8,
            MJConst.Tong2, MJConst.Tong5, MJConst.Tong8,
            MJConst.Tiao2, MJConst.Tiao5, MJConst.Tiao8,
        }
        if table.keyof(ErWuBa, self.validHuCard) ~= nil then
            innerFill(HuTypeConst.kHuType.kErWuBa, huDetails)
        end
    end

    if self.isZiMo then
        innerFill(HuTypeConst.kHuType.kZiMo, huDetails)
    end

    if self.isAutoHu then
        -- LOG_DEBUG(' -- auto Hu --')
    end

    self.huDetails = huDetails
    self.fan = hua
    return huDetails
end

-- 获取所有的花数，包括自摸的
function CountHuType:getTotalFan()
    -- 自摸花数*3
    local fan = self.fan
    if nil == fan then
        -- LOG_DEBUG("before getTotalFan ,do calculate")
        fan = 0
    end
    -- 自摸 番3倍
    if self.isZiMo == true then
    end
    return fan
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

    -- 必须是自摸
    if self.player:hasNewCard() == false then
        return false
    end

    return true
end

-- 人胡
function CountHuType:isRenHu()
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

-- 门清
function CountHuType:isBuQiuRen()
    if self.isZiMo == false then
        return false
    end
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

-- 连七对
function CountHuType:isLianQiDui()
    local huCard = self.huCard
    if huCard == nil then
        huCard = self.player:getNewCard()
    end
    if huCard == nil then
        return 0
    end
    local countMap = self.fullCountMap
    local start = nil   -- 开始位置

    for k, v in pairs(countMap) do
        if v > 0 then
            if start == nil then
                start = k
            else
                start = start + 1
                if start ~= k then   -- 没连上
                    return false
                end
            end
        end
    end
    return true
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
    local countMap = self.fullCountMap

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

-- 杠开
function CountHuType:isGangKai()
    local len = #self.player.opHistoryList
    if len > 1 then
        local justDoOper = self.player.opHistoryList[len - 1]
        if justDoOper == MJConst.kOperMG or
        justDoOper == MJConst.kOperAG or
        justDoOper == MJConst.kOperMXG then
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

-- 无花果
function CountHuType:isWuHuaGuo()
    if #self.player.huaList > 0 then
        return false
    end
    return true
end

-- 海底捞月 只能自摸
function CountHuType:isHaiDi()
    if self.mjWall:getCanGetCount() <= 16 and 
    self.fangPaoPos == nil then
        return true
    end
    return false
end

-- 压绝
function CountHuType:isYaJue()
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

    if showCount >= 3 then
        return true
    end
    return false
end

-- 是不是调将
function CountHuType:isDiao()
    local huCard = self.huCard
    -- LOG_DEBUG('-- isDiao --')
    if huCard == nil then
        huCard = self.player:getNewCard()
    end
    if huCard == nil then
        -- LOG_DEBUG('-- isDiao 2 --')
        return false
    end

    local canHuCards = self.player:getCanHuCardList()
    if #canHuCards ~= 1 then  -- 只能胡一张牌,一定是卡边吊
        -- LOG_DEBUG('-- isDiao 5 --')
        -- dump(canHuCards)
        return false
    end
    -- 取巧，只能胡一张的一定是边卡吊，如果不是边卡，一定是吊
    if not self:isBian() and not self:isKa() then
        return true
    end
    return false
end

-- 边枝 只能是1 7的非字牌
function CountHuType:isBian()
    -- LOG_DEBUG('-- isBian 1 --')
    local huCard = self.huCard
    if huCard == nil then
        huCard = self.player:getNewCard()
    end
    if huCard == nil then
        -- LOG_DEBUG('-- isBian 2 --')
        return false
    end
    local card = MJCard.new({byte = huCard})
    if card.suit == MJConst.kMJSuitZi then
        -- LOG_DEBUG('-- isBian 3 --')
        return false
    end
    if card.point ~= MJConst.kMJPoint3 and
        card.point ~= MJConst.kMJPoint7 then
            -- LOG_DEBUG('-- isBian 4 --'..huCard)
            -- dump(card)
            return false
    end
    local canHuCards = self.player:getCanHuCardList()
    if #canHuCards ~= 1 then  -- 只能胡一张牌,一定是卡边吊
        -- LOG_DEBUG('-- isBian 5 --')
        -- dump(canHuCards)
        return false
    end
    local countMap = self.player:transHandCardsToCountMap(false)

    if card.point == MJConst.kMJPoint7 then
        countMap[huCard + 1] = countMap[huCard + 1] - 1
        countMap[huCard + 2] = countMap[huCard + 2] - 1
        if countMap[huCard + 1] < 0 or
            countMap[huCard + 2] < 0 then
            -- LOG_DEBUG('-- isBian 6 --')
            return false
        end
    elseif card.point == MJConst.kMJPoint3 then
        countMap[huCard - 1] = countMap[huCard - 1] - 1
        countMap[huCard - 2] = countMap[huCard - 2] - 1
        if countMap[huCard - 1] < 0 or
            countMap[huCard - 2] < 0 then
            -- LOG_DEBUG('-- isBian 7 --')
            return false
        end
    else
        return false
    end
    -- LOG_DEBUG('-- isBian 8 --')
    return self.player.mjMath:canHu(countMap)
end

-- 卡档 只能是2-8的非字牌
function CountHuType:isKa()
    -- LOG_DEBUG('-- isKa 1 --')
    local huCard = self.huCard
    if huCard == nil then
        huCard = self.player:getNewCard()
    end
    if huCard == nil then
        -- LOG_DEBUG('-- isKa 2 --')
        return false
    end
    local card = MJCard.new({byte = huCard})
    if card.suit == MJConst.kMJSuitZi then
        -- LOG_DEBUG('-- isKa 3 --')
        return false
    end
    if card.point == MJConst.kMJPoint1 or
        card.point == MJConst.kMJPoint9 then
            -- LOG_DEBUG('-- isKa 4 --'..huCard)
            -- dump(card)
            return false
    end

    local canHuCards = self.player:getCanHuCardList()
    if #canHuCards ~= 1 then  -- 只能胡一张牌,一定是卡边吊
        -- LOG_DEBUG('-- isKa 5 --'..huCard)
        -- dump(canHuCards)
        return false
    end
    local countMap = self.player:transHandCardsToCountMap(false)

    countMap[huCard + 1] = countMap[huCard + 1] - 1
    countMap[huCard - 1] = countMap[huCard - 1] - 1
    if countMap[huCard + 1] < 0 or
        countMap[huCard - 1] < 0 then
        -- LOG_DEBUG('-- isKa 6 --'..huCard)
        return false
    end
    -- LOG_DEBUG('-- isKa 7 --')
    -- dump(countMap)
    return self.player.mjMath:canHu(countMap)
end

-- 杠数量
function CountHuType:getGangCount()
    local sum = 0
    local pileList = self.player.pileList
    for k, v in pairs(pileList) do
        if v.operType == MJConst.kOperMG or
           v.operType == MJConst.kOperMXG or 
           v.operType == MJConst.kOperAG then
            sum = sum + 1
        end
    end
    return sum
end

-- 明杠数量
function CountHuType:getMGangCount()
    local sum = 0
    local pileList = self.player.pileList
    for k, v in pairs(pileList) do
        if v.operType == MJConst.kOperMG or
           v.operType == MJConst.kOperMXG then
            sum = sum + 1
        end
    end
    return sum
end

-- 八仙过海
function CountHuType:isBaXian()
    local len = #self.player:getHuaList()
    return len == 8
end

-- 绿一色
function CountHuType:isLvYiSe()
    local validCards = {
        MJConst.Tiao2,
        MJConst.Tiao3,
        MJConst.Tiao6,
        MJConst.Tiao8,
        MJConst.Zi6,
    }
    for k, card in pairs(self.player.cardList) do
        if table.keyof(validCards, card) == nil then
            return false
        end
    end
    for k, pile in pairs(self.player.pileList) do
        for _, card in pairs(pile.cardList) do
            if table.keyof(validCards, card) == nil then
                return false
            end
        end
    end
    return true
end

-- 九莲宝灯
function CountHuType:isBaoDeng()
    if #self.player.pileList > 0 then
        return false
    end
    
    local validCount = {3, 1, 1, 1, 1, 1, 1, 1, 3}
    local countMap = self.handCountMap
    
    local index = 1
    for i = MJConst.Tiao1, MJConst.Tiao9 do
        if countMap[i] ~= validCount[index] then
            return false
        end
        index = index + 1
    end
    return true
end

-- 风对数量
function CountHuType:getFengDuiCount()
    local validCards = {MJConst.Zi1, MJConst.Zi2, MJConst.Zi3, MJConst.Zi4}
    local sum = 0
    for k, v in pairs(validCards) do
        if self.fullCountMap[v] == 2 then
            sum = sum + 1
        end
    end
    return sum
end

-- 风刻数量
function CountHuType:getFengKeCount()
    local validCards = {MJConst.Zi1, MJConst.Zi2, MJConst.Zi3, MJConst.Zi4}
    local sum = 0
    for _, pile in pairs(self.player.pileList) do
        if table.keyof(validCards, pile.cardList[1]) ~= nil then
            sum = sum + 1
        end
    end

    for k, v in pairs(validCards) do
        if self.fullCountMap[v] >= 3 then
            sum = sum + 1
        end
    end
    return sum
end

-- 箭刻数量
function CountHuType:getJianKeCount()
    local validCards = {MJConst.Zi5, MJConst.Zi6, MJConst.Zi7}
    local sum = 0
    for _, pile in pairs(self.player.pileList) do
        if table.keyof(validCards, pile.cardList[1]) ~= nil then
            sum = sum + 1
        end
    end

    for k, v in pairs(validCards) do
        if self.fullCountMap[v] >= 3 then
            sum = sum + 1
        end
    end
    return sum
end

-- 箭对数量
function CountHuType:getJianDuiCount()
    local validCards = {MJConst.Zi4, MJConst.Zi5, MJConst.Zi6}
    local sum = 0
    for k, v in pairs(validCards) do
        if self.fullCountMap[v] == 2 then
            sum = sum + 1
        end
    end
    return sum
end

-- 一色双龙
function CountHuType:isShuangLong()
    local validCount = {2, 2, 2, 0, 2, 0, 2, 2, 2}
    for i = MJConst.Tiao1, MJConst.Tiao9 do
        if self.fullCountMap[i] ~= validCount[i] then
            return false
        end
    end
    return true
end

-- 一色N同顺的计数 由于2人麻将只有条子，所在这里只判断条子
function CountHuType:getTongCount()
    local sum = 0
    local map = table.clone(self.fullCountMap)
    -- 把吃的牌加上去
    local chiType = {MJConst.kOperLChi,
        MJConst.kOperMChi, MJConst.kOperRChi}
    for _, pile in pairs(self.player.pileList) do
        if table.keyof(chiType, pile.oper) ~= nil then
            for k1, card in pairs(pile.cardList) do
                map[card] = map[card] + 1
            end
        end
    end

    for i = MJConst.Tiao1, MJConst.Tiao7 do
        if map[i] > 1 and map[i + 1] > 1 and map[i + 2] > 1 then
            local tb = {map[i], map[i + 1], map[i + 2]}
            table.sort(tb)
            sum = tb[1]
            break
        end
    end
    return sum
end

-- 一色四步高
function CountHuType:isSiBuGao()
    local sum = 0
    local map = table.clone(self.fullCountMap)
    -- 把吃的牌加上去
    local chiType = {MJConst.kOperLChi,
        MJConst.kOperMChi, MJConst.kOperRChi}
    for _, pile in pairs(self.player.pileList) do
        if table.keyof(chiType, pile.oper) ~= nil then
            for k1, card in pairs(pile.cardList) do
                map[card] = map[card] + 1
            end
        end
    end
    local validCount = {1, 2, 3, 3, 2, 1}
    for i = MJConst.Tiao1, MJConst.Tiao4 do
        for j = 1, #validCount do
            if map[i + j - 1] >= validCount[j] then
                if j == #validCount then
                    return true
                end
            else
                break
            end
        end
    end
    return false
end

-- 一色3步高
function CountHuType:isSanBuGao()
    local sum = 0
    local map = table.clone(self.fullCountMap)
    -- 把吃的牌加上去
    local chiType = {MJConst.kOperLChi,
        MJConst.kOperMChi, MJConst.kOperRChi}
    for _, pile in pairs(self.player.pileList) do
        if table.keyof(chiType, pile.oper) ~= nil then
            for k1, card in pairs(pile.cardList) do
                map[card] = map[card] + 1
            end
        end
    end
    local validCount = {1, 2, 3, 2, 1}
    for i = MJConst.Tiao1, MJConst.Tiao5 do
        for j = 1, #validCount do
            if map[i + j - 1] >= validCount[j] then
                if j == #validCount then
                    return true
                end
            else
                break
            end
        end
    end
    return false
end

-- 青龙
function CountHuType:isQingLong()
    local sum = 0
    local map = table.clone(self.fullCountMap)
    -- 把吃的牌加上去
    local chiType = {MJConst.kOperLChi,
        MJConst.kOperMChi, MJConst.kOperRChi}
    for _, pile in pairs(self.player.pileList) do
        if table.keyof(chiType, pile.oper) ~= nil then
            for k1, card in pairs(pile.cardList) do
                map[card] = map[card] + 1
            end
        end
    end

    for i = MJConst.Tiao1, MJConst.Tiao9 do
        if map[i] >= 1 then
        else
            return false
        end
    end
    return true
end

-- 暗刻次数
function CountHuType:getAnKeCount()
    local sum = 0
    for _, pile in pairs(self.player.pileList) do
        if pile.oper == MJConst.kOperAG then
            sum = sum + 1
        end
    end

    for _, count in pairs(self.fullCountMap) do
        if count >= 3 then
            sum = sum + 1
        end
    end
    return sum
end

-- 断幺九
function CountHuType:isDuan()
    local invalidCards = {
        MJConst.Tiao1, MJConst.Tiao9, MJConst.Zi1,
        MJConst.Zi2, MJConst.Zi3, MJConst.Zi4, MJConst.Zi5,
        MJConst.Zi6, MJConst.Zi7,
    }
    for _, pile in pairs(self.player.pileList) do
        for k, card in pairs(pile.cardList) do
            if table.keyof(invalidCards, card) ~= nil then
                return false
            end
        end
    end

    for card, count in pairs(self.fullCountMap) do
        if table.keyof(invalidCards, card) ~= nil then
            return false
        end
    end
    return true
end

-- 全带幺
function CountHuType:isQuanYao()
    local invalidCards = {
        MJConst.Tiao2, MJConst.Tiao3, MJConst.Tiao4,
        MJConst.Tiao5, MJConst.Tiao6, MJConst.Tiao7,
        MJConst.Tiao8
    }
    local validCards = {
        MJConst.Tiao1, MJConst.Tiao2, MJConst.Tiao3, 
        MJConst.Tiao7, MJConst.Tiao8, MJConst.Tiao9
    }
    local chiType = {
        MJConst.kOperLChi,
        MJConst.kOperMChi, 
        MJConst.kOperRChi
        }

    -- 吃牌中只允许有123, 789,碰杠牌不允许出来2345678
    for _, pile in pairs(self.player.pileList) do
        for k, card in pairs(pile.cardList) do
            if table.keyof(chiType, pile.oper) ~= nil then
                if table.keyof(invalidCards, card) ~= nil then
                    return false
                end
            else
                if table.keyof(validCards, card) ~= nil then
                    return false
                end
            end
        end
    end

    local map = {}
    for i = MJConst.Tiao1, MJConst.Tiao9 do
        map[i] = self.fullCountMap[i]
        if self.fullCountMap[i] > 0 then
            if i >= MJConst.Tiao4 and i <= MJConst.Tiao6 then
                return false
            end
        end
    end
    
    -- 判断有没有不用的2378
    if map[MJConst.Tiao2] > map[MJConst.Tiao1] or
        map[MJConst.Tiao3] > map[MJConst.Tiao1] or
        map[MJConst.Tiao8] > map[MJConst.Tiao9] or
        map[MJConst.Tiao7] > map[MJConst.Tiao9] then
        return false
    end
    return true
end

-- 直立
function CountHuType:isZhiLi()
    if #self.player.pileList == 0 and self.player.isTing then
        return true
    end
    return false
end

-- 幺九刻
function CountHuType:isYaoJiuKe()
    local validCards = {
            MJConst.Tiao1, MJConst.Tiao9, MJConst.Zi1,
            MJConst.Zi2, MJConst.Zi3, MJConst.Zi4,
            MJConst.Zi5, MJConst.Zi6, MJConst.Zi7
        }
    for _, card in pairs(validCards) do
        if self.fullCountMap[card] >=3 then
            return true
        end
    end
    return false
end

-- 老少
function CountHuType:isLaoShao()
    local validCards = {
            MJConst.Tiao1, MJConst.Tiao2, MJConst.Tiao3, 
            MJConst.Tiao7, MJConst.Tiao8, MJConst.Tiao9
        }
    local map = table.clone(self.fullCountMap)
    -- 把吃的牌加上去
    local chiType = {MJConst.kOperLChi,
        MJConst.kOperMChi, MJConst.kOperRChi}
    for _, pile in pairs(self.player.pileList) do
        if table.keyof(chiType, pile.oper) ~= nil then
            for k1, card in pairs(pile.cardList) do
                map[card] = map[card] + 1
            end
        end
    end
    for _, card in pairs(validCards) do
        if map[card] <= 0 then
            return false
        end
    end
    return true
end

-- 连六
function CountHuType:isLiuLian()
    local validCount = {
           1, 1, 1, 1, 1, 1,
        }
    local map = table.clone(self.fullCountMap)
    -- 把吃的牌加上去
    local chiType = {MJConst.kOperLChi,
        MJConst.kOperMChi, MJConst.kOperRChi}
    for _, pile in pairs(self.player.pileList) do
        if table.keyof(chiType, pile.oper) ~= nil then
            for k1, card in pairs(pile.cardList) do
                map[card] = map[card] + 1
            end
        end
    end
    for i = MJConst.Tiao1, MJConst.Tiao4 do
        for j = 1, #validCount do
            if map[i + j - 1] >= validCount[j] then
                if j == #validCount then
                    return true
                end
            else
                break
            end
        end
    end
    return false
end

return CountHuType