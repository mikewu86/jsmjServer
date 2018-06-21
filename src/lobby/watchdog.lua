--
-- Author: Liuq
-- Date: 2016-04-16 01:00:21
--
local skynet = require "skynet"
local socket = require "socket"
local string = require "string"


local handler = {}
local CMD = {}
local SOCKET = {}
local agent = {}
local gate
local healthCheckIPs = {}

local function close_agent(fd)
    local a = agent[fd]
    agent[fd] = nil
    if a then
        skynet.call(gate, "lua", "kick", fd)
        -- disconnect never return
        skynet.send(a, "lua", "disconnect")
    end 
end

function SOCKET.open(fd, addr)
	-- 健康检查的ip不需要创建agent
	for _, ipPattern in pairs(healthCheckIPs) do
		if ipPattern then
			if string.len(ipPattern) > 0 then
				local bFind = string.match(addr, ipPattern)
				if bFind then
					-- 1秒后关闭连接
					skynet.timeout (100, function()
						skynet.call(gate, "lua", "kick", fd)
					end)
					return
				end
			end
		end
	end
	LOG_DEBUG("SOCKET New client from:" .. addr)
	agent[fd] = skynet.newservice("loginagent")
	skynet.call(agent[fd], "lua", "start", { gate = gate, fd = fd, watchdog = skynet.self() })
end



function SOCKET.close(fd)
    LOG_DEBUG("SOCKET close",fd)
    close_agent(fd)
end

function SOCKET.error(fd, msg)
    --LOG_ERROR("SOCKET error",fd, msg)
    close_agent(fd)
end

function SOCKET.data(fd, msg)
    --print("[data]",fd, msg)
end

function CMD.start(conf)
	skynet.call(gate, "lua", "open" , conf)
end

function CMD.close(fd)
	close_agent(fd)
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

	local hIPStr = skynet.getenv("healthcheckip")
	healthCheckIPs = string.split(hIPStr, "|")


	skynet.call(".logger", "lua", "regInterService", SERVICE_NAME)
    gate = skynet.newservice("gate")
end)