-- 扑克牌定义
local PokerConst = require("poker_core.PokerConst")

local PokerCard = class("PokerCard")

function PokerCard:ctor(_args)
    self.suit = PokerConst.kPokerSuitNull
    self.point = PokerConst.kPokerPointNull
    if _args then
        if _args.byte then
            self:fromByte(_args.byte)
        elseif _args.suit and _args.point then
            self:fromSuitAndPoint(_args.suit, _args.point)
        end
    end
end

function PokerCard:fromByte(_byte)
    local suit = math.floor(_byte / PokerConst.CardBitMask)
    local point = _byte - suit * PokerConst.CardBitMask
    if suit >= PokerConst.kPokerSuitSpade and suit <= PokerConst.kPokerSuitDiamond then
        if point >= PokerConst.kPokerPoint1 and point <= PokerConst.kPokerPointK then
            self.suit = suit
            self.point = point
            return true
        else
            return false
        end
    elseif suit == PokerConst.kPokerSuitNull then
        if point == PokerConst.kPokerPointBlack or point == PokerConst.kPokerPointRed then
            self.suit = suit
            self.point = point
            return true
        else
            return false
        end
    else
        return false
    end
end

function PokerCard:fromSuitAndPoint(_suit, _point)
    local byte = _suit * PokerConst.CardBitMask + _point
    return self:fromByte(byte)
end

function PokerCard:toByte()
    return self.suit * PokerConst.CardBitMask + self.point
end

function PokerCard:isValid()
    local suit = self.suit
    local point = self.point
    if suit >= PokerConst.kPokerSuitSpade and suit <= PokerConst.kPokerSuitDiamond then
        if point >= PokerConst.kPokerPoint1 and point <= PokerConst.kPokerPointK then
            return true
        else
            return false
        end
    elseif suit == PokerConst.kPokerSuitNull then
        if point == PokerConst.kPokerPointBlack or point == PokerConst.kPokerPointRed then
            return true
        else
            return false
        end
    else
        return false
    end
end

return PokerCard