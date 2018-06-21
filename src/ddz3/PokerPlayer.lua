local BasePlayer = require("base.BasePlayer")
local PokerPlayer = class("PokerPlayer", BasePlayer)
local skynet = require("skynet")
--local ByteArray = require("serialize.ByteArray")

function PokerPlayer:ctor()
	--	playing state
	self.playing = false

	--	logic data
	self:resetLogicData()
end

function PokerPlayer:resetLogicData()
	self.logicData = {}

	--	筹码
	self.logicData.chips = 0

	--	发到手上的牌
	self.logicData.cards = {}

	--	是否盖牌了
	self.logicData.fold = false

	--	可进行的操作
	self.logicData.operations = {}

	--	下注记录
	self.logicData.betList = {}
end

function PokerPlayer:isPlaying()
	return self.playing
end

function PokerPlayer:setPlaying(_playing)
	self.playing = _playing
end

function PokerPlayer:getChips()
	return self.logicData.chips
end

function PokerPlayer:setChips(_chips)
	self.logicData.chips = _chips
end

function PokerPlayer:incChips(_dif)
	self.logicData.chips = self.logicData.chips + _dif
end

function PokerPlayer:decChips(_dif)
	local currentChips = self:getChips()
	if currentChips < _dif then
		self.logicData.chips = 0
		geLogError("decChips: total chips:"..currentChips.." dec chips:".._dif)
	else
		self.logicData.chips = self.logicData.chips - _dif
	end
end

function PokerPlayer:isFold()
	return self.logicData.fold
end

function PokerPlayer:setFold(_fold)
	self.logicData.fold = _fold
end

function PokerPlayer:addCard(_card)
	table.insert(self.logicData.cards, _card)
end

function PokerPlayer:getCards()
	return self.logicData.cards
end

function PokerPlayer:getCardsCount()
	return #self.logicData.cards
end

function PokerPlayer:getLastCard()
	if #self.logicData.cards == 0 then return nil end
	return self.logicData.cards[self:getCardsCount()]
end


function PokerPlayer:hasCards(_cards)
	--local cardsCopy = clone(self.logicData.cards)
	if nil == self.logicData.cards then
		return false
	end
	local cardsCopy = table.clone(self.logicData.cards)
	if nil ==  cardsCopy then 
		return false 
	end
	for _, v in ipairs(_cards) do
		local find = false
		for i1, v1 in ipairs(cardsCopy) do
			if v == v1 then
				find = true
				table.remove(cardsCopy, i1)
				break
			end
		end

		if not find then
			return false
		end
	end

	return true
end

function PokerPlayer:removeCards(_cards)
	for _, v in ipairs(_cards) do
		for i1, v1 in ipairs(self.logicData.cards) do
			if v == v1 then
				table.remove(self.logicData.cards, i1)
				break
			end
		end
	end
end

function PokerPlayer:getBetList()
	return self.logicData.betList
end

function PokerPlayer:addBet(_bet)
	table.insert(self.logicData.betList, _bet)
end

function PokerPlayer:getTotalBet()
	local totalBet = 0

	for i, b in ipairs(self.logicData.betList) do
		totalBet = totalBet + b
	end

	return totalBet
end

function PokerPlayer:isAllIn()
	return self:getChips() == 0
end

function PokerPlayer:setOperations(_op)
	self.logicData.operations = _op
end

function PokerPlayer:getOperations()
	return self.logicData.operations
end

function PokerPlayer:checkOperation(_op)
	--return (bit.band(self.logicData.operations, math.pow(2, _op)) ~= 0)
	if nil == self.logicData.operations then return false end

	for i, v in ipairs(self.logicData.operations) do
		if v == _op then
			return true
		end
	end

	return false
end

function PokerPlayer:addOperation(_op)
	--local prevOperations = self.logicData.operations
	--local operations = bit.bor(prevOperations, math.pow(2, _op))
	--self:setOperations(operations)
	if nil == self.logicData.operations then return end

	for i, v in ipairs(self.logicData.operations) do
		if v == _op then
			return
		end
	end

	table.insert(self.logicData.operations, _op)
end

function PokerPlayer:updatePlayerInfo(playing)
	self.super.updatePlayerInfo(self)

	local uid = self:getUid()
	if 0 == uid then return end

	if nil ~= playing then
		self:setPlaying(playing)
	else
		skynet.error("updatePlayerInfo: get invalid player's data")
	end
end

function PokerPlayer:getMoney()
	local money = 0
	if self.agent then
		money = skynet.call(self.agent, "lua", "getMyCoin", "coin")		
	end
	return money
end

function PokerPlayer:updateMoney(_winMoney)
	if self.agent then
		local money = self:getMoney()
		local modifyValue = _winMoney
		if 0 > (money + _winMoney) then
			modifyValue = 0 - money
		end
		skynet.call(self.agent, "lua", "updateMoney", _winMoney, modifyValue,"ddz3","三人斗地主")
	end
end

function PokerPlayer:sendPakcet(_pkg)
	if nil == _pkg.ID then
		geLogError("send a invalid packet")
		return
	end

	--[[local buf = ByteArray.new(ByteArray.ENDIAN_BIG)
	_pkg:Write(buf)
	geSendBuffer(self:getUID(), _pkg.ID, buf:getPack())
	--]]
end


return PokerPlayer