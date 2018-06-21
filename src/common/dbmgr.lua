--
-- Author: Liuq
-- Date: 2016-04-19 14:26:22
--
local skynet = require "skynet"
require "skynet.manager"
local mongo = require "mongo"
local bson = require "bson"


local db
local CMD = {}

local platformCollection = skynet.getenv "platformCollection" or "dev_nanjingmj"
local gameCollection = skynet.getenv "gameCollection" or "dev_texas_record"

local function getCollection(dbName, colName)
	return db[dbName][colName]
end

local function getNextId(dbName, colName)
	local doc = {query = { name = colName}, new = true, upsert = true, update = {["$inc"] = {nextid = 1}},}
	local ret = getCollection(dbName, "seq"):findAndModify(doc)
	assert(ret and ret.value.nextid > 0)
	
	return ret.value.nextid
end

local function clearFangRoomHistoryCache(roomId)
	local redismgr = skynet.uniqueservice("redismgr")
	local ret = getCollection(platformCollection, "FangRoomHistory"):findOne({ RoomRId = roomId})
	if ret and ret.rounddata and ret.result then
		for _, value in pairs(ret.result) do
			local cacheKey = "roomhistory-"..tostring(value.uid)
			skynet.call(redismgr, "lua", "del_key", cacheKey)
			LOG_DEBUG("roomid:"..roomId.." uid:"..value.uid.." cacheKey:"..cacheKey.." clear in redis")
		end
	end
end

function CMD.find_GameServerNode_single(nodeid)
	local ret = getCollection(platformCollection, "GameServerNode"):findOne({ NodeId = nodeid})
	-- assert(ret)
	return ret
end

function CMD.update_UserLastLobbyNode(uid, nodeid, nodeName)
	local docUserMap = {}
	docUserMap.query = {
		GameUid = uid
	}
	docUserMap.update = {["$set"] = { LobbyNodeId = nodeid, LobbyNodeName = nodeName, LastLobbyTime = bson.date(os.time()) }}
	ret = getCollection(platformCollection, "FangUserAtLobbyNode"):update(docUserMap.query, docUserMap.update, 0, 1)
	return ret
end

function CMD.find_Fang_single(roompassword)
	local ret = getCollection(platformCollection, "FangRoom"):findOne({ RoomPassword = roompassword, RoomStatus = {['$lt'] = kVipRoomState.gameover}})
	-- assert(ret)
	return ret
end

function CMD.find_Fang_single_byroomid(roomId)
	local ret = getCollection(platformCollection, "FangRoom"):findOne({ RoomRId = roomId})
	assert(ret)
	return ret
end

-- 更新开房模式的房间房间内的用户数量，在room有人enter或leave的时候都需要调用一下
-- roomId 房间id
-- currentUserCount 当前人数
function CMD.update_Fang_OnlineUser(roomId, currentUserCount)
	LOG_DEBUG('update_Fang_OnlineUser roomId '..roomId..' currentUserCount'..currentUserCount)
	local doc = {
		query = { RoomRId = roomId}, 
		new = true, 
		upsert = true, 
		update = {["$set"] = { UserCount = currentUserCount }},
	}
	local ret = getCollection(platformCollection, "FangRoom"):findAndModify(doc)
	assert(ret and ret.value.UserCount == currentUserCount)
	dump(ret, 'update_Fang_OnlineUser ret = ')
	return true
end

--更新玩家在房间中的状态，在玩家落座和主动离开房间的时候调用
--roomId 房间id
--uid 用户id
--isPlayer  落座的时候true  离坐的时候false
-- player的服务地址
function CMD.update_Fang_Player_status(roomId, uid, isPlayer, playeraddr)
	doc = { 
		query = {
			RoomRId = roomId,
			GameUId = uid
		}, 
		new = false, 
		upsert = true, 
		update = {
			["$set"] = { 
				IsPlayer = isPlayer
			}
		},
	}
	local ret = getCollection(platformCollection, "FangRoomUserMap"):findAndModify(doc)
	assert(ret and ret.value.RoomRId > 0)
	if playeraddr then
		CMD.set_roomplayer_serviceaddr(roomId, uid, playeraddr)
	end
end


