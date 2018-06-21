--
-- Author: Liuq
-- Date: 2016-04-20 00:32:20
--
local skynet = require "skynet"
local queue = require "skynet.queue"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local snax = require "snax"
local lock = queue()  -- cs 是一个执行队列
local cluster = require "cluster"

local dbmgr
local sngmgr = nil
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

local function CreateRoom(roomid, _roomType)
	LOG_DEBUG("createRoom call %d, %s", roomid, _roomType)
    local roomaddr = skynet.newservice("room", _roomType)
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
    local groupid = room_pool[roomid].groupid
    table.removeItem(group_list[groupid].rooms, roomid)
    skynet.send(room_pool[roomid].room, "lua", "resetRoom")
    LOG_DEBUG(string.format("room %d is exited", roomid))
	if notCreate == nil then
    	CreateRoom(roomid, group_list[groupid].roomType)
	end
end

-- 检查房间是否满足开始条件，满足开始条件的话就开始游戏
local function CheckGameStart(groupid, roomid)
	--不处理正在游戏的房间检查
	local room = room_pool[roomid]
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
	
	if room.roomType == RoomConstant.RoomType.SNG then 
		if #room.curplayers == 0 and #room.watchplayers == 0 then
			ResetRoom(roomid)
		end
		return 
	end
	
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
					--通知agent状态
					for _, uid in pairs(room.curplayers) do
						skynet.call(player_list[uid].agent, "lua", "changePlayingStatus", true, groupid, roomid)
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
						skynet.call(player_list[uid].agent, "lua", "changePlayingStatus", true, groupid, roomid)
					end
				end
			end
		end
	end
    
    --当房间中没有人时回收该房间
	if room.roomType == RoomConstant.RoomType.VIP then
		LOG_DEBUG("roomtype is VIP, room data saved.")
		if room.isReleased then
			if #room.curplayers == 0 and #room.watchplayers == 0 then
				local roomAddr = room.room
				room = nil
				skynet.send(roomAddr, "lua", "resetRoom")
			end
		end
	else
		if #room.curplayers == 0 and #room.watchplayers == 0 then
			ResetRoom(roomid)
		end
	end
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
	--通过platform透传消息给客户端
	local ok, gamenodedb = pcall(cluster.query, "platform", "gamenodedb")
	if not room_pool[roomId] then
		ok = false
	end
	if not ok then
		LOG_ERROR("connect to platform server error, skipping!")
	else
		proxyGameNodeMgr = cluster.proxy("platform", gamenodedb)
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

		local regret = skynet.call(proxyGameNodeMgr, "lua", "relay_to_client", notifyUids, notifyCMD, notifyData)
		if regret.ret == true then
			LOG_DEBUG("relay msg to platform server success!")
		else
			LOG_ERROR("relay msg to platform server failed!")
		end
	end
end

local function getEnterRoomRes(_roomid, _ret, _initMoney)
	local enterroomRes = {}
	local room = room_pool[_roomid]
	enterroomRes.ret = _ret
	enterroomRes.roomid = _roomid
	enterroomRes.players = {}
	enterroomRes.maxplayer = room.maxplayernum
	enterroomRes.unitcoin = room.unitcoin
	if not user_dc then
		user_dc = snax.uniqueservice("userdc")
	end

	-- 若是锁定过的房间，则发送当前锁定玩家的信息
	local lockedPlayers = skynet.call(room.room, 'lua', 'getLockedPlayer')
	-- 有占位玩家的，则发送已占位玩家的信息
	local holdPlayers = skynet.call(room.room, 'lua', 'getHoldPlayers')
	dump(holdPlayers, ' holdPlayers = ')
	dump(room.seatplayers, 'seatPlayer')
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
				playerData.money = user_dc.req.getvalue(playerid, "CoinAmount")
				if type(1) ~= type(_initMoney) then
					playerData.sngScore = skynet.call(sngmgr, "lua", "getMoney", playerid, _roomid)
				else
					playerData.sngScore = _initMoney
				end
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
	local room = room_pool[roomid]
	if room then
		local ret = true
		-- if room.roomType == RoomConstant.RoomType.VIP then
		-- 	ret = skynet.call(dbmgr, 'lua', 'update_Fang_status', room.roomid, kVipRoomState.disband)
		-- end
		if ret then
			LOG_DEBUG('-- requestReleaseRoom --'..roomid)
			local groupid = room_pool[roomid].groupid
			table.removeItem(group_list[groupid].rooms, roomid)
			-- skynet.call(room_pool[roomid].room, "lua", "resetRoom")
			LOG_DEBUG(string.format("room %d is released", roomid))
			room_pool[roomid].isReleased = true
		end
	end
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
		CMD.leaveRoom(uid)
		table.removeItem(group_list[player.groupid].players, uid)
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
		room_pool[player.roomid].roomstatus = Enums.RoomState.WAIT
    end
