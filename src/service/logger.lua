local skynet = require "skynet"
require "skynet.manager"

local queue = require "skynet.queue"
local cs = queue()

local interService = {}

--local nodename = skynet.getenv "nodename" or "unknownode"
local logpath = skynet.getenv("log_dirname")
local logbashname = skynet.getenv("log_basename") or "unknow"

local MB = 1024 * 1024
local FILE_LIMIT = 32 * MB

-- Also works on 'print' of C and Python, 'echo' of Unix like Shell, etc.
local DEFAULT_COLOR = "\x1b[m"
local LOG_COLOR_MAP = {
	DEBUG = DEFAULT_COLOR,
	INFO = "\x1b[32m",
	WARN = "\x1b[33m",
	ERROR = "\x1b[31m",
	FATAL = "\x1b[35m",
	SKY = "\x1b[34m",
}

local CMD = {}

local _log_file = nil
local _log_name = ""
local _log_size = 0
local _log_idx = 0

local function str_datetime(t, p)
	t = t or os.date("*t")
	p = p or math.floor(skynet.time() *100 % 100)
	return string.format("%04d-%02d-%02d %02d:%02d:%02d.%02d0",
        t.year, t.month, t.day, t.hour, t.min, t.sec, p)
end

--根据服务地址查询服务名称
local function queryInterService(address)
	local serviceInfo = interService[address]
	if not serviceInfo then
		return "NOTREG", nil
	else
		return serviceInfo.name, serviceInfo.idx
	end
end


local function logging(source, typ, msg)
	cs(function()
		--print("ttttttttttttttttttt:"..typ)
		local t = os.date("*t")
		local p = math.floor(skynet.time()*100%100)
		local tm = str_datetime(t,p)
		local nodename = skynet.getenv "nodename" or "unknownode"
		--local servicemgr = skynet.uniqueservice("servicemgr")
		local serviceName, idx = queryInterService(source)
		
		local log = ""
		if idx then
			log = string.format("[%s] [%s] [%08x:%s] [%s] [idx:%s] %s", typ, nodename, source, serviceName, tm, tostring(idx), msg)
		else
			log = string.format("[%s] [%s] [%08x:%s] [%s] %s", typ, nodename, source, serviceName, tm, msg)
		end
		
		--local log = string.format("[%s] [%s] [%s:%x] %s", tm, typ, nodename, source, msg)
		print(LOG_COLOR_MAP[typ]..log..DEFAULT_COLOR)
		
		if not _log_file then
			_log_name = string.format("%s/%s_%04d%02d%02d_%02d%02d%02d_%02d.log",
				logpath, logbashname, t.year, t.month, t.day, t.hour, t.min, t.sec, _log_idx)
			local f, e = io.open(_log_name, "a+")
			if not f then
				print("logger error:", tostring(e))
				return
			end
			_log_file = f
		end
		_log_file:write(log .. "\n")
	    _log_file:flush()
		
		_log_size = _log_size + string.len(log) + 1
		if _log_size >= FILE_LIMIT then
			_log_file:close()
			_log_file = nil
			_log_size = 0
			_log_idx = _log_idx + 1
		end
	end)
end



function CMD.logging(source, typ, log)
    logging(source, typ, log)
end


function CMD.logging_ret(source, typ, log)
	logging(source, typ, log)
	skynet.retpack()
end

--注册地址和服务名称
-- idx 可用于输入用户id 或者 房间id，这样在查询服务的时候可以明确知道这个服务所属的id是什么
function CMD.regInterService(address, name, idx)
	local serviceInfo = interService[address]
	if not serviceInfo then
		interService[address] = {
			name = name,
			idx = idx
		}
	else
		if serviceInfo.name ~= name then
			LOG_ERROR("can not reg same address with diff name, address:%s  name:%s", address, name)
		else
			LOG_DEBUG("inter service reg already exists, address:%s  name:%s", address, name)
		end
	end
	skynet.retpack()
end


skynet.register_protocol {
	name = "text",
	id = skynet.PTYPE_TEXT,
	unpack = skynet.tostring,
	dispatch = function(_, address, msg)
        logging(address, "DEBUG", msg)
	end
}


skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(CMD[cmd], cmd .. " not found")
		f(source, ...)
	end)

	skynet.register(".logger")
	--tlog.info("terminator logger is ready.")
end)