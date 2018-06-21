--- Author: zhangyl
--- Date:   2016/8/29
--- test mj type
--- card from new pool dif from game's
--- 1. check card valid
--- 2. return result
--- 3. notify game delete self player hand cards pengcards.
local skynet = require("skynet")
local algorithm  =  require("MJAlgorithm")
local MJGROUP = {
	NJMJ = 1, --- nanjingmj
	SZMJ = 2, --- suzhoumj
	HFMJ = 3, --- hefeimj
	WHMJ = 4, --- wuhumj
}

local MJType = {}



--- card is byte
local cardPool = nil

function MJType.initCard()
	if not cardPool then
		cardPool = {} 
		if algorithm then
			algorithm.randomInitCards(cardPool)
		end
	end
end

function MJType.checkCards(_cards)
	MJType.initCard()
	local bRes = false
	if not _cards or "table" ~= type(_cards) or #_cards < 1 then
		LOG_DEBUG("cards arg invalid")
		return false
	else 
		for _, card in pairs(_cards) do
			bRes = MJType.checkCard(card)
			if not bRes then
				return false
			end
		end			
	end
	
	return true
end

function MJType.checkCard(_card)
	if not _card or "number" ~= type(_card) then
		LOG_DEBUG("_card type error")
		return false
	else
		for _, data in pairs(cardPool) do 
			if data == _card then
				return true
			end
		end
		LOG_DEBUG("not found")
		return false
	end
end

return MJType
