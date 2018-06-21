---- zhangyl 2016/11/25 8:39
---- 此类作为管理类进行使用
---- 所有的初始化都是按照顺序，取得时候使用随机数
---- 取后更新每一个张牌的使用数量
---- 最后使用同一接口刷新所有的顺子 刻子 杠 的内存 
---- 现在考虑的是删除和采用标志的方式进行处理
local GoodCardManage = class("GoodCardManage")
local GoodItemJunkoGroup = require("GoodCardType.GoodItemJunkoGroup")
local GoodItemThreePileGroup = require("GoodCardType.GoodItemThreePileGroup")
local GoodItemFourPileGroup = require("GoodCardType.GoodItemFourPileGroup")
local combType = require("GoodCardType.GoodCardType").combinationType
local MJConst = require("mj_core.MJConst")

function GoodCardManage:ctor(_wallConfig)
	self.handCards = {}     ---  存储玩家分配的牌
	self.wallConfig = _wallConfig or {   --牌墙配置, 与外面的牌墙的初始化统一使用
        4, 4, 4, 4, 4, 4, 4, 4, 4,
        4, 4, 4, 4, 4, 4, 4, 4, 4,
        4, 4, 4, 4, 4, 4, 4, 4, 4,
        4, 4, 4, 4, 4, 4, 4,
        0, 0, 0, 0, 0, 0, 0, 0
    }
    self.itemList = {}    --- 如果后期项目有扩展需要在init中增加
end 

function GoodCardManage:init()
	local junko = GoodItemJunkoGroup.new()
	self.itemList[junko.siType] = junko
	local threePile = GoodItemThreePileGroup.new()
	self.itemList[threePile.siType] = threePile
	local fourPile = GoodItemFourPileGroup.new()
	self.itemList[fourPile.siType] = fourPile
end

function GoodCardManage:clear()
	self.handCards = {}
	self.wallConfig = {}
	self.itemList = {}
end

function GoodCardManage:getGoodCards(pos, typeList)
    self.handCards[pos] = {}
	local bSameSuit = typeList.bSameSuit
	local sameNum = typeList.SameNum
	local cardTypes = typeList.cardTypes
	local tempSameNum = 0
	local bFetchMax = true
	local suit = -9999
	for _, siType in pairs(cardTypes) do 
		if true == bFetchMax then 
			local bRet, item = self.itemList[siType]:getValidSuit()
			if true == bRet then
                suit = item.suit
				if true == bSameSuit then
					if suit == item.suit then
						tempSameNum = tempSameNum + #item.cardList
					else
						tempSameNum = #item.cardList
					end

                    if sameNum < tempSameNum then
						bSameSuit = false
					else
                        bFetchMax = false
					end
				end
				self:updateCardMap(item.cardList)
                self:updatePlayerCards(pos, item.cardList)
			end
		else
		    LOG_DEBUG("suit:"..suit)
			local bRet, item = self.itemList[siType]:getItemBySuit(suit)
			if true == bRet then
				if true == bSameSuit then
					if suit == item.suit then
                        tempSameNum = tempSameNum + #item.cardList
                    else
                        if tempSameNum < #item.cardList then
                            tempSamNum = #item.cardList
                        end
					end
                    if sameNum - 1 < tempSameNum then
                        bSameSuit = false
                        bFetchMax = true
                    end
				end
				self:updateCardMap(item.cardList)
                self:updatePlayerCards(pos, item.cardList)
			else
                bFetchMax = true
                bSameSuit = false
			end
		end
	end

end

function GoodCardManage:updateCardMap(cards)
	for _, card in pairs(cards) do 
        LOG_DEBUG("count:"..self.wallConfig[card])
        if self.wallConfig[card] > 0 then
            LOG_DEBUG("card "..card.."count:"..self.wallConfig[card])
			self.wallConfig[card] = self.wallConfig[card] - 1
			self:updateCardType(card)
		end
	end
end

function GoodCardManage:updateCardType(card)
	local suit = math.floor(card / MJConst.kMJPointNull)
	local count  = self.wallConfig[card]
	if 3 == count then
		self.itemList[combType.Four]:deleteItem(card)
	elseif 2 == count or 1 == count then
		self.itemList[combType.Four]:deleteItem(card)
		self.itemList[combType.Three]:deleteItem(card)
	elseif 0 == count then
		self.itemList[combType.Junko]:deleteItem(card)
        self.itemList[combType.Four]:deleteItem(card)
        self.itemList[combType.Three]:deleteItem(card)
	end
end

function GoodCardManage:updatePlayerCards(pos, cards)
    for _, card in pairs(cards) do 
        table.insert(self.handCards[pos], card)
    end
end

return GoodCardManage