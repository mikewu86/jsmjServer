--
-- Author: Liuq
-- Date: 2016-04-09 01:17:07
--
local skynet = require "skynet"
--local jsonpack = require "jsonpack"
local netpack = require "websocketnetpack"
local socket = require "socket"
local snax = require "snax"
local protobuf = require "protobuf"
local socketdriver = require "socketdriver"

local CMD = {}
local host
local REQUEST = {}

local client_fd


local function print_r(root)
    local cache = {  [root] = "." }
    local function _dump(t,space,name)
        local temp = {}
        for k,v in pairs(t) do
            local key = tostring(k)
            if cache[v] then
                table.insert(temp,"+" .. key .. " {" .. cache[v].."}")
            elseif type(v) == "table" then
                local new_key = name .. "." .. key
                cache[v] = new_key
                table.insert(temp,"+" .. key .. _dump(v,space .. (next(t,k) and "|" or " " ).. string.rep(" ",#key),new_key))
            else
                table.insert(temp,"+" .. key .. " [" .. tostring(v).."]")
            end
        end
        return table.concat(temp,"\n"..space)
    end

    print("\n------------------------------------------------------------------------\n" 
        .. _dump(root, "","")
        .. "\n------------------------------------------------------------------------")
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
	print("name:"..name)
	--print_r(args)
	--print_r(response)
	local f = assert(REQUEST[name])
	local r = f(args)
	if response then
		return response(r)
	end
end

function pb_encode(name, msg)
	if not msg then
		print("msg is nil")
	end

	local data = protobuf.encode(name, msg)
	if not data then
		print("pb_encode error")
	end
	return data
end

function send_client(fd, proto, data)
	local payload = pb_encode(proto, data)
	local msg = protobuf.encode("netmsg.NetMsg", { name = proto, payload = payload })
	if not msg then
		print("protobuf.encode error")
		error("protobuf.encode error")
	end

	msg = msg .. string.pack(">BI4", 1, 9)
	msg = string.pack(">s2", msg)
	--socketdriver.send(fd, msg)	
	socketdriver.send(client_fd, msg)
end


local function send_package(pack)
print("on send_package:")
	--print(pack)
	local package = string.pack(">s2", pack)
	--local tmpstr = skynet.packstring(pack)
	--print("sendto:"..client_fd.."   package:"..package)
	--socketdriver.send(client_fd, package)
	--skynet.ret(package)
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

local function msg_pack(data)
	local msg = protobuf.encode("netmsg.NetMsg", data)
	if not msg then
		LOG_ERROR("msg_pack error")
		error("msg_pack error")
	end
	return msg
end

local function msg_dispatch(netmsg)
	local begin = skynet.time()
	assert(#netmsg.name > 0)
	if netmsg.name == "netmsg.LogoutRequest" then
		return logout()
	end

	local name = netmsg.name
	print("calling to:"..name)
	local module, method = netmsg.name:match "([^.]*).(.*)"
	local data = {}
	local ok, obj = pcall(snax.uniqueservice, module)
	if not ok then
		local data = {}
	data.name = "hihihi"
	send_client(fd, "user.UserInfoResponse", data)

	
		print(string.format("unknown module %s", module))
		return
	else
		pcall(obj.req[method], {
				name = name,
				payload = netmsg.payload,
				uid = UID,
				fd = FD
			}
		)
	end


	

	print(string.format("process %s time used %f ms", name, (skynet.time()-begin)*10))
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		print "register_protocol  unpack"
		--print(netpack.tostring(msg, sz))
		return msg_unpack(msg, sz)
	end,
	dispatch = function (_, _, netmsg)
		print("onDispatch")
		msg_dispatch(netmsg)
	end
}


function CMD.start(gate , fd)
	print("CMD.start:"..fd)
	--host = sprotoloader.load(1):host "package"

	--[[

	send_request = host:attach(sprotoloader.load(2))
	skynet.fork(function()
		while true do
			send_package(send_request "heartbeat")
			skynet.sleep(500)
		end
	end)
	]]

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

	protobuf.register_file("./protocol/netmsg.pb")
	protobuf.register_file("./protocol/user.pb")
end)