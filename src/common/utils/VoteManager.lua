--2017.1.12 投票管理器
-- 
local skynet = require("skynet")


-- 投票的状态
local kVoteNull     = 0     -- 未投
local kVoteAgree    = 1    -- 同意
local kVoteDisagree = 2 -- 不同意
local kVoteRequest  = 3  -- 发起请求


local kVoteClientDisagree   = 0
local kVoteClientAgree      = 1

local kNotDisband   = 0
local kDisband      = 1

local kNotReturnToHall  = 0
local kReturnToHall     = 1


local kPerecent     = 100  -- 1秒时长
local kVoteTimeOut  = 60 * kPerecent -- 投票超时时长

local VoteItem = class("VoteItem")
function VoteItem:ctor(status, uid, name)
    self.status = status
    self.uid    = uid or 0
    self.name   = name or ''
end

function VoteItem:clear()
    self.status = kVoteNull
    self.uid     = 0
    self.name    = ''
end

local VoteManager = class("VoteManager")
function VoteManager:ctor(room)
    self.room = room
    self.voteHandle = nil
    self.requestUseName = ''
    self.disband = false
    self.leftTimeOut = 0
    self.round = 1
    self:initVoteList()
end

function VoteManager:initVoteList()
    self.voteList = {}
    for i = 1, self.room.maxPlayer do
	    table.insert(self.voteList, VoteItem.new(kVoteNull))
    end
end

function VoteManager:isDisband()
    return self.disband
end

function VoteManager:startVoteTimeOut()
    if self.leftTimeOut > 0 then
        self.leftTimeOut = self.leftTimeOut - 1
        self.room:setTimeOut(kPerecent, function()
            self:startVoteTimeOut()
        end)
    else
        self.leftTimeOut = 0
    end
end

-- 玩家请求解散
function VoteManager:onPlayerRequestDisband(uid, _pkg)
    LOG_DEBUG('onPlayerRequestDisband uid:'..uid)
    if self.voteHandle then
        self:sendVIPErrorMsg(uid, '正在投票中！', kNotReturnToHall)
        return
    end
    local player = self.room.players[uid]
    if player then
        local pos = player:getDeskPos()
        if pos > 0 and pos <= self.room.maxPlayer then
            if not self.room.isVIPLock then
                if self.room.fangInfo and self.room.fangInfo.OwnerUserId then
                    if uid == self.room.fangInfo.OwnerUserId then  -- 只有房主才能解散游戏
                        self.room:addDisbandLog(uid, self.round, kDisband, true)
                        self:sendVoteResultMsg(nil, kDisband, uid)
                    else
                        self:sendVIPErrorMsg(uid, '非房主不能在游戏开始前解散游戏！', kNotReturnToHall)
                    end
                else
                    -- dump(self.room.fangInfo, 'self.room.fangInfo = ')
                    self:sendVIPErrorMsg(uid, '无法解散！', kNotReturnToHall)
                end
            else
                self:sendVoteMsg(nil, uid, _pkg.isRequest, pos, kVoteClientAgree)
                self.room:addDisbandLog(uid, self.round, kDisband, true)
                self:initVoteList()
                -- dump(self.voteList)
                -- LOG_DEBUG('pos = '..pos)
                if self.voteList[pos] then
                    self.voteList[pos].status   = kVoteRequest
                    self.voteList[pos].uid      = uid
                    self.voteList[pos].name     = player.nickname
                else
                end

                self.leftTimeOut = math.ceil(kVoteTimeOut / kPerecent)
                self:startVoteTimeOut()
                self.voteHandle = self.room:setTimeOut(kVoteTimeOut, function()
                    self.voteHandle = nil
                    self:sendVoteResultMsg(nil, kDisband, uid)
                end)
            end
        else
            self:sendVIPErrorMsg(uid, '无效的玩家坐位', kNotReturnToHall)
        end
    else
        local player = self.room.watchers[uid]   -- 旁观状态下解散，只有房主在未开始的状态下可以
        if uid == self.room.fangInfo.OwnerUserId and player then
            if not self.room.isVIPLock then
                self:sendVoteResultMsg(nil, kDisband, uid)
            else
                self:sendVIPErrorMsg(uid, '无法解散！', kNotReturnToHall)
            end
        else
            self:sendVIPErrorMsg(uid, '无效的玩家', kNotReturnToHall)
        end
    end
