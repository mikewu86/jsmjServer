local Singleton = class(Singleton)
local instance = nil

function Singleton:ctor()
    self.objMap = {}
end

function Singleton:getInstance()
    if nil == instance then
        instance = Singleton.new()
    end
    return instance
end

function Singleton:register(name, obj)
    local bRet = false
    if nil == self.objMap[name] then
        self.objMap[name] = obj
        bRet = true
    else
        LOG_DEBUG(name.." obj is exist.")
    end
    return bRet 
end

function Singleton:lookup(name)
    if nil == self.objMap[name] then
        LOG_DEUBG(name.." obj does not exist.")
    end
    return self.objMap[name]
end

function Singleton:clear()
    for _, obj in pairs(self.objMap) do 
        obj = nil
    end
    self.objMap = nil
end

return Singleton
