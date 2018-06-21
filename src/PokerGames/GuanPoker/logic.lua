--- function: game logic or progress,playing and calc result.
--- author: zhangyl
--- date: 2016/12/30 9:36
---
local TimeManager = require("TimeManager")
local WallCards = require("common.wallCards")
local PokerCard = require("common.pokerCard")
local Argorithm = require("common.argorithm")
local Singleton = require("singleton")
local Waits = require("state.waits")
local Begins = require("state.begins")
local Playings = require("state.playings")
local Ends = require("state.ends")
local logic = class("logic")
local TempData = class("tempData")
function logic:ctor()
    self.players = nil
    self.timer = TimeManager.new()
    self.wallCards = WallCards.new()
    self.algorithm = Argorithm.new()
    self.pokerCard = PokerCard.new()
    self.state = nil
    self.singleton = Singleton:getInstance()
    self.tempData = TempData.new()
end
--- as room init
function logic:init(cardPrio, confMap)
    self.pokerCard:init(cardPrio)
    self.wallCards:init(confMap, self.pokerCard)
end

function logic:initState()
    self.singleton:register("waits", Waits:getInstance(self))
    self.singleton:register("begins", Begins:getInstance(self))
    self.singleton:register("playings", Playings:getInstance(self))
    self.singleton:register("ends", Ends:getInstance(self))
end
--- as game start
function logic:start()

end
--- as game over
function logic:reset()

end

function logic:ended()

end
--- as room end
function logic:clear()
end

--- update players per start game
function logic:updatePlayerInfo(players)
    self.players = players
end

--- timer
function logic:setTimeOut(delayMS, callbackFunc, param)
	LOG_DEBUG("-- logic:setTimeOut --")
	return self.timer:setTimeOut(delayMS, callbackFunc, param)
end

function logic:deleteTimeOut(handle)
    LOG_DEBUG("-- logic:deleteTimeOut --")
	self.timer:deleteTimeOut(handle)
end

function logic:changeState(name, args)
    local bRet = true
    local state = self.singleton:lookup(name)
    if nil ~= state then
        self.state = state
        self.state:init(args)
    else
        bRet = false
        self.state = nil
    end
    return bRet
end

function logic:handle()
    if nil ~= self.state then
        self.state:handle()
    else
        LOG_DEBUG("game logic interrupt exception.")
    end
end

return logic