--更新开房模式的数据库中房间状态, 在房间开始、结束、取消的时候都需要调用一下以及时更新状态和时间戳
--roomId 房间id
--roomStatus 状态
-- ptrjeffrey 状态已常量在enums.lua kVipRoomState中
--  0:等待开始(初始状态，由api服务器生成)
--  1:正在游戏(由游戏服务器控制修改)
--  2:游戏结束(由游戏服务器控制修改)
--  3:房间已解散(由游戏服务器控制修改)
--roomPlayers 房间中正式的游戏玩家   当roomStatus=正在游戏 的时候需要传入该值，该值为用户id的数组 其他状态下可不传
-- 如果更新成功返回true  否则返回false
function CMD.update_Fang_status(roomId, roomStatus, roomPlayers)
	local doc = {}
	local docUserMap = {}
	local docRoomHistory = {}
	LOG_DEBUG('roomPlayers = '..roomStatus)
	--dump(roomPlayers, 'roomPlayers = ')
	if roomStatus == kVipRoomState.playing then
		doc = {query = { RoomRId = roomId}, new = false, upsert = true, update = {["$set"] = { RoomStatus = roomStatus, GameBeginTime = bson.date(os.time()) }},}
		if roomPlayers then
			docUserMap.query = {
				RoomRId = roomId,
				GameUId = { ["$in"] = roomPlayers }
			}

			docUserMap.update = {["$set"] = { IsPlayer = true }}
		end
		--docRoomHistory.query = {
		--	RoomRId = roomId
		--}
		--docRoomHistory.update = {["$set"] = { BeginTime = bson.date(os.time()) }}
	elseif roomStatus == kVipRoomState.gameover then
		doc = {query = { RoomRId = roomId}, new = false, upsert = true, update = {["$set"] = { RoomStatus = roomStatus, GameEndTime = bson.date(os.time()) }},}
		docUserMap.query = {
			RoomRId = roomId
		}
		docUserMap.update = {["$set"] = { IsPlayer = false }}
		docRoomHistory.query = {
			RoomRId = roomId
		}
		local newHistoryId = getNextId(platformCollection, "FangRoomHistory")
		docRoomHistory.update = {["$set"] = { EndTime = bson.date(os.time()), RId = newHistoryId }}
	elseif roomStatus == kVipRoomState.disband then
		doc = {query = { RoomRId = roomId}, new = false, upsert = true, update = {["$set"] = { RoomStatus = roomStatus, CancelTime = bson.date(os.time()) }},}
		docUserMap.query = {
			RoomRId = roomId
		}
		docUserMap.update = {["$set"] = { IsPlayer = false }}
		docRoomHistory.query = {
			RoomRId = roomId
		}
		local newHistoryId = getNextId(platformCollection, "FangRoomHistory")
		docRoomHistory.update = {["$set"] = { EndTime = bson.date(os.time()), RId = newHistoryId }}
	else
		LOG_DEBUG("update_Fang_status roomStatus is not valid")
		return false
	end
	
	local ret = getCollection(platformCollection, "FangRoom"):findAndModify(doc)
	assert(ret and ret.value.RoomRId > 0)
	if docUserMap then
		ret = getCollection(platformCollection, "FangRoomUserMap"):update(docUserMap.query, docUserMap.update, 0, 1)
	end
	-- update FangRoomHistory endtime
	if roomStatus == kVipRoomState.gameover or roomStatus == kVipRoomState.disband then
		if docRoomHistory then
			ret = getCollection(platformCollection, "FangRoomHistory"):findOne({ RoomRId = roomId})
			if ret and ret.rounddata and ret.result then
				ret = getCollection(platformCollection, "FangRoomHistory"):update(docRoomHistory.query, docRoomHistory.update, 0, 1)
				-- 清除redis中的缓存
				clearFangRoomHistoryCache(roomId)
			end
		end
	end
	return true
end

function CMD.get_fang_history(roomId)
	local fangHistory = getCollection(platformCollection, "FangRoomHistory"):findOne({ RoomRId = roomId})
	return fangHistory
end

-- 记录用户的解散操作
-- roomId 房间号
-- uid 用户id
-- idx 第几轮解散
-- status 1 允许解散  0 不允许解散
-- isfirst 是否是发起人  true 发起人  false 非发起人
function CMD.addDisbandLog(roomId, uid, idx, status, isfirst)
	local logitem = {}
	logitem.idx = idx
	logitem.uid = uid
	logitem.ret = status
	logitem.first = isfirst

	local docFangRoom = { 
		query = { RoomRId = roomId }, 
		new = false, 
		upsert = true, 
		update = {["$push"] = { disbandlog = logitem}}
	}
	-- LOG_DEBUG('-- refund 3--'..roomId)
	local retFangRoom = getCollection(platformCollection, "FangRoom"):findAndModify(docFangRoom)
	if not retFangRoom then
		LOG_DEBUG("addDisbandLog error roomid not exists! roomid:"..roomid)
	end
