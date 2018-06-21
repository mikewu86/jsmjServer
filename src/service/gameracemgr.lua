--
-- Author: Liuq
-- Date: 2016-04-20 00:32:20
--
local skynet = require "skynet"
require "skynet.manager"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local snax = require "snax"
local cluster = require "cluster"
local queue = require "skynet.queue"
local cs = queue()  -- cs 是一个执行队列
local dbmgr
--local sngmgr = nil
local CMD = {}

--分组列表  key 是groupid
--minplayer 配置的最小游戏人数
--maxplayer 配置的最大游戏人数
--gameBeginType 配置的游戏开始方式  Enums.GameBeginType
--mincoin  配置的最小金币数量
--maxcoin 配置的最大金币数量
--rooms  roomid数组
--players uid数组
-- roomType: 房间类型
local group_list = {}

--房间池 key是roomid
-- roomid: roomid
-- room: room服务地址
-- roomstatus: 房间状态 Enums.RoomState
-- minplayernum: 最小人数
-- maxplayernum: 最大人数
-- curplayers: 当前用户uid列表
-- readyplayers: 当前举手用户uid列表
-- seatplayers:  当前有座位的用户uid列表
-- watchplayers:  当前旁观用户uid列表
-- cutplayers: 掉线用户列表
-- groupid: 所属groupid 闲置的时候为0
-- roomType: 房间类型
-- enteredplayers:  所有进入过的用户uid列表
local  room_pool = {}

--用户列表 key是uid
-- FD:  socket句柄
-- playerstatus: Enums.PlayerState
-- agent: 用户的对应agent
-- roomid: 房间id
-- groupid: group id
local player_list = {}

local nextRoomId = 1

--流程：初始化的时候从数据库读取分组配置（分组id, 分组的最小金额，最大金额，底注，扩展配置等） 当选择一个空房间（没人的）的时候将把配置init到那个room

--房间排序函数
local function roomSortFunc(a, b)
	-- 如果a未开始 b已开始 则a在前面
	-- a未开始
	--if a.roomstatus ~= Enums.RoomState.PLAYING then
		-- a还有空位
		if #a.seatplayers < a.maxplayernum then
			--如果b已经开始 那么a在前面
			--if b.roomstatus == Enums.RoomState.PLAYING then
			--	return true
			--else
				-- a,b都未开始
				-- 空位最少的排上面
				if #b.seatplayers >= b.maxplayernum then
					return true
				else
					if a.maxplayernum - #a.seatplayers < b.maxplayernum - #b.seatplayers then
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

-- 向ROOM中添加已座玩家，已有就不加了
local function addRoomSeatPlayer(room, uid)
	if room and table.keyof(room.seatplayers, uid) == nil then
		table.insert( room.seatplayers, uid )
	end
end

-- 向ROOM中添加当前玩家，已有就不加了
local function addRoomCurPlayer(room, uid)
	if room and table.keyof(room.curplayers, uid) == nil then
		table.insert(room.curplayers, uid )
	end
end

-- 向ROOM中添加当前旁观者，已有就不加了
local function addRoomWatcher(room, uid)
	if room and table.keyof(room.watchplayers, uid) == nil then
		table.insert(room.watchplayers, uid )
	end
end

-- 向ROOM中添加已准备玩家，已有就不加了
local function addRoomReadyPlayer(room, uid)
	if room and table.keyof(room.readyplayers, uid) == nil then
		table.insert(room.readyplayers, uid )
	end
end

-- 向ROOM中添加已进入玩家，已有就不加了
local function addRoomEnteredPlayer(room, uid)
	if room and table.keyof(room.enteredplayers, uid) == nil then
		table.insert(room.enteredplayers, uid )
	end
end


local function CreateRoom(roomid, _roomType)
	LOG_DEBUG("createRoom call %d, %s", roomid, _roomType)
    local roomaddr = skynet.newservice("room", _roomType, roomid)
    local room = { roomid = roomid,
						room = roomaddr, 
						roomstatus = Enums.RoomState.IDLE, 
						maxplayernum = 0,
                        unitcoin = 0,
						tax = 0,
						curplayers = {},
						readyplayers = {},
						seatplayers = {},
						watchplayers = {},
						cutplayers = {},
						enteredplayers = {},
						groupid = 0,
						roomType = _roomType }
                        
    room_pool[roomid] = room
    LOG_DEBUG(string.format("create room service for roomid:%d", roomid))
    skynet.call(room_pool[roomid].room, "lua", "setRoomId", roomid)
	skynet.send(dbmgr, 'lua', 'set_room_serviceaddr', roomid, roomaddr)
end

-- 取出一个idel的room 同时设置状态为wait
-- 初始化的时候增加了包房的信息
local function getRoomFromPool(groupid, roundid, fixedRoomId, fangInfo)
	-- dump(fangInfo, ' getRoomFromPool fangInfo = ')
	local minplayernum = group_list[groupid].minplayer
	local maxplayernum = group_list[groupid].maxplayer
	local unitcoin = group_list[groupid].unitcoin
	local tax = group_list[groupid].tax
	local roomType = group_list[groupid].roomType
	local minCoin = group_list[groupid].mincoin
	local maxCoin = group_list[groupid].maxcoin
	local roundTime = group_list[groupid].roundTimeClient
	for key, room in pairs(room_pool) do
		local idleRoom = (room.roomstatus == Enums.RoomState.IDLE and nil == fixedRoomId)
		local findRoom = (type(1) == type(fixedRoomId) and fixedRoomId == room.roomid)
		if true ==  idleRoom or true == findRoom  then
			room.roomstatus = Enums.RoomState.WAIT
			room.minplayernum = minplayernum
			room.maxplayernum = maxplayernum
			room.unitcoin = unitcoin
			room.tax = tax
			room.roundid = roundid
			room.groupid = groupid
			room_pool[key] = room
			
			local roomVer = skynet.call(room.room, "lua", "init", 
			skynet.self(), dbmgr, groupid, minplayernum, maxplayernum, unitcoin, tax, 
			roomType, nil, minCoin, maxCoin, roundTime, roundid, fangInfo)
			room_pool[key].version = roomVer
			return room
		end
	end
	
	if not fixedRoomId then
		CreateRoom(nextRoomId, roomType)
		nextRoomId = nextRoomId + 1
		return getRoomFromPool(groupid, roundid)
	else
		--指定了roomid
		CreateRoom(fixedRoomId, roomType)
		return getRoomFromPool(groupid, roundid, fixedRoomId, fangInfo)
	end

	--return nil