end

function CMD.userSelectSeat(uid, pos)
	local player = player_list[uid]
	if player then
		local roomid = player_list[uid].roomid
		local room = room_pool[roomid]
		local ret = skynet.call(room.room, "lua", "userSelectSeat", uid, pos)
		if ret then  -- 已坐下
			player.playerstatus = Enums.PlayerState.SEAT
			table.removeItem(room.readyplayers, uid)
			table.removeItem(room.seatplayers, uid)
			table.removeItem(room.watchplayers, uid)
			table.insert(room.seatplayers, uid)
			player_list[uid].playerstatus = Enums.PlayerState.SEAT
		else -- 未坐下
			table.removeItem(room.readyplayers, uid)
			table.removeItem(room.seatplayers, uid)
			table.removeItem(room.watchplayers, uid)
			table.insert(room.watchplayers, uid)
			player_list[uid].playerstatus = Enums.PlayerState.WATCH
			--给用户发送当前房间的信息
			--send_client(player_list[uid].FD, send_request("enterroomRes", getEnterRoomRes(roomid, true)))
		end
	end
end

function CMD.userQuit(uid)
	local player = player_list[uid]
	if player then
		local roomid = player_list[uid].roomid
		local room = room_pool[roomid]
		local ret = skynet.call(room.room, "lua", "userQuit", uid)
		if ret then
			player.playerstatus = Enums.PlayerState.SEAT
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
		table.insert(room.readyplayers, uid)
		-- local beforeSeat = skynet.call(room.room, "lua", "getPlayerPos", uid)
		skynet.call(room.room, "lua", "userReady", uid, othersUid)
		--因为包间是准备以后再分配座位了，所以得重新发送一下当前的玩家坐位
		-- skynet.call(room.room, "lua", "getPlayerPos", uid)
		dump(room.readyplayers, 'room.readyplayers = ')
		local groupid = room.groupid
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
			table.insert(room_pool[roomid].watchplayers, uid)
			
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
function CMD.gamechatReq(uid, range, content)
	if range == 1 then
		local ret, room = getRoomAddressByUid(uid)
		if ret == true then
			--分发到room
			skynet.call(room, "lua", "sendChat", uid, range, content)
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

-- 用户离开房间
function CMD.leaveRoom(uid)
	-- 安全检查，查看用户当前是否在任何group里面
	if not player_list[uid] then
		LOG_ERROR(string.format("CMD.leaveRoom fail! user %d is not in list", uid))
		return {ret = false}
	else
		local player = player_list[uid]
		if not room_pool[player.roomid] then
			LOG_ERROR(string.format("CMD.leaveRoom fail!  user %d not in roomid:%d", uid, player.roomid))
			return {ret = false, msg = "user not in roomid:"..player.roomid}
		end
		--调用room中的方法
		local bRet = skynet.call(room_pool[player.roomid].room, "lua", "leaveRoom", uid)
		
		if bRet == false then
			LOG_DEBUG(string.format("CMD.leaveRoom fail! user %d is playing in roomid:%d", uid, player.roomid))
			return { ret = false, msg = "can not leave from room"}
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
		player_list[uid].playerstatus = Enums.PlayerState.IDLE
		local roomid = player_list[uid].roomid
		player_list[uid].roomid = 0
		CheckGameStart(player.groupid, roomid)
		
		LOG_DEBUG('-- will send leave room --')
		relay_roominfo_toclient(roomid, 
		player.playerstatus == Enums.PlayerState.PLAYING)
		
		-- dump(room_pool[roomid])
		LOG_DEBUG(uid..' leave room successed -- ')
		return {ret = true }
	end
	
end

function CMD.changePlayerState(uid, state)
	local player = player_list[uid]
	if not player then
		return false
	end
	player.playerstatus = state
end

