--
-- Author: Liuq
-- Date: 2016-04-20 00:32:20
--
local skynet = require "skynet"
local queue = require "skynet.queue"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

local lock = queue()  -- cs 是一个执行队列



local CMD = {}

--分组列表  key 是groupid
--minplayer 配置的最小游戏人数
--maxplayer 配置的最大游戏人数
--gameBeginType 配置的游戏开始方式  Enums.GameBeginType
--mincoin  配置的最小金币数量
--maxcoin 配置的最大金币数量
--rooms  roomid数组
--players uid数组
local group_list = {}

--房间池 key是roomid
-- roomid: roomid
-- room: room服务地址
-- roomstatus: 房间状态 Enums.RoomState
-- minplayernum: 最小人数
-- maxplayernum: 最大人数
-- curplayers: 当前用户uid列表
-- readyplayers: 当前举手用户uid列表
-- watchplayers:  当前旁观用户uid列表
-- groupid: 所属groupid 闲置的时候为0
local room_pool = {}

--用户列表 key是uid
-- FD:  socket句柄
-- playerstatus: Enums.PlayerState
-- agent: 用户的对应agent
-- roomid: 房间id
-- groupid: group id
local player_list = {}

--流程：初始化的时候从数据库读取分组配置（分组id, 分组的最小金额，最大金额，底注，扩展配置等） 当选择一个空房间（没人的）的时候将把配置init到那个room

--房间排序函数
local function roomSortFunc(a, b)
	-- 如果a未开始 b已开始 则a在前面
	-- a未开始
	--if a.roomstatus ~= Enums.RoomState.PLAYING then
		-- a还有空位
		if #a.curplayers < a.maxplayernum then
			--如果b已经开始 那么a在前面
			--if b.roomstatus == Enums.RoomState.PLAYING then
			--	return true
			--else
				-- a,b都未开始
				-- 空位最少的排上面
				if #b.curplayers >= b.maxplayernum then
					return true
				else
					if a.maxplayernum - #a.curplayers < b.maxplayernum - #b.curplayers then
						return true
					else
						return false
					end
				end
			--end
		end
	--end

	return false
end

-- 取出一个idel的room 同时设置状态为wait
local function getRoomFromPool(minplayernum, maxplayernum, groupid)
	for key, room in pairs(room_pool) do
		if room.roomstatus == Enums.RoomState.IDLE then
			room.roomstatus = Enums.RoomState.WAIT
			room.minplayernum = minplayernum
			room.maxplayernum = maxplayernum
			room.groupid = groupid
			room_pool[key] = room
			
			skynet.call(room.room, "lua", "init", skynet.self(), minplayernum, maxplayernum)

			return room
		end
	end

	return nil
end

-- 通过uid查找room服务地址
local function getRoomAddressByUid(uid)
	local player = player_list[uid]
	if not player then
		skynet.error(string.format("getRoomAddressByUid fail! user %s is not found in player_list", uid))
		return false, "用户不存在"
	end
	
	if player.roomid == 0 then
		skynet.error(string.format("getRoomAddressByUid fail! user %s is not in room", uid))
		return false, "用户未在房间中"
	end
	
	if room_pool[player.roomid] then
		return true, room_pool[player.roomid].room
	else
		return false, "房间不存在"
	end
end

