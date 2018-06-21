--
-- Author: Liuq
-- Date: 2016-04-12 23:02:07
--

local skynet = require "skynet"
local socket = require "socket"
local string = require "string"
local websocket = require "websocket"
local httpd = require "http.httpd"
local urllib = require "http.url"
local sockethelper = require "http.sockethelper"


local handler = {}
local CMD = {}
local SOCKET = {}
local agent = {}
local gate

function SOCKET.open(fd, addr)
	skynet.error("wsSOCKET New client from : " .. addr)
	agent[fd] = skynet.newservice("agentsproto")
	skynet.call(agent[fd], "lua", "start", gate, fd)
end

local function close_agent(fd)
    local a = agent[fd]
    agent[fd] = nil
    if a then
        skynet.call(gate, "lua", "kick", fd)
        -- disconnect never return
        skynet.send(a, "lua", "disconnect")
    end 
end

function SOCKET.close(fd)
    print("wsSOCKET close",fd)
    close_agent(fd)
end

function SOCKET.error(fd, msg)
    print("wsSOCKET error",fd, msg)
    close_agent(fd)
end

function SOCKET.data(fd, msg)
    print("[data]",fd, msg)
end

function CMD.start(conf)
	skynet.call(gate, "lua", "open" , conf)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)

    gate = skynet.newservice("wsgate")
end)