end

-- 检查是否解散
function VoteManager:checkNeedDisband()
    for _, v in pairs(self.voteList) do
        if v.status == kVoteNull then
            return false
        end
    end
    return true
end

-- 玩家投票
function VoteManager:onPlayerVote(uid, _pkg)
    -- dump(_pkg, ' onPlayerVote = ')
    if not self.voteHandle then
        self:sendVIPErrorMsg(uid, '投票已结束', kNotReturnToHall)
        return
    end
    if _pkg.willDisband == kVoteClientDisagree then
        -- 只要有人不同意就不解散
        local player = self.room.players[uid]
        if player then
            local pos = player:getDeskPos()
            if pos > 0 and pos <= self.room.maxPlayer then
                self.room:deleteTimeOut(self.voteHandle)
                self.voteHandle = nil
                self:sendVoteMsg(nil, uid, _pkg.isRequest, pos, kVoteClientDisagree)
                self:sendVoteResultMsg(nil, kNotDisband, uid)
                self.room:addDisbandLog(uid, self.round, kNotDisband, false)
                self.round = self.round + 1
            else
                self:sendVIPErrorMsg(uid, '拒绝玩家坐位错误！', kNotReturnToHall)
            end
        else
            self:sendVIPErrorMsg(uid, '拒绝玩家错误！', kNotReturnToHall)
        end
    else
        local player = self.room.players[uid]
        if player then
            local pos = player:getDeskPos()
            if pos > 0 and pos <= self.room.maxPlayer then
                if self.voteList[pos].status == kVoteNull then
                    self.voteList[pos].status = kVoteAgree
                    self.voteList[pos].uid    = uid
                    self.voteList[pos].name   = player.nickname
                    self:sendVoteMsg(nil, uid, _pkg.isRequest, pos, kVoteClientAgree)
                    self.room:addDisbandLog(uid, self.round, kDisband, false)
                elseif self.voteList[pos].status == kVoteAgree then
                    self:sendVIPErrorMsg(uid, '您已经投过票了！', kNotReturnToHall)
                end
                if self:checkNeedDisband() then
                    self:sendVoteResultMsg(nil, kDisband, uid)
                end
            else
                LOG_DEBUG('-- vote pos is illegal --'..pos)
                self:sendVIPErrorMsg(uid, '游戏玩家坐位错误！', kNotReturnToHall)
            end
        else
            LOG_DEBUG('-- nil player vote --')
            self:sendVIPErrorMsg(uid, '非游戏玩家投票！', kNotReturnToHall)
        end
    end
end

function VoteManager:onPlayerDisband(uid, _pkg)
    if _pkg.isRequest == 1 then  -- 请求解散
		self:onPlayerRequestDisband(uid, _pkg)
	else
		self:onPlayerVote(uid, _pkg)
	end
end

-- 这个玩家是否需要投票
function VoteManager:needVote(uid)
    if self.voteHandle then
        -- dump(self.voteList, 'self.voteList = ')
        if self.room.GameProgress then
            local player = nil
            for _, _player in pairs(self.room.GameProgress.playerList) do
                if _player and _player:getUid() == uid then
                    player = _player
                    break
                end
            end
            if player then
                local pos = player:getDeskPos()
                -- LOG_DEBUG('pos = '..pos..' uid = '..uid)
                if self.voteList[pos] and self.voteList[pos].status == kVoteNull then
                    return true
                end
            else
                LOG_DEBUG('-- player is nil --')
            end
        else
            LOG_DEBUG('-- no GameProgress --')
        end
        return true
    end
    return false
end