end

-- 通过uid查找room服务地址
local function getRoomAddressByUid(uid)
	local player = player_list[uid]
	if not player then
		LOG_DEBUG(string.format("getRoomAddressByUid fail! user %s is not found in player_list", uid))
		return false, "用户不存在"
	end
	
	if player.roomid == 0 then
		LOG_DEBUG(string.format("getRoomAddressByUid fail! user %s is not in room", uid))
		return false, "用户未在房间中"
	end

	-- dump(player, 'getRoomAddressByUid uid'..uid)
	
	if room_pool[player.roomid] and room_pool[player.roomid].room  then
		return true, room_pool[player.roomid].room
	else
		return false, "房间不存在"
	end
end

--回收房间，删除房间服务并重新创建一个
local function ResetRoom(roomid, notCreate)
	if not room_pool[roomid] then
		return
	end
    local groupid = room_pool[roomid].groupid
	-- LOG_DEBUG('-- requestReleaseRoom 2--'..roomid)
    table.removeItem(group_list[groupid].rooms, roomid)
    skynet.send(room_pool[roomid].room, "lua", "resetRoom")
    LOG_DEBUG(string.format("room %d is exited", roomid))
	if notCreate == nil then
    	CreateRoom(roomid, group_list[groupid].roomType)
	end
end

-- 检查房间是否满足开始条件，满足开始条件的话就开始游戏
local function CheckGameStart(groupid, roomid)
	cs(function() 
		LOG_DEBUG('--checkGameStart--')
		--不处理正在游戏的房间检查
		local room = room_pool[roomid]
		if not room then
			return
		end
		if room.roomstatus == Enums.RoomState.PLAYING then return end
		
		--将掉线列表中的玩家清理掉
		if room.cutplayers then
			for _, _cutUid in pairs(room.cutplayers) do
				table.removeItem(room.seatplayers, _cutUid)
				skynet.fork(function()
					CMD.leaveRoom(_cutUid)
					CMD.leaveGame(_cutUid)
				end)
			end
			room.cutplayers = {}
		end
		
		-- dump(room.seatplayers, ' ready, room.seatplayers = ')
		-- dump(room.readyplayers, ' ready, room.readyplayers = ')
		-- dump(room.maxplayernum, ' room.maxplayernum = ')

		if room and room.seatplayers and room.minplayernum then
			--只有当前房间人数 ＝＝ 举手人数的时候才会执行开始检查
			if #room.seatplayers == #room.readyplayers then
				if group_list[groupid].gameBeginType == Enums.GameBeginType.ALLREADY_EQUAL_MAXPLAYER then
					if #room.seatplayers == room.maxplayernum then
						LOG_DEBUG("room can startgame, roomid:"..roomid)
						room.roomstatus = Enums.RoomState.PLAYING
						-- dump(room.seatplayers, "seatPlayers")
						--清空举手表
						room.readyplayers = {}	
						skynet.call(room.room, "lua", "startGame")
						-- 将player服务地址保存
						--通知agent状态
						for _, uid in pairs(room.curplayers) do
							skynet.call(player_list[uid].agent, "lua", "changePlayingStatus", true, groupid, roomid)
							skynet.send(dbmgr, "lua", "set_roomplayer_serviceaddr", roomid, uid, player_list[uid].agent)
						end
						-- 去掉玩家的占位房间号
						for _, uid in pairs(room.seatplayers) do
							if player_list[uid] then
								player_list[uid].holdRoomId = 0
							end
						end
					end
				elseif group_list[groupid].gameBeginType == Enums.GameBeginType.ALLREADY_MORETHAN_MINPLAYER then
					--dump(room_pool)
					if #room.seatplayers >= room.minplayernum then
						dump(room.seatplayers, "seatPlayers")
						LOG_DEBUG("room can startgame, roomid:"..roomid)
						room.roomstatus = Enums.RoomState.PLAYING	
						room.readyplayers = {}	
						skynet.call(room.room, "lua", "startGame")
						--通知agent状态
						for _, uid in pairs(room.curplayers) do
							if player_list[uid] then
								skynet.call(player_list[uid].agent, "lua", "changePlayingStatus", true, groupid, roomid)
							else
							end
						end
						-- 去掉玩家的占位房间号
						for _, uid in pairs(room.seatplayers) do
							if player_list[uid] then
								player_list[uid].holdRoomId = 0
							end
						end
					end
				end
			end
		end
		
		--当房间中没有人时回收该房间
		if room.roomType == RoomConstant.RoomType.VIP then
			if room.isReleased then
				if #room.curplayers == 0 and #room.watchplayers == 0 then
					local roomAddr = room.room
					local groupid = room.groupid
					table.removeItem(group_list[groupid].rooms, roomid)
					room_pool[roomid] = nil
					-- LOG_DEBUG('-- requestReleaseRoom 3--'..roomid)
					skynet.send(roomAddr, "lua", "resetRoom")
				end
			end
		else
			if #room.curplayers == 0 and #room.watchplayers == 0 then
				ResetRoom(roomid)
			end
		end
		LOG_DEBUG('--checkGameStart End--')
	end)
