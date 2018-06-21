--- poker card valid check and translate
--- author: zhangyl
--- date:2016/12/29 11:14
local pokerConst = require("common.pokerConst")
local pokerCard = class("pokerCard")

--- point to  only one pri and  pri to only one point
function pokerCard:ctor()
end

function pokerCard:init(priority)
    --- to compare point 
    self.pointPri = priority or {}
    self.totalPP = #self.pointPri
    --- to get last point
    self.priPoint = {}
    for index, point in pairs(self.pointPri) do 
        self.priPoint[index] = point
    end
end

function pokerCard:getCardString(value)
    local string = ""
    if true == self:isValid(value) then
        if type({}) == type(value) then
            local strColor = pokerConst.strColor[value.color] or ""
            local strPoint = pokerConst.strPoint[value.point] or ""
            string = string + strColor + strPoint
        elseif type(1) == type(value) then
            local data = self:cardByte2Data(value)
            local strColor = pokerConst.strColor[data.color] or ""
            local strPoint = pokerConst.strPoint[data.point] or ""
            string = string + strColor + strPoint 
        end
    end
end

function pokerCard:isValid(value)
    local bRet = false
    if type({}) == type(value) then
        local byte =  self:cardData2Byte(value)
        if true ==  self:isRange(byte) then
            bRet = true
        end
    elseif type(1) == type(value) then
        if true ==  self:isRange(value) then
            bRet = true
        end
    end
    return false
end

function pokerCard:cardByte2Data(_byte)
    local card = nil
    if type(1) == type(_byte) then
        local color = math.floor(_byte/pokerConst.weight)
        local point = _byte % pokerConst.weight
        card.color = color
        card.point = point
    elseif type({}) == type(_byte) then
        card = table.copy(_byte)
    end
    return card
end

function pokerCard:cardData2Byte(_data)
    local byte = nil
    if type({}) == type(_data) then
        if _data.color and _data.point then
            byte =  _data.color * pokerConst.weight + _data.point
        end
    end
    return byte
end

function pokerCard:isRange(byte)
    local bRet = false
    if type(1) == type(byte) then
        if byte >= PokerConst.DA and byte <= PokerConst.J2 then
            bRet = true
        end
    end
    return bRet
end

local function compareByte(num1, num2)
    local sRet = -1
    if num1 > num2 then
        sRet = 1
    elseif num1 == num2 then
        sRet = 0
    end
    return sRet
end

--- less: -1 equal: 0 more: 1 invalid:2
function pokerCard:compare(byte1, byte2)
    local sRet = 2
    if true == self:isValid(byte1) and true == self:isValid(byte2) then
        local value1 = self:cardByte2Data(byte1)
        local value2 = self:cardByte2Data(byte2)
        local bJoker1 = self:isJoker(value1.color)
        local bJoker2 = self:isJoker(value2.color) 
        local pri1 = self.pointPri[value1.point]
        local pri2 = self.pointPri[value2.point]
        if false == bJoker1 and false == bJoker2 then
            if nil == pri1 or nil == pri2 then
                LOG_DEBUG("pokercard priority is not configed.")
            else
                sRet = compareByte(pri1, pri2)
            end
        elseif true == bJoker1 and true == bJoker2 then
            sRet = compareByte(pri1, pri2)
        else
            if true == bJoker1 then
                sRet = 1
            end

            if true == bJoker2 then
                sRet = -1
            end
        end
    end
    return sRet
end

function pokerCard:isJoker(color)
    local bRet = false
    if color == PokerConst.kJoker then
        bRet = true
    end
    return bRet
end

--- for sequence three, four, six, seven
function pokerCard:getNextPoint(index)
    local point = nil
    local gap = -1
    if type(1) == type(index) then
        if index < self.totalPP then
            point = self.priPoint[index + 1]
            gap = self.totalPP - index
        end
    end
    return point, gap
end

return pokerCard