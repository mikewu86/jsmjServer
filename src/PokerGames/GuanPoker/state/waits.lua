local Waits = class("Waits")

local instance = nil

function Waits:ctor(logic)
    self.logic = logic
end

function Waits:getInstance(logic)
    if nil == instance then
        instance = Waits.new(logic)
    end
    return instance
end

function Waits:handle()
end

function Waits:changeState()
    self.logic:changeState("begins")
end

return Waits
