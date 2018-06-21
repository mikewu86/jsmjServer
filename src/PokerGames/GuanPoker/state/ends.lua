local Ends = class("Ends")

local instance = nil

function Ends:ctor(logic)
    self.logic = logic
end

function Ends:getInstance(logic)
    if nil == instance then
        instance = Ends.new(logic)
    end
    return instance
end

function Ends:handle()
end

function Ends:changeState()
    self.logic:changeState("waits")
end

return Ends
