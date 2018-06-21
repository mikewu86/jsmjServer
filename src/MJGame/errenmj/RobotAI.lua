local skynet = require "skynet"
local datacenter = require "datacenter"

local RobotAI = class("RobotAI")
local CardConstant = require "MJCommon.MJConstant"
local MJUtils = require "MJCommon.MJUtils"
local MJOperations = MJUtils.MJOperations
local MJConst = require "mj_core.MJConst"
RobotAI.AIType = {}
RobotAI.AIType.ADVENTURE = 1              --冒险型
RobotAI.AIType.ROBUST = 2                 --稳健性
RobotAI.AIType.CONSERVATIVE = 3           --保守性

function RobotAI:ctor(_playerCound, _aiType)
    self.handCards = {}
    self.deskCards = {}
    self.playerCount = _playerCound
    if not _aiType then
        _aiType = RobotAI.AIType.ADVENTURE
    end
    self.aiType = _aiType
    --self:initCache()
end

function RobotAI:reset()
    self.handCards = {}
    self.deskCards = {}
    self.pengCards = {}
    self.gangCards = {}
    self.operations = MJOperations.new()
end

function RobotAI:getHandCards()
    return self.handCards
end

function RobotAI:addHandCards(_cards)
    --dump(_cards)
    --先排序
    table.insert(self.handCards, _cards)
end

function RobotAI:removeHandCards(_cards)
    if table.size(self.handCards) > 0 then
        table.removeItem(self.handCards, _cards)
    end
end

function RobotAI:sortHandCards(_func)
    if ("function" == type(_func)) then
        table.sort(self.logicData.handCards, _func)
    end
end

function RobotAI:getDeskCards()
    return self.deskCards
end

function RobotAI:addDeskCards(_card)
    table.insert(self.deskCards, _card)
end

function RobotAI:removeDeskCards(_card)
    if table.size(self.deskCards) > 0 then 
        table.removeItem(self.deskCards, _card)
    end
end

function RobotAI:getPendCards()
    return self.pengCards
end

function RobotAI:addPengCards(_card)
    table.insert(self.pengCards, _card)
end

function RobotAI:ting(data)
end

function RobotAI:addchicards(data)
end

function RobotAI:getGangCards()
    return self.gangCards
end

function RobotAI:addGangCards(_card)
    table.insert(self.gangCards, _card)
end

function RobotAI:resetOperations()
    self.operations:reset()
end

function RobotAI:addOperations(_ops)
    self:resetOperations()
    self.operations:addOperations(_ops)
end

function RobotAI:setOperations(_op)
    self.operations:setOperations(_op)
end

function RobotAI:checkOperation(_op)
    LOG_DEBUG("RobotAI:checkOperation")
    return self.operations:checkOperation(_op)
end

function RobotAI:getOperations()
    return self.operations:getOperations()
end

function RobotAI:hasGangOps()
    local bRet = false
    if nil == self.operations then
        return bRet
    end
    if true == self.operations:checkOperation(MJConst.kOperMG) or 
        true == self.operations:checkOperation(MJConst.kOperAG) or
        true == self.operations:checkOperation(MJConst.kOperMXG) then
        bRet = true
    end
    return bRet
end

return RobotAI