--
-- Author: Liuq
-- Date: 2016-04-20 00:34:48
--
local skynet = require "skynet"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

local CMD = {}
local REQUEST = {}    --游戏逻辑命令
local players = {}
local minPlayer
local maxPlayer
local RACEMGR

local ROOMMAXUSER = 99   --房间最大人数，与maxplayer的区别是 maxplayer是座位数  而这个包含了旁观者的数量

local host
local send_request

local roomid = tonumber(...)
--游戏开始类型
-- 1:maxPlayer都准备请求后就开始
-- 2:当前房间中用户数量大于等于minPlayer并且都准备后就开始
-- 3:当前房间中准备用户数量大于等于minPlayer就开始，即使有其他玩家在座位上并未准备（类似德州扑克）
local gameBeginType       

--发送房间聊天
function CMD.sendChat()

end

--玩家请求开始（准备）
function CMD.startGameReq()

end

-- 用户站起来，进入旁观状态
function CMD.userStandup(uid)

end

-- 用户坐下，进入准备游戏状态
function CMD.userSeatdown(uid)
    
end

function REQUEST:playcard(data)
	print("recv user playcard msg, uid:"..self)
	dump(data)
	
	
	local tbtest = {}
	table.insert(tbtest, {fa = "fa1", fb = 1})
	table.insert(tbtest, {fa = "fa2", fb = 2})
	local playcardNotify = { uid = self, card = data.card, testa = tbtest}
	
	for _, player in pairs(players) do
		send_client(player.client_fd, send_request("playcardNotify", playcardNotify))
	end
	
	skynet.error("brocast user playcard ok!")
end

local function request(uid, name, args)
	local f = assert(REQUEST[name])
	local r = f(uid, args)
end

-- 游戏自身包的入口
-- uid 用户id
-- packagename 消息名称
-- request 消息内容
function CMD.dispatchGameRequest(uid, name, args)
	skynet.error(string.format("recv game self data, from uid:%s  name:%s", uid, name))
	local ok, result  = pcall(request, uid, name, args)
	if not ok then
		skynet.error(result)
	end
end

-- 游戏开始
function CMD.startGame()
	-- 向玩家广播开始消息
	
	local beginNotify = { roomid = roomid, status = Enums.RoomState.PLAYING }
	for _, player in pairs(players) do
		send_client(player.client_fd, send_request("roomstatuNotify", beginNotify))
	end
	
	
end

--玩家离开房间
function CMD.leaveRoom(uid)
	
	
	
	-- 玩家能否离开房间由room决定  如果可以离开清理room里面的用户信息并返回true  否则返回false
	for seatid, player in pairs(players) do
		if player.uid == uid then
		
			--only test demo for call db
			skynet.call(players[seatid].agent, "lua", "saveGameRecord", roomid, seatid,
				11, 12, 13, 14, 15, 16, 17, 18)
		
			players[seatid] = nil
			break
		end
	end
	return true
end

--玩家准备
function CMD.userReady(uid)
	print("user:"..uid.."  is ready! roomid:"..roomid)
	
	for seatid, player in pairs(players) do
		if player.uid == uid then
			if seatid <= maxPlayer then
				return true
			end
		end
	end
	
	return false
	
end

-- 玩家掉线重入
function CMD.userCutBack(uid, client_fd)
	local resultSeat = 0
	for seatId = 1, maxPlayer, 1 do
		if players[seatId] then
			if players[seatId].uid == uid then
				resultSeat = seatId
			end
		end
	end
	
	players[resultSeat].client_fd = client_fd
	
	skynet.error(string.format("player cut back, uid:%d seatid:%d fd:%d", uid, resultSeat, client_fd))

	--以下开始处理游戏掉线后的逻辑
end

--玩家正常进入房间
function CMD.enterRoom(uid, agent, client_fd)
	-- 需要返回是否enter成功，并且用户是否是player(否则为watcher)
	local resultSeat = 0
	for seatId = 1, ROOMMAXUSER, 1 do
		if not players[seatId] then
			players[seatId] = { uid = uid, agent = agent, client_fd = client_fd }
			resultSeat = seatId
			break
		end
	end
	dump(players)
	print("user:"..uid.."  is enter room! roomid:"..roomid.."   maxPlayer:"..maxPlayer.."  resultSeat:"..resultSeat)
	if resultSeat > 0 then
		if resultSeat <= maxPlayer then
			return true, true
		else
			-- watcher
			return true, false
		end
	else
		return false, false
	end

end

--重置房间，用于回收回房间池中
function CMD.uninit()
	players = {}
end

--初始化房间
function CMD.init(raceMgr, roomminPlayer, roommaxPlayer)

	
	RACEMGR = raceMgr
	minPlayer = roomminPlayer
	maxPlayer = roommaxPlayer
	
	print("room CMD.init  minPlayer:"..minPlayer.."   maxPlayer:"..maxPlayer.." roomid:"..roomid)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
	
	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))

end)