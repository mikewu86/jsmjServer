---- zhangyl 2016/11/25 8:45
---- 仅用于数据的存储
local MJConst = require("mj_core.MJConst")
local GoodCardTypeItem = class("GoodCardTypeItem")

function GoodCardTypeItem:ctor()
	self.cardList = {}
	self.suit = 0
end

function GoodCardTypeItem:clear()
	self.cardList = {}
end

local GoodCardTypeItemGroup = class("GoodCardTypeItemGroup")

function GoodCardTypeItemGroup:ctor()
    self.itemList = {} --- 存储各种牌型
    self.suitDelCount = {}
end

function GoodCardTypeItemGroup:clear()
    for _, subList in pairs(self.itemList) do 
        subList = {}
    end
    self.itemList = {}
end

function GoodCardTypeItemGroup:addItem(_suit, _cardList)
    if nil == self.itemList[_suit] then
        self.itemList[_suit] = {}
    end
    local item = GoodCardTypeItem.new()
    item.cardList = table.copy(_cardList)
    item.suit = _suit
    table.insert(self.itemList[_suit], item)
end

function GoodCardTypeItemGroup:getItemBySuit(_suit)
    local bRet = false
    local count = #self.itemList[_suit]
    local item = nil
    if count > 0 then
        item = self.itemList[_suit][1]
        bRet = true
        self.suitDelCount[_suit] = self.suitDelCount[_suit] + 1
    end
    return bRet, item
end

function GoodCardTypeItemGroup:getValidSuit()
    local bRet = false
    local item = nil
    local index = -9999
    local tempValue = 9999
    for siType, allItem in pairs(self.itemList) do
        cnt = self.suitDelCount[siType]
        if tempValue > cnt then
            tempValue = cnt
            index = siType
        end
    end
    
    if tempValue ~= 9999 and table.size(self.itemList[index]) > 0 then
        bRet = true
        item = self.itemList[index][1]
        self.suitDelCount[index] = self.suitDelCount[index] + 1
    end
    return bRet, item
end

function GoodCardTypeItemGroup:shuffle() ---- 注意类型必须连续问题
    local cycleCnt = table.size(self.itemList) - 1
    for index = 0, cycleCnt  do
        local totalCount = #self.itemList[index]
        math.randomseed(os.time())
        local tempList = table.copy(self.itemList[index])
        self.itemList[index] = {}
        for j = 1, totalCount do
            local pos = math.random(1, #tempList)
            local randomCard = table.remove( tempList, pos)
            table.insert(self.itemList[index], randomCard)
        end
    end
    
    ---- init count 
    for siType, itemList in pairs(self.itemList) do 
       self.suitDelCount[siType] = 0
    end
end

function GoodCardTypeItemGroup:deleteItem(_card, _allFlag)  --- 此标志便于仅有一个结果的情况下，快速结束循环;使用时可以不传入参数
    local suit = math.floor(_card / MJConst.kMJPointNull)
    local count = #self.itemList[suit]
    if count > 0 then
        for i = count, 1, -1 do
            if nil ~= table.keyof(self.itemList[suit][i].cardList, _card) then
                table.remove(self.itemList[suit], i)
                if true == _allFlag then
                    break
                end
            end
        end
    end
end


return GoodCardTypeItemGroup

