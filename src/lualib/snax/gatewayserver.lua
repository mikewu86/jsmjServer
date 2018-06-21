--
-- Author: Liuq
-- Date: 2016-04-18 14:21:19
--
local skynet = require "skynet"
require "skynet.manager"
local gateserver = require "snax.gateserver"
local netpack = require "netpack"
local crypt = require "crypt"
local socketdriver = require "socketdriver"
local assert = assert
local b64encode = crypt.base64encode
local b64decode = crypt.base64decode
local md5    = require "md5"

--[[
Protocol:
	All the number type is big-endian
	Shakehands (The first package)
	Client -> Server :
	base64(uid)@base64(server)#base64(subid):index:base64(hmac)
	Server -> Client
	XXX ErrorCode
		404 User Not Found
		403 Index Expired
		401 Unauthorized
		400 Bad Request
		200 OK
	Req-Resp
	Client -> Server : Request
		word size (Not include self)
		string content (size-4)
		dword session
	Server -> Client : Response
		word size (Not include self)
		string content (size-5)
		byte ok (1 is ok, 0 is error)
		dword session
API:
	server.userid(username)
		return uid, subid, server
	server.username(uid, subid, server)
		return username
	server.login(username, secret)
		update user secret
	server.logout(username)
		user logout
	server.ip(username)
		return ip when connection establish, or nil
	server.start(conf)
		start server
Supported skynet command:
	kick username (may used by loginserver)
	login username secret  (used by loginserver)
	logout username (used by agent)
Config for server.start:
	conf.expired_number : the number of the response message cached after sending out (default is 128)
	conf.login_handler(uid, secret) -> subid : the function when a new user login, alloc a subid for it. (may call by login server)
	conf.logout_handler(uid, subid) : the functon when a user logout. (may call by agent)
	conf.kick_handler(uid, subid) : the functon when a user logout. (may call by login server)
	conf.request_handler(username, session, msg) : the function when recv a new request.
	conf.register_handler(servername) : call when gate open
	conf.disconnect_handler(username) : call when a connection disconnect (afk)
]]

local server = {}

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
}

local user_online = {}	-- username -> u
local handshake = {}	-- 需要握手的连接列表
local connection = {}	-- fd -> u

function server.userid(username)
	-- base64(uid)@base64(server)#base64(subid)
	local uid, servername, subid = username:match "([^@]*)@([^#]*)#(.*)"
	return b64decode(uid), b64decode(subid), b64decode(servername)
end

function server.username(uid, subid, servername)
	return string.format("%s@%s#%s", b64encode(uid), b64encode(servername), b64encode(tostring(subid)))
end

function server.disconnect(username)
	local u = user_online[username]
	if u and u.fd then
		gateserver.closeclient(u.fd)
	end
end

function server.logout(username)
	local u = user_online[username]
	user_online[username] = nil
	if u and u.fd then
		gateserver.closeclient(u.fd)
		connection[u.fd] = nil
	end
end

function server.login(username, secret)
	assert(user_online[username] == nil)
	skynet.error("!!!!!!!!!!!!!!!server.login!!!!!!!!!!!!!!!!!!!!! username:"..username)
	user_online[username] = {
		secret = secret,
		version = 0,
		index = 0,
		username = username,
		--response = {},	-- response cache
	}
end

function server.ip(username)
	local u = user_online[username]
	if u and u.fd then
		return u.ip
	end
end