-- SNGWEB报名,玩家先于WEB报名则不处理
function CMD.SNGSignUp(uid, groupid)
	local player = player_list[uid]
	if player then
		return
	end
	if RoomConstant.RoomType.SNG ~= group_list[groupid].roomType then  -- SNG比赛
		return
	end

	if table.keyof(group_list[groupid].players, uid) == nil then
		table.insert(group_list[groupid].players, uid)
	end
	local agent = skynet.newservice "gamemsgagent"
	
	skynet.call(agent, "lua", "setUserID", uid)
	skynet.call(agent, "lua", "setHoldFlag", true)

	player_list[uid] = { FD = 0, roomid = 0, playerstatus = Enums.PlayerState.IDLE, groupid = groupid, agent = agent, isHold = true}
	player_list[uid].ipaddr = skynet.call(agent, "lua", "getMyIP")
	if RoomConstant.RoomType.SNG == group_list[groupid].roomType then  -- SNG比赛
		local success = skynet.call(sngmgr, "lua", "signup",uid, groupid, agent, true,
		group_list[groupid].sngConfig)
		if success then
			player_list[uid].playerstatus = Enums.PlayerState.SNGSIGNUP
		end
	end
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
		dump(fangRoom, 'fangRoom = ')
		if not fangRoom then
			LOG_ERROR("loading room from FangRoom error, roompassword:%s", roompassword)
			local pkg = {}
			pkg.Content = '房间不存在'
			pkg.needExit  = 1
			send_client(client_fd, send_request("vipErrorMsg", pkg))
			return
		else
			CMD.enterGame(uid, agent, client_fd, groupid)
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

-- 用户进入sng游戏,如果是掉线的，则主动帮玩家进入房间
-- 不是则待待分配
function CMD.enterSNGGame(uid, agent, client_fd, groupid, roundid)
	LOG_DEBUG(string.format("user enterSNGGame uid:%d agent:%d groupid:%d", uid, agent, groupid))
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

	--若是占位玩家，则需要整体换掉agent
	if player_list[uid] and player_list[uid].isHold then
		player_list[uid].agent = agent
		player_list[uid].FD = client_fd
		player_list[uid].isHold = false
		player_list[uid].ipaddr = skynet.call(agent, "lua", "getMyIP")
	end
	
	if isCutBack == false then
		if table.keyof(group_list[groupid].players, uid) == nil then
			table.insert(group_list[groupid].players, uid)
		end
		player_list[uid] = { FD = client_fd, roomid = 0, playerstatus = Enums.PlayerState.IDLE, groupid = groupid, agent = agent }
		player_list[uid].ipaddr = skynet.call(agent, "lua", "getMyIP")
		if RoomConstant.RoomType.SNG == group_list[groupid].roomType then  -- SNG比赛
			-- dump(group_list[groupid].sngConfig, 'grouSngConfig = ')
			local success = skynet.call(sngmgr, "lua", "signup",uid, groupid, agent, false,
			group_list[groupid].sngConfig)
			if success then
				player_list[uid].playerstatus = Enums.PlayerState.SNGSIGNUP
			end
		end
	else
		--掉线重入的话只需要修改用户的FD,只有非机器人才会掉线重连
		player_list[uid].FD = client_fd
		local bRet = skynet.call(sngmgr, "lua", 'onPlayerLoadingNotify', uid, groupid)
		if false == bRet then
			LOG_DEBUG("sync player loading notify fail.")
			return
		end
		enterSNGPlayingRoom(uid)
	end
	LOG_DEBUG("racemgr enterSNGGame finish")
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
		table.insert(group_list[groupid].players, uid)
		player_list[uid] = { FD = client_fd, roomid = 0, playerstatus = Enums.PlayerState.IDLE, groupid = groupid, agent = agent }
		player_list[uid].ipaddr = skynet.call(agent, "lua", "getMyIP")
		-- dump(group_list[groupid].sngConfig, 'grouSngConfig = ')
		if RoomConstant.RoomType.SNG == group_list[groupid].roomType then  -- SNG比赛
			skynet.call(sngmgr, "lua", "signup",uid, groupid, agent, false,
			group_list[groupid].sngConfig)
		elseif RoomConstant.RoomType.VIP == group_list[groupid].roomType then
		end
	else
		--掉线重入的话只需要修改用户的FD
		player_list[uid].FD = client_fd
	end
	
	LOG_DEBUG("racemgr enterGame finish")
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