end



local function ClearUserFromRoom(uid, roomid)
	local room = room_pool[roomid]
	if room then
		table.removeItem(room.curplayers, uid)
		table.removeItem(room.readyplayers, uid)
		table.removeItem(room.seatplayers, uid)
		table.removeItem(room.watchplayers, uid)
	end
end

local function relay_roominfo_toclient(roomId, isGameBegin, cnt)
	--通过lobby服务器透传消息给客户端
	if not room_pool[roomId] then
		LOG_ERROR("roomid not exists in room_pool, roomid:"..roomId)
	end

	local notifyUids = room_pool[roomId].enteredplayers
	local notifyCMD = "update_myroom_info"
	local notifyData = {
		roomid = roomId,
		usercount = #room_pool[roomId].curplayers,
		isbegin = isGameBegin,
	}

	if cnt ~= nil then
		notifyData.usercount = cnt
	end

	for _, uid in pairs(room_pool[roomId].enteredplayers) do
		if player_list[uid] and player_list[uid].agent then
			skynet.send(player_list[uid].agent, "lua", "relayToLobbyUser", notifyCMD, notifyData)
		end
	end
end

local function getEnterRoomRes(_roomid, _ret, _initMoney)
	local enterroomRes = {}
	local room = room_pool[_roomid]
	enterroomRes.ret = _ret
	enterroomRes.roomid = _roomid
	enterroomRes.players = {}
	if not room then
		enterroomRes.maxplayer = 4
		enterroomRes.unitcoin = 1
		enterroomRes.readyplayers = {}
		return enterroomRes
	end
	enterroomRes.maxplayer = room.maxplayernum
	enterroomRes.unitcoin = room.unitcoin
	enterroomRes.readyplayers = room.readyplayers

	
	if not user_dc then
		user_dc = snax.uniqueservice("userdc")
	end

	-- 若是锁定过的房间，则发送当前锁定玩家的信息
	local lockedPlayers = skynet.call(room.room, 'lua', 'getLockedPlayer')
	-- 有占位玩家的，则发送已占位玩家的信息
	local holdPlayers = skynet.call(room.room, 'lua', 'getHoldPlayers')
	-- dump(holdPlayers, ' holdPlayers = ')
	-- dump(room.seatplayers, 'seatPlayer')
	if lockedPlayers then
		for pos, player in pairs(lockedPlayers) do
			table.insert(enterroomRes.players, player)
		end
	elseif holdPlayers then
		for pos, player in pairs(holdPlayers) do
			table.insert(enterroomRes.players, player)
		end
	else
		for pos, playerid in pairs(room.seatplayers) do
			local playerData = {}
			playerData.uid = playerid
			playerData.nickname = user_dc.req.getvalue(playerid, "NickName")
			playerData.sex = user_dc.req.getvalue(playerid, "Sex")
			-- if user_dc.req.getvalue(playerid, "UseTempMoney") then
				-- playerData.money = user_dc.req.getvalue(playerid, "TempMoney")
			-- else
			if room.roomType == RoomConstant.RoomType.SNG then
				--[[
				playerData.money = user_dc.req.getvalue(playerid, "CoinAmount")
				if type(1) ~= type(_initMoney) then
					playerData.sngScore = skynet.call(sngmgr, "lua", "getMoney", playerid, _roomid)
				else
					playerData.sngScore = _initMoney
				end]]
			elseif room.roomType == RoomConstant.RoomType.VIP then
				playerData.money = skynet.call(room.room, "lua", "getPlayerVIPScore", playerid)
				if playerData.money == nil then
					playerData.money = 0
				end
			else
				playerData.money = user_dc.req.getvalue(playerid, "CoinAmount")
			end
			-- end
			playerData.face = 0
			playerData.pic_url = user_dc.req.getvalue(playerid, "SmallLogoUrl")
			playerData.wincount = user_dc.req.getvalue(playerid, "WinCount")
			playerData.losecount = user_dc.req.getvalue(playerid, "LoseCount")
			playerData.drawcount = user_dc.req.getvalue(playerid, "DrawCount")
			playerData.user_ipaddr = player_list[playerid].ipaddr
			playerData.iswatcher = skynet.call(player_list[playerid].agent, "lua", "getWatcher")
			if playerData.iswatcher == 0 then
				playerData.Pos = skynet.call(room.room, "lua", "getPlayerPos", playerid)
			else
				playerData.Pos = 1
			end
			table.insert(enterroomRes.players, playerData)
		end
	end
	return enterroomRes
end

--[[
** 申请释放房间，针对于不会自动释放的房间(如包间)
** 释放房间必须从raceMgr执行，不能在房间内部操作，因为房间是由raceMgr创建
** 它在管理房间
 ]]
function CMD.requestReleaseRoom(roomid)
	cs(function()
		local room = room_pool[roomid]
		if room then
			local ret = true
			-- if room.roomType == RoomConstant.RoomType.VIP then
			-- 	ret = skynet.call(dbmgr, 'lua', 'update_Fang_status', room.roomid, kVipRoomState.disband)
			-- end
			if ret then
				-- LOG_DEBUG('-- requestReleaseRoom 1--'..roomid)
				local groupid = room_pool[roomid].groupid
				table.removeItem(group_list[groupid].rooms, roomid)
				LOG_DEBUG(string.format("room %d will released", roomid))
				room.isReleased = true
				if #room.curplayers == 0 and #room.watchplayers == 0 then
					
				else
					LOG_DEBUG('-- release warning --, players left!!')
					if #room.curplayers ~= 0 then
						dump(room.curplayers, ' curplayers = ')
					end
					if #room.watchplayers ~= 0 then
						dump(room.watchplayers, ' curplayers = ')
					end
					-- 把该房间的玩家清空
					room.curplayers = {}
					room.watchplayers = {}
				end
				--强制解散房间
				local roomAddr = room.room
				room_pool[roomid] = nil
				skynet.send(roomAddr, "lua", "resetRoom")
			end
		end
	end)
