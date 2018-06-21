--
-- Author: Liuq
-- Date: 2016-04-18 17:15:01
--
local skynet = require "skynet"
local netpack = require "netpack"
local socketdriver = require "socketdriver"

local TEST_LOGGER = false

function _logoutput(loglevel, fmt, ...)
	local ok, log = pcall(string.format, fmt, ...)
	if not ok then
		loglevel = "ERROR"
		--log = log .. ":\n" .. concat({fmt, "|", ...})
	end

--[[
	local info = debug.getinfo(3)
	if info then
		local filename = string.match(info.short_src, "[^/.]+.lua")
		log = string.format("[%s:%d] %s", filename, info.currentline, log)
	end]]

    if TEST_LOGGER then
        skynet.call(".logger", "lua", "logging_ret", loglevel, log)
    else
        skynet.send(".logger", "lua", "logging", loglevel, log)
    end
end

function LOG_DEBUG(fmt, ...)
	_logoutput("DEBUG", fmt, ...)
end

function LOG_INFO(fmt, ...)
	_logoutput("INFO", fmt, ...)
end

function LOG_WARNING(fmt, ...)
	_logoutput("WARN", fmt, ...)
end

function LOG_ERROR(fmt, ...)
	_logoutput("ERROR", fmt, ...)
end

function LOG_FATAL(fmt, ...)
	_logoutput("FATAL", fmt, ...)
end

function STR_DATETIME(t, p)
	t = t or os.date("*t")
	p = p or math.floor(skynet.time() *100 % 100)
	return string.format("%04d-%02d-%02d %02d:%02d:%02d.%02d0",
        t.year, t.month, t.day, t.hour, t.min, t.sec, p)
end

function send_client(client_fd, pack)
	if client_fd ~= nil then
		socketdriver.send(client_fd, netpack.pack(pack))
	end
end

function close_client(client_fd)
	socketdriver.close(client_fd)
end