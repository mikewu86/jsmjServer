local MJConst = require("mj_core.MJConst")
local jiang = MJConst.kMJAnyCard
local paiMap = {}
local function remain(pai)
    local sum = 0
    for i = 1, #pai do
        sum = sum + pai[i]
    end
    return sum
end

local function getNotNone(pai)
    local index = 0
    for i = 1, #pai do
        if pai[i] > 0 then
            index = i
            break
        end
    end
    return index
end
local function transferKeyMap(pai)
    local paiCopy = table.copy(pai)
    paiMap = {}
    for card, cnt in pairs(paiCopy) do 
        table.insert(paiMap, {key = card, value = cnt})
    end
    table.sort(paiMap, function(a, b) 
                            if a.value ~= b.value then
                                return a.value > b.value
                            else
                                return a.key < b.key
                            end
                        end)
end

local function modifyKeyMap(pai)
    for key, value in pairs(pai) do
        for _, item in pairs(paiMap) do
            if item.key == key then
                item.value = value
                break
            end
        end
    end
end

function calcAndGetJiangTou(pai)
    jiang = MJConst.kMJAnyCard
    transferKeyMap(pai)
    -- dump(pai, "calcAndGetJiangTou pai")
    -- dump(paiMap, "calcAndGetJiangTou map")
    standerHu(pai, paiMap)
    -- dump(pai, "calcAndGetJiangTou pai ------------------")
    -- dump(paiMap, "calcAndGetJiangTou map---------------------")
    keyMap = {}
    return jiang
end


