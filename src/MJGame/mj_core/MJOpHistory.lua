-- 记录玩家操作记录
local MJConst = require("mj_core.MJConst")
local crypt = require "crypt"
-- 历史操作结点，因为有发牌，所以这里是cards

local MJOpHistory = class("MJOpHistory")
function MJOpHistory:ctor(gamePrgress)
    -- 序列化
    self.send_request = gamePrgress.room.send_request
	self.opHistory = {}
	self.opHistory.playerList = {}
    self.opHistory.gameBegin  = {}
    self.opHistory.operList   = {}
    self.opHistory.gameEnd    = {}

    self.beginTime = 0
end

function MJOpHistory:clear()
    self.opHistory = {}
    self.opHistory.playerList = {}
    self.opHistory.gameBegin  = {}
    self.opHistory.operList   = {}
    self.opHistory.gameEnd    = {}

    self.beginTime = 0
end

function MJOpHistory:setPlayerList(playerList)
	self.opHistory.playerList  = playerList
end

function MJOpHistory:setGameBegin()
	local time = os.time()
	self.beginTime = time
	table.insert(self.opHistory.gameBegin ,1)
	table.insert(self.opHistory.gameBegin ,time)
end

function MJOpHistory:addOperHistory(oper, data)
	local time = os.time() - self.beginTime
    -- crypt.base64decode
    local serialize = self:PackageDataFunc(oper, data)
    table.insert(self.opHistory.operList, serialize)
end

function MJOpHistory:setGameEnd()
    local time = os.time() - self.beginTime
	table.insert(self.opHistory.gameEnd ,1)
	table.insert(self.opHistory.gameEnd ,time)
end

function MJOpHistory:getOpHistoryList()
    local str = self:Serialize(self.opHistory)
    local record = crypt.base64encode(str)
    return record
end

function MJOpHistory:dumpList()
end

function MJOpHistory:PackageDataFunc(oper, data)
    return self.send_request(oper, data)
end

function MJOpHistory:Serialize(obj)
    local tring = ""
    local t = type(obj)
    if t == "number" then
        tring = tring .. obj
    elseif t == "boolean" then
        tring = tring .. tostring(obj)
    elseif t == "string" then
        tring = tring .. string.format("%q", obj)
    elseif t == "table" then
        tring = tring .. "{"
    for k, v in pairs(obj) do
        tring = tring .. "[" .. self:Serialize(k) .. "]=" .. self:Serialize(v) .. ","
    end
    local metatable = getmetatable(obj)
        if metatable ~= nil and type(metatable.__index) == "table" then
        for k, v in pairs(metatable.__index) do
            tring = tring .. "[" .. self:Serialize(k) .. "]=" .. self:Serialize(v) .. ","
        end
    end
        tring = tring .. "}"
    elseif t == "nil" then
        return nil
    else
        error("can not self:Serialize a " .. t .. " type.")
    end
    return tring
end

return MJOpHistory