end

function CMD.refreshFangList(roomid)
	relay_roominfo_toclient(roomid, false, -99)
	return true
end

-- 用户断开连接了
function CMD.userDisconnect(uid)
	local player = player_list[uid]
	if nil == player then 
		LOG_DEBUG("uid: "..uid.." not entergame")
		return
	end
	LOG_DEBUG('player '..uid..' disconnected state = '..player.playerstatus)
	--非游戏状态清理用户信息
	if player.playerstatus == Enums.PlayerState.SNGSIGNUP then
		--已报名未分配，玩家信息不清除
	elseif player.playerstatus ~= Enums.PlayerState.PLAYING  then
		local ret = CMD.leaveRoom(uid)
		if ret.leaveGame then
			CMD.leaveGame(uid)
		else
			table.removeItem(group_list[player.groupid].players, uid)
		end
	else
		--游戏状态
		--加入掉线列表中
		if not room_pool[player.roomid].cutplayers then
			room_pool[player.roomid].cutplayers = {}
		end
		table.removeItem(room_pool[player.roomid].cutplayers, uid)
		table.insert(room_pool[player.roomid].cutplayers, uid)
		CMD.cutRoom(uid)
	end
end

--服务器关闭了
function CMD.serverShutdown()
	--通知所有的room退出
	for key, room in pairs(room_pool) do
		skynet.send(room.room, "lua", "serverShutdown")
	end
	--skynet.exit()
	return true
end

-- 由room通知游戏开始
function CMD.userGameStart(uid)
    local player = player_list[uid]
	if player then
        player.playerstatus = Enums.PlayerState.PLAYING
    end
end

-- 由room通知游戏结束
function CMD.userGameEnd(uid)
    local player = player_list[uid]
	if player then
		if player.playerstatus == Enums.PlayerState.PLAYING then
        	player.playerstatus = Enums.PlayerState.SEAT
		end
		if player.roomid and room_pool[player.roomid] then
			room_pool[player.roomid].roomstatus = Enums.RoomState.WAIT
		end
    end
end

function CMD.userSelectSeat(uid, pos)
	cs(function()
		local player = player_list[uid]
		-- dump(room_pool, ' room pool = ')
		LOG_DEBUG(' race select seat '..pos..' uid = '..uid)
		if player then
			local roomid = player_list[uid].roomid
			local room = room_pool[roomid]
			local ret = 0
			if pos == 0 then   -- 随机分配
				ret = skynet.call(room.room, "lua", "randomSeat", uid, room.readyplayers)
			else
				ret = skynet.call(room.room, "lua", "userSelectSeat", uid, pos, room.readyplayers)
			end
			LOG_DEBUG('ret = '..ret..' uid = '..uid)
			if ret == 1 or ret == 2 then  -- 已坐下
				player.playerstatus = Enums.PlayerState.SEAT
				table.removeItem(room.readyplayers, uid)
				addRoomSeatPlayer(room, uid)
				table.removeItem(room.watchplayers, uid)
				player_list[uid].playerstatus = Enums.PlayerState.SEAT
				player_list[uid].holdRoomId = roomid
			elseif ret == 0 then -- 未坐下
				table.removeItem(room.readyplayers, uid)
				table.removeItem(room.seatplayers, uid)
				table.removeItem(room.watchplayers, uid)
				addRoomWatcher(room, uid)
				player_list[uid].playerstatus = Enums.PlayerState.WATCH
				player_list[uid].holdRoomId = 0
				--给用户发送当前房间的信息
				--send_client(player_list[uid].FD, send_request("enterroomRes", getEnterRoomRes(roomid, true)))
			else
			end
		end
	end)
end

function CMD.userQuit(uid)
	local player = player_list[uid]
	if player then
		local roomid = player_list[uid].roomid
		local room = room_pool[roomid]
		if not room then
			return
		end
		local ret = skynet.call(room.room, "lua", "userQuit", uid)
		if ret then
			player.playerstatus = Enums.PlayerState.IDLE  -- 玩家主动离开
			player.holdRoomId = 0
		end
	end
end

function CMD.userReady(uid)
	local player = player_list[uid]
	if player then
		if player.playerstatus == Enums.PlayerState.READY then
			return
		end
		-- 安全检查，举手用户的状态必须为SEAT状态才可以
		if player.playerstatus ~= Enums.PlayerState.SEAT then
			LOG_DEBUG(string.format("CMD.userReady fail, uid:%s current status is:%s cannot be ready status!", uid, player.playerstatus))
			return
		end
	
		--player.playerstatus = Enums.PlayerState.READY
		local roomid = player_list[uid].roomid
		local room = room_pool[roomid]
		player.playerstatus = Enums.PlayerState.READY
		
		table.removeItem(room.readyplayers, uid)
		local othersUid = {}
		for _, uid in pairs(room.readyplayers) do 
			table.insert(othersUid, uid)
		end
		addRoomReadyPlayer(room, uid)
		-- local beforeSeat = skynet.call(room.room, "lua", "getPlayerPos", uid)
		skynet.call(room.room, "lua", "userReady", uid, othersUid)
		--因为包间是准备以后再分配座位了，所以得重新发送一下当前的玩家坐位
		-- skynet.call(room.room, "lua", "getPlayerPos", uid)
		dump(room.readyplayers, 'room.readyplayers = ')
		local groupid = room.groupid
		CheckGameStart(groupid, roomid)
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
		LOG_DEBUG("allocateRoom: the group not exists, groupid:"..groupid)
	end
	
	return nil
