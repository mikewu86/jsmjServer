package.path = "./?.lua;./unittest/?.lua;../../global/?.lua;" .. package.path
package.path = "../../common/?.lua;../../MJGame/?.lua;" .. package.path
function _logoutput(loglevel, msg)
	print(msg)
end
require "functions"
local GameProgress = require("GameProgress")
local testcase = require("testcase")
local testcaseextra = require("testcaseextra")
local MJConst = require("mj_core.MJConst")
local MJPile = require("mj_core.MJPile")
local CountHuType = require("CountHuType")


local runningIndex = 1
-- make the room table for test
local room = {}
room.host = 1
room.send_request = function(a, b)
end
room.broadcastMsg = function(eName, data, exceptSeat)
end
room.roundTime = 1
room.fangInfo = {RoomRule = {}, RoundCount = 1}
--------------------------------------------------
local cardMap = {
	['一万'] = MJConst.Wan1, ['二万'] = MJConst.Wan2, ['三万'] = MJConst.Wan3,
	['四万'] = MJConst.Wan4, ['五万'] = MJConst.Wan5, ['六万'] = MJConst.Wan6,
	['七万'] = MJConst.Wan7, ['八万'] = MJConst.Wan8, ['九万'] = MJConst.Wan9,
	['一筒'] = MJConst.Tong1, ['二筒'] = MJConst.Tong2, ['三筒'] = MJConst.Tong3,
	['四筒'] = MJConst.Tong4, ['五筒'] = MJConst.Tong5, ['六筒'] = MJConst.Tong6,
	['七筒'] = MJConst.Tong7, ['八筒'] = MJConst.Tong8, ['九筒'] = MJConst.Tong9,
	['一条'] = MJConst.Tiao1, ['二条'] = MJConst.Tiao2, ['三条'] = MJConst.Tiao3,
	['四条'] = MJConst.Tiao4, ['五条'] = MJConst.Tiao5, ['六条'] = MJConst.Tiao6,
	['七条'] = MJConst.Tiao7, ['八条'] = MJConst.Tiao8, ['九条'] = MJConst.Tiao9,
	['东'] = MJConst.Zi1, ['南'] = MJConst.Zi2, ['西'] = MJConst.Zi3,
	['北'] = MJConst.Zi4, ['中'] = MJConst.Zi5, ['发'] = MJConst.Zi6,
	['白'] = MJConst.Zi7,
	['梅'] = MJConst.Hua1, ['兰'] = MJConst.Hua2, ['竹'] = MJConst.Hua3,
	['菊'] = MJConst.Hua4, ['春'] = MJConst.Hua5, ['夏'] = MJConst.Hua6,
	['秋'] = MJConst.Hua7, ['冬'] = MJConst.Hua8,
	['财'] = MJConst.Cai, ['宝'] = MJConst.Bao, ['猫'] = MJConst.Mao,
	['鼠'] = MJConst.Shu, ['大白'] = MJConst.Blank, ['百搭'] = MJConst.Baida,
}

local operMap = {
	['左吃'] = MJConst.kOperLChi, ['中吃'] = MJConst.kOperMChi, ['右吃'] = MJConst.kOperRChi,
	['碰'] = MJConst.kOperPeng, ['明杠'] = MJConst.kOperMG, ['暗杠'] = MJConst.kOperAG,
	['杠'] = MJConst.kOperMG,
	['面下杠'] = MJConst.kOperMXG, ['补花'] = MJConst.kOperBuHua, ['吃'] = MJConst.kOperLChi,
	['无'] = MJConst.kOperNull, ['新牌'] = MJConst.kOperNewCard
}

local gameProgress = GameProgress.new(room, 1, 1)
gameProgress.mjWall:init()
gameProgress.roomRuleMap.cz_playrule_7dui = true
local endState = gameProgress.gameStateList[gameProgress.kGameEnd]
local playingState = gameProgress.gameStateList[gameProgress.kGamePlaying]

local fillHandCards = function(pos, cards)
	local player = gameProgress.playerList[pos]
	if player then
		for _, v in pairs(cards) do
			player:addHandCard(cardMap[v])
		end
	end
end

local setNewCard = function(pos, card)
	local player = gameProgress.playerList[pos]
	if player then
		dump(player, "addNewCard"..cardMap[card])
		player:addNewCard(cardMap[card])
	end
end

local fillHua = function(pos, cards)
	local player = gameProgress.playerList[pos]
	if player then
		for _, v in pairs(cards) do
			player:addHua(cardMap[v])
		end
	end
end

local fillOper = function(pos, opers)
	local player = gameProgress.playerList[pos]
	if player then
		player.opHistoryList = {}
		for _, v in pairs(opers) do
			table.insert(player.opHistoryList, operMap[v])
		end
	end
