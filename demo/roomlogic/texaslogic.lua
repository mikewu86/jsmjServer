--
-- Author: Liuq
-- Date: 2016-04-11 00:24:17
--
local skynet = require "skynet"

function response.ping(hello)
    skynet.sleep(100)
    return hello
end

function accept.hello()
    i = i + 1
    print (i, hello)
end

function init( ... )
    print ("texaslogic server start:", ...)
end

function exit(...)
    print ("texaslogic server exit:", ...)
end