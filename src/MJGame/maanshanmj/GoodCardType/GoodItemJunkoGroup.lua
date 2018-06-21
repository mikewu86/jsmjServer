--- zhangyl date 2016/11/25 13:06
local MJConst = require("mj_core.MJConst")
local GoodCardType = require("GoodCardType.GoodCardType")
local GoodItemJunkoGroup = class("GoodItemJunkoGroup")
local GoodCardTypeItemGroup = require("GoodCardType.GoodCardTypeItemGroup")

function GoodItemJunkoGroup:ctor()
    self.siType = GoodCardType.combinationType.Junko
    self.goodCardTypeItemGroup = GoodCardTypeItemGroup.new()
    self:init()
end

function GoodItemJunkoGroup:clear()
    self.goodCardTypeItemGroup:clear()
end

function GoodItemJunkoGroup:init()
    self:initData()
    self:shuffle()
end

function GoodItemJunkoGroup:initData()
--- 用于三顺子的初始化
	local tbTemp = {
                    {MJConst.kMJPoint1, MJConst.kMJPoint2, MJConst.kMJPoint3},
					{MJConst.kMJPoint2, MJConst.kMJPoint3, MJConst.kMJPoint4},
					{MJConst.kMJPoint3, MJConst.kMJPoint4, MJConst.kMJPoint5},
					{MJConst.kMJPoint4, MJConst.kMJPoint5, MJConst.kMJPoint6},
					{MJConst.kMJPoint5, MJConst.kMJPoint6, MJConst.kMJPoint7},
					{MJConst.kMJPoint6, MJConst.kMJPoint7, MJConst.kMJPoint8},
					{MJConst.kMJPoint7, MJConst.kMJPoint8, MJConst.kMJPoint9},
				}
	for suit = MJConst.kMJSuitWan, MJConst.kMJSuitTong  do
		for _, item in pairs(tbTemp) do
            local cardList = {}
			for _, card in pairs(item) do
                local tempValue = card + suit * MJConst.kMJPointNull
                table.insert(cardList, tempValue)
		    end
            self.goodCardTypeItemGroup:addItem(suit, cardList)
		end	
	end
end

function GoodItemJunkoGroup:getItemBySuit(_suit)
    return self.goodCardTypeItemGroup:getItemBySuit(_suit)
end

function GoodItemJunkoGroup:getValidSuit()
    return self.goodCardTypeItemGroup:getValidSuit()
end

function GoodItemJunkoGroup:shuffle()
    self.goodCardTypeItemGroup:shuffle()
end

function GoodItemJunkoGroup:deleteItem(_card)
    self.goodCardTypeItemGroup:deleteItem(_card, false)
end

return GoodItemJunkoGroup