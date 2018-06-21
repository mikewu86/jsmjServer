--- zhangyl date 2016/11/25 13:04
local MJConst = require("mj_core.MJConst")
local GoodCardType = require("GoodCardType.GoodCardType")
local typeName = GoodCardType.typeName
local GoodCardTypeItemGroup = require("GoodCardType.GoodCardTypeItemGroup")
local GoodItemThreePileGroup = class("GoodItemThreePileGroup")

function GoodItemThreePileGroup:ctor()  --- 共同代码
    self.goodCardTypeItemGroup = GoodCardTypeItemGroup.new()
	self.siType = GoodCardType.combinationType.Three
	self:init()
end

function GoodItemThreePileGroup:clear()  --- 共同代码
    self.goodCardTypeItemGroup:clear()
end

function GoodItemThreePileGroup:init()
    self:initData()
    self:shuffle()
end

function GoodItemThreePileGroup:initData()
	--- 初始化 三张刻子
	for suit = MJConst.kMJSuitWan, MJConst.kMJSuitTong  do
        for point = MJConst.kMJPoint1, MJConst.kMJPoint9 do
            local cardList = {}
			for i = 1, 3 do 
				local tempValue = point + suit * MJConst.kMJPointNull
                table.insert(cardList, tempValue)
			end
            self.goodCardTypeItemGroup:addItem(suit, cardList)
		end
	end	
end

function GoodItemThreePileGroup:getItemBySuit(_suit) --- 共同代码
    return self.goodCardTypeItemGroup:getItemBySuit(_suit)
end

function GoodItemThreePileGroup:getValidSuit()   ---- 共同代码
    return self.goodCardTypeItemGroup:getValidSuit()
end

function GoodItemThreePileGroup:shuffle()    ----共同代码
    self.goodCardTypeItemGroup:shuffle()
end

function GoodItemThreePileGroup:deleteItem(_card)
    self.goodCardTypeItemGroup:deleteItem(_card, true)
end

return GoodItemThreePileGroup