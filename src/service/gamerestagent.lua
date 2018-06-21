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
local nodeType = ...

local function response(id, ...)
    local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
    if not ok then
        -- if err == sockethelper.socket_error , that means socket closed.
        LOG_DEBUG(string.format("fd = %d, %s", id, err))
    end
end

skynet.start(function()
    skynet.dispatch("lua", function (_,_,id)
        socket.start(id)  -- 开始接收一个 socket
        
        -- limit request body size to 8192 (you can pass nil to unlimit)
        -- 一般的业务不需要处理大量上行数据，为了防止攻击，做了一个 8K 限制。这个限制可以去掉。
        local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
        if code then
            if code ~= 200 then  -- 如果协议解析有问题，就回应一个错误码 code 。
                response(id, code)
            else
                local defaultResp = function()
                    local tmp = {}
                    if header.host then
                        table.insert(tmp, string.format("host: %s", header.host))
                    end
                    local path, query = urllib.parse(url)
                    table.insert(tmp, string.format("path: %s", path))
                    if query then
                        local q = urllib.parse_query(query)
                        for k, v in pairs(q) do
                            table.insert(tmp, string.format("query: %s= %s", k,v))
                        end
                    end
                    return tmp                
                end
                local respContent = ""
                local path, query = urllib.parse(url)
                LOG_DEBUG("run nodeType:"..nodeType)
                if nodeType == "platform" then
                    if path == "/stat/nodemgr" then
                        local nodemgr = skynet.uniqueservice("gamenodemgr")
                        local stats = skynet.call(nodemgr, "lua", "stats")
                        cjson.encode_empty_table_as_object(false)
                        respContent = cjson.encode(stats)
                    elseif path == "/debug/list" then
                        local tmpRet = skynet.call(".launcher", "lua", "LIST")
                        cjson.encode_empty_table_as_object(false)
                        respContent = cjson.encode(tmpRet)
                    elseif path == "/debug/stat" then
                        local tmpRet = skynet.call(".launcher", "lua", "STAT")
                        cjson.encode_empty_table_as_object(false)
                        respContent = cjson.encode(tmpRet)
                    elseif path == "/debug/mem" then
                        local tmpRet = skynet.call(".launcher", "lua", "MEM")
                        cjson.encode_empty_table_as_object(false)
                        respContent = cjson.encode(tmpRet)
                    else
                        respContent = cjson.encode(defaultResp())
                    end
                else
                    
                    if path == "/stat/racemgr" then
                        local racemgr = skynet.uniqueservice("gameracemgr")
                        local stats = skynet.call(racemgr, "lua", "stats")
                        -- 目前的cjson库暂时不支持该函数，等编译支持的c库以后再打开
                        cjson.encode_empty_table_as_object(false)
                        respContent = cjson.encode(stats)
                    elseif path == "/debug/list" then
                        local tmpRet = skynet.call(".launcher", "lua", "LIST")
                        cjson.encode_empty_table_as_object(false)
                        respContent = cjson.encode(tmpRet)
                    elseif path == "/debug/stat" then
                        local tmpRet = skynet.call(".launcher", "lua", "STAT")
                        cjson.encode_empty_table_as_object(false)
                        respContent = cjson.encode(tmpRet)
                    elseif path == "/debug/mem" then
                        local tmpRet = skynet.call(".launcher", "lua", "MEM")
                        cjson.encode_empty_table_as_object(false)
                        respContent = cjson.encode(tmpRet)
                    elseif path == "/fang/disband" then
                        -- url: /fang/disband?roomid=1234
                        local roomid = 0
                        if query then
                            local q = urllib.parse_query(query)
                            for k, v in pairs(q) do
                                if k == "roomid" then
                                    roomid = tonumber(v)
                                end
                            end
                        end
                        local racemgr = skynet.uniqueservice("gameracemgr")
                        local stats = skynet.call(racemgr, "lua", "disbandroom", roomid)
                        respContent = cjson.encode(stats)
                    elseif path == "/shutdown" then
                        --目前的做法是通知racemgr强制存盘，（德州中退出筹码），后期可以修改为等待所有游戏结束
                        local ret = skynet.call(racemgr, "lua", "serverShutdown")
                        respContent = cjson.encode({ret = true})
                    else
                        -- 这是一个示范的回应过程，你可以根据你的实际需要，解析 url, method 和 header 做出回应。
                        respContent = cjson.encode(defaultResp())
                    end
                end
                local httpHeader = {}
                httpHeader["Cache-Control"] = "private"
                httpHeader["Content-Type"] = "application/json; charset=utf-8"
                httpHeader["Server"] = "mgserver"
                response(id, code, respContent, httpHeader)
                
            end
        else
            -- 如果抛出的异常是 sockethelper.socket_error 表示是客户端网络断开了。
            if url == sockethelper.socket_error then
                LOG_DEBUG("socket closed")
            else
                LOG_DEBUG(url)
            end
        end
        socket.close(id)
    end)
    --skynet.call(".logger", "lua", "regInterService", SERVICE_NAME)
    --skynet.register(SERVICE_NAME)
end)