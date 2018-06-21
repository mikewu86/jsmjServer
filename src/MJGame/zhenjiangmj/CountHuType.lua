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
    self.isKuaiZhao = false
end

function CountHuType:setParams(pos, gameProgress, huCard, fangPaoPos, isQiangGang, isZiMo, isTuoDa, isPaoDa)
    self.pos = pos
    self.player = gameProgress.playerList[pos]
    self.playerList = gameProgress.playerList
    self.gameProgress = gameProgress
    self.mjWall = gameProgress.mjWall
    self.riverCardList = gameProgress.riverCardList
    self.huCard = huCard  -- 要胡的牌，为空时说明是自摸
    self.fangPaoPos = fangPaoPos -- 放炮人的位置
    self.isQiangGang = isQiangGang -- 是不是抢杠
    self.isTuoDa = isTuoDa -- 是否脱搭
    self.isPaoDa = isPaoDa -- 是否跑搭
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

-- 包牌情况1 抢杠
function CountHuType:baoPao1(pileList, noAnGangPileList, fromList, anGangCount)
    if self.isQiangGang then
        self.baoPaiPos = self.fangPaoPos   -- 更改放炮玩家为包牌玩家
        self.isBaoPai = true
        return true
    end
    return false
end

function CountHuType:checkKuaiZhao()
    local bRet = false
    local pileList = self.player.pileList 
    if #pileList ~= 4 then
        return bRet
    end
    local fromList = {}
    for i = 1, 3  do
        local v = pileList[i]
        dump(v, "vvvv")
        if v.operType ~= MJConst.kOperAG then
            if nil == table.keyof(fromList, v.from) then
                table.insert(fromList, v.from)
            end
        end
    end
    dump(fromList, "fromList")
    --- 检查前三次是 是否有人可以连续碰3次， 如果有第四次胡牌
    --- 只能暗杠 或者 碰别人
    if #fromList == 1 then
        bRet = true
    end

    return bRet
end

