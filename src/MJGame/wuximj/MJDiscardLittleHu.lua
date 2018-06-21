-- function: after discard little hu, must hu larger than discards.  
-- author: zhangyanlei
-- date:   2016/12/14 10:39
local MJDiscardLittleHu = class("MJDiscardLittleHu")

function MJDiscardLittleHu:ctor()
    self:reset()
end

function MJDiscardLittleHu:updateHuFan()
    if self.littleHuFan < self.tempHuFan then
        self.littleHuFan = self.tempHuFan
    end
end

function MJDiscardLittleHu:setTempLittleHu(_fan)
    if type(1) == type(_fan) then
        self.tempHuFan = _fan
    end
end

function MJDiscardLittleHu:getHuFan()
    return self.littleHuFan
end

function MJDiscardLittleHu:reset()
    self.littleHuFan = -9999
    self.tempHuFan = -9999   
end

return MJDiscardLittleHu