-- 检查房间是否满足开始条件，满足开始条件的话就开始游戏
local function CheckGameStart(groupid, roomid)
	--只有当前房间人数 ＝＝ 举手人数的时候才会执行开始检查
	if #room_pool[roomid].curplayers == #room_pool[roomid].readyplayers then
		if group_list[groupid].gameBeginType == Enums.GameBeginType.ALLREADY_EQUAL_MAXPLAYER then
			if #room_pool[roomid].curplayers == room_pool[roomid].maxplayernum then
				skynet.error("room can startgame, roomid:"..roomid)
					
				room_pool[roomid].roomstatus = Enums.RoomState.PLAYING
				--清空举手表
				room_pool[roomid].readyplayers = {}
					
				skynet.call(room_pool[roomid].room, "lua", "startGame")
				
				--通知agent状态
				for _, uid in pairs(room_pool[roomid].curplayers) do
					skynet.call(player_list[uid].agent, "lua", "changePlayingStatus", true, groupid, roomid)
				end
				
			end
		elseif group_list[groupid].gameBeginType == Enums.GameBeginType.ALLREADY_MORETHAN_MINPLAYER then
			if #room_pool[roomid].curplayers >= room_pool[roomid].minplayernum then
				skynet.error("room can startgame, roomid:"..roomid)
				
				room_pool[roomid].roomstatus = Enums.RoomState.PLAYING
					
				room_pool[roomid].readyplayers = {}
					
				skynet.call(room_pool[roomid].room, "lua", "startGame")
				
				--通知agent状态
				for _, uid in pairs(room_pool[roomid].curplayers) do
					skynet.call(player_list[uid].agent, "lua", "changePlayingStatus", true, groupid, roomid)
				end
			end
		end
	end
end

function CMD.userReady(uid)
	local player = player_list[uid]
	if player then
		-- 安全检查，举手用户的状态必须为SEAT状态才可以
		if player.playerstatus ~= Enums.PlayerState.SEAT then
			skynet.error(string.format("CMD.userReady fail, uid:%s current status is:%s cannot be ready status!", uid, player.playerstatus))
			return
		end
		--player.playerstatus = Enums.PlayerState.READY
		local roomid = player_list[uid].roomid
		player_list[uid].playerstatus = Enums.PlayerState.READY
		
		table.removeItem(room_pool[roomid].readyplayers, uid)
		table.insert(room_pool[roomid].readyplayers, uid)

		skynet.call(room_pool[roomid].room, "lua", "userReady", uid)
		
		local groupid = room_pool[roomid].groupid
		
		
		CheckGameStart(groupid, roomid)
		
		--dump(room_pool[roomid])
		--dump(player_list[uid])
	end
end

-- 分配房间,可指定忽略的roomid
local function allocateRoom(groupid, excludeRoomId)
	local group = group_list[groupid]
	if group then
		-- 先取出到临时table中
		local tmpRooms = {}
		for _, roomid in pairs(group.rooms) do
			if excludeRoomId then
				if roomid ~= excludeRoomId then
					table.insert(tmpRooms, room_pool[roomid])
				end
			else
				table.insert(tmpRooms, room_pool[roomid])
			end
			
		end
		
		--如果是个空表 直接返回nil
		if next(tmpRooms) == nil then
			return nil
		end
		
		--排序
		table.sort(tmpRooms, roomSortFunc)
		
		return tmpRooms
	else
		skynet.error("allocateRoom: the group not exists, groupid:"..groupid)
	end
	
	return nil
end

-- 用户站起来，进入旁观状态
function CMD.userStandup(uid)

end

-- 用户坐下，进入准备游戏状态
function CMD.userSeatdown(uid)
	
end

-- 用户更换房间
function CMD.changeRoom(uid)
	--用户是否可以离开当前房间
	local oldRoomId = player_list[uid].roomid
	local leaveRet = CMD.leaveRoom(uid)
	if leaveRet.ret then
		local enterRet = CMD.enterRoom(uid, oldRoomId)
		if enterRet.ret then
			local newRoomId = player_list[uid].roomid
			skynet.error(string.format("CMD.changeRoom ok! user %s old roomid:%s,  new roomid:%s", uid, oldRoomId, newRoomId))
		else
			skynet.error(string.format("CMD.changeRoom fail! enter new room error, user %s old roomid:%s", uid, oldRoomId))
		end
	else
		skynet.error(string.format("CMD.changeRoom fail! leave old room error, user %s old roomid:%s", uid, oldRoomId))
	end
end