end

local addPile = function(pos, oper, cards, pos1)
	local player = gameProgress.playerList[pos]
	if player then
		local pile = MJPile.new()
		local cardList = {}
		for _, card in pairs(cards) do
			table.insert(cardList, cardMap[card])
		end
		dump(operMap[oper], "operMap[oper]")
		if oper == "面下杠" then
			player.pileList[1]:setPile(#cards, cardList, true, pos1, operMap[oper])
		else
			pile:setPile(#cards, cardList, true, pos1, operMap[oper])
			table.insert(player.pileList, pile)
		end
	end
	dump(player.pileList, "player.pileList")
end

local checkResult = function(isZiMo, poses, pos1, byteCard, args, _result)
	local isHu = false
	if isZiMo then
		isHu = playingState:checkSelfHu(poses[1])
	else
		for _, pos in pairs(poses) do
			dump(pos, "winPos")
			isHu = playingState:canHuOther(pos, pos1, byteCard, args.isQiangGang)
		end
	end
	dump(isHu, "isHU")
	dump(_result, "_result")
	if isHu == _result.canHu then
		if isHu then
			endState:initCountHuType(args)
			local result = endState:calculate(args)
			dump(result.details, '详细胡牌列表')
			local money = result.money
			local huLists = {}
			for pos, v in pairs(endState.countHuTypeList) do
				if v.huTypeList then
					table.insert(huLists, v.huTypeList)
				else
					table.insert(huLists, {})
				end
			end
			for i = 1, #money do
				if money[i] ~= _result.money[i] then
					dump(_result.money, '期望分数')
					dump(money, '实际分数')
					assert(false, _result.desc..'结算分数出错')
				end
			end
			dump(_result.huLists, '期望牌型列表')
			dump(huLists, '实际牌型列表')
			for i = 1, #huLists do
				local l = huLists[i]
				local r = _result.huLists[i]
				if #l ~= #r then
					assert(false, _result.desc..'胡牌类型有误')
				end
				table.sort(l)
				table.sort(r)
				for j = 1, #l do
					if l[j] ~= r[j] then
						dump(l, '期望牌型列表')
						dump(r, '实际牌型列表')
						assert(false, '胡牌类型出错')
					end
				end
			end
		end
		print( _result.desc..' 测试通过 索引号为'..runningIndex)
	else
		assert(false, _result.desc..' 测试出错 索引号为'..runningIndex)
	end
end

-- deal the tese case
for index, v in pairs(testcase) do
	runningIndex = index
	local args = v.resultArgs
	args.huCard = cardMap[args.huCard]
	gameProgress:clear()
	playingState:onEntry()
	-- hua
	for pos, cards in pairs(v.huaList) do
		fillHua(pos, cards)
	end
	-- fill handcard
	for pos, cards in pairs(v.handcards) do
		fillHandCards(pos, cards)
	end
	--
	for pos, card in pairs(v.newcards) do
		setNewCard(pos, card)
	end
	--
	for pos, opers in pairs(v.justDoOper) do
		fillOper(pos, opers)
	end
	-- done cards
	for pos, piles in pairs(v.piles) do
		for _, pile in pairs(piles) do
			dump(pile, "pile")
			addPile(pile.pos, pile.oper, pile.cards, pile.pos1)
		end
	end
	--
	checkResult(args.isZiMo, args.winnerPosList, 
	args.fangPaoPos, args.huCard, args, v.result)
end

for index, v in pairs(testcaseextra) do
	gameProgress.roomRuleMap.cz_playrule_dlg = false
	gameProgress.roomRuleMap.cz_playrule_b4g = false
	gameProgress.roomRuleMap.cz_playrule_b6g = false
	print("testing "..v.flag.desc)
	if v.flag.dlg == true then
		gameProgress.roomRuleMap.cz_playrule_dlg = true
	elseif v.flag.bgt4 == true then
		gameProgress.roomRuleMap.cz_playrule_b4g = true
	elseif v.flag.bgt6 == true then
		gameProgress.roomRuleMap.cz_playrule_b6g = true
	end
	local cards = {}
	for _, str in pairs(v.cards) do 
		table.insert(cards, cardMap[str])
	end
	local fans = gameProgress:calcExtraFans(v.zhuangPos, v.winPos, cards)
	for pos, score in pairs(v.result) do
		if fans[pos] ~= score then
			dump(fans, "计算结果")
			dump(v.result, "期待结果")
			assert(fans[pos] == score, "额外验证失败 index"..index)
		end
	end
	print("额外验证通过 index"..index)

end