-- 进入已分配好的房间
function CMD.enterAllocatedRoom(roomid, uid, isRobot, initMoney)
	local player = player_list[uid]
	local isCutBack = false
	if not player then
		LOG_DEBUG(string.format("CMD.enterRoom fail! user %s is not found in player_list", uid))
		return { ret = false, msg = "用户尚未进入游戏"}
	end
	LOG_DEBUG('enterAllocatedRoom --'..' uid = '..uid..' agent = '..player.agent..' roomid = '..roomid)
	local group = group_list[player.groupid]
	if group then
		if not room_pool[roomid] then
			LOG_DEBUG('-- enterAllocatedRoom 指定的房间不存在'..roomid)
			return {ret = false, msg = "指定的房间不存在"}
		end
		-- 开始操作房间
		local enterOK, isPlayer, resultSeat = skynet.call(room_pool[roomid].room, "lua", "enterRoom", 
		uid, player.agent, player.FD, isRobot, initMoney)
		if enterOK then
			table.insert(room_pool[roomid].curplayers, uid)
			if isPlayer then
				table.insert(room_pool[roomid].seatplayers, uid)
				player_list[uid].playerstatus = Enums.PlayerState.SEAT
			else
				table.insert(room_pool[roomid].watchplayers, uid)
				player_list[uid].playerstatus = Enums.PlayerState.WATCH
			end
			player_list[uid].roomid = roomid
			--dump(room_pool[roomid])
			--dump(player_list[uid])
			--给用户发送当前房间的信息
			send_client(player_list[uid].FD, send_request("enterroomRes", getEnterRoomRes(roomid, true, initMoney)))
			
			return { ret = true, pos = resultSeat}
		else
			--todo: 用户进入房间失败，需要通知客户端
			LOG_DEBUG('-- enterAllocatedRoom 进入房间失败')
			return { ret = false, msg = "进入房间失败"}
		end
	else
		LOG_DEBUG('-- enterAllocatedRoom 不存在的房间分组信息')
		return { ret = false, msg = "不存在的房间分组信息" }
	end
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
	
	if player.roomid > 0 then
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
		
		if newRoomId then
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
			table.insert(room_pool[findedRoomId].curplayers, uid)
			if isPlayer then
				table.insert(room_pool[findedRoomId].seatplayers, uid)
				player_list[uid].playerstatus = Enums.PlayerState.SEAT
			else
				table.insert(room_pool[findedRoomId].watchplayers, uid)
				player_list[uid].playerstatus = Enums.PlayerState.WATCH
			end

			local bInList = false
			for _, entereduid in pairs(room_pool[findedRoomId].enteredplayers) do
				if entereduid == uid then
					bInList = true
				end
			end

			if bInList == false then
				table.insert(room_pool[findedRoomId].enteredplayers, uid)
			end
			
			
			player_list[uid].roomid = findedRoomId
			
			dump(room_pool[findedRoomId], " room_pool")
			dump(player_list[uid], "player 11172")
			
			--给用户发送当前房间的信息
			send_client(player_list[uid].FD, send_request("enterroomRes", getEnterRoomRes(findedRoomId, true)))
			
			relay_roominfo_toclient(findedRoomId, false)
			
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

function enterSNGPlayingRoom(uid)
	local player = player_list[uid]
	if nil == player then
		LOG_DEBUG("user: "..uid.." cut back sng game fail.")
		return 
	end
	local roomId = player.roomid
	local roomInfo = room_pool[roomId]
	if nil == roomInfo then
		LOG_DEBUG("user:"..uid.." query roomInfo is nil")
		return 
	end

	table.removeItem(roomInfo.cutplayers, uid)
	send_client(player.FD, send_request("enterroomRes", getEnterRoomRes(roomId, true)))
	skynet.call(roomInfo.room, "lua", "userCutBack", uid, player.FD)
end

function CMD.updatePlayerScore(roomId, uid, score)
	local roomInfo = room_pool[roomId]
	if nil ~= roomInfo then
		local room = roomInfo.room
		if nil ~= room then
			skynet.call(room, "lua", "updatePlayerScore", uid, score)	
		end
	else
		LOG_DEBUG("roomId:"..roomId.." is not Exist.")
	end
end

function getPlayerScore(roomId, uid)
	local roomInfo = room_pool[roomId]
	if nil ~= roomInfo then
		local room = roomInfo.room 
		if nil ~= room then
			return skynet.call(room, "lua", "getPlayerScore", uid)
		end
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
    
    if not dbmgr then
		dbmgr = skynet.uniqueservice("dbmgr")
	end

	if not sngmgr then
		sngmgr = skynet.uniqueservice("sngmgr")
	end
	
	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))
	--[[
	send_request1 = host:attach(sprotoloader.load(1))
	
	local chattest = {}
	chattest.chatcontent = "this is demo chat!"
	local ccc = send_request1("gamechatReq", chattest)
	local unccc = sproto.unpack(ccc)
	
	local bytes = {string.byte(ccc, 0, -1)}
	local unbytes = {string.byte(unccc, 0, -1)}
	local ttt = table.concat(bytes, ', ')
	local unttt = table.concat(unbytes, ', ')
	dump(ttt)
	dump(unttt)
	]]
end)