-- 2016.9.22 ptrjeffrey
-- 麻将胡牌算法

local MJConst = require("mj_core.MJConst")

local MJMath = class("MJMath")
function MJMath:ctor()
    self.jiang = MJConst.kCardNull
end

function MJMath:remain(pai)
    local sum = 0
    for i = 1, #pai do
        sum = sum + pai[i]
    end
    return sum
end

function MJMath:getNotNone(pai)
    local index = 0
    for i = 1, #pai do
        if pai[i] > 0 then
            index = i
            break
        end
    end
    return index
end

function MJMath:init()
    self.jiang = MJConst.kCardNull
end

-- 是否可以胡牌
function MJMath:canHu(pai)
    if (self:remain(pai) + pai[0]) % 3 ~= 2 then
        return false
    end
    self:init()
    local oripai = table.clone(pai)
    return self:standerHu(oripai)
end

function MJMath:standerHu(pai)
    if self:remain(pai) == 0 then
        if self.jiang == MJConst.kCardNull then     -- 胡牌时没有将头，则将头是百搭
            self.jiang = MJConst.kMJAnyCard
        end
        return true
    end
    if self:remain(pai) == 1 and pai[0] == 1 and self.jiang == MJConst.kCardNull then
        local idx = self:getNotNone(pai)
        if idx ~= 0 then
            self.jiang = idx
            return true
        end
    end

    local idx = 1
    for i = idx, #pai do
        if pai[i] > 0 then
            idx = i
            break
        end
    end

    if pai[idx] >= 3 then
        pai[idx] = pai[idx] - 3
        if self:standerHu(pai) then
            return true
        end
        pai[idx] = pai[idx] + 3
    end

    if pai[idx] >= 2 and self.jiang == MJConst.kCardNull then
        pai[idx] = pai[idx] - 2
            self.jiang = idx
        if self:standerHu(pai) then
            return true
        end
        pai[idx] = pai[idx] + 2
        self.jiang = MJConst.kCardNull
    end

    if idx < MJConst.Zi1 and pai[idx + 1] > 0 and pai[idx + 2] > 0 and idx % 10 <= MJConst.kMJPoint7 then
        pai[idx] = pai[idx] - 1
        pai[idx + 1] = pai[idx + 1] - 1
        pai[idx + 2] = pai[idx + 2] - 1
        if self:standerHu(pai) then
            return true
        end
        pai[idx] = pai[idx] + 1
        pai[idx + 1] = pai[idx + 1] + 1
        pai[idx + 2] = pai[idx + 2] + 1
    end

    if pai[idx] >= 2 and pai[0] > 0 then
        pai[idx] = pai[idx] - 2
        pai[0] = pai[0] - 1
        if self:standerHu(pai) then
            return true
        end
        pai[idx] = pai[idx] + 2
        pai[0] = pai[0] + 1
    end

    if pai[idx] >= 1 and pai[0] >= 2 then
        pai[idx] = pai[idx] - 1
        pai[0] = pai[0] - 2
        if self:standerHu(pai) then
            return true
        end
        pai[idx] = pai[idx] + 1
        pai[0] = pai[0] + 2
    end

    if pai[0] >= 1 and idx < MJConst.Zi1 and idx % 10 <= MJConst.kMJPoint7 and
        (pai[idx + 1] >= 1 or pai[idx + 2] >= 1) then
            pai[idx] = pai[idx] - 1
            pai[0] = pai[0] - 1
            if pai[idx + 1] >= 1 then
                pai[idx + 1] = pai[idx + 1] - 1
                if self:standerHu(pai) then
                    return true
                end
                pai[idx] = pai[idx] + 1
                pai[0] = pai[0] + 1
                pai[idx + 1] = pai[idx + 1] + 1
            else
                pai[idx + 2] = pai[idx + 2] - 1
                if self:standerHu(pai) then
                    return true
                end
                pai[idx] = pai[idx] + 1
                pai[0] = pai[0] + 1
                pai[idx + 2] = pai[idx + 2] + 1
            end
    end

    if pai[0] >= 1 and idx < MJConst.Zi1 and idx % 10 <= MJConst.kMJPoint8 and
       pai[idx + 1] >= 1 then
            pai[idx] = pai[idx] - 1
            pai[0] = pai[0] - 1
            pai[idx + 1] = pai[idx + 1] - 1
            if self:standerHu(pai) then
                return true
            end
            pai[idx] = pai[idx] + 1
            pai[0] = pai[0] + 1
            pai[idx + 1] = pai[idx + 1] + 1
    end

    if pai[0] >= 1 and self.jiang == MJConst.kCardNull then
        self.jiang = idx
        pai[idx] = pai[idx] - 1
        pai[0] = pai[0] - 1
        if self:standerHu(pai) then
            return true
        end
        self.jiang = MJConst.kCardNull
        pai[idx] = pai[idx] + 1
        pai[0] = pai[0] + 1
    end
    return false