-- 用户离开游戏
function CMD.leaveGame(uid)
	--todo: 一些逻辑判断
	player_list[uid] = nil
	table.removeItem(group_list[player.groupid].players, uid)
end

-- 用户离开房间
function CMD.leaveRoom(uid)
	-- 安全检查，查看用户当前是否在任何group里面
	if not player_list[uid] then
		skynet.error(string.format("CMD.leaveRoom fail! user %s is not in list", uid))
		return false
	else
		local player = player_list[uid]
		--调用room中的方法
		local bRet = skynet.call(room_pool[player.roomid].room, "lua", "leaveRoom", uid)
		
		if bRet == false then
			skynet.error(string.format("CMD.leaveRoom fail! user %s is playing in roomid:", uid, player.roomid))
			return { ret = false, msg = "can not leave from room"}
		end

		if player.playerstatus == Enums.PlayerState.PLAYING then
			skynet.error(string.format("CMD.leaveRoom fail! user %s is playing in roomid:", uid, player.roomid))
			return { ret = false, msg = "user state is playing" }
		end
		
		local roomid = player.roomid
		--从room的用户列表和举手列表中删除
		table.removeItem(room_pool[player.roomid].curplayers, uid)
		table.removeItem(room_pool[player.roomid].readyplayers, uid)
		table.removeItem(room_pool[player.roomid].watchplayers, uid)
		
		--设置用户为闲置状态
		player_list[uid].playerstatus = Enums.PlayerState.IDLE
		
		player_list[uid].roomid = 0
		CheckGameStart(player.groupid, roomid)
		
		dump(room_pool[roomid])
		
		return {ret = true }
	end
	
end

-- 用户进入游戏
function CMD.enterGame(uid, agent, client_fd, groupid)
	--安全检查,禁止用户重复进入
	local isCutBack = false
	for groupkey, group in pairs(group_list) do
		for key, playerid in pairs(group.players) do
			if playerid == uid then
				skynet.error(string.format("CMD.enterGame fail! duplicate user %s is already in group:%s", uid, groupkey))
				isCutBack = true
			end
		end
	end
	
	if isCutBack == false then
		table.insert(group_list[groupid].players, uid)
		player_list[uid] = { FD = client_fd, roomid = 0, playerstatus = Enums.PlayerState.IDLE, groupid = groupid, agent = agent }
	else
		--掉线重入的话只需要修改用户的FD
		player_list[uid].FD = client_fd
	end
end

--用户进入房间, 如果有oldRoomId代表是换房间操作，需要分配不同的房间
function CMD.enterRoom(uid, oldRoomId)
	local player = player_list[uid]
	local isCutBack = false
	if not player then
		skynet.error(string.format("CMD.enterRoom fail! user %s is not found in player_list", uid))
		return { ret = false, msg = "用户尚未进入游戏"}
	end
	
	if player.roomid > 0 then
		skynet.error(string.format("CMD.enterRoom fail! duplicate user %s is already in roomid:%s", uid, player.roomid))
		--return { ret = false, msg = "用户已在房间中"}
		isCutBack = true
	end
	
	if isCutBack then
		skynet.call(room_pool[player.roomid].room, "lua", "userCutBack", uid, player.FD)
		return { ret = true}
	end
	
	local groupid = player.groupid

	local group = group_list[groupid]
	if group then
		local bFind = false
		local roominfoitem

		local findedRoomId = 0

		-- 搜索合适的房间
		if next(group.rooms) ~= nil then
			local sortedRoomList = allocateRoom(groupid, oldRoomId)
			if sortedRoomList ~= nil then
				-- 取第一个，因为之前已经根据规则排序过了
				if sortedRoomList[1].maxplayernum > #sortedRoomList[1].curplayers then
					findedRoomId = sortedRoomList[1].roomid
					bFind = true
				end
			end
		else
			skynet.error("group rooms is null, groupid:"..groupid)
		end

		-- group中没有合适的房间可用
		if bFind == false then
			local newroominfo = getRoomFromPool(group.minplayer, group.maxplayer, groupid)
			if newroominfo then
				--local newroomlistitem = { roominfo = newroominfo, curPlayerNum = 0, curReadyNum = 0, maxPlayerNum = 2 }
				table.insert(group_list[groupid].rooms, newroominfo.roomid)
				findedRoomId = newroominfo.roomid
			else
				return { ret = false, msg = "当前无可用房间分配，请稍后再试" }
			end
		end

		-- 开始操作房间
		local enterOK, isPlayer = skynet.call(room_pool[findedRoomId].room, "lua", "enterRoom", uid, player.agent, player.FD)
		if enterOK then
			if isPlayer then
				table.insert(room_pool[findedRoomId].curplayers, uid)
				
				player_list[uid].playerstatus = Enums.PlayerState.SEAT
			else
				table.insert(room_pool[findedRoomId].watchplayers, uid)
				
				player_list[uid].playerstatus = Enums.PlayerState.WATCH
			end
			
			
			player_list[uid].roomid = findedRoomId
			
			--dump(room_pool[findedRoomId])
			--dump(player_list[uid])
			
			return { ret = true}
			
			
		else
		
			--todo: 用户进入房间失败，需要通知客户端
			
			return { ret = false, msg = "进入房间失败"}
		end
	else
		return { ret = false, msg = "不存在的房间分组信息" }
	end

