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