end

-- 是否能胡七对
function MJMath:canHuQiDui(pai)
    if self:remain(pai) + pai[0] ~= 14 then
        return false
    end
    local list = self:countSingle(pai)
    local cnt = pai[0]
    if #list == 0 then
        return true
    end
    if cnt >= #list and (cnt - #list) % 2 == 0 then
        return true
    end
    return false
end

function MJMath:countSingle(pai)
    local list = {}
    for i = 1, #pai do
        local cnt = pai[i] % 2
        if cnt ~= 0 then
            for j = 1, cnt do
                table.insert( list, i)
            end
        end
    end
    return list
end

-- 可以胡哪些牌
function MJMath:getCanHuCards(pai)
    local list = {}
    if (self:remain(pai) + pai[0]) % 3 ~= 1 then
        return list
    end
    local ingorSuit = {
        [MJConst.kMJSuitWan] = true, 
        [MJConst.kMJSuitTiao] = true, 
        [MJConst.kMJSuitTong] = true, 
        [MJConst.kMJSuitZi] = true
    }
    local cardList = {}

    if pai[0] == 0 then
        local sum = 0
        for i = MJConst.Wan1, MJConst.Wan9 do
            sum = sum + pai[i]
        end
        if sum % 3 ~= 0 then
            ingorSuit[MJConst.kMJSuitWan] = false
        end
        sum = 0
        for i = MJConst.Tiao1, MJConst.Tiao9 do
            sum = sum + pai[i]
        end
        if sum % 3 ~= 0 then
            ingorSuit[MJConst.kMJSuitTiao] = false
        end
        sum = 0
        for i = MJConst.Tong1, MJConst.Tong9 do
            sum = sum + pai[i]
        end
        if sum % 3 ~= 0 then
            ingorSuit[MJConst.kMJSuitTong] = false
        end
        sum = 0
        for i = MJConst.Zi1, MJConst.Zi7 do
            sum = sum + pai[i]
        end
        if sum % 3 ~= 0 then
            ingorSuit[MJConst.kMJSuitZi] = false
        end
    else -- 有百搭不能省略
        ingorSuit[MJConst.kMJSuitWan] = false
        ingorSuit[MJConst.kMJSuitTiao] = false
        ingorSuit[MJConst.kMJSuitTong] = false
        ingorSuit[MJConst.kMJSuitZi] = false
    end

    for i = MJConst.kMJSuitWan, MJConst.kMJSuitZi do
        if false ==  ingorSuit[i] then
            local from = MJConst.Wan1
            local to = MJConst.Wan9
            if i == MJConst.kMJSuitTiao then
                from = MJConst.Tiao1
                to = MJConst.Tiao9
            elseif i == MJConst.kMJSuitTong then
                from = MJConst.Tong1
                to = MJConst.Tong9
            elseif i == MJConst.kMJSuitZi then
                from = MJConst.Zi1
                to = MJConst.Zi7
            end
            for j = from, to do
                pai[j] = pai[j] + 1
                if self:canHu(pai) then
                    table.insert(list, j)
                end
                pai[j] = pai[j] - 1
            end      
        end
    end
    return list
    
end

function MJMath:getJiangTou()
    return self.jiang
end

return MJMath