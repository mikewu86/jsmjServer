local skynet = require "skynet"
local GameRecorder = class("GameRecorder")
local CardConstant = require "CardConstant"

function GameRecorder:ctor(_uuid, _dealerPos, _sbPos, _bbPos, _sbBet, _bbBet)
    self.result = {}
    self.result.uuid = _uuid
    self.result.timestamp = skynet.time()
    self.result.players = {}
    self.result.DealerPos = _dealerPos
    self.result.SBPos = _sbPos
    self.result.BBPos = _bbPos
    self.result.SBBet = _sbBet
    self.result.BBBet = _bbBet
    
    self.result.gameSteps = {}
    --self.result.gameResult = {}
end

function GameRecorder:addPlayer(_pos, _uid, _nickname, _chips, _icon)
    local player = {}
    player.pos = _pos
    player.uid = _uid
    player.nickname = _nickname
    player.chips = _chips
    player.icon = _icon
    table.insert(self.result.players, player)
    
end

function GameRecorder:addGameStepHandCard(_pos, _cards, _round)
    local gamestep = {}
    gamestep.type = CardConstant.RECORDSTEP_HANDCARD
    gamestep.pos = _pos
    gamestep.cards = _cards
    gamestep.timestamp = skynet.time()
    gamestep.round = _round
    
    table.insert(self.result.gameSteps, gamestep)
end

function GameRecorder:addGameStepDeskCard(_cards, _round)
    local gamestep = {}
    gamestep.type = CardConstant.RECORDSTEP_DESKCARD
    gamestep.round = _round
    gamestep.cards = _cards
    gamestep.timestamp = skynet.time()
    
    table.insert(self.result.gameSteps, gamestep)
end

function GameRecorder:addGameStepOperation(_pos, _operation, _betAmount, _isAllin, _round)
    local gamestep = {}
    gamestep.type = CardConstant.RECORDSTEP_BET
    gamestep.pos = _pos
    gamestep.operation = _operation
    gamestep.timestamp = skynet.time()
    gamestep.betamount = _betAmount
    gamestep.isallin = _isAllin
    gamestep.round = _round
    
    table.insert(self.result.gameSteps, gamestep)
end

function GameRecorder:addGameResult(_result)
    self.result.gameResult = _result
end

function GameRecorder:getData()
    return self.result
end

return GameRecorder