-- 处理此玩家的投票
function VoteManager:handleCutPlayerVote(uid)
    if self:needVote() then
        local pkg = {}
        pkg.agreedList = {}
        pkg.leftTime = self.leftTimeOut
        for _, item in pairs(self.voteList) do
            if item.status == kVoteRequest then
                pkg.owner = item.uid
                table.insert(pkg.agreedList, item.uid)
            elseif item.status == kVoteAgree then
                table.insert(pkg.agreedList, item.uid)
            end
        end
        self.room:sendMsgToUid(uid, 'vipDisbandStatus', pkg)
    else
        -- LOG_DEBUG('-- cutter not need Vote --')
    end
end

------------------------消息发送------------------------
function VoteManager:sendVIPErrorMsg(uid, content, willExit)
    local pkg = {}
    pkg.Content = content
    pkg.needExit = willExit
    if uid then
        self:sendMsg(uid, 'vipErrorMsg', pkg)
    else
        self.room:broadcastMsgToAll('vipErrorMsg', pkg)
    end
end

function VoteManager:sendVoteMsg(uid, fromUId, isRequest, pos, willDisband)
    local pkg = {}
    pkg.userName = ''
    pkg.isRequest = isRequest
    local player = self.room.players[fromUId]
    if player then
        pkg.userName = player.nickname
        pkg.pos = pos
    end
    pkg.willDisband = willDisband
    pkg.totalTime = math.ceil(kVoteTimeOut / kPerecent)
    self.requestUseName = pkg.userName
    self:sendMsg(uid, 'vipDisbandVote', pkg)
end

-- 解散消息需要通知旁观玩家
function VoteManager:sendVoteResultMsg(uid, result, userId, reason)
    local pkg = {}
    pkg.result = result
    pkg.uid  = userId
    pkg.msg  = '此房间已解散\n(游戏未开始不扣钻石)'
    local needMoney = false
    if self.room.isVIPLock then
        if #self.room.GameProgress.roundScoreList == 0 then
            pkg.msg  = '此房间已解散\n(第一局结算前不扣钻石)'
        else
            pkg.msg  = '此房间已解散\n(已经是第'..self.room.GameProgress.roundCount..'局，扣除钻石X'..self.room.fangInfo.FangCard..')'
            needMoney = true
        end
        self.room.GameProgress:sendVoteBeforeGameInfo(result)
    end
    local cpyMsg = table.copy(pkg)
    cpyMsg.msg = '此房间已解散'
    
    if result == kDisband then
        self:onDisband()
    else
        self.disband = false
    end

    if uid then
        if self.room:isOwner(uid) then
            self:sendMsg(uid, 'vipDisbandResult', pkg)
        else
            self:sendMsg(uid, 'vipDisbandResult', cpyMsg)
        end
    else
        -- Player
        for uid, player in pairs(self.room.players) do
            if self.room:isOwner(uid) then
                self:sendMsg(uid, 'vipDisbandResult', pkg)
            else
                self:sendMsg(uid, 'vipDisbandResult', cpyMsg)
            end
        end
        -- watcher
        for uid, player in pairs(self.room.watchers) do
            if self.room:isOwner(uid) then
                self:sendMsg(uid, 'vipDisbandResult', pkg)
            else
                self:sendMsg(uid, 'vipDisbandResult', cpyMsg)
            end
        end
        -- self.room:broadcastMsgToAll('vipDisbandResult', pkg)
    end
end

function VoteManager:onDisband()
    if self.voteHandle then
        self.room:deleteTimeOut(self.voteHandle)
        self.voteHandle = nil
    end
    self.disband = true
    self.room:clearHoldPlayersForRace()
    self.room:onDisband()   -- 回调房间的解散处理
end

function VoteManager:sendMsg(uid, pkgName, pkg)
    if not uid then
        self.room:broadcastMsg(pkgName, pkg)
    else
        self.room:sendMsgToUid(uid, pkgName, pkg)
    end
end

return VoteManager