end

-- 用户站起来/坐下，进入旁观状态
function CMD.userStandup(uid, _isstandup)
	local roomid = player_list[uid].roomid
	--调用room中的方法
	local bRet = skynet.call(room_pool[roomid].room, "lua", "userStandup", uid, _isstandup)
	if bRet then
		if _isstandup == 1 then
			
			table.removeItem(room_pool[roomid].readyplayers, uid)
			table.removeItem(room_pool[roomid].seatplayers, uid)
			table.removeItem(room_pool[roomid].watchplayers, uid)
			addRoomWatcher(room_pool[roomid], uid)
			
			player_list[uid].playerstatus = Enums.PlayerState.WATCH
			
			LOG_DEBUG("userStandup is call uid:%d _isstandup:%d", uid, _isstandup)
			
			--用户站起来的时候要检查游戏是否可以开始
			CheckGameStart(player_list[uid].groupid, roomid)
		else
			table.removeItem(room_pool[roomid].readyplayers, uid)
			table.removeItem(room_pool[roomid].seatplayers, uid)
			table.removeItem(room_pool[roomid].watchplayers, uid)
			table.insert(room_pool[roomid].seatplayers, uid)
			
			player_list[uid].playerstatus = Enums.PlayerState.SEAT
			
			LOG_DEBUG("userStandup is call uid:%d _isstandup:%d", uid, _isstandup)
			
			--下定时器自动开始,2秒
			skynet.fork(function()
				LOG_DEBUG("CMD.userStandup call userReady")
				CMD.userReady(uid)
			end)
			
			--用户坐下的时候要检查游戏是否可以开始
			CheckGameStart(player_list[uid].groupid, roomid)
		end
	else
		LOG_ERROR("call room userStandup failed! uid:%d _isstandup:%d", uid, _isstandup)
	end	
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
			LOG_DEBUG(string.format("CMD.changeRoom ok! user %s old roomid:%s,  new roomid:%s", uid, oldRoomId, newRoomId))
		else
			LOG_DEBUG(string.format("CMD.changeRoom fail! enter new room error, user %s old roomid:%s", uid, oldRoomId))
		end
	else
		LOG_DEBUG(string.format("CMD.changeRoom fail! leave old room error, user %s old roomid:%s", uid, oldRoomId))
	end

end

-- 用户离开游戏
function CMD.leaveGame(uid)
	--todo: 一些逻辑判断
	local player = player_list[uid]
	table.removeItem(group_list[player.groupid].players, uid)
	player_list[uid] = nil
	LOG_DEBUG(' -- '..uid..' leave Game successed! --')
end

-- 用户聊天
function CMD.gamechatReq(fromuid, chattype, content, touid)
	LOG_DEBUG(' -- '..fromuid.." gamechatReq --")
	if chattype == 0 or chattype == 1 or chattype == 2 or chattype == 3 then
		local ret, room = getRoomAddressByUid(fromuid)
		if ret == true then
			--分发到room
			skynet.send(room, "lua", "sendChat", fromuid, touid, chattype, content)
		end
	end
end

function CMD.cutRoom(uid)
	if not player_list[uid] then
		LOG_ERROR(string.format("CMD.cutRoom fail! user %d is not in list", uid))
		return {ret = false}
	else
		local player = player_list[uid]
		if not room_pool[player.roomid] then
			LOG_ERROR(string.format("CMD.cutRoom fail!  user %d not in roomid:%d", uid, player.roomid))
			return {ret = false, msg = "user not in roomid:"..player.roomid}
		end
		--调用room中的方法
		local bRet = skynet.call(room_pool[player.roomid].room, "lua", "userCutting", uid, room_pool[player.roomid].cutplayers)
		LOG_DEBUG(uid..' cut room successed -- ')
		return {ret = true }
	end
end

-- 用于设置玩家的占位状态
function CMD.setPlayerHoldRoomId(uid, roomId)
	LOG_DEBUG('uid = '..uid..' setHoldRoomId = '..roomId)
	if player_list[uid] then
		player_list[uid].holdRoomId = roomId
	end
end

function CMD.leaveRoom(uid)
	ret = userLeaveRoom(uid)
	return ret
end

-- 用户离开房间
function userLeaveRoom(uid)
	LOG_DEBUG('-- uid '..uid..' will leave room')
	-- 安全检查，查看用户当前是否在任何group里面
	local player = player_list[uid]
	if not player then
		LOG_ERROR(string.format("CMD.leaveRoom fail! user %d is not in list", uid))
		return {ret = false}
	else
		local room = room_pool[player.roomid]
		if not room then
			LOG_ERROR(string.format("CMD.leaveRoom fail!  user %d not in roomid:%d", uid, player.roomid))
			return {ret = false,leaveGame = true, msg = "user not in roomid:"..player.roomid}
		end
		--调用room中的方法
		local bRet, isHold = skynet.call(room.room, "lua", "leaveRoom", uid)

		if bRet == false then
			LOG_DEBUG(string.format("CMD.leaveRoom fail! user %d is playing in roomid:%d", uid, player.roomid))
			return { ret = false, msg = "can not leave from room"}
		end

		if isHold then
			player.holdRoomId = player.roomid
		else
			player.holdRoomId = 0
		end

		if player.playerstatus == Enums.PlayerState.PLAYING then
			LOG_DEBUG(string.format("CMD.leaveRoom fail! user %d is playing in roomid:%d", uid, player.roomid))
			return { ret = false, msg = "user state is playing" }
		end
		
		local roomid = player.roomid
		--从room的用户列表和举手列表中删除
		table.removeItem(room_pool[player.roomid].curplayers, uid)
		table.removeItem(room_pool[player.roomid].readyplayers, uid)
		table.removeItem(room_pool[player.roomid].watchplayers, uid)
		table.removeItem(room_pool[player.roomid].seatplayers, uid)
		table.removeItem(room_pool[player.roomid].cutplayers, uid)
		--设置用户为闲置状态

		skynet.call(player_list[uid].agent, "lua", "changePlayingStatus", false, player.groupid, player.roomid)
		
		local roomid = player_list[uid].roomid
		player_list[uid].roomid = 0
		-- dump(isHold, ' isHold = ')
		-- dump(player_list, ' player_list = ')
		local canLeaveGame = false
		if not isHold then
			canLeaveGame = true
		end
		player_list[uid].playerstatus = Enums.PlayerState.IDLE
		CheckGameStart(player.groupid, roomid)
		-- dump(player_list, ' player_list = ')
		
		-- LOG_DEBUG('-- will send leave room --')
		relay_roominfo_toclient(roomid, 
		player.playerstatus == Enums.PlayerState.PLAYING)
		
		-- dump(room_pool[roomid])
		LOG_DEBUG(uid..' leave room ..'..roomid..' successed -- ')
		return {ret = true , leaveGame = canLeaveGame}
	end
	
