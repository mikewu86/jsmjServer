local skynet = require "skynet"
local BasePlayer = require("base.BasePlayer")
local PokerPlayer = class("PokerPlayer", BasePlayer)
local snax = require "snax"

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
	-- 下注记录按轮记录
	self.logicData.roundBetList = {}
end

function PokerPlayer:isPlaying()
	return self.playing
end

function PokerPlayer:setPlaying(_playing)
	self.playing = _playing
end

--从金币兑换筹码
function PokerPlayer:exchangeInChips(chipsAmount)
	LOG_DEBUG("PokerPlayer:exchangeInChips call")
    assert(chipsAmount > 0)
    local chipsAmount2 = 0 - math.abs(chipsAmount)
	
	if not self.user_dc then
		self.user_dc = snax.uniqueservice("userdc")
	end
	
	local beforeAmount = self.user_dc.req.getvalue(self:getUid(), "CoinAmount")
	
    local nRet = skynet.call(self.agent, "lua", "updateMoney",
            chipsAmount2,
            chipsAmount2,
            "德州筹码",
            "兑换筹码")
			
	local resultAmount
	if nRet == true then
		resultAmount = self.user_dc.req.getvalue(self:getUid(), "CoinAmount")
		        
    	if beforeAmount - resultAmount == chipsAmount then
        	self:incChips(chipsAmount)
			self:setMoney(resultAmount)
			
			--通知客户端
			local exchangeChipsRes = {}
			exchangeChipsRes.chipsAmount = chipsAmount
			exchangeChipsRes.moneyAmount = resultAmount
			self:sendMsg("exchangeChipsRes", exchangeChipsRes)
			
			return true
		else
			LOG_ERROR(string.format("PokerPlayer:exchangeInChips error, beforeAmount:%d resultAmount:%d wantedDiff:%d", beforeAmount, resultAmount, chipsAmount))
    		return false
		end
	else
		LOG_ERROR("PokerPlayer:exchangeInChips db error")
		return false
	end
end

--从筹码返回为金币
function PokerPlayer:exchangeOutChips()
	local chipsAmount = self:getChips()
	
	if not self.user_dc then
		self.user_dc = snax.uniqueservice("userdc")
	end
	
	local beforeAmount = self.user_dc.req.getvalue(self:getUid(), "CoinAmount")
	
	if chipsAmount > 0 then
		local nRet = skynet.call(self.agent, "lua", "updateMoney",
				chipsAmount,
				chipsAmount,
				"德州筹码",
				"返回退码")
		local resultAmount
		if nRet then
			resultAmount = self.user_dc.req.getvalue(self:getUid(), "CoinAmount")
			if resultAmount - beforeAmount == chipsAmount then
				self.logicData.chips = 0
			else
				LOG_DEBUG(string.format("PokerPlayer:exchangeOutChips error, beforeAmount:%d resultAmount:%d wantedDiff:%d", beforeAmount, resultAmount, chipsAmount))
			end
		else
			LOG_DEBUG("PokerPlayer:exchangeOutChips db error")
		end
	end
end

function PokerPlayer:getChips()
	return self.logicData.chips
end

function PokerPlayer:setChips(_chips)
	self.logicData.chips = _chips
	--同步到db
	local nRet = skynet.call(self.agent, "lua", "updateChips",
				_chips,
				self:getGameUUID())

end

function PokerPlayer:incChips(_dif)
	local tmpChips = self.logicData.chips + _dif
	self:setChips(tmpChips)
	--self.logicData.chips = self.logicData.chips + _dif
end

function PokerPlayer:decChips(_dif)
	local currentChips = self:getChips()
	if currentChips < _dif then
		self:setChips(0)
		--self.logicData.chips = 0
		LOG_ERROR("decChips: total chips:"..currentChips.." dec chips:".._dif)
	else
		local tmpChips = self.logicData.chips - _dif
		self:setChips(tmpChips)
		--self.logicData.chips = self.logicData.chips - _dif
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

function PokerPlayer:getBetList()
	return self.logicData.betList
end

function PokerPlayer:addBet(_bet, _round)
	table.insert(self.logicData.betList, _bet)
	if self.logicData.roundBetList[_round] then
		self.logicData.roundBetList[_round] = self.logicData.roundBetList[_round] + _bet
	else
		self.logicData.roundBetList[_round] = _bet
	end
end

function PokerPlayer:getRoundBet(_round)
	if self.logicData.roundBetList[_round] then
		return self.logicData.roundBetList[_round]
	else
		return 0
	end
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
    
    --判断用户有没有筹码  如果没有筹码的话需要补充筹码
    if self:getChips() <= 0 then
    
    end

	--local playing = geGetPlayerInfo(uid, "playing")
	if nil ~= playing then
		self:setPlaying(playing)
	else
		--LOG_ERROR("updatePlayerInfo: get invalid player's data")
	end
end



return PokerPlayer