local skynet = require "skynet"

config_other = {}
--组id,用于区分其他服务器组
config_other.nodename = os.getenv("NODENAME") or "guanPoker"

for _key, _value in pairs(config_other) do
    skynet.setenv(_key, _value)
end