end

function CMD.changePlayerState(uid, state)
	local player = player_list[uid]
	if not player then
		return false
	end
	player.playerstatus = state
end

-- 用户进入开房游戏房间
function CMD.enterFangGame(uid, agent, client_fd, groupid, roompassword, roomid)
	LOG_DEBUG(string.format("user enterFangGame uid:%d agent:%d roompassword:%s", uid, agent, roompassword))
	local roomId = roomid
	if roomid ~= -1 then		--掉线重连，不用查库
		if not room_pool[roomid] or  not room_pool[roomid].room then		-- 房间不存在
			local pkg = {}
			pkg.Content = '房间已解散'
			pkg.needExit  = 1
			send_client(client_fd, send_request("vipErrorMsg", pkg))
			return
		else
			CMD.enterGame(uid, agent, client_fd, groupid)
		end
	else
		local fangRoom = skynet.call(dbmgr, "lua", "find_Fang_single", roompassword)
		-- dump(fangRoom, 'fangRoom = ')
		if not fangRoom then
			LOG_ERROR("loading room from enterFangGame error, roompassword:%s", roompassword)
			local pkg = {}
			pkg.Content = '房间不存在'
			pkg.needExit  = 1
			send_client(client_fd, send_request("vipErrorMsg", pkg))
			return
		else
			if CMD.enterGame(uid, agent, client_fd, groupid) == false then
				local pkg = {}
				pkg.Content = '房间数据异常'
				pkg.needExit  = 1
				send_client(client_fd, send_request("vipErrorMsg", pkg))
				LOG_DEBUG(string.format("CMD.enterFangGame fail! enter room error, user %s ,roomid:%s", uid, roomid))
				return
			end
			-- dump(player_list[uid], ' player = ')
			if player_list[uid].roomid ~= 0 then
				roomId = player_list[uid].roomid
			else
				if not room_pool[fangRoom.RoomRId] or not room_pool[fangRoom.RoomRId].room  then
					--房间不存在，需要创建
					LOG_DEBUG("get room from pool roomID:"..fangRoom.RoomRId)
					local newroominfo = getRoomFromPool(groupid, nil, fangRoom.RoomRId, fangRoom)
					if newroominfo then
						--local newroomlistitem = { roominfo = newroominfo, curPlayerNum = 0, curReadyNum = 0, maxPlayerNum = 2 }
						table.insert(group_list[groupid].rooms, newroominfo.roomid)
					else
						return { ret = false, msg = "当前无可用房间分配，请稍后再试" }
					end
				end
			end
			roomId = fangRoom.RoomRId
		end
	end

	local enterRet = CMD.enterRoom(uid, nil, roomId, false)
	if enterRet.ret then
		local newRoomId = player_list[uid].roomid
		LOG_DEBUG(string.format("CMD.enterFangGame ok! user %s , roomid:%s", uid, roomId))
	else
		LOG_DEBUG(string.format("CMD.enterFangGame fail! enter room error, user %s ,roomid:%s", uid, roomId))
	end
end

-- 用户进入游戏
function CMD.enterGame(uid, agent, client_fd, groupid)
	LOG_DEBUG(string.format("user enterGame uid:%d agent:%d groupid:%d", uid, agent, groupid))
	--安全检查,禁止用户重复进入
	local isCutBack = false
	for groupkey, group in pairs(group_list) do
		for key, playerid in pairs(group.players) do
			if playerid == uid then
				LOG_DEBUG(string.format("CMD.enterGame fail! duplicate user %s is already in group:%s", uid, groupkey))
				isCutBack = true
			end
		end
	end
	
	if isCutBack == false then
		-- dump(group_list, "get server group list...")
		if group_list[groupid] == nil then
			LOG_DEBUG('CMD.enterGame fail! not has the group '..groupid)
			return false
		end
		table.insert(group_list[groupid].players, uid)
		if not player_list[uid] then
			LOG_DEBUG('-- a new player enter --'..uid)
			player_list[uid] = { FD = client_fd, roomid = 0, playerstatus = Enums.PlayerState.IDLE, groupid = groupid, agent = agent }
			player_list[uid].ipaddr = skynet.call(agent, "lua", "getMyIP")
		else
			LOG_DEBUG('-- not new hold player enter --'..uid)
			player_list[uid].FD = client_fd
			player_list[uid].playerstatus = Enums.PlayerState.IDLE
			player_list[uid].groupid = groupid
			player_list[uid].agent = agent
			if player_list[uid].holdRoomId ~= nil and player_list[uid].holdRoomId ~= 0 then
				player_list[uid].roomid = player_list[uid].holdRoomId
			end
		end
		-- dump(group_list[groupid].sngConfig, 'grouSngConfig = ')
		--[[
		if RoomConstant.RoomType.SNG == group_list[groupid].roomType then  -- SNG比赛
			skynet.call(sngmgr, "lua", "signup",uid, groupid, agent, false,
			group_list[groupid].sngConfig)
		elseif RoomConstant.RoomType.VIP == group_list[groupid].roomType then
		end
		]]
	else
		--掉线重入的话只需要修改用户的FD和agent地址，因为agent现在有可能是一个新创建的了（之前的可能会超时释放掉)
		player_list[uid].FD = client_fd
		player_list[uid].agent = agent
	end
	LOG_DEBUG("uid:"..uid.." racemgr enterGame finish")
	return true
