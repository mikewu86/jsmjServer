-- for test case module
-- zhangxiao
-- 2017.4.12
-- skynet

local skynet = {}

LOG_DEBUG = function(fmt, ...)
    local msg = string.format(fmt, ...)
    print(msg)
end

LOG_ERROR = function(fmt, ...)
    local msg = string.format(fmt, ...)
    print(msg)
end

return skynet