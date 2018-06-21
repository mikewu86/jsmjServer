local skynet = require "skynet"
local snax = require "snax"
local EntityFactory = require "EntityFactory"

local entUser

function init(...)
	entUser = EntityFactory.get("d_account")
	entUser:init()
	--entAccount:load()
end

function exit(...)
end

function response.load(uid)
	if not uid then return end
	return entUser:load(uid)
end

function response.unload(uid)
	if not uid then return end
	entUser:unload(uid)
end

function response.getvalue(uid, key)
	return entUser:getValue(uid, key)
end

function response.updateMoney(row)
	return entUser:updateMoney(row)
end


function response.updateWinInfo(_record)
	return  entUser:updateWinInfo(_record)
end