end

-- 退回开房所用的房卡，用在玩家一局没有结束的时候解散游戏的情况
-- 注意：根据游戏规则请确保调用这个函数的时候玩家第一局游戏没有结束掉
-- 作为安全监测如果发现有FangRoomHistory存在的情况下退款动作将不生效
-- 2017.3.17 zhangxiao 如果服务器要强制退费，则还是要退
function CMD.fang_Refund_card(roomId, force)
	-- LOG_DEBUG('-- refund 1--'..roomId)
	local fangHistory = getCollection(platformCollection, "FangRoomHistory"):findOne({ RoomRId = roomId})
	--如果有过游戏记录就抛出异常
	-- assert(fangHistory == nil, "Refund must the room not finish any round!")

	if fangHistory then
		if not force then
			return
		end
	end

	-- LOG_DEBUG('-- refund 2--'..roomId)

	--上锁 避免重复调用
	local docFangRoom = { 
		query = { RoomRId = roomId, IsRefund = false }, 
		new = false, 
		upsert = false, 
		update = {["$set"] = { IsRefund = true }},
	}
	-- LOG_DEBUG('-- refund 3--'..roomId)
	local retFangRoom = getCollection(platformCollection, "FangRoom"):findAndModify(docFangRoom)
	assert(retFangRoom and retFangRoom.value.IsRefund == false, "refund must roomid exists and IsRefund == false")
	if not retFangRoom.value then
		return
	end
	-- LOG_DEBUG('-- refund 4--'..roomId)
	local fangRoom = retFangRoom.value
	local uid = fangRoom.OwnerUserId

	local wantedamount = fangRoom.FangCard
	local modifyamount = wantedamount

	local docUser = { 
		query = { Uid = uid }, 
		new = true, 
		upsert = false, 
		update = {["$inc"] = { FangCard = wantedamount }},
	}
	-- LOG_DEBUG('-- refund 5--'..roomId)
	local ret = getCollection(platformCollection, "GameUser"):findAndModify(docUser)
	assert(ret and ret.value.Uid == uid)
	local resultAmount = ret.value.FangCard
	local prevAmount = resultAmount - modifyamount
	local newId = getNextId(platformCollection, "UserFangCardLog")
	local doclog = {
		RId = newId,
		CurrentAmount = prevAmount,
		WantedAmount = wantedamount,
		ModifyAmount = modifyamount,
		ResultAmount = resultAmount,
		ModuleName = "解散返还",
		Remark = "roomid:"..tostring(roomId),
		UserIPAddr = "127.0.0.1",
		WriteTime = bson.date(os.time()),
		GameUid = uid,
	}
	if force then
		doclog.ModuleName = '强制解散返还'
	end
	local ret2 = getCollection(platformCollection, "UserFangCardLog"):safe_insert(doclog)
	assert(ret2 and ret2.n == 1)
	-- LOG_DEBUG('-- refund 6--'..roomId)
	return ret.value
	
end

