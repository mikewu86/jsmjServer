-- 2016.9.22 ptrjeffrey
-- 牌墙

local MJConst = require("mj_core.MJConst")
local MJCard = require("mj_core.MJCard")

--麻将牌墙单元
local MJWallItem = class("MJWallItem")

local MJWallItemState = {
    kSateNull      = 0,
    kStateCanGet   = 1,
    kStateToken    = 2,
    kStateShow     = 3,
    kStateFixed    = 4,
}

-- 从索引转成牌值的映射表
local index2ByteCardMap = {
    MJConst.Wan1, MJConst.Wan2, MJConst.Wan3, MJConst.Wan4, MJConst.Wan5, MJConst.Wan6, MJConst.Wan7, MJConst.Wan8, MJConst.Wan9,
    MJConst.Tiao1, MJConst.Tiao2, MJConst.Tiao3, MJConst.Tiao4, MJConst.Tiao5, MJConst.Tiao6, MJConst.Tiao7, MJConst.Tiao8, MJConst.Tiao9,
    MJConst.Tong1, MJConst.Tong2, MJConst.Tong3, MJConst.Tong4, MJConst.Tong5, MJConst.Tong6, MJConst.Tong7, MJConst.Tong8, MJConst.Tong9,
    MJConst.Zi1, MJConst.Zi2, MJConst.Zi3, MJConst.Zi4, MJConst.Zi5, MJConst.Zi6, MJConst.Zi7,
    MJConst.Hua1, MJConst.Hua2, MJConst.Hua3, MJConst.Hua4, MJConst.Hua5, MJConst.Hua6, MJConst.Hua7, MJConst.Hua8,
    MJConst.Cai, MJConst.Bao, MJConst.Mao, MJConst.Shu, MJConst.Blank, MJConst.Baida
}

function MJWallItem:ctor()
    self.byteCard       = MJConst.kCardNull
    self.stateList      = {[MJWallItemState.kSateNull] = true}
end

function MJWallItem:getByteCard()
    return self.byteCard
end

function MJWallItem:getStateList()
    return self.stateList
end

function MJWallItem:clear()
    self.byteCard       = MJConst.kCardNull
    self.stateList      = {[MJWallItemState.kSateNull] = true}
end

function MJWallItem:setItem(byteCard, state)
    local card = MJCard.new({byte = byteCard})
    if not card:isValid() then
        return false
    end
    if not self:isValidState(state) then
        return false
    end
    self.byteCard = byteCard
    return true
end

function MJWallItem:addState(state)
    if not self:isValidState(state) then
        return false
    end
    self.stateList[state] = true
    --self:addState(state)
    return true
end

function MJWallItem:subState(state)
    if not self:isValidState(state) then
        return false
    end
    self.stateList[state] = false
    return true
end

function MJWallItem:hasState(state)
    if self.stateList[state] then
        return true
    end
    return false
end

function MJWallItem:canGet()
    return self:hasState(MJWallItemState.kStateCanGet)
end

function MJWallItem:isValidState(state)
    if state ~= MJWallItemState.kSateNull and 
        state ~= MJWallItemState.kStateCanGet and
        state ~= MJWallItemState.kStateToken and
        state ~= MJWallItemState.kStateShow and 
        state ~= MJWallItemState.kStateFixed then
        return false
    end
    return true
end

local MJWall = class("MJWall")

-- 麻将牌墙，传入的是每种麻将子的个数
function MJWall:ctor(wallConfigMap)
    self.wallConfigMap = wallConfigMap
    self.wallList = {}
    self.frontIndex = 1
    self.backIndex  = 0
    self.count      = 0
end

function MJWall:clear()
    self.wallList = {}
    self.frontIndex = 1     --正向索引
    self.backIndex  = 0     --反向索引
    self.count      = 0     --总共多少张牌墙
end

-- 初始化牌墙
function MJWall:init()
    self:clear()
    for k, v in pairs(self.wallConfigMap) do
        self:addMJ(index2ByteCardMap[k], v)
    end
    self.backIndex = #self.wallList
end

function MJWall:setFrontIndex(num)
    if num <= self.backIndex and num >= self.frontIndex then
        self.frontIndex = num
    end 
end

function MJWall:setBackIndex(num)
    if num <= self.backIndex and num >= self.frontIndex then
        self.backIndex = num
    end 
end

function MJWall:getFrontIndex()
    return self.frontIndex
end

function MJWall:getBackIndex()
    return self.backIndex
