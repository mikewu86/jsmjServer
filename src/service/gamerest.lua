--游戏服务器的rest接口，实现基本的管理和监控功能
local skynet = require "skynet"
require "skynet.manager"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local table = table
local string = string
local cjson = require "cjson"
local mode = ...
local nodeType = "gamesvr"
if mode == "platform" then
    nodeType = mode
end
skynet.start(function()
    --local servicemgr = skynet.uniqueservice("servicemgr")
    --local serviceName = skynet.call(servicemgr, "lua", "regInterService", SERVICE_NAME)
    local agent = {}
    for i= 1, 20 do
        -- 启动 20 个代理服务用于处理 http 请求
        agent[i] = skynet.newservice("gamerestagent", nodeType)  
    end
    local balance = 1
    -- 监听一个 web 端口
    local id = socket.listen("0.0.0.0", 7788)  
    socket.start(id , function(id, addr)  
        -- 当一个 http 请求到达的时候, 把 socket id 分发到事先准备好的代理中去处理。
        LOG_DEBUG(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
        skynet.send(agent[balance], "lua", id)
        balance = balance + 1
        if balance > #agent then
            balance = 1
        end
    end)
    
    skynet.call(".logger", "lua", "regInterService", SERVICE_NAME)
    skynet.register(SERVICE_NAME)
end)