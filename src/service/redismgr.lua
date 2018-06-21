local skynet = require "skynet"
require "skynet.manager"
local redis = require "redis"
local json = require "cjson"

local conf = {
    host = "ba63cee3eb294180.redis.rds.aliyuncs.com",
    port = 6379,
    db = 0,
    auth = "Javjav11"
}
local db
local CMD = {}

local queueProcess = nil

-- return the list size
function CMD.add_list(key, value)
    local t = type(value)
    if t == "table" then
        -- convert to json
        local js = json.encode(value)
        return db:rpush(key, js)
    else
        return db:rpush(key, value)
    end
end

--add value to redis, the key must not exist
function CMD.add_value(key, value)
    local t = type(value)
    if t == "table" then
        -- convert to json
        local js = json.encode(value)
        return db:set(key, js, "NX")
    else
        return db:set(key, value, "NX")
    end
end

--set value to redis, whenever the key is exist
function CMD.set_value(key, value)
    local t = type(value)
    if t == "table" then
        -- convert to json
        local js = json.encode(value)
        return db:set(key, js)
    else
        return db:set(key, value)
    end
end

function CMD.get_value(key)
    return db:get(key)
end

--delete a key
function CMD.del_key(key)
    db:del(key)
end

local function watchingconf()
    local w = redis.watch(conf)
    local servername = skynet.getenv "nodename"
    local channelName = "mgserver.config."..servername
    LOG_DEBUG("channel:"..channelName)
    w:subscribe(channelName)
    while true do
        LOG_DEBUG("Watch "..w:message())
    end
end

local function watching()
    local w = redis.watch(conf)
    local servername = skynet.getenv "nodename"
    local channelName = skynet.getenv "webchannel"
    --print("channel:", channelName)
    --dump(conf)
    w:subscribe(channelName)
    while true do
        if queueProcess then
            skynet.call(queueProcess, "lua", "process", w:message())
        else
            LOG_DEBUG("queueProcess is nil")
        end
        --print("Watch", w:message())
    end
end

function CMD.start(processor)
    if processor then
        queueProcess = processor
    end
    local redishost = skynet.getenv("redisServer")
    if redishost then
        LOG_DEBUG("!!!!!!!!!!!!!!!!!!!!!!!!!!!!redishost!!!!!!!!!!!!!!!!!!!!!!")
        conf.host = redishost
    else
        LOG_DEBUG("xxxxxxxxxxxxxxxxxxxxx")
    end
    db = redis.connect(conf)
    skynet.fork(watchingconf)
    if processor then
        skynet.fork(watching)
    end
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(CMD[cmd], cmd .. "not found")
		skynet.retpack(f(...))
	end)
    
    --local servicemgr = skynet.uniqueservice("servicemgr")
	--local serviceName = skynet.call(servicemgr, "lua", "regInterService", SERVICE_NAME)
    skynet.call(".logger", "lua", "regInterService", SERVICE_NAME)
	skynet.register(SERVICE_NAME)
end)