--开房模式每局游戏结束后服务器写分, 请注意每局结束只需要调用一次，请勿对相同的roomid和roundid多次调用！！
--roomId 房间id/int
--roundId 第几局/int
--roundrecord 当局的游戏录像/string
--resultdata 当局游戏积分及牌型信息 格式如下
--[[

	[
		{
			uid:8888						--用户id,
			score:11						--当局输赢分数,
			paixing:["门清", "清一色"]		--牌型列表，没有就空
			
		},
		{
			uid:1234						--用户id,
			score:-11						--当局输赢分数,
			paixing:[]						--牌型列表，没有就空
		},
		{
			uid:2234						--用户id,
			score:0						--当局输赢分数,
			paixing:[]						--牌型列表，没有就空
		},
		{
			uid:3234						--用户id,
			score:0						--当局输赢分数,
			paixing:[]						--牌型列表，没有就空
		}
	]
-- paiData:[
	{
		uid: 8888,
		hands: [11,22,33,44],
		huCard: 23,
		huaCount: 11,
		pengGane: [
			{
				cards = [11,11,11],
				pengType = 2
			}
		]
	}
]   --结果胡牌数据 包含吃碰杠的牌、手中牌、胡的牌
]]
function CMD.insert_Fang_RoomRecord(roomId, roundId, roundrecord, resultdata, operData, paiData)
	--先查找
	local ret = getCollection(platformCollection, "FangRoomHistory"):findOne({ RoomRId = roomId})

	local docRoundItem = {}
	docRoundItem.roundid 	= roundId
	docRoundItem.record 	= roundrecord
	docRoundItem.result 	= {}
	docRoundItem.result 	= table.clone(resultdata)
	--没有的话先创建
	if not ret then
		local doc = {}
		doc.RoomRId = roomId
		doc.rounddata = {}
		doc.result = {}
		-- dump(operData, ' operData =')
		for _, resultdataItem in pairs(resultdata) do
			local tbResult = {}
			tbResult.uid = resultdataItem.uid
			tbResult.score = resultdataItem.score
			tbResult.operData = resultdataItem.operData
			table.insert( doc.result, tbResult )
		end

		-- add BeginTime
		local fangRoom = CMD.find_Fang_single_byroomid(roomId)
		doc.BeginTime = fangRoom.GameBeginTime


		table.insert( doc.rounddata, docRoundItem)
		local ret2 = getCollection(platformCollection, "FangRoomHistory"):safe_insert(doc)
		assert(ret2 and ret2.n == 1)
	else
		if ret.rounddata then
			--更新
			--检查roundid是否冲突
			for _, value in pairs(ret.rounddata) do
				if value.roundid == roundId then
					LOG_DEBUG("roomid:"..roomId.." roundId:"..roundId.."  alreay in db history, can not add again!")
					return false
				end
			end
		end
		
		doc = { query = { RoomRId = roomId}, new = true, upsert = false, update = {["$push"] = { rounddata = docRoundItem}},}
		local ret2 = getCollection(platformCollection, "FangRoomHistory"):findAndModify(doc)
		assert(ret2)

		local oldResult = ret2.value.result
		local newResult = {}

		for _, resultdataItem in pairs(resultdata) do
			for __, oldResultItem in pairs(oldResult) do
				if resultdataItem.uid == oldResultItem.uid then
					local tbResult = {}
					tbResult.uid = resultdataItem.uid
					tbResult.score = oldResultItem.score + resultdataItem.score
					tbResult.operData = resultdataItem.operData
					table.insert( newResult, tbResult )
				end
			end
		end


		--累加总成绩result
		local doc2 = {
				query = { RoomRId = roomId }, 
				new = false, 
				upsert = false, 
				update = {
					["$set"] = { result = newResult}
				},
			}
		local ret3 = getCollection(platformCollection, "FangRoomHistory"):findAndModify(doc2)
		assert(ret3)
	end


	-- 更新结果牌
	local docPaiData = {}
	local docRoundResultItem = {}
	docRoundResultItem.roundid = roundId
	docRoundResultItem.paiData = {}
	docRoundResultItem.paiData = table.clone(paiData)
	docPaiData = { query = { RoomRId = roomId}, new = true, upsert = true, update = {["$push"] = { roundresult = docRoundResultItem}},}
	local retRet = getCollection(platformCollection, "FangRoomHistory"):findAndModify(docPaiData)
	assert(retRet)


	-- 清除redis中的缓存
	clearFangRoomHistoryCache(roomId)

	return true
end

function CMD.get_user_single(uid)
	uid = tonumber(uid)
	skynet.error("CMD.get_user_single:"..uid)
	local ret = getCollection(platformCollection, "GameUser"):findOne({ Uid = uid})
	return ret
end

-- 将skynet的服务地址存入fangroom中
function CMD.set_room_serviceaddr(roomid, serviceaddr)
	local doc = {query = { RoomRId = roomid }, new = true, upsert = true, update = { ["$set"] = { skynetaddr = serviceaddr } },}
	local ret = getCollection(platformCollection, "FangRoom"):findAndModify(doc)
	assert(ret)
end

-- 将skynet的服务地址存入FangRoomUserMap中
function CMD.set_roomplayer_serviceaddr(roomid, uid, serviceaddr)
	local doc = {query = { RoomRId = roomid, GameUId = uid }, new = true, upsert = true, update = { ["$set"] = { skynetaddr = serviceaddr } },}
	local ret = getCollection(platformCollection, "FangRoomUserMap"):findAndModify(doc)
	-- assert(ret)
end

