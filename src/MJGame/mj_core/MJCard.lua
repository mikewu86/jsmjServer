-- 麻将牌定义
local MJConst = require("mj_core.MJConst")

local MJCard = class("MJCard")


function MJCard:ctor(args)
    self.suit = MJConst.kMJSuitNull
    self.point =  MJConst.kMJPointNull
    if args.byte then
        self:fromByte(args.byte)
    elseif args.suit and args.point then
        self:fromSuitAndPoint(args.suit, args.point)
    end
end

-- 从类型和点数转成对象
function MJCard:fromSuitAndPoint(suit, point)
    local byte = suit * MJConst.kMJPointNull + point
    return self:fromByte(byte)
end

function MJCard:toByte()
    return self.suit * MJConst.kMJPointNull + self.point
end

-- 从一个byte值转成对象
function MJCard:fromByte(byte)
    local suit = math.floor(byte / MJConst.kMJPointNull)
    local point = byte - suit * MJConst.kMJPointNull
    if suit >= MJConst.kMJSuitWan and suit <= MJConst.kMJSuitTong then
        if point >= MJConst.kMJPoint1 and point <= MJConst.kMJPoint9 then
            self.suit = suit
            self.point = point
            return true
        else
            return false
        end
    elseif suit == MJConst.kMJSuitZi then
        if point >= MJConst.kMJPoint1 and point <= MJConst.kMJPoint7 then
            self.suit = suit
            self.point = point
            return true
        else
            return false
        end
    elseif suit == MJConst.kMJSuitHua then
        if point >= MJConst.kMJPoint1 and point <= MJConst.kMJPoint8 then
            self.suit = suit
            self.point = point
            return true
        else
            return false
        end
    elseif suit == MJConst.kMJSuitCai then
        if point >= MJConst.kMJPoint1 and point <= MJConst.kMJPoint4 then
            self.suit = suit
            self.point = point
            return true
        else
            return false
        end
    elseif suit == MJConst.kMJSuitBlank then
        if point == MJConst.kMJPoint1 or point == MJConst.kMJPoint2 then
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

function MJCard:isValid()
    local suit = self.suit
    local point = self.point
    if suit >= MJConst.kMJSuitWan and suit <= MJConst.kMJSuitTong then
        if point >= MJConst.kMJPoint1 and point <= MJConst.kMJPoint9 then
            self.suit = suit
            self.point = point
            return true
        else
            return false
        end
    elseif suit == MJConst.kMJSuitZi then
        if point >= MJConst.kMJPoint1 and point <= MJConst.kMJPoint7 then
            self.suit = suit
            self.point = point
            return true
        else
            return false
        end
    elseif suit == MJConst.kMJSuitHua then
        if point >= MJConst.kMJPoint1 and point <= MJConst.kMJPoint8 then
            self.suit = suit
            self.point = point
            return true
        else
            return false
        end
    elseif suit == MJConst.kMJSuitCai then
        if point >= MJConst.kMJPoint1 and point <= MJConst.kMJPoint4 then
            self.suit = suit
            self.point = point
            return true
        else
            return false
        end
    elseif suit == MJConst.kMJSuitBlank then
        if point == MJConst.kMJPoint1 or point == MJConst.kMJPoint2 then
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

return MJCard