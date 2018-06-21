-- 搬杠头
local MJConst = require("mj_core.MJConst")
local function transferCardToNumber(cards)
    for index, card in pairs(cards) do 
        if card < MJConst.Zi1 then
            cards[index] = card % MJConst.kMJPointNull
        end
    end
end

local function calcElemCount(srcTb, decTb)
    local cnt = 0
    -- dump(srcTb, "srcTb")
    -- dump(decTb, "decTb")
    for _, elem in pairs(srcTb) do 
        if table.keyof(decTb, elem) ~= nil then
            cnt = cnt + 1
        end
    end
    return cnt
end

function calcMoveBarHead(cards, zhuangPos, maxCount, cardsMap)
    local result = {0, 0, 0, 0}
    local _cardsMap = cardsMap or {
        {1, 5, 9, MJConst.Zi1,MJConst.Zi5, MJConst.Hua1}, -- 庄家
        {4, 8, MJConst.Zi4, MJConst.Hua4}, -- 下家
        {3, 7, MJConst.Zi3, MJConst.Zi7, MJConst.Hua3}, -- 对家
        {2, 6, MJConst.Zi2, MJConst.Zi6, MJConst.Hua2}, -- 上家
    }
    local _cards = table.copy(cards) or {}
    transferCardToNumber(_cards)
    _maxCount = maxCount or 4
    for pos = 1, _maxCount do 
        local chairId = (pos - zhuangPos + _maxCount) % _maxCount + 1
        if _cardsMap[chairId] == nil then
            result[chairId] = 0
        end
        result[pos] = calcElemCount(_cards, _cardsMap[chairId])
    end
    return result
end
--- in return 0 is num 1 is hua
function calcSingleDragonBarType(card)
    if card < MJConst.Zi1 then
        return 0
    else
        return 1
    end
end