end



-- 分配一个room
function CMD.allocateValidRoom(groupid, roundid)
	local newroominfo = getRoomFromPool(groupid, roundid)
	if newroominfo then
		if table.keyof(group_list[groupid].rooms, newroominfo.roomid) == nil then
			table.insert(group_list[groupid].rooms, newroominfo.roomid)
		end
	end
	return newroominfo
end

-- 开始游戏
function CMD.startGame(roomid, groupid)
	room_pool[roomid].roomstatus = Enums.RoomState.PLAYING
	-- dump(room_pool[roomid].seatplayers, "seatPlayers")
	--清空举手表
	room_pool[roomid].readyplayers = {}	
	skynet.call(room_pool[roomid].room, "lua", "startGame")
	--通知agent状态
	for _, uid in pairs(room_pool[roomid].curplayers) do
		skynet.call(player_list[uid].agent, "lua", "changePlayingStatus", true, groupid, roomid)
	end
end

--用户进入房间, 如果有oldRoomId代表是换房间操作，需要分配不同的房间
--newRoomId 普通用户进入无需调用 是给robot准备的
function CMD.enterRoom(uid, oldRoomId, newRoomId, _isRobot)
	local player = player_list[uid]
	local isCutBack = false
	local isRobot = _isRobot
	if not player then
		LOG_DEBUG(string.format("CMD.enterRoom fail! user %s is not found in player_list", uid))
		return { ret = false, msg = "用户尚未进入游戏"}
	end
	
	if player.roomid > 0 and player.holdRoomId == 0 then
		LOG_DEBUG(string.format("CMD.enterRoom fail! duplicate user %s is already in roomid:%s", uid, player.roomid))
		--return { ret = false, msg = "用户已在房间中"}
		isCutBack = true
	end
	
	if isCutBack then
		table.removeItem(room_pool[player.roomid].cutplayers, uid)
		send_client(player_list[uid].FD, send_request("enterroomRes", getEnterRoomRes(player.roomid, true)))
		skynet.call(room_pool[player.roomid].room, "lua", "userCutBack", uid, player.FD, room_pool[player.roomid].cutplayers)
		return { ret = true}
	end
	
	local groupid = player.groupid

	local group = group_list[groupid]
	if group then
		local bFind = false
		local roominfoitem

		local findedRoomId = 0
		
		if player.holdRoomId ~= nil and player.holdRoomId > 0 then
			findedRoomId = player.holdRoomId
			LOG_DEBUG("enterRoom with holdRoomId:"..findedRoomId)
		elseif newRoomId then
			findedRoomId = newRoomId
			LOG_DEBUG("enterRoom with newRoomId:"..newRoomId)
		else
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
				LOG_DEBUG("group rooms is null, groupid:"..groupid)
			end

			-- group中没有合适的房间可用
			if bFind == false then
				local newroominfo = getRoomFromPool(groupid)
				if newroominfo then
					--local newroomlistitem = { roominfo = newroominfo, curPlayerNum = 0, curReadyNum = 0, maxPlayerNum = 2 }
					table.insert(group_list[groupid].rooms, newroominfo.roomid)
					findedRoomId = newroominfo.roomid
				else
					return { ret = false, msg = "当前无可用房间分配，请稍后再试" }
				end
			end
		end

		

		-- 开始操作房间
		local enterOK, isPlayer, resultSeat = skynet.call(room_pool[findedRoomId].room, "lua", "enterRoom", uid, player.agent, player.FD, isRobot)
		if enterOK then
			addRoomCurPlayer(room_pool[findedRoomId], uid)
			if isPlayer then
				addRoomSeatPlayer(room_pool[findedRoomId], uid)
				player_list[uid].playerstatus = Enums.PlayerState.SEAT
			else
				addRoomWatcher(room_pool[findedRoomId], uid)
				player_list[uid].playerstatus = Enums.PlayerState.WATCH
			end

			addRoomEnteredPlayer(room_pool[findedRoomId], uid)
			player_list[uid].roomid = findedRoomId
			
			dump(room_pool[findedRoomId], " room_pool")
			dump(player_list[uid], "player = ")
			
			--给用户发送当前房间的信息
			send_client(player_list[uid].FD, send_request("enterroomRes", getEnterRoomRes(findedRoomId, true)))
			
			relay_roominfo_toclient(findedRoomId, false)
			-- 2017.4.6 把当前已准备玩家的消息发下玩家
			-- local readyPlayers = room_pool[findedRoomId].readyplayers
			-- local userreadyNotify = {}
			-- for _, uidOther in pairs(readyPlayers) do
			-- 	userreadyNotify.uid = uidOther
			-- 	userreadyNotify.pos = 0
			-- 	send_client(player_list[uid].FD, send_request("userreadyNotify", userreadyNotify))
			-- end
			return { ret = true, pos = resultSeat}
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

