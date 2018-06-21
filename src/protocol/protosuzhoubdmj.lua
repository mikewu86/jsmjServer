local baseTypes = require("types")

local protocols = {
    require("platform"),
    require("gamecommon"),
    require("gamesuzhoubdmj"),
}

--local sparser = require("sprotoparser")

local proto = {}

local types = [[]]
types = types .. baseTypes
for i, v in ipairs(protocols) do
    types = types .. v.types
end

local c2s = [[]]
--c2s = c2s .. types
for i, v in ipairs(protocols) do
    c2s = c2s .. v.c2s
end

local s2c = [[]]
--s2c = s2c .. types
for i, v in ipairs(protocols) do
    s2c = s2c .. v.s2c
end

proto.types = types
proto.c2s = c2s
proto.s2c = s2c

return proto
