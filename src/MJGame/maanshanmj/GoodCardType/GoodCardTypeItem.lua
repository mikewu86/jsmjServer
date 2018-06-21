---- zhangyl 2016/11/25 8:45
---- 仅用于数据的存储

local GoodCardTypeItem = class("GoodCardTypeItem")

function GoodCardTypeItem:ctor()
	self.cardList = {}
	self.suit = 0
end

function GoodCardTypeItem:clear()
	self.cardList = {}
end

return GoodCardTypeItem