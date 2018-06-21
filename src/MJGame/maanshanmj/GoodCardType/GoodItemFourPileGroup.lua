--- zhangyl date 2016/11/25 13:05
local MJConst = require("mj_core.MJConst")
local GoodCardType = require("GoodCardType.GoodCardType")
local typeName = GoodCardType.typeName
local GoodItemFourPileGroup = class("GoodItemFourPileGroup")
local GoodCardTypeItemGroup = require("GoodCardType.GoodCardTypeItemGroup")

function GoodItemFourPileGroup:ctor()  --- 共同代码
    self.goodCardTypeItemGroup = GoodCardTypeItemGroup.new()
	self.siType = GoodCardType.combinationType.Four
	self:init()
end

function GoodItemFourPileGroup:clear()  --- 共同代码
    self.goodCardTypeItemGroup:clear()
end

function GoodItemFourPileGroup:init()
    self:initData()
    self:shuffle()
end

function GoodItemFourPileGroup:initData()
	--- 初始化 四張杠
	for suit = MJConst.kMJSuitWan, MJConst.kMJSuitTong  do
        for point = MJConst.kMJPoint1, MJConst.kMJPoint9 do
            local cardList = {}
			for i = 1, 4 do 
				local tempValue = point + suit * MJConst.kMJPointNull
                table.insert(cardList, tempValue)
			end
            self.goodCardTypeItemGroup:addItem(suit, cardList)
		end
	end	
end

function GoodItemFourPileGroup:getItemBySuit(_suit) --- 共同代码
    return self.goodCardTypeItemGroup:getItemBySuit(_suit)
end

function GoodItemFourPileGroup:getValidSuit()   ---- 共同代码
    return self.goodCardTypeItemGroup:getValidSuit()
end

function GoodItemFourPileGroup:shuffle()    ----共同代码
    self.goodCardTypeItemGroup:shuffle()
end

function GoodItemFourPileGroup:deleteItem(_card)
    self.goodCardTypeItemGroup:deleteItem(_card, true)
end

return GoodItemFourPileGroup