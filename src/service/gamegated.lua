--
-- Author: Liuq
-- Date: 2016-04-18 11:56:39
--
local msgserver = require "snax.gatewayserver"
local crypt = require "crypt"
local skynet = require "skynet"
local cluster = require "cluster"

require "skynet.manager"

-------local loginservice = tonumber(...)

local server = {}
local users = {}
local username_map = {}
local internal_id = 0

function server.init_handler()

end

--服务器关闭了
function server.serverShutdown()
	LOG_INFO("gamegated going shutdown")
	--退出服务
	skynet.exit()
	
	return true
end

-- 与游服握手成功后回调
function server.auth_handler(username, fd, addr)
	local uid = msgserver.userid(username)
	uid = tonumber(uid)

	LOG_DEBUG(string.format("notify agent uid=%d is real login ip:%s", uid, addr))
	skynet.call(users[uid].agent, "lua", "auth", uid, fd, addr)	-- 通知agent认证成功，玩家真正处于登录状态了
end

-- 获取所有的在线agent列表
function server.get_agents()
	local agnets = {}
	for k, v in pairs(users) do
		agents[k] = v.agent
	end
	return agents
end

function server.online_handler(uid, fd)
	skynet.call(users[uid].agent, "lua", "online", uid, fd)
end

-- 获取在线玩家uid所对应的agent
function server.get_agent(uid)
	uid = tonumber(uid)
	if users[uid] then
		return users[uid].agent
	end
end

function server.is_online(uid)
	uid = tonumber(uid)
	if users[uid] then
		return true
	else
		return false
	end
end

-- login server disallow multi login, so login_handler never be reentry
-- call by login server
-- 内部命令login处理函数
-- 玩家登录 登录服务器成功后，调用此函数登录游戏服务器

function server.login_handler(uid, secret, lobbyNodeName)
	uid = tonumber(uid)
	
	internal_id = internal_id + 1
	local id = internal_id	-- don't use internal_id directly
	local username = msgserver.username(uid, id, servername)
	LOG_DEBUG(string.format("server.login_handler username:%s", username))
	local agent
	-- 如果用户已经登录过
	if users[uid] then
		--error(string.format("%s is already login", uid))
		LOG_DEBUG(string.format("%s is already login", uid))
		
		agent = users[uid].agent
		local oldusername = users[uid].username
		-- 先执行gate上的注销，将断开先前socket连接
		msgserver.disconnect(oldusername)
		
		LOG_DEBUG(string.format("server.login_handler duplicate login old username:%s is disconnect", oldusername))
	else
		-- 构造agent的时候传入uid 方便在debug_console中根据uid定位服务
		agent = skynet.newservice("gamemsgagent", uid)		
	end
	
	local u = {
		username = username,
		agent = agent,
		uid = uid,
		subid = id,
	}
	
	
		
	users[uid] = u

	-- trash subid (no used)
	skynet.call(agent, "lua", "login", uid, id, secret, lobbyNodeName)

	username_map[username] = u

	msgserver.login(username, secret)

	-- you should return unique subid
	return id
end

-- call by agent
-- 内部命令logout处理函数
function server.logout_handler(uid, subid)
	uid = tonumber(uid)
	local u = users[uid]
	if u then
		local username = msgserver.username(uid, subid, servername)
		assert(u.username == username)
		msgserver.logout(u.username)
		users[uid] = nil
		username_map[u.username] = nil
		-------skynet.call(loginservice, "lua", "logout",uid, subid)
	end
end

-- call by login server
-- 内部命令kick处理函数
-- 玩家登录 登录服务器，发现用户已登录到其他游戏服务器，调用此函数踢掉
function server.kick_handler(uid, subid)
	uid = tonumber(uid)
	local u = users[uid]
	if u then
		local username = msgserver.username(uid, subid, servername)
		assert(u.username == username)
		-- NOTICE: logout may call skynet.exit, so you should use pcall.
		pcall(skynet.call, u.agent, "lua", "logout")
	end
end

-- call by self (when socket disconnect)
function server.disconnect_handler(username)
	LOG_DEBUG(string.format("server.disconnect_handler username:%s", username))
	local u = username_map[username]
	if u then
		skynet.call(u.agent, "lua", "afk")
	end
end

-- call by self (when recv a request from client)
function server.request_handler(username, msg)
	--print("request_handler: username:"..username.."   msg:"..msg)
	-----local u = username_map[username]
	-----return skynet.tostring(skynet.rawcall(u.agent, "client", msg))
	local u = username_map[username]
	local agent = u.agent
	if agent then
		skynet.redirect(agent, 0, "client", 0, msg)
	end
end

-- call by self (when gate open)
function server.register_handler(name)
	servername = name
	cluster.register("gated")

	--local servicemgr = skynet.uniqueservice("servicemgr")
	--local serviceName = skynet.call(servicemgr, "lua", "regInterService", SERVICE_NAME)
	skynet.call(".logger", "lua", "regInterService", SERVICE_NAME)
	skynet.register(SERVICE_NAME)
end

msgserver.start(server)