function standerHu(pai, paiMap)
    if remain(pai) == 0 then
        if jiang == MJConst.kMJAnyCard and pai[0] == 2 then
            jiang = 0
        end
        return true
    end
    if remain(pai) == 1 and pai[0] == 1 and jiang == MJConst.kMJAnyCard then
        local idx = getNotNone(pai)
        if idx ~= 0 then
            jiang = 0
            return true
        end
    end

    local idx = 1
    local mapIdx = 1
    for index, item in pairs(paiMap) do
        if item.value > 0 and item.key  > 0 then
            idx = item.key
            mapIdx = index
            --print("find index:"..idx.." map Index:"..index)
            break
        end
    end

    if pai[idx] >= 3 then
        pai[idx] = pai[idx] - 3
        paiMap[mapIdx].value = paiMap[mapIdx].value - 3
        --dump(paiMap, "three map")
        if standerHu(pai,paiMap) then
            return true
        end
        pai[idx] = pai[idx] + 3
        paiMap[mapIdx].value = paiMap[mapIdx].value + 3
    end

    if pai[idx] >= 2 and pai[0] > 0 then
        pai[idx] = pai[idx] - 2
        pai[0] = pai[0] - 1
        modifyKeyMap(pai)
        --dump(paiMap, "two  and  da")
        if standerHu(pai, paiMap) then
            return true
        end
        pai[idx] = pai[idx] + 2
        pai[0] = pai[0] + 1
        modifyKeyMap(pai)
    end

    if pai[idx] >= 2 and jiang == MJConst.kMJAnyCard then
        pai[idx] = pai[idx] - 2
        paiMap[mapIdx].value = paiMap[mapIdx].value - 2
        --dump(paiMap, "two map")
        if pai[0] == 0 then
            jiang = idx
        end
        if standerHu(pai,paiMap) then
            return true
        end
        pai[idx] = pai[idx] + 2
        paiMap[mapIdx].value = paiMap[mapIdx].value + 2
        jiang = MJConst.kMJAnyCard
    end

    if idx < MJConst.Zi1 and idx % 10 >= MJConst.kMJPoint2  and idx %10 <= MJConst.kMJPoint8 and pai[idx +1] > 0 and pai[idx - 1] > 0  then
        pai[idx] = pai[idx] - 1
        pai[idx - 1] = pai[idx - 1] - 1
        pai[idx + 1] = pai[idx + 1] - 1
        modifyKeyMap(pai)
        if standerHu(pai,paiMap) then
            return true
        end
        pai[idx] = pai[idx] + 1
        pai[idx - 1] = pai[idx - 1] + 1
        pai[idx + 1] = pai[idx + 1] + 1
        modifyKeyMap(pai)        
    end

    if idx < MJConst.Zi1 and idx % 10 >= MJConst.kMJPoint3 and pai[idx -1] > 0 and pai[idx - 2] > 0  then
        pai[idx] = pai[idx] - 1
        pai[idx - 1] = pai[idx - 1] - 1
        pai[idx - 2] = pai[idx - 2] - 1
        modifyKeyMap(pai)
        if standerHu(pai,paiMap) then
            return true
        end
        pai[idx] = pai[idx] + 1
        pai[idx - 1] = pai[idx - 1] + 1
        pai[idx - 2] = pai[idx - 2] + 1
        modifyKeyMap(pai)        
    end

    if idx < MJConst.Zi1 and idx % 10 <= MJConst.kMJPoint7 and pai[idx + 1] > 0 and pai[idx + 2] > 0  then
        pai[idx] = pai[idx] - 1
        pai[idx + 1] = pai[idx + 1] - 1
        pai[idx + 2] = pai[idx + 2] - 1
        modifyKeyMap(pai)
        if standerHu(pai,paiMap) then
            return true
        end
        pai[idx] = pai[idx] + 1
        pai[idx + 1] = pai[idx + 1] + 1
        pai[idx + 2] = pai[idx + 2] + 1
        modifyKeyMap(pai)
    end


    if pai[idx] >= 1 and pai[0] >= 2 then
        pai[idx] = pai[idx] - 1
        pai[0] = pai[0] - 2
        modifyKeyMap(pai)
        if standerHu(pai, paiMap) then
            return true
        end
        pai[idx] = pai[idx] + 1
        pai[0] = pai[0] + 2
        modifyKeyMap(pai)
    end

    if pai[0] >= 1 and idx < MJConst.Zi1 and idx % 10 <= MJConst.kMJPoint7 and
        (pai[idx + 1] >= 1 or pai[idx + 2] >= 1) then
            pai[idx] = pai[idx] - 1
            pai[0] = pai[0] - 1
            if pai[idx + 1] >= 1 then
                pai[idx + 1] = pai[idx + 1] - 1
                modifyKeyMap(pai)
                if standerHu(pai,paiMap) then
                    return true
                end
                pai[idx] = pai[idx] + 1
                pai[0] = pai[0] + 1
                pai[idx + 1] = pai[idx + 1] + 1
                modifyKeyMap(pai)
            else
                pai[idx + 2] = pai[idx + 2] - 1
                modifyKeyMap(pai)
                if standerHu(pai,paiMap) then
                    return true
                end
                pai[idx] = pai[idx] + 1
                pai[0] = pai[0] + 1
                pai[idx + 2] = pai[idx + 2] + 1
                modifyKeyMap(pai)
            end
    end

    if pai[0] >= 1 and idx < MJConst.Zi1 and idx % 10 <= MJConst.kMJPoint8 and
       pai[idx + 1] >= 1 then
            pai[idx] = pai[idx] - 1
            pai[0] = pai[0] - 1
            pai[idx + 1] = pai[idx + 1] - 1
            modifyKeyMap(pai)
            if standerHu(pai,paiMap) then
                return true
            end
            pai[idx] = pai[idx] + 1
            pai[0] = pai[0] + 1
            pai[idx + 1] = pai[idx + 1] + 1
            modifyKeyMap(pai)
    end

    if pai[0] >= 1 and jiang == MJConst.kMJAnyCard then
        jiang = 0
        pai[idx] = pai[idx] - 1
        pai[0] = pai[0] - 1
        modifyKeyMap(pai)
        if standerHu(pai,paiMap) then
            return true
        end
        jiang = MJConst.kMJAnyCard
        pai[idx] = pai[idx] + 1
        pai[0] = pai[0] + 1
        modifyKeyMap(pai)
    end
    return false
end