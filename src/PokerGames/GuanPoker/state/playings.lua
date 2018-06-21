local Playings = class("Playings")

local instance = nil

function Playings:ctor(logic)
    self.logic = logic
end

function Playings:getInstance(logic)
    if nil == instance then
        instance = Playings.new(logic)
    end
    return instance
end

function Playings:handle()
end

function Playings:changeState()
    self.logic:changeState("ends")
end

return Playings
