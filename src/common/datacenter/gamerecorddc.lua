local skynet = require "skynet"
local snax = require "snax"
local EntityFactory = require "EntityFactory"

local entGameRecord

function init(...)
	entGameRecord = EntityFactory.get("d_account")
	entAccount:init()
	--entAccount:load()
end

function exit(...)

end

function response.add(row)
	return entAccount:add(row)
end

function response.delete(row)
	return entAccount:delete(row)
end

function response.get(uid)
	return entAccount:get(uid)
end

function response.update(row)
	return entAccount:update(row)
end

function response.get_nextid()
	return entAccount:getNextId()
end