end

local function utf8_from(t)
	local tts = ""
	for _, v in ipairs(t) do
		--print("xxxssss:"..string.char(v))
		tts = tts..string.char(v)
		--print("ttt"..v)
	end

	return tts
end

function CMD.RequestGame(uid, name, args)
	local ret, room = getRoomAddressByUid(uid)
	if ret == true then
		--分发到room
		skynet.call(room, "lua", "dispatchGameRequest", uid, name, args)
	end
end

function CMD.open()
	local nMaxRooms = (tonumber(skynet.getenv("maxrooms")) or 2000)
	nStepRooms = nMaxRooms / 10
	skynet.error("precreate %d rooms", nStepRooms)
	for i = 1, nStepRooms do
		local roomaddr = assert(skynet.newservice("room", i), string.format("precreate room %d of %d error", i, nStepRooms))
		local room = { roomid = i,
						room = roomaddr, 
						roomstatus = Enums.RoomState.IDLE, 
						maxplayernum = 0, 
						curplayers = {}, 
						readyplayers = {},
						watchplayers = {},
						groupid = 0 }
						
		room_pool[i] = room
	end

	-- todo: 这是测试数据，正式的应该是从db中获取配置
	group_list[1] = { minplayer = 2, 
					maxplayer = 6, 
					gameBeginType = Enums.GameBeginType.ALLREADY_MORETHAN_MINPLAYER, 
					mincoin = 100, 
					maxcoin = 10000, 
					rooms = {}, 
					players = {} }


	--todo:一个定时器，扫描当前房间的状态进行动态扩容/缩容
	--如果80%都处于使用状态的话，那么增加 maxrooms/10 直到>=maxrooms
	--如果80%都处于空闲状态的话，那么减少 maxrooms/10 直到<=maxrooms/10  （这是个可选项）
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
	
	--[[
	local host = sprotoloader.load(1):host "package"
	local send_request = host:attach(sprotoloader.load(1))
	
	local testobj = { card = { 11, 18} }
	
	local ccc = send_request("playcard", testobj)
	
	local unccc = sproto.unpack(ccc)
	local bytes = {string.byte(ccc, 0, -1)} -- type(bytes) == 'table', #bytes == 3
--assert_equal(table.concat(bytes, ', '), '97, 98, 99')

	local unbytes = {string.byte(unccc, 0, -1)}
	local ttt = table.concat(bytes, ', ')
	local unttt = table.concat(unbytes, ', ')
	dump(ttt)
	dump(unttt)
	]]
end)