end

function MJWall:getRemainCardsNum()
    return (self.backIndex - self.frontIndex + 1)
end

-- 按顺序初始化牌墙
function MJWall:initWithSeq(data)
    self:clear()
    for _, v in pairs(data) do
        self:addMJ(v, 1)
    end
    self.backIndex = #self.wallList
end

function MJWall:checkCardCanGet(byteCard)
    local canGet = false
    local cardIndex = -1
    local card = MJCard.new({byte = byteCard})
    if not card:isValid() then
        return canGet, cardIndex
    end
    for startI = self.frontIndex, self.backIndex do
        local cardItem = self.wallList[startI]
        if cardItem:canGet() and cardItem:getByteCard() == byteCard then
            cardIndex = startI
            canGet = true
            break
        end
    end
    return canGet, cardIndex
end

function MJWall:canGetIndexCard(index)
    local canGet = false
    local byteCard = -1
    if type(1) == type(index) and index >= self.frontIndex and index <= self.backIndex then
        local item = self.wallList[index]
        if item:canGet() then
            byteCard = item:getByteCard()
            canGet = true
        end
    end
    return canGet, byteCard
end
function MJWall:takeIndexCard(index)
    if type(1) == type(index) and index >= self.frontIndex and index <= self.backIndex then
        local item = self.wallList[index]
        if item:canGet() then
            self:takeaway(item)
        end
    end
end


-- 从头取一张牌
function MJWall:getFrontCard()
    if self:getCanGetCount() > 0 and self.frontIndex <= self.backIndex then
        local item = self:getFrontItem()
        if not item:canGet() then
            for i = self.frontIndex, self.backIndex do
                self.frontIndex = self.frontIndex + 1
                item = self:getFrontItem()
                if item:canGet() then
                    break
                end
            end
        end
        if not item:canGet() then
            LOG_DEBUG("MJWall:getFrontCard fail.")
            return nil
        else
            local byteCard = item:getByteCard()
            self:takeaway(item)
            self.frontIndex = self.frontIndex + 1
            return byteCard
        end
    end
    return nil
end

-- 从尾取一张牌
function MJWall:getBackCard()
    if self:getCanGetCount() > 0 and self.frontIndex <= self.backIndex then
        local item = self:getBackItem()
        if not item:canGet() then
            for i = self.backIndex, self.frontIndex, -1 do
                self.backIndex = self.backIndex - 1
                item = self.getBackItem()
                if item:canGet() then
                    break
                end
            end
        end
        if not item:canGet() then
            return nil
        else
            local byteCard = item:getByteCard()
            self:takeaway(item)
            self.backIndex = self.backIndex - 1
            return byteCard
        end
    end
    return nil
end


function MJWall:addMJ(byteCard, count)
    if count <= 0 or count == nil then 
        return
    end
    for i = 1, count do
        local item = MJWallItem.new()
        local ret = item:setItem(byteCard, MJWallItemState.kStateCanGet)
        if ret then
            self:addGetStat(item)
            table.insert(self.wallList, item)
        else
            LOG_DEBUG("输出错误信息")
            -- 输出错误信息
        end
    end
end

function MJWall:addGetStat(item)
    item:subState(MJWallItemState.kSateNull)
    item:subState(MJWallItemState.kStateToken)
    item:addState(MJWallItemState.kStateCanGet)
end

function MJWall:takeaway(item)
    item:subState(MJWallItemState.kSateNull)
    item:subState(MJWallItemState.kStateCanGet)
    item:addState(MJWallItemState.kStateToken)
end

function MJWall:shuffle(count)
    if not count then
        count = 3
    end
    local totalCount = #self.wallList

    for i = 0, count do
        math.randomseed(os.time())
        local tempWall = table.copy(self.wallList)
        self.wallList = {}
        for j = 1, totalCount do
            local pos = math.random( 1, #tempWall)
            local randomCard = table.remove( tempWall, pos)
            table.insert( self.wallList, randomCard)
        end
    end
end

function MJWall:getCanGetCount()
    return self:getStateCount(MJWallItemState.kStateCanGet)
end

function MJWall:getStateCount(state)
    local count = 0
    for k, v in pairs(self.wallList) do
        if v:hasState(state) then
            count = count + 1
        end
    end
    return count
end

function MJWall:getFrontItem()
    return self.wallList[self.frontIndex]
end

function MJWall:getBackItem()
    return self.wallList[self.backIndex]
end

return MJWall