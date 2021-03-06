--
-- Author: Liuq
-- Date: 2016-04-09 01:17:07
--
local skynet = require "skynet"
--local jsonpack = require "jsonpack"
local netpack = require "netpack"
local socket = require "socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

local CMD = {}
local host
local REQUEST = {}

local client_fd

local function xfs_send(v)
	data = p.unpack(v)
	print("[LOG]",os.date("%m-%d-%Y %X", skynet.time()),"send ok",data.v,data.p)
	socket.write(client_fd, netpack.pack(v))
end

function REQUEST:set()
	print("set", self.what, self.value)
	local r = skynet.call("SIMPLEDB", "lua", "set", self.what, self.value)
end

function REQUEST:get()
	print("get", self.what)
	local r = "aaaaasssss"
	return { result = r }
end

function REQUEST:handshake()
	return { msg = "Welcome to skynet, I will send heartbeat every 5 sec." }
end

function REQUEST:login()
	print("login function call"..self.token)

	return {result = 1}
	--return { result = 1, nickname = "test", headimg = "headimg", sex = 1, city = "xxx", country = "yyy"}
end

local function request(name, args, response)
	local f = assert(REQUEST[name])
	local r = f(args)
	if response then
		return response(r)
	end
end

local function send_package(pack)
	local package = string.pack(">s2", pack)
	socket.write(client_fd, package)
end

local function msg_unpack(msg, sz)
	local data = skynet.tostring(msg, sz)
	local netmsg = protobuf.decode("netmsg.NetMsg", data)

	if not netmsg then
		LOG_ERROR("msg_unpack error")
		error("msg_unpack error")
	end
	
	return netmsg
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return host:dispatch(msg, sz)
	end,
	dispatch = function (_, _, type, ...)
		if type == "REQUEST" then
			local ok, result  = pcall(request, ...)
			if ok then
				if result then
					send_package(result)
				end
			else
				skynet.error(result)
			end
		else
			assert(type == "RESPONSE")
			error "This example doesn't support request client"
		end
	end
}

function CMD.start(gate , fd)
	print("CMD.start:"..fd)
	host = sprotoloader.load(1):host "package"

	
	send_request = host:attach(sprotoloader.load(2))
	skynet.fork(function()
		while true do
			send_package(send_request "heartbeat")
			skynet.sleep(500)
		end
	end)
	

	client_fd = fd
	skynet.call(gate, "lua", "forward", fd)

	local ppp = {}
	ppp["test1"] = "xxaa"

	--skynet.ret(skynet.pack(ppp))
end

function CMD.disconnect()
	-- todo: do something before exit
	print("CMD.disconnect")
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)