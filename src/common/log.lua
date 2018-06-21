local skynet = require "skynet"
require "skynet.manager"
local logger = require "log.core"
 
local CMD = {}

function CMD.start()
	logger.init(tonumber(skynet.getenv("log_level")) or 0,
		tonumber(skynet.getenv("log_rollsize")) or 1024,
		tonumber(skynet.getenv("log_flushinterval")) or 5,
		skynet.getenv("log_dirname") or "log",
		skynet.getenv("log_basename") or "test")
end

function CMD.stop( )
	logger.exit()
end

function CMD.debug(serverIP, name, msg)
	local log = string.format("%s [%s] [%s] DEBUG %s",os.date("%Y-%m-%d %H:%M:%S"), serverIP, name, msg)
	logger.debug(log)
	print(log)
end

function CMD.info(serverIP, name, msg)
	local log = string.format("%s [%s] INFO %s",os.date("%Y-%m-%d %H:%M:%S"), serverIP, name, msg)
	logger.info(log)
	print(log)
end

function CMD.warning(serverIP, name, msg)
	local log = string.format("%s [%s] WARN %s",os.date("%Y-%m-%d %H:%M:%S"), serverIP, name, msg)
	logger.warning(log)
	print(log)
end

function CMD.error(serverIP, name, msg)
	local log = string.format("%s [%s] ERROR %s",os.date("%Y-%m-%d %H:%M:%S"), serverIP, name, msg)
	logger.error(log)
	print("\x1b[31m"..log.."\x1b[0m")
end

function CMD.fatal(serverIP, name, msg)
	local log = string.format("%s [%s] FATAL %s",os.date("%Y-%m-%d %H:%M:%S"), serverIP, name, msg)
	logger.fatal(log)
	print(log)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(CMD[cmd], cmd .. "not found")
		if cmd == "start" or cmd == "stop" then
			skynet.retpack(f(...))
		else
			f(...)
		end
	end)

	skynet.register(SERVICE_NAME)
end)