--更新用户金币并写入金币操作日志，返回需要操作的金币数量
function CMD.update_gameuser_money(uid, wantedamount, modifyamount, modulename, remark, useripaddr)
	local doc = { query = { Uid = uid }, new = true, upsert = false, update = {["$inc"] = { CoinAmount = modifyamount }},}
	local ret = getCollection(platformCollection, "GameUser"):findAndModify(doc)
	assert(ret and ret.value.Uid == uid)
	local resultAmount = ret.value.CoinAmount
	local prevAmount = resultAmount - modifyamount
	local newId = getNextId(platformCollection, "UserMoneyLog")
	local doc2 = {
		RId = newId,
		CurrentAmount = prevAmount,
		WantedAmount = wantedamount,
		ModifyAmount = modifyamount,
		ResultAmount = resultAmount,
		ModuleName = modulename,
		Remark = remark,
		UserIPAddr = useripaddr,
		WriteTime = bson.date(os.time()),
		UId = uid,
		GameCurrency = 1,
	}
	local ret2 = getCollection(platformCollection, "UserMoneyLog"):safe_insert(doc2)
	assert(ret2 and ret2.n == 1)
	return ret.value
end

function CMD.insert_game_steprecord(gameid, nodeid, data)
	if data then
		local doc = {}
		doc.gameid = gameid
		doc.nodeid = nodeid
		doc.savetime = bson.date(os.time())
		doc.record = {}
		doc.record = table.clone(data)
		local ret2 = getCollection(gameCollection, "StepRecord"):safe_insert(doc)
		assert(ret2 and ret2.n == 1)
	end
end

--从chips中返回到money中,这个函数在服务器初始化的时候调用，将之前临时存的筹码返回为用户的金币，用于灾难恢复
function CMD.restore_gameuser_money_from_chips(gameid, nodeid)
	local ret = getCollection(platformCollection, "GameChips"):find({ ChipsAmount = {['$gt'] = 0}, gameid = gameid, nodeid = nodeid})
	local result = {}
	while ret:hasNext() do
		local cret = ret:next()
		table.insert(result, cret)
	end
	
	if table.empty(result) then return end
	
	--dump(result)
	
	for _, value in pairs(result) do
		--更新money
		CMD.update_gameuser_money(value.UId, value.ChipsAmount, value.ChipsAmount, "服务器重启恢复", string.format("gameid:%d-nodeid:%d", value.gameid, value.nodeid), "127.0.0.1")
		--删除chips
		getCollection(platformCollection, "GameChips"):delete({_id = value._id})
		
		LOG_INFO("restore uid:%d chipsAmount:%d from GameChips", value.UId, value.ChipsAmount)
	end
	
end

function CMD.update_gameuser_chips(uid, chipsAmount, gameid, nodeid, remark, useripaddr)
	local doc = { query = { UId = uid, gameid = gameid, nodeid = nodeid }, new = false, upsert = true, update = {["$set"] = { ChipsAmount = chipsAmount }},}
	local ret = getCollection(platformCollection, "GameChips"):findAndModify(doc)
	assert(ret)
	local prevAmount = 0
	--不是新增加的
	if ret.value.ChipsAmount then
		prevAmount = ret.value.ChipsAmount
	end
	--local resultAmount = ret.value.ChipsAmount
	--local prevAmount = ret.value.ChipsAmount
	local wantedamount = chipsAmount - prevAmount
	local newId = getNextId(platformCollection, "UserChipsLog")
	local doc2 = {
		RId = newId,
		CurrentAmount = prevAmount,
		WantedAmount = wantedamount,
		ResultAmount = chipsAmount,
		gameid = gameid,
		nodeid = nodeid,
		Remark = remark,
		UserIPAddr = useripaddr,
		WriteTime = bson.date(os.time()),
		UId = uid,
		GameCurrency = 1,
	}
	local ret2 = getCollection(platformCollection, "UserChipsLog"):safe_insert(doc2)
	assert(ret2 and ret2.n == 1)
	return ret.value
end

function CMD.update_gameuser_game_win_lose(_record)
	local doc = nil


	if "WinCount" == _record.key then 
		-- doc = { query = { Uid = uid}, new = true, upsert = true, update = {["$inc"] = { WinCount = _value }},}
		doc = { query = { Uid = _record.uid}, new = true, upsert = false, update = {["$inc"] = { WinCount = _record.value}},}
	elseif "LoseCount" == _record.key then
		doc = { query = { Uid = _record.uid}, new = true, upsert = false,update = {["$inc"] = { LoseCount = _record.value}},}
	elseif "DrawCount" == _record.key then
		doc = { query = { Uid = _record.uid}, new = true,upsert = false, update = {["$inc"] = { DrawCount = _record.value}},}
	else
		LOG_DEBUG("no find key")
		return nil
	end
	local ret = getCollection(platformCollection, "GameUser"):findAndModify(doc)
	assert(ret)
	return ret