-- 计算包牌 情况的顺序代表包牌判断的优先级
function CountHuType:calulateBaoPai()
    self.isBaoPai = false
    self.baoPaiPos = nil
    -- 南京麻将的包牌都在碰杠出来的牌上做文章
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
    if self:baoPao1(pileList, noAnGangPileList, fromList, anGangCount) then
        return
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
        dump(self.pos)
        return huDetails
    end
    local huTypeMap = HuTypeConst.huTypeMap  -- 胡牌对照表 
    local hua = 0

    local bDaHu = false
    local bMengQing = false

    huDetails.pos = self.pos
    huDetails.describe = ''

    -- if true == self:checkKuaiZhao() then
    --     LOG_DEBUG("kuaizhao is true")
    --     self.isKuaiZhao = true
    --     self.isAutoHu = true
    -- end

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
    -- -- 七对,豪华七对，超豪华，超超豪华
    -- if self:isQiDui() then
    --     local qiDuiType = self:getQiDuiType()
    --     if qiDuiType == 1 then
    --         innerFill(HuTypeConst.kHuType.kHQiDui, huDetails)
    --     elseif qiDuiType == 2 then
    --         innerFill(HuTypeConst.kHuType.kCHQiDui, huDetails)
    --     elseif qiDuiType == 3 then
    --         innerFill(HuTypeConst.kHuType.kCCHQiDui, huDetails)
    --     else
    --         innerFill(HuTypeConst.kHuType.kQiDui, huDetails)
    --     end
    -- else
    --     -- 门清
    --     if self:isMengQing() then
    --         innerFill(HuTypeConst.kHuType.kMengQing, huDetails)
    --     end
    -- end
    -- -- 天胡，地胡,海底
    -- if self:isTianHu() then
    --     innerFill(HuTypeConst.kHuType.kTianHu, huDetails)
    -- elseif self:isDiHu() then
    --     innerFill(HuTypeConst.kHuType.kDiHu, huDetails)
    -- elseif self:isHaiDi() then
    --     innerFill(HuTypeConst.kHuType.kHaiDi, huDetails)
    -- end
    -- -- 清一色，混一色,缺门
    -- local yiSeType = self:getYiSeType()
    -- if yiSeType == 2 then
    --     innerFill(HuTypeConst.kHuType.kQingYiSe, huDetails)
    -- elseif yiSeType == 3 then
    --     innerFill(HuTypeConst.kHuType.kHunYiSe, huDetails)
    -- elseif self:isQueMeng() then
    --     innerFill(HuTypeConst.kHuType.kQueMeng, huDetails)
    -- end
    -- -- 对对胡
    -- if self:isDuiDuiHu() or true == self.isKuaiZhao then
    --     innerFill(HuTypeConst.kHuType.kDuiDuiHu, huDetails)
    -- end
    -- -- 压绝
    -- if self:isYaJue() then
    --     innerFill(HuTypeConst.kHuType.kYaJue, huDetails)
    -- end
    -- 大小杠开
    -- if self:isGangKai() then
    --     innerFill(HuTypeConst.kHuType.kGangKai, huDetails)
    -- elseif self:isXiaoGangKai() then
    --     innerFill(HuTypeConst.kHuType.kXGangKai, huDetails)
    -- end
    -- -- 全球独钓
    -- if self:isDaDiaoChe() then
    --     innerFill(HuTypeConst.kHuType.kDaDiaoChe, huDetails)
    -- end
    -- -- 无花果
    -- if self:isWuHuaGuo() and bDaHu then
    --     innerFill(HuTypeConst.kHuType.kWuHuaGuo, huDetails)
    -- else -- 硬花数
    --     huDetails.describe = huDetails.describe..#self.player.huaList..'硬花 *2 花;'
    --     hua = hua + #self.player.huaList * 2
    -- end
    -- -- 边枝，压档，独占
    -- if self:isBian() then
    --     innerFill(HuTypeConst.kHuType.kBian, huDetails)
    -- elseif self:isKa() then  -- 有压绝时不再重复计算卡张
    --     if self:hasHuType(HuTypeConst.kHuType.kYaJue) == false then
    --         innerFill(HuTypeConst.kHuType.kKa, huDetails)
    --     end
    -- elseif self:isDiao() then
    --     if self:hasHuType(HuTypeConst.kHuType.kDaDiaoChe) == false then
    --         innerFill(HuTypeConst.kHuType.kDuZhan, huDetails)
    --     end
    -- end

    -- -- 风碰
    -- local fengPengCount = self:getFengPengCount()
    -- if fengPengCount > 0 then
    --     huDetails.describe = huDetails.describe..'风碰'..fengPengCount..' *2 花;'
    --     hua = hua + fengPengCount * 2
    -- end

    -- 杠开
    if self:isGangKai() then
        -- 有搭
        if self.player:hasBaiDa(self.gameProgress.baiDa) ~= 0 then
            -- 脱搭
            if self.isTuoDa then
                huDetails.describe = huDetails.describe..'脱搭杠开 8子;'
                hua = hua + 8
            else
                huDetails.describe = huDetails.describe..'杠开 5子;'
                hua = hua + 5
            end
        else
            -- 无搭，明杠杠开
            if self:isMGangKai() then
                huDetails.describe = huDetails.describe..'明杠杠开 8子;'
                hua = hua + 8
            elseif self:isAGangKai() then
                huDetails.describe = huDetails.describe..'暗杠杠开 10子;'
                hua = hua + 10
            end
        end
    end

    -- 跑搭，跑搭脱搭 放炮的情况不算
    if self.isZiMo then
        if self.isPaoDa then
            if self.isTuoDa then
                innerFill(HuTypeConst.kHuType.kPaoDaTuoDa, huDetails)
            else
                innerFill(HuTypeConst.kHuType.kPaoDa, huDetails)
            end
        end
    end

    -- 计算胡牌人的打搭情况
    -- 是否打了首搭
    if self.gameProgress.playDa[self.pos][1] ~= 0 then
        huDetails.describe = huDetails.describe..'首搭 6子;'
        hua = hua + 6
    end
    -- 是否中途打搭
    if self.gameProgress.playDa[self.pos][2] ~= 0 then
        huDetails.describe = huDetails.describe..'打搭 '..self.gameProgress.playDa[self.pos][2]..'X4子;'
        hua = hua + self.gameProgress.playDa[self.pos][2] * 4
    end
    -- 是否碰牌后打搭
    if self.gameProgress.playDa[self.pos][3] ~= 0 then
        huDetails.describe = huDetails.describe..'碰牌打搭 '..self.gameProgress.playDa[self.pos][3]..'X2子;'
        hua = hua + self.gameProgress.playDa[self.pos][3] * 2
    end

    -- 计算包牌
    self:calulateBaoPai()
    if true == self.isBaoPai then
        huDetails.describe = huDetails.describe..'抢杠 1子;'
        hua = hua + 1
    end

    -- 带搭自摸或脱搭自摸
    if self.isZiMo then
        if self.isTuoDa == false then
            huDetails.describe = huDetails.describe..'自摸 X3;'
        elseif self.isTuoDa == true then
            huDetails.describe = huDetails.describe..'脱搭自摸 X6;'
        end
    end
 
    -- 天胡
    if self:isTianHu() then
        hua = hua * 2
        huDetails.describe = huDetails.describe..'天胡 X2;'
    end

    if self.isAutoHu then
        LOG_DEBUG(' -- auto Hu --')
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
        LOG_DEBUG("before getTotalFan ,do calculate")
        fan = 0
    end
    -- 自摸 子3倍
    if self.isZiMo == true and false == self.isKuaiZhao then
        -- 有搭，不脱搭，自摸 3倍
        if self.player:hasBaiDa(self.gameProgress.baiDa) ~= 0 then
            if self.isTuoDa == false then
                fan = math.ceil(fan * 3)
            else
                -- 脱搭自摸 6倍
                fan = math.ceil(fan * 6)
            end
        end
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

    -- 必须不是自摸
    if self.player:hasNewCard() == true then
        return false
    end

    return true
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