--给rest服务提供解散房间接口
function CMD.disbandroom(roomid)
	LOG_DEBUG('disbandroom id = '..roomid)
	local result = {}
	result.ret = false
	result.message = "测试解散房间失败"
	--todo: 需要调用具体的游戏接口去解散房间
	-- 解散成功了result.ret = true
	-- 解散失败了result.ret = false 并且  result.message 为失败原因
	local room  = room_pool[roomid]
	if room then
		result.ret = skynet.call(room.room, 'lua', 'masterDisband')
	end
	if result.ret then
		result.message = "测试解散房间成功"
	else
		result.message = "解散房间失败，该房间已解散"
	end
	return result
end

--给rest服务反馈当前状态
function CMD.stats()
	local stat = {}
	local stat_group = {}
	for gid, value in pairs(group_list) do
		local item = {}
		item["id"] = gid
		item["players"] = table.clone(value.players)
		item["rooms"] = table.clone(value.rooms)
		item["minplayer"] = value.minplayer
		item["maxplayer"] = value.maxplayer
		item["mincoin"] = value.mincoin
		item["maxcoin"] = value.maxcoin
		item["gameBeginType"] = value.gameBeginType
		item["roundTime"] = value.roundTime
		table.insert(stat_group, item)
	end
	stat["group"] = stat_group
	
	local stat_room = {}
	for rid, value in pairs(room_pool) do
		local item = {}
		item["id"] = rid
		item["groupid"] = value.groupid
		item["address"] = value.room
		item["status"] = value.roomstatus
		item["version"] = value.version
		item["curplayers"] = table.clone(value.curplayers)
		item["readyplayers"] = table.clone(value.readyplayers)
		item["seatplayers"] = table.clone(value.seatplayers)
		item["watchplayers"] = table.clone(value.watchplayers)
		item["cutplayers"] = table.clone(value.cutplayers)
		table.insert(stat_room, item)
	end
	stat["room"] = stat_room
	
	local stat_user = {}
	for uid, value in pairs(player_list) do
		local item = {}
		item["uid"] = uid
		item["agent"] = value.agent
		item["roomid"] = value.roomid
		item["groupid"] = value.groupid
		item["playerstatus"] = value.playerstatus
		
		table.insert(stat_user, item)
	end
	stat["player"] = stat_user
	--dump(stat)
	return stat
end

function CMD.RequestGame(uid, name, args)
	LOG_DEBUG('RequestGame uid = '..uid..' name = '..name)
	local ret, room = getRoomAddressByUid(uid)
	-- dump(ret)
	if ret == true then
		--分发到room
		skynet.call(room, "lua", "dispatchGameRequest", uid, name, args)
	end
end

-- 由反作弊服务调用通知room反作弊查询的结果
-- roomid 目标roomid
-- msg 输出给客户端的提示信息
-- cheatuids 有作弊可能的uid列表，给非该uid列表中的用户发送通知，在这个列表中的用户就不通知了
function CMD.NotifyAntiCheatResult(roomid, msg, cheatuids)
	-- todo: 通知到相应的room中
	local room = room_pool[roomid]
	if room then
		skynet.send(room.room, 'lua', 'onAniCheatReulst', msg, cheatuids)
	else
		LOG_DEBUG('on Anti Cheat Result room '..roomid..' is not exsit')
	end
	
end

function CMD.open()
	print("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx:"..skynet.getenv("nodeid"))
	local nMaxRooms = (tonumber(skynet.getenv("maxrooms")) or 2000)
	nStepRooms = nMaxRooms / 10
	LOG_DEBUG("precreate %d rooms", nStepRooms)
	for i = 1, nStepRooms do
        --CreateRoom(i)
	end
	--LOG_DEBUG("GameServerGroup  app.RId:"..tonumber(skynet.getenv("gameid")))
	local groupList = skynet.call(dbmgr, "lua", "get_group_list", tonumber(skynet.getenv("gameid")), tonumber(skynet.getenv("nodeid")))
	dump(groupList, "groupList")
    for _, value in pairs(groupList) do
		--dump(value, "group list item...")
        group_list[value.GroupId] = { minplayer = value.MinPlayers or tonumber(skynet.getenv("minPlayers")), 
					maxplayer = value.MaxPlayers or tonumber(skynet.getenv("maxPlayers")), 
					gameBeginType = Enums.GameBeginType.ALLREADY_MORETHAN_MINPLAYER, 
					mincoin = value.MinCoin, 
					maxcoin = value.MaxCoin,
                    unitcoin = value.UnitCoin,
					roomType = value.RoomType,
					tax = value.Tax,
					rooms = {}, 
					roundTime = value.operationtimeoutServer,
					roundTimeClient = value.operationtimeoutClient,
					matchConfig = value.matchConfig or {},
					sngConfig = value.sngConfig or {},
					players = {} }
    end

    dump(group_list, 'gameraceMgr Open')

	--todo:一个定时器，扫描当前房间的状态进行动态扩容/缩容
	--如果80%都处于使用状态的话，那么增加 maxrooms/10 直到>=maxrooms
	--如果80%都处于空闲状态的话，那么减少 maxrooms/10 直到<=maxrooms/10  （这是个可选项）
end

function judgePlayerCoinValid(_groupId, _uid)

end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
    
    if not dbmgr then
		dbmgr = skynet.uniqueservice("dbmgr")
	end

	--if not sngmgr then
	--	sngmgr = skynet.uniqueservice("sngmgr")
	--end
	
	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))
	
	--local servicemgr = skynet.uniqueservice("servicemgr")
	--local serviceName = skynet.call(servicemgr, "lua", "regInterService", SERVICE_NAME)
	skynet.call(".logger", "lua", "regInterService", SERVICE_NAME)
	skynet.register(SERVICE_NAME)
end)