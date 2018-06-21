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

-- 包牌情况2 大杠开，由被杠的人承包
function CountHuType:baoPao2(pileList, noAnGangPileList, fromList, anGangCount)
    if self:hasHuType(HuTypeConst.kHuType.kGangKai) == true then
        local pile = noAnGangPileList[#noAnGangPileList]
        if nil ~= pile then
            if pile.operType == MJConst.kOperMXG or
                pile.operType == MJConst.kOperMG then
                    self.baoPaiPos = pile.from   -- 更改放炮玩家为包牌玩家
                    self.isBaoPai = true
                    return true
            end
        end
    end
    return false
end

-- 包牌情况3 被同一人连续碰杠在次，再对出任何一次，则送3嘴的人包
function CountHuType:baoPao3(pileList, noAnGangPileList, fromList, anGangCount)
    if #noAnGangPileList >= 3 then
        -- 送3次的人包牌
        if fromList[1] == fromList[2] and 
           fromList[2] == fromList[3] then
           self.baoPaiPos = fromList[1]   -- 更改放炮玩家为包牌玩家
           self.isBaoPai = true
           if #pileList == 4 then
                self.isAutoHu = true
           end
           return true
        end
        if #noAnGangPileList == 4 then
            if fromList[3] == fromList[4] and 
                fromList[2] == fromList[3] then
                self.baoPaiPos = fromList[2]   -- 更改放炮玩家为包牌玩家
                self.isBaoPai = true
                self.isAutoHu = true
                return true
            end
        end
    end
    return false
end

-- 包牌情况4 给暗杠2次的人对一嘴
function CountHuType:baoPao4(pileList, noAnGangPileList, fromList, anGangCount)
    if anGangCount >= 2 and #noAnGangPileList > 0 then
        self.baoPaiPos = noAnGangPileList[1].from   -- 更改放炮玩家为包牌玩家
        self.isBaoPai = true
        if #pileList == 4 then
            self.isAutoHu = true
        end
        return true
    end
    return false
end

-- 包牌情况5 给同一个对2嘴后，此人还有暗杠
function CountHuType:baoPao5(pileList, noAnGangPileList, fromList, anGangCount)
    if anGangCount < 1 then
        return false
    end
    local totalPile = #pileList
    if #fromList == 2  then
        if fromList[1] == fromList[2] then
            self.baoPaiPos = fromList[1]   -- 更改放炮玩家为包牌玩家
            self.isBaoPai = true
            if totalPile == 4 then
                self.isAutoHu = true
            end
            return true
        end
    elseif #fromList == 3  then
        if fromList[1] == fromList[2] or 
            fromList[1] == fromList[3] then
            self.baoPaiPos = fromList[1]   -- 更改放炮玩家为包牌玩家
            self.isBaoPai = true
            if totalPile == 4 then
                self.isAutoHu = true
            end
            return true
        elseif fromList[2] == fromList[3] then
            self.baoPaiPos = fromList[2]   -- 更改放炮玩家为包牌玩家
            self.isBaoPai = true
            if totalPile == 4 then
                self.isAutoHu = true
            end
            return true
        end
    end
    return false
end

-- 包牌情况6 有人对了3嘴以后形成清一色牌面，送同样花色的第4嘴的人包牌
function CountHuType:baoPao6(pileList, noAnGangPileList, fromList, anGangCount)
    if #noAnGangPileList == 4 then
        local suitCountList = {}
        local suitCount = 0
        for suit = MJConst.kMJSuitWan, MJConst.kMJSuitZi do
            suitCount = suitCount + self.player:getSuitCountInPile(suit)
            suitCountList[suit] = suitCount
        end
        suitCount = 0
        for k, v in pairs(suitCountList) do
            if v > 0 then
                suitCount = suitCount + 1
            end
        end
        if suitCount == 1 then  -- 碰杠出来的牌是清一色牌面
            self.baoPaiPos = fromList[4]   -- 更改放炮玩家为包牌玩家
            self.isBaoPai = true
            return true
        end
    end
    return false
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
    elseif self:baoPao2(pileList, noAnGangPileList, fromList, anGangCount) then
        return
    elseif self:baoPao3(pileList, noAnGangPileList, fromList, anGangCount) then
        return
    elseif self:baoPao4(pileList, noAnGangPileList, fromList, anGangCount) then
        return
    elseif self:baoPao5(pileList, noAnGangPileList, fromList, anGangCount) then
        return
    elseif self:baoPao6(pileList, noAnGangPileList, fromList, anGangCount) then
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
    -- 七对,豪华七对，超豪华，超超豪华
    if self:isQiDui() then
        local qiDuiType = self:getQiDuiType()
        -- 豪华，超豪华，超超豪华都加上四核
        if qiDuiType == 1 then
            innerFill(HuTypeConst.kHuType.k4He, huDetails)
            innerFill(HuTypeConst.kHuType.kHQiDui, huDetails)
        elseif qiDuiType == 2 then
            innerFill(HuTypeConst.kHuType.k4He, huDetails)
            innerFill(HuTypeConst.kHuType.kCHQiDui, huDetails)
        -- elseif qiDuiType == 3 then
        --     innerFill(HuTypeConst.kHuType.k4He, huDetails)
        --     innerFill(HuTypeConst.kHuType.kCCHQiDui, huDetails)
        else
            innerFill(HuTypeConst.kHuType.kQiDui, huDetails)
        end
    -- else
    --     -- 门清
    --     if self:isMengQing() then
    --         innerFill(HuTypeConst.kHuType.kMengQing, huDetails)
    --     end
    end
    -- 天胡，地胡,海底
    if self:isTianHu() then
        innerFill(HuTypeConst.kHuType.kTianHu, huDetails)
    elseif self:isDiHu() then
        innerFill(HuTypeConst.kHuType.kDiHu, huDetails)
    elseif self:isHaiDi() then
        innerFill(HuTypeConst.kHuType.kHaiDi, huDetails)
    end
    -- 清一色，混一色,缺门
    local yiSeType = self:getYiSeType()
    if yiSeType == 2 then
        innerFill(HuTypeConst.kHuType.kQingYiSe, huDetails)
    -- elseif yiSeType == 3 then
    --     innerFill(HuTypeConst.kHuType.kHunYiSe, huDetails)
    elseif self:isQueMeng() then
        innerFill(HuTypeConst.kHuType.kQueMeng, huDetails)
    end
    -- -- 对对胡
    -- if self:isDuiDuiHu() then
    --     innerFill(HuTypeConst.kHuType.kDuiDuiHu, huDetails)
    -- end
    -- 四暗刻
    if self:is4AnKe() then
        innerFill(HuTypeConst.kHuType.k4AnKe, huDetails)
    end
    -- -- 压绝
    -- if self:isYaJue() then
    --     innerFill(HuTypeConst.kHuType.kYaJue, huDetails)
    -- end
    -- -- 大小杠开
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
    --     -- local item = {pos = self.pos, 
    --     -- huastr = '硬花',
    --     -- countstr = #self.player.huaList..'*2 花'}
    --     -- table.insert(huDetails, item)
    --     hua = hua + #self.player.huaList * 2
    -- end
    -- -- 边枝，压档，独占
    -- if self:isBian() then
    --     innerFill(HuTypeConst.kHuType.kBian, huDetails)
    -- elseif self:isKa() then
    --     innerFill(HuTypeConst.kHuType.kKa, huDetails)
    -- elseif self:isDiao() then
    --     innerFill(HuTypeConst.kHuType.kDuZhan, huDetails)
    -- end

    -- -- 风碰
    -- if self:isFengPeng() then
    --     innerFill(HuTypeConst.kHuType.kFengPeng, huDetails)
    -- end

    -- 卡
    if self:isKa() then
        innerFill(HuTypeConst.kHuType.kKa, huDetails)
    end

    -- 四核
    if self:is4He() then
        innerFill(HuTypeConst.kHuType.k4He, huDetails)
    end

    local shuangPuZiType = self:getShuangPuZiType()
    --dump(shuangPuZiType, "**************shuangPuZiType***************")
    if shuangPuZiType ~= false then
        -- 自摸+10嘴
        if self.huCard == nil then
            huDetails.describe = huDetails.describe..'双铺子自摸'..' 10嘴'..';'
            hua = hua + 10
        end
        -- 明双铺子
        if shuangPuZiType == 0 then
            innerFill(HuTypeConst.kHuType.kMShuangPuZi, huDetails)
        -- 暗双铺子
        elseif shuangPuZiType == 1 then
            innerFill(HuTypeConst.kHuType.kAShuangPuZi, huDetails)
        -- 双暗双铺子
        elseif shuangPuZiType == 2 then
            innerFill(HuTypeConst.kHuType.k2An2Shuang, huDetails)
        end
    end

    -- 3连坎
    if self:is3LianKan() then
        innerFill(HuTypeConst.kHuType.k3LianKan, huDetails)
    end

    -- 10同
    if self:is10Tong() then
        innerFill(HuTypeConst.kHuType.k10Tong, huDetails)
    end

    -- 不能直接填充嘴数的胡牌类型
    -- 同
    local bTong, tongFan = self:getTongFanNums()
    --dump(tongFan, '*********tongFan**********')
    if bTong then
        huDetails.describe = huDetails.describe..'同'..' '..tongFan..'嘴'..';'
        hua = hua + tongFan
    end

    -- 支
    local bZhi, zhiFan = self:getZhiFanNums()
    --dump(zhiFan, '*********zhiFan**********')
    if bZhi then
        huDetails.describe = huDetails.describe..'支'..' '..zhiFan..'嘴'..';'
        hua = hua + zhiFan
    end

    -- 坎
    local bKan, kanFan = self:getKanFanNums()
    --dump(kanFan, '*********kanFan**********')
    if bKan then
        huDetails.describe = huDetails.describe..'坎'..' '..kanFan..'嘴'..';'
        hua = hua + kanFan
    end

    -- 连庄
    -- 庄家胡
    dump(self.pos, "胡牌人是")
    dump(self.gameProgress.banker, "庄家是")
    if self.pos == self.gameProgress.banker then
        -- 庄家自摸 连庄数*4嘴
        if self.isZiMo == true then
            local lianZhuangFan = self.gameProgress:getRemainBanker() * 4
            huDetails.describe = huDetails.describe..'连庄数'..self.gameProgress:getRemainBanker()..' 庄自摸'..self.gameProgress:getRemainBanker()..'*'..'4'..'嘴'..';'
            hua = hua + lianZhuangFan
        -- 庄家胡牌 连庄数*2嘴
        else
            local lianZhuangFan = self.gameProgress:getRemainBanker() * 2
            huDetails.describe = huDetails.describe..'连庄数'..self.gameProgress:getRemainBanker()..' 庄胡'..self.gameProgress:getRemainBanker()..'*'..'2'..'嘴'..';'
            hua = hua + lianZhuangFan
        end
    else
        -- 闲家胡
        -- 闲家自摸 连庄数*4嘴 其中庄家多付连庄数*4嘴
        if self.isZiMo == true then
            local lianZhuangFan = self.gameProgress:getRemainBanker() * 4
            huDetails.describe = huDetails.describe..'连庄数'..self.gameProgress:getRemainBanker()..' 闲家自摸，庄家多付'..self.gameProgress:getRemainBanker()..'*'..'4'..'嘴'..';'
            hua = hua + lianZhuangFan
        -- 闲家胡牌 庄放冲  庄家多付连庄数*2嘴
        elseif self.fangPaoPos == self.gameProgress.banker and self.isZiMo == false then
            local lianZhuangFan = self.gameProgress:getRemainBanker() * 2
            huDetails.describe = huDetails.describe..'连庄数'..self.gameProgress:getRemainBanker()..' 闲家胡，庄点炮，多付'..self.gameProgress:getRemainBanker()..'*'..'2'..'嘴'..';'
            hua = hua + lianZhuangFan
        end
    end

    -- 杠
    local bGang, gangFan = self:getAGFanNums()
    if bGang then
        huDetails.describe = huDetails.describe..'杠'..' '..gangFan..'*4嘴'..';'
        hua = hua + gangFan * 4
    end

    -- 杠后开花，总嘴数*2
    if self:isGangKai() then
        huDetails.describe = huDetails.describe..'杠后开花'..' '..'总嘴数'..'*'..'2'..';'
        hua = hua * 2
    end
    
    -- -- 计算包牌
    -- self:calulateBaoPai()
    -- if self.isBaoPai then
    --     -- local item = {pos = self.pos, 
    --     -- huastr = '包牌',
    --     -- countstr = ''}
    --     -- table.insert(huDetails, item)
    --     huDetails.describe = huDetails.describe..'包牌;'
    -- end

    -- if self.isAutoHu then
    --     LOG_DEBUG(' -- auto Hu --')
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
    -- elseif true == self.isBaoPai then
    --     fan = math.ceil(fan * 3)
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
            --dump(card)
            return false
    end

    local canHuCards = self.player:getCanHuCardList()
    if #canHuCards >= 2 then
        table.removeItem(canHuCards, 1)
        table.removeItem(canHuCards, 9)
        if #canHuCards ~= 1 then  -- 只能胡一张牌,一定是卡边吊
        -- LOG_DEBUG('-- isKa 5 --'..huCard)
            return false
        end
        return true
    end
    --local countMap = self.player:transHandCardsToCountMap(false)
    --dump(countMap, "1111111111111111111111111")
    -- countMap[huCard + 1] = countMap[huCard + 1] - 1
    -- countMap[huCard - 1] = countMap[huCard - 1] - 1
    -- dump(countMap)
    -- if countMap[huCard + 1] < 0 or
    --     countMap[huCard - 1] < 0 then
    --     -- LOG_DEBUG('-- isKa 6 --'..huCard)
    --     return false
    -- end
    -- LOG_DEBUG('-- isKa 7 --')
    -- dump(countMap)
    --return self.player.mjMath:canHu(countMap)
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
            return true
        end
    end
    
    return false
end

-- 四暗刻
function CountHuType:is4AnKe()
    -- 必须自摸
    if self.player:hasNewCard() == false then
        return false
    end

    local huCard = self.player:getNewCard()
    if huCard == nil then
        LOG_DEBUG("player's zimo card is nil")
        return false
    end

    local countMap = self.player:transHandCardsToCountMap(false)
    countMap[huCard] = countMap[huCard] + 1
    local siKeSum = 0
    for k, v in pairs(countMap) do
        if v == 3 then
            siKeSum = siKeSum + 1
        end

        if siKeSum == 4 then
            return true
        end
    end
    return false
end

-- 四核
function CountHuType:is4He()
    local huCard = self.huCard
    if huCard == nil then
        huCard = self.player:getNewCard()
    end
    if huCard == nil then
        return false
    end
    local countMap = self.player:transHandCardsToCountMap(false)
    countMap[huCard] = countMap[huCard] + 1
    for _, v in pairs(countMap) do
        if v == 4 then
            return true
        end
    end
    return false
end

-- 双铺子
-- 0:明双铺子 1:暗双铺子 2:双暗双铺子
function CountHuType:getShuangPuZiType()
    local huCard = self.huCard
    if huCard == nil then
        huCard = self.player:getNewCard()
    end
    if huCard == nil then
        return false
    end

    function isShuangPuZi(_countMap)
        local tbTmp = {}
        for k, v in pairs(_countMap) do
            if v >= 2 then
                table.insert(tbTmp, k)
            end
        end

        -- 有几对双铺子
        local sum = 0
        table.sort(tbTmp, function (a, b) return a < b end)
        for k, _ in pairs(tbTmp) do
            if tbTmp[k] + 1 == tbTmp[k + 1] and tbTmp[k] + 2 == tbTmp[k + 2] then
                sum = sum + 1
            end
        end

        if sum >= 1 then
            return true, sum
        else
            return false, sum
        end
    end

    local countMap = self.player:transHandCardsToCountMap(false)
    local bMatch, num = isShuangPuZi(countMap)
    if bMatch then
        -- 双暗双铺子，非自摸算暗双铺子
        if num >= 2 then
            -- 不是自摸
            if self.huCard ~= nil then
                return 1
            -- 自摸
            elseif self.huCard == nil then
                return 2
            end
        -- 暗双铺子
        elseif num == 1 then
            return 1
        else
            -- 包含所胡牌
            local countMapIncludeHuCard = table.clone(countMap)
            countMapIncludeHuCard[huCard] = countMapIncludeHuCard[huCard] + 1
            -- 明双铺子
            local bMatch, _ = isShuangPuZi(countMapIncludeHuCard)
            if bMatch then
                return 0
            end
        end
    end

    return false
end

-- 3连坎
function CountHuType:is3LianKan()
    local huCard = self.huCard
    if huCard == nil then
        huCard = self.player:getNewCard()
    end
    if huCard == nil then
        return false
    end

    local countMap = self.player:transHandCardsToCountMap(false)
    countMap[huCard] = countMap[huCard] + 1
    local tbTmp = {}
    for k, v in pairs(countMap) do
        if v == 3 then
            table.insert(tbTmp, k)
        end
    end

    table.sort(tbTmp, function(a, b) return a < b end)
    for k , _ in ipairs(tbTmp) do
        if tbTmp[k] + 1 == tbTmp[k + 1] and tbTmp[k] + 2 == tbTmp[k + 2] then
            return true
        end
    end
    return false
end

-- 10同
function CountHuType:is10Tong()
    local huCard = self.huCard
    if huCard == nil then
        huCard = self.player:getNewCard()
    end
    if huCard == nil then
        return false
    end

    local tbHandCardsCopy = self.player:getHandCardsCopy()
    local tbPileCardsCopy = self.player:getPileCardValueList()
    local tbHuCard = MJCard.new({byte = huCard})

    -- 把明牌table的值加入到手牌后计算
    if tbPileCardsCopy ~= nil then
        for _, v in ipairs(tbPileCardsCopy) do
            table.insert(tbHandCardsCopy, v)
        end
    end
    local tbTmp = {}
    for _, v in ipairs(tbHandCardsCopy) do
        local card = MJCard.new({byte = v})
        if tbTmp[card.point] then
            tbTmp[card.point] = tbTmp[card.point] + 1
            if tbHuCard.point == card.point then
                tbTmp[card.point] = tbTmp[card.point] + 1
            end
        else
            tbTmp[card.point] = 1
        end

        if tbTmp[card.point] >= 10 then
            return true
        end
    end
    return false
end

-- 同，返回+X嘴
function CountHuType:getTongFanNums()
    local huCard = self.huCard
    if huCard == nil then
        huCard = self.player:getNewCard()
    end
    if huCard == nil then
        return false, 0
    end

    -- local tbHandCardsCopy = self.player:getHandCardsCopy()
    -- local tbPileCardsCopy = self.player:getPileCardsCopy()
    -- local tbHuCard = MJCard.new({byte = huCard})

    -- -- 把明牌table的值加入到手牌后计算
    -- if tbPileCardsCopy ~= nil then
    --     for _, v in ipairs(tbPileCardsCopy) do
    --         table.insert(tbHandCardsCopy, v)
    --     end
    -- end
    local allCards = {}
    if self.huCard ~= nil then
        allCards = self.player:getAllCards()
        table.insert(allCards, self.huCard)
    else
        allCards = self.player:getAllCards()
    end

    local tbTmp = {}
    local sum = 0
    for _, v in pairs(allCards) do
        local card = MJCard.new({byte = v})
        if tbTmp[card.point] then
            tbTmp[card.point] = tbTmp[card.point] + 1
        else
            tbTmp[card.point] = 1
        end
    end

    -- 大于4张的相同点数牌，从4张起数，每多一张，+1倍基础分
    for point, num in pairs(tbTmp) do
        -- if tbHuCard.point == point then
        --     num = num + 1
        -- end

        if num >= 4 then
            local fan = num - 4
            sum = sum + fan
        end
    end

    if sum > 0 then
        return true, sum
    end
    return false, 0
end

function CountHuType:getZhiFanNums()
    local huCard = self.huCard
    if huCard == nil then
        huCard = self.player:getNewCard()
    end
    if huCard == nil then
        return false, 0
    end

    local sum = 0
    -- local tbHandCardsCopy = self.player:getHandCardsCopy()
    -- table.insert(tbHandCardsCopy, huCard)

    for i = MJConst.kMJSuitWan, MJConst.kMJSuitTong do
        local huaSeNumsHand = self.player:getSuitCountInHand(i, true)
        local huaSeNumsPile = self.player:getSuitCountInPile(i)
        local huaSeNums = huaSeNumsHand + huaSeNumsPile
        if huaSeNums >= 9 then
            local fan = huaSeNums - 8
            sum = sum + fan
            --dump(sum, "**************getZhiFanNums*************")
            return true, sum
        end
    end
    return false, 0
end

function CountHuType:getKanFanNums()
    local huCard = self.huCard
    if huCard == nil then
        huCard = self.player:getNewCard()
    end
    if huCard == nil then
        return false, 0
    end

    local sum = 0
    local countMap = self.player:transHandCardsToCountMap(false)

    countMap[huCard] = countMap[huCard] + 1
    local sum = 0
    for _, v in pairs(countMap) do
        if v == 3 then
            sum = sum + 1
        end
    end
    --dump(sum, "********************getKanFanNums***************")
    if sum > 0 then
        return true, sum
    end
    return false, 0
end

function CountHuType:getAGFanNums()
    if self.player.pileList ~= nil and #self.player.pileList ~= 0 then
        return true, #self.player.pileList
    else
        return false, 0
    end
    return false, 0
end

return CountHuType