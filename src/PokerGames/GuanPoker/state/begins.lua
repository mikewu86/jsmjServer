local Begins = class("Begins")

local instance = nil

function Begins:ctor(logic)
    self.logic = logic
end

function Begins:getInstance(logic)
    if nil == instance then
        instance = Begins.new(logic)
    end
    return instance
end

function Begins:handle()
end

function Begins:changeState()
    self.logic:changeState("playings")
end

return Begins