end
--
--uid
--roomid
--chairid
--groupid
--resulttype
--gametime
--taxamount
--wantedamount
--modifyamount
--useripaddr
--fancount
--unitcoin
function CMD.insert_game_record(uid, roomid, chairid, groupid, resulttype, gametime, taxamount, wantedamount, modifyamount, useripaddr, fancount, unitcoin)
	local newId = getNextId(gameCollection, "GameRecord")
	local doc = {rid = newId, 
				tableid = roomid, 
				chairid = chairid, 
				serverid = groupid,
				resulttype = resulttype,
				gametime = gametime,
				taxamount = taxamount,
				wantedamount = wantedamount,
				modifyamount = modifyamount,
				useripaddr = useripaddr,
				usermacaddr = "",
				writetime = bson.date(os.time()),
				fancount = fancount,
				unitcoin = unitcoin,
				uid = uid}
	dump(doc)
	local ret = getCollection(gameCollection, "GameRecord"):safe_insert(doc)

	assert(ret and ret.n == 1)
end

function CMD.update_user_status(uid, isPlaying, gameid, groupid, roomid)
	local doc = {query = { uid = uid}, new = true, upsert = true, update = { uid = uid, IsPlaying = isPlaying, GameId = gameid, GroupId = groupid, RoomId = roomid},}
	local ret = getCollection(platformCollection, "UserOnlineStatus"):findAndModify(doc)
	assert(ret)
end

function CMD.get_user_status(uid)
	
	local ret = getCollection(platformCollection, "UserOnlineStatus"):findOne({ uid = uid})
	return ret
end

function CMD.get_group_list(gameid, nodeid)
	local result = {}
	local ret = getCollection(platformCollection, "GameServerGroupV2"):find({ GameId = gameid})
	while ret:hasNext() do
		local cret = ret:next()
		table.insert(result, cret)
	end

	local filteredResult = {}
	for _, groupItem in pairs(result) do
		for k1, nodeIds in pairs(groupItem["GameServerNodeIds"]) do
			if nodeIds == nodeid then
				table.insert(filteredResult, groupItem)
			end
		end
	end
	return filteredResult
end

function CMD.updateWinInfo(record)
	local ret = getCollection(platformCollection, "GameUser")
	dump(ret, "getCollection")
	if ret then
		local res = ret:update(record.query, record.update, 1, 2)
		dump(res, "updateWinInfo")
		assert(res)
		return res
	end
end

function CMD.start()
	LOG_DEBUG("start database client")
	local mongoconnstr = skynet.getenv("mongoconnstr")
	--local mongoconnstr = "apiuser:JavAtjav11@mongo1.mgame.ucop.io:27017,mongo2.mgame.ucop.io:27017,mongo3.mgame.ucop.io:27017"
	local mongouser = nil
	local mongopass = nil
	--带有用户名密码的连接串
	if string.find(mongoconnstr, "@") ~= nil then
		local mongoconstr2 = string.split(mongoconnstr, "@")
		local userpwd = string.split(mongoconstr2[1], ":")
		mongouser = userpwd[1]
		mongopass = userpwd[2]
		mongoconnstr = mongoconstr2[2]
	end
	local mongosrvs = string.split(mongoconnstr, ",")

	--apiuser:JavAtjav11@mongo1.mgame.ucop.io:27017,mongo2.mgame.ucop.io:27017,mongo3.mgame.ucop.io:27017

	local mongoconf = {}
	mongoconf.rs = {}

	for _, value in pairs(mongosrvs) do
		local srvitem = string.split(value, ":")
		local rsItem = {}
		rsItem.host = srvitem[1]
		rsItem.port = tonumber(srvitem[2])
		rsItem.username = mongouser
		rsItem.password = mongopass
		rsItem.authmod = "scram_sha1"
		table.insert(mongoconf.rs, rsItem)
    end
	dump(mongoconf)
	db = mongo.client(mongoconf)
	dump(db, "db")
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(CMD[cmd], cmd .. "not found")
		skynet.retpack(f(...))
	end)

	--local servicemgr = skynet.uniqueservice("servicemgr")
	--local serviceName = skynet.call(servicemgr, "lua", "regInterService", SERVICE_NAME)
	local serviceName = skynet.call(".logger", "lua", "regInterService", SERVICE_NAME)
	skynet.register(SERVICE_NAME)
	
	
end)