
--[[ 一个sng的游戏组  对场次进行自动管理 ]]
local GroupMgr = class('GroupMgr')
local RoundMgr = require "sngroundmgr"

function GroupMgr:ctor(groupId, timeMgr, racemgr, robotMgr, sngConfig)
    self.id = groupId
    self.rounds = {}
    self.curRoundIndex = 1
    self.curRound = nil
    self.racemgr = racemgr
    self.timeMgr = timeMgr
    self.robotMgr = robotMgr
    self.sngConfig = sngConfig
end

-- 把玩家分配进一个可用的场次
function GroupMgr:allocPlayerInRound(uid, agent, isHold)
    LOG_DEBUG('GroupMgr:allocPlayerInRound')
    local round = self:getValidRound(uid, isHold)
    round:addPlayer(uid, agent, isHold)
end

-- 获取一个可用的场次
-- one round is full, create new. 
function GroupMgr:getValidRound(uid, isHold)
    -- 首先找已存在HOLD标志的场次
    if not isHold then
        for idx, round in pairs(self.rounds) do
            if round:isHoldPlayer(uid) == true then
                self.curRound = round
                return round
            end
        end
    end
    -- 从最近的场次查找
    if self.curRound and self.curRound:isPlaying() == false and 
        self.curRound:getPlayerCount() < self.sngConfig.openCount then
        return self.curRound
    end
    -- 从已有的场次中找出可用的比赛场
    for idx, round in pairs(self.rounds) do
        if round:isPlaying() == false and 
            round:getPlayerCount() < self.sngConfig.openCount then
            self.curRound = round
            return round
        end
    end
    -- 未找到,新建一个场次
    self.rounds[self.curRoundIndex] = RoundMgr.new(self.id, self.curRoundIndex, self.timeMgr, self.sngConfig, 
    self.racemgr, self.robotMgr)
    self.curRound = self.rounds[self.curRoundIndex]
    self.curRoundIndex = self.curRoundIndex + 1
    return self.curRound
end

function GroupMgr:getRound(roundId)
    return self.rounds[roundId]
end

function GroupMgr:getRoundByRoomId(roomid)
    for _, round in pairs(self.rounds) do
        if round:hasRoom(roomid) then
            return round
        end
    end
    return nil
end

-- 玩家能否报名
function GroupMgr:canPlayerSignUp(uid)
    for _, round in pairs(self.rounds) do
        if round:hasPlayer(uid) == true then
            return false
        end
    end
    return true
end

function GroupMgr:cancelSignup(uid)
    for _, round in pairs(self.rounds) do
        if round:hasPlayer(uid) then
            return round:cancelSignup(uid)
        end
    end
    return false
end

function GroupMgr:getRoundByUid(uid)
    local bRet = false
    local tempRound = nil
    for _, round in pairs(self.rounds) do 
        if true == round:hasPlayer(uid) then
            bRet = true
            tempRound = round
            break
        end
    end
    return bRet, tempRound
end

return GroupMgr