-- 缺门 缺字不算，只能缺万条筒
function CountHuType:isQueMeng()
    local suitCountList = {}
    local suitCount = 0
    for suit = MJConst.kMJSuitWan, MJConst.kMJSuitTong do
        suitCount = self.player:getSuitCountInHand(suit, true)
        suitCount = suitCount + self.player:getSuitCountInPile(suit)
        suitCountList[suit] = suitCount
    end
    if nil ~= self.huCard then
        local suit = math.floor(self.huCard / 10)
        if suit >= MJConst.kMJSuitWan and suit <= MJConst.kMJSuitTong then
            suitCountList[suit] = 1
        end
    end

    suitCount = 0
    for k, v in pairs(suitCountList) do
        if v > 0 then
            suitCount = suitCount + 1
        end
    end
    if suitCount < 3 then
        return true
    end
    return false
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

-- 明杠开
function CountHuType:isMGangKai()
    local len = #self.player.opHistoryList
    if len > 1 then
        local justDoOper = self.player.opHistoryList[len - 1]
        if justDoOper == MJConst.kOperMG then
            return true
        end
    end
    return false
end

-- 暗杠开
function CountHuType:isAGangKai()
    local len = #self.player.opHistoryList
    if len > 1 then
        local justDoOper = self.player.opHistoryList[len - 1]
        if justDoOper == MJConst.kOperAG then
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
    if self.mjWall:getCanGetCount() <= 4 and 
    self.isZiMo == true then
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
    local canHuCards = self.player:getCanHuCardList()
    if #canHuCards ~= 1 then  -- 只能胡一张牌,一定是卡边吊
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
        if self:isBian() or self:isKa() then
            return true
        end
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
            dump(card)
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
            dump(card)
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

-- 风碰
function CountHuType:getFengPengCount()
    local sum = 0
    local pileList = self.player.pileList
    for byteCard = MJConst.Zi1, MJConst.Zi4 do
        for k, v in pairs(pileList) do
            if v:getCardCount(byteCard) > 0 then
                sum = sum + 1
            end
        end
    end
    local huCard = self.huCard
    if huCard == nil then
        huCard = self.player:getNewCard()
    end
    if huCard == nil then
        return sum
    end
    -- 手中牌也要算
    local countMap = self.player:transHandCardsToCountMap(false)
    countMap[huCard] = countMap[huCard] + 1
    for i = MJConst.Zi1, MJConst.Zi4 do
        if countMap[i] == 3 then
            sum = sum + 1
        end
    end
    
    return sum
end

return CountHuType