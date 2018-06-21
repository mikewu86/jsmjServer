package.path = "./?.lua;./unittest/?.lua;../../global/?.lua;" .. package.path
package.path = "../../common/?.lua;../../MJGame/?.lua;" .. package.path
function _logoutput(loglevel, msg)
	print(msg)
end
require "functions"
local GameProgress = require("GameProgress")
local testcase = require("testcase")
local MJConst = require("mj_core.MJConst")
local MJPile = require("mj_core.MJPile")
local CountHuType = require("CountHuType")
local mjMath = require("mj_core.MJMath")

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
	['1万'] = MJConst.Wan1, ['2万'] = MJConst.Wan2, ['3万'] = MJConst.Wan3,
	['4万'] = MJConst.Wan4, ['5万'] = MJConst.Wan5, ['6万'] = MJConst.Wan6,
	['7万'] = MJConst.Wan7, ['8万'] = MJConst.Wan8, ['9万'] = MJConst.Wan9,
	['1筒'] = MJConst.Tong1, ['2筒'] = MJConst.Tong2, ['3筒'] = MJConst.Tong3,
	['4筒'] = MJConst.Tong4, ['5筒'] = MJConst.Tong5, ['6筒'] = MJConst.Tong6,
	['7筒'] = MJConst.Tong7, ['8筒'] = MJConst.Tong8, ['9筒'] = MJConst.Tong9,
	['1条'] = MJConst.Tiao1, ['2条'] = MJConst.Tiao2, ['3条'] = MJConst.Tiao3,
	['4条'] = MJConst.Tiao4, ['5条'] = MJConst.Tiao5, ['6条'] = MJConst.Tiao6,
	['7条'] = MJConst.Tiao7, ['8条'] = MJConst.Tiao8, ['9条'] = MJConst.Tiao9,
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
		pile:setPile(#cards, cardList, true, pos1, operMap[oper])
		table.insert(player.pileList, pile)
	end
end

local checkResult = function(isZiMo, poses, pos1, byteCard, args, _result)
	local isHu = false
	if isZiMo then
		isHu = playingState:checkSelfHu(poses[1])
	else
		for _, pos in pairs(poses) do
			isHu = playingState:canHuOther(pos, pos1, byteCard)
		end
	end

	if isHu == _result.canHu then
		if isHu then
			endState:initCountHuType(args)
			local result = endState:calculate(args)
			-- dump(result.details, '详细胡牌列表')
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
			for i = 1, #huLists do
				local l = huLists[i]
				local r = _result.huLists[i]
				if #l ~= #r then
					dump(r, '期望牌型列表')
					dump(l, '实际牌型列表')
					assert(false, _result.desc..'胡牌类型有误')
				end
				table.sort(l)
				table.sort(r)
				for j = 1, #l do
					if l[j] ~= r[j] then
						dump(r, '期望牌型列表')
						dump(l, '实际牌型列表')
						assert(false, '胡牌类型出错')
					end
				end
			end
			print('=================='.._result.desc..'测试OK 索引号为'..runningIndex)
		else
			print('=================='.._result.desc..'测试OK 索引号为'..runningIndex)
		end
	else
		assert(false, '=================='.._result.desc..' ==测试FAIL 索引号为'..runningIndex)
	end
end

-- deal the tese case
for index, v in pairs(testcase) do
	runningIndex = index
	local args = v.resultArgs
	args.huCard = cardMap[args.huCard]
	gameProgress:clear()
	--v
	if v.wall then
		gameProgress.mjWall.wallConfigMap = v.wall
		gameProgress.mjWall:init()
	end
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
	--
	if v.river then
		for pos, cards in pairs(v.river) do
			local river = gameProgress.riverCardList[pos]
			for _, card in pairs(cards) do
				river:pushCard(cardMap[card])
			end
		end
	end
	-- done cards
	for pos, piles in pairs(v.piles) do
		for _, pile in pairs(piles) do
			addPile(pile.pos, pile.oper, pile.cards, pile.pos1)
		end
	end
	--
	gameProgress.isZhuangXian = true
	gameProgress.isLiangZhuang = true
	gameProgress.banker = 1
	if args.banker ~= nil then
		gameProgress.banker = args.banker
	end

	gameProgress.bankerCount = 1
	if args.bankerCount ~= nil then
		gameProgress.bankerCount = args.bankerCount
	end
	checkResult(args.isZiMo, args.winnerPosList, 
	args.fangPaoPos, args.huCard, args, v.result)
end

-- print('-- test math--')
-- math = mjMath.new()
-- local mmap = {0,0,1,1,0,0,0,0,0,0,
-- 			  0,0,0,1,1,1,0,0,0,0,
-- 			  2,0,0,0,0,0,0,0,0,0,
-- 			  0,0,0,0,0,0,0}
-- 			  mmap[0] = 1
-- -- dump(mmap, 'mmap = ')
-- print('can hu = ',math:canHu(mmap))
