--[[
	此文件主要对牌按类型排序
--]]
local MJPublicFunc = {}
local MJUtils = require("MJCommon.MJUtils")

---  server\cpp\MJCommon\inc\mjcommon.h 
function MJPublicFunc.groupBySuit(_cards)
    local cardsCopy = table.clone(_cards)
    table.sort(cardsCopy, MJUtils.sort_ByteCardLess)

    local groups = {}
    local index = 1

    if #cardsCopy == 0 then
        return groups
    end

    for i = 1, #cardsCopy do
        local card = cardsCopy[i]
        local cardData = MJUtils.CardByteToData(card)

        if nil == groups[cardData.suit] then
            groups[cardData.suit] = {}
        end
        table.insert(groups[cardData.suit], card)
    end

    return groups
end

function MJPublicFunc.groupByValue(_cards)
    local cardsCopy = table.clone(_cards)
    table.sort(cardsCopy, MJUtils.sort_ByteCardLess)

    local groups = {}
    local index = 1

    if #cardsCopy == 0 then
        return groups
    end

    for i = 1, #cardsCopy do
        local card = cardsCopy[i]
        local cardData = MJUtils.CardByteToData(card)

        if nil == groups[cardData.value] then
            groups[cardData.value] = 1
        else
            groups[cardData.value] = groups[cardData.value] + 1
        end
    end

    return groups
end

--  statistics counts each card, sort by pocker suit and pocker value 
function MJPublicFunc.groupBySuitValue(_cards)
    local cardsCopy = table.clone(_cards)
    table.sort(cardsCopy, MJUtils.sort_ByteCardLess)

    local groups = {}
    local index = 1

    if #cardsCopy == 0 then
        return groups
    end

    table.insert(groups, {cardsCopy[1]})

    for i = 2, #cardsCopy do
        local card = cardsCopy[i]
        local prevCard = cardsCopy[i - 1]

        if card == prevCard then
            local group = groups[#groups]
            table.insert(group, card)
        else
            table.insert(groups, {card})
        end
    end

    return groups
end

function MJPublicFunc.delSpecNumCards(_cards, _delCard, _delNum)
    if not _cards or not _delCard or not _delNum then
        return false
    end

    local siDelHu = 0
    local bDelHuTwo = false
    for i = #_cards, 1, -1 do
        if _cards[i] == _delCard then
           table.remove(_cards, i)
           siDelHu = siDelHu + 1
           if _delNum == siDelHu then
                bDelHuTwo = true
                break
           end
        end
    end
    return bDelHuTwo
end

return MJPublicFunc