function server.start(conf)
	local expired_number = conf.expired_number or 128

	local handler = {}

	local CMD = {
		login = assert(conf.login_handler),
		logout = assert(conf.logout_handler),
		kick = assert(conf.kick_handler),
		init = assert(conf.init_handler),		-- 主要用于初始化agent池
		get_agents = assert(conf.get_agents),
		get_agent = assert(conf.get_agent),
		is_online = assert(conf.is_online),
		serverShutdown = assert(conf.serverShutdown),
	}

	-- 内部命令处理
	function handler.command(cmd, source, ...)
		local f = assert(CMD[cmd])
		return f(...)
	end

	-- 网关服务器open（打开监听）回调
	function handler.open(source, gateconf)
		local servername = assert(gateconf.servername)
		return conf.register_handler(servername)
	end

	-- 新连接到来回调
	function handler.connect(fd, addr)
		skynet.error(string.format("handler.connect fd:%d", fd))
		handshake[fd] = addr
		gateserver.openclient(fd)
	end

	-- 连接断开回调
	function handler.disconnect(fd)
		skynet.error(string.format("handler.disconnect fd:%d", fd))
		handshake[fd] = nil
		local c = connection[fd]
		if c then
			c.fd = nil
			connection[fd] = nil
			if conf.disconnect_handler then
				conf.disconnect_handler(c.username)
			end
		end
	end

	-- socket发生错误时回调
	handler.error = handler.disconnect

	local auth_handler = conf.auth_handler
	local online_handler = conf.online_handler

	-- atomic , no yield
	local function do_auth(fd, message, addr)
		skynet.error(string.format("do_auth fd:%d message:%s", fd, message))
		--skynet.error("do_auth, message:"..message)
		local username, index, hmac = string.match(message, "([^:]*):([^:]*):([^:]*)")
		skynet.error("do_autu username:%s index:%s hmac:%s", username, index, hmac)
		local u = user_online[username]
		if u == nil then
			skynet.error("404 User Not Found")
			return "404 User Not Found"
		end
		
		local idx = assert(tonumber(index))
		hmac = b64decode(hmac)

		if idx <= u.version then
			skynet.error("403 Index Expired")
			return "403 Index Expired"
		end

		local text = string.format("%s:%s", username, index)
		
		local v = md5.sumhexa(string.format("%s%s",text,u.secret))
		--local v = crypt.hmac_hash(u.secret, text)	-- equivalent to crypt.hmac64(crypt.hashkey(text), u.secret)
		skynet.error("hmac plain:"..text.."  secret:"..u.secret.."    server_sign:"..v.."    mysign:"..hmac)
		if v ~= hmac then
			skynet.error("401 Unauthorized")
			return "401 Unauthorized"
		end
		
		--如果之前有连接则断开之前的连接
		if u.fd then
			skynet.error(string.format("disconnect before fd:%d", u.fd))
			gateserver.closeclient(u.fd)
			connection[u.fd] = nil
		end

		u.version = idx
		u.fd = fd
		u.ip = addr
		connection[fd] = u

		
	end

	local function auth(fd, addr, msg, sz)
		skynet.error(string.format("auth fd:%d", fd))
		local message = netpack.tostring(msg, sz)
		local ok, result = pcall(do_auth, fd, message, addr)
		if not ok then
			skynet.error(result)
			result = "400 Bad Request"
		end

		local close = result ~= nil

		if result == nil then
			result = "200 OK"
		end

		

		if close then
			socketdriver.send(fd, netpack.pack(result))
			gateserver.closeclient(fd)
		else

			--auth success
			local username = string.match(message, "([^:]*):([^:]*):([^:]*)")
			local user = connection[fd]
			if user then
				local ip = user.ip
				auth_handler(username, fd, ip)
				local uid = server.userid(username)
				uid = tonumber(uid)
				online_handler(uid, fd)
			else
				skynet.error("auth verify success but no associte user found for fd", fd)
			end

			socketdriver.send(fd, netpack.pack(result))
		end
	end

	local request_handler = assert(conf.request_handler)

	-- u.response is a struct { return_fd , response, version, index }
	local function retire_response(u)
		if u.index >= expired_number * 2 then
			local max = 0
			local response = u.response
			for k,p in pairs(response) do
				if p[1] == nil then
					-- request complete, check expired
					if p[4] < expired_number then
						response[k] = nil
					else
						p[4] = p[4] - expired_number
						if p[4] > max then
							max = p[4]
						end
					end
				end
			end
			u.index = max + 1
		end
	end
	
	local function do_request(fd, message)
		
		local u = assert(connection[fd], "invalid fd")
		local session = string.unpack(">I4", message, -4)
		message = message:sub(1,-5)
		--skynet.error("do_request session:"..session)
		local p = u.response[session]
		if p then
			-- session can be reuse in the same connection
			if p[3] == u.version then
				local last = u.response[session]
				u.response[session] = nil
				p = nil
				if last[2] == nil then
					local error_msg = string.format("Conflict session %s", crypt.hexencode(session))
					skynet.error(error_msg)
					error(error_msg)
				end
			end
		end

		if p == nil then
			p = { fd }
			u.response[session] = p
			local ok, result = pcall(conf.request_handler, u.username, message)
			-- NOTICE: YIELD here, socket may close.
			result = result or ""
			if not ok then
				skynet.error(result)
				result = string.pack(">BI4", 0, session)
			else
				result = result .. string.pack(">BI4", 1, session)
			end

			p[2] = string.pack(">s2",result)
			p[3] = u.version
			p[4] = u.index
		else
			-- update version/index, change return fd.
			-- resend response.
			p[1] = fd
			p[3] = u.version
			p[4] = u.index
			if p[2] == nil then
				-- already request, but response is not ready
				return
			end
		end
		u.index = u.index + 1
		-- the return fd is p[1] (fd may change by multi request) check connect
		fd = p[1]
		if connection[fd] then
			socketdriver.send(fd, p[2])
		end
		p[1] = nil
		retire_response(u)
	end

	local function request(fd, msg, sz)
		
		local message = netpack.tostring(msg, sz)
		--local tmp = bin2hex(message)
		local ok, err = pcall(do_request, fd, message)
		-- not atomic, may yield
		if not ok then
			skynet.error(string.format("Invalid package %s : %s", err, message))
			if connection[fd] then
				gateserver.closeclient(fd)
			end
		end
	end

	-- socket消息到来时回调，新连接的第一条消息是握手消息
	function handler.message(fd, msg, sz)
		local addr = handshake[fd]
		if addr then
			auth(fd,addr,msg,sz)
			handshake[fd] = nil
			skynet.error(string.format("auth is finish and cleared handshake table, fd:%d", fd))
		else
			--request(fd, msg, sz)
			local user = assert(connection[fd], "invalid fd")
			local message = netpack.tostring(msg, sz)
			message = message:sub(1,-5)
			request_handler(user.username, message)
		end
	end

	return gateserver.start(handler)
end

return server