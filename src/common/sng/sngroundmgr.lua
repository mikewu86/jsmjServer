--[[
    Author:zhangxiao
    Date:2016.12.7
    具体的场次管理, 本场比赛中管理淘汰的分数,
    每次都分配新room, 该room由raceMgr自动回收, 
    不考虑从有人的room上凑
]]

local skynet = require "skynet"

local dealyAllociTime = 10 * 50  -- 延时分配机器人的时间
local dealyBeginTime = 200

local PlayerItem = class('PlayerItem')
-- 没有agent的情况下生成一个假的agent
function PlayerItem:ctor(uid, agent, isHold)
    self.uid = uid
    self.agent = agent
    self.isHold = isHold
    self.isRobot = skynet.call(agent, "lua", "isRobot")
    self.score = 0
    self.room = nil
    self.nickName = skynet.call(agent, "lua", "getName")
end

local RoundMgr = class('Round')
function RoundMgr:ctor(groupId, roundId, timeMgr, sngConfig, raceMgr, robotMgr)
    self.groupId = groupId
    self.roundid = roundId
    self.playing = false
    self.playerList = {}
    self.roomList = {}
    self.timeMgr = timeMgr
    self.racemgr = raceMgr
    self.sngConfig = sngConfig
    self.reservePlayer = {}  -- 保留继续下一轮的玩家
    self.roundLevel = 0
    self.roundCount = 1  -- 当前的轮次
    self.robotMgr = robotMgr
    self.delayCallRobotHandle = nil
    self.playingPlayers = {}
    self.rankList = {}      --所有玩家的排行
    self.roundConfig = sngConfig.roundConfig[self.roundCount]
    self.cutScore = self.roundConfig.cutScore[1]
end

-- 比赛结束
function RoundMgr:overRound()
    LOG_DEBUG('============== over Round ==================')
    self.playing = false
    self.playerList = {}
    
    self.roundLevel = 0
    self.roundCount = 1  -- 当前的轮次
    if self.cutHaldle then
        self:deleteTimeOut(self.cutHaldle)
        self.cutHaldle = nil
    end
    self.delayCallRobotHandle = nil
    self.roundConfig = self.sngConfig.roundConfig[self.roundCount]
    self.cutScore = self.roundConfig.cutScore[1]

    local raceMgr = skynet.uniqueservice("gameracemgr")
    -- 清除所有的保留玩家
    for _, item in pairs(self.reservePlayer) do
        skynet.call(item.agent, 'lua', 'sendMsg', 'sngOver', {})
        skynet.call(raceMgr, "lua", "changePlayerState", item.uid, Enums.PlayerState.IDLE)
        skynet.call(raceMgr, "lua", "leaveRoom", item.uid)
        skynet.call(raceMgr, "lua", 'leaveGame', item.uid)  -- 保留的玩家离开游戏
    end
    self.reservePlayer = {}
end

function RoundMgr:getPlayerCount()
    return #self.playerList
end

function RoundMgr:getMoney(uid)
    if nil ~= self.rankList then
        for _, item in pairs(self.rankList) do
            if item.uid == uid then
                return item.score
            end
        end
    end
    return 0
end

function RoundMgr:isPlaying()
    return self.playing
end

-- 策略为到点后一次分配一个机器人，直到分配完成
function RoundMgr:allocRobot()
    if self.playing then
        return
    end
    -- LOG_DEBUG('allocRobot self.getPlayerCount = '..self:getPlayerCount())
    -- LOG_DEBUG('allocRobot self.sngConfig.openCount = '..self.sngConfig.openCount)
    -- LOG_DEBUG('self.roundid = '..self.roundid..' self.groupId = '..self.groupId)
    if self:getPlayerCount() < self.sngConfig.openCount then
        local robot = skynet.call(self.robotMgr, "lua", "requestRobot", nil, self.groupId)
        if robot then
            skynet.call(robot, "lua", "enterSNGGame", self.roundid, self.groupId)
        end
    else
        self.delayCallRobotHandle = nil
    end
end

-- 这里会出现一种情况是，web通知有人报名了,WEB报名通知时起占位作用
-- 这具人此时还没有agent，等他连接到race上时，才会真有agent
-- 这样处理的目的是当WEB通知在真人上来前，用真人的替换WEB的
--真人上的在WEB前，则不用替换,
function RoundMgr:addPlayer(uid, agent, isHold)
    LOG_DEBUG('RoundMgr:addPlayer'..uid)
    LOG_DEBUG('addPlayer '..self.roundid..' self.groupId = '..self.groupId)
    local isExisted = false
    -- 查找当前有没有这个玩家
    for _, item in pairs(self.playerList) do
        if item.uid == uid then
            isExisted = true
            if item.isHold then
                item.agent = agent
                break
            end
        end
    end

    if not isExisted then
        local player = PlayerItem.new(uid, agent, isHold)
        table.insert(self.playerList, player)
        --报名成功以后就写库，指出这个玩家应该掉线后连到哪个raceMgr
        local redisMgr = skynet.uniqueservice('redismgr')
        skynet.call(redisMgr, "lua", "set_value", uid, {
            gameid = tonumber(skynet.getenv('gameid')),
            nodeid = tonumber(skynet.getenv('nodeid')),
            groupid = self.groupId
        })
    end
    -- dump(self.playerList)
    self:sendNotifyGameLoadingBegin(agent, self:getPlayerCount(),self.sngConfig.openCount)

    if self:getPlayerCount() >= self.sngConfig.openCount then
        if self.delayCallRobotHandle then
            self.timeMgr:deleteTimeOut(self.delayCallRobotHandle)
            self.delayCallRobotHandle = nil
        end
        self.timeMgr:setTimeOut(dealyBeginTime, function()
            self:sendNotifyGameLoadingEnd()
            self.rankList = {}
            self.rankList = table.copy(self.playerList)
            self:beginRound(self.playerList)
        end)
        return
    end
    -- dump(self.delayCallRobotHandle, 'self.delayCallRobotHandle')
    if self.delayCallRobotHandle == nil then
        self.delayCallRobotHandle = self.timeMgr:setTimeOut(dealyAllociTime, function()            
            LOG_DEBUG('-- delayCallRobotHandle callback')
            self:allocRobot()
        end)
    else
        LOG_DEBUG('-- continue aloc robot')
        self:allocRobot()  -- 在分配机器人未停止时，若还能分配则马上分配
    end
end

function RoundMgr:deletePlayer(uid)
    for idx, item in pairs(self.playerList) do
        if item.uid == uid then
            table.remove(self.playerList, idx)
            return true
        end
    end
    return false
end

-- 淘汰分数升高, 淘汰一部分人
function RoundMgr:checkCutScore()
    self.roundLevel = self.roundLevel + 1
    self.cutHaldle = nil
    if #self.roundConfig.cutScore < self.roundLevel then
        self.roundLevel = #self.roundConfig.cutScore
    else
        --
        self.cutHaldle = self:setTimeOut(500, function()
            self:checkCutScore()
        end)
    end
    self.cutScore = self.roundConfig.cutScore[self.roundLevel]
end

-- 一轮比赛开始
function RoundMgr:beginRound(playerList)
    LOG_DEBUG('beginRound')
    -- dump(playerList)
    for _, player in pairs(playerList) do
        LOG_DEBUG(' >>>>>>>> uid = '..player.uid)
    end
    self.playing = true
    self.playingPlayers = {}
    self.roundLevel = 0
    for _, item in pairs(playerList) do
        if self.roundCount == 1 then
            item.score = tonumber(self.sngConfig.initScore)
        else
            item.score = math.ceil(item.score / 2)
        end
        self:refreshRankList(item)
        LOG_DEBUG("uid:"..item.uid.." score:"..item.score)
        --table.insert(self.playingPlayers, table.copy(item))
    end
    if self.cutHaldle then
        self:deleteTimeOut(self.cutHaldle)
        self.cutHaldle = nil
    end
    --todo 根据配置文件在规定时间内长高淘汰分数
    self.cutHaldle = self:setTimeOut(500, function()
        self:checkCutScore()
    end)
    -- 根据需求先分配出来room,将玩家按组分配进去
    if #playerList == self.roundConfig.openCount then
        self.timeMgr:setTimeOut(100, function()
             self:allocRoom(playerList) --让所有玩家进房间
        end)
    else        --无法分配了, 直接发奖
        --todo 通知web服务器发奖
        LOG_DEBUG('cannot open need'..self.roundConfig.openCount..' act = '..#playerList)
        -- default two player from  self.rankList award.
        self:awardPlayers()
    end
    -- 这项放到最后
    self.reservePlayer = {}
end

-- 当前的玩家分桌子
function RoundMgr:allocRoom(playerList)
    self:broadCastRankList()
    local raceMgr = skynet.uniqueservice("gameracemgr")
    local waitAllocPlayers = table.clone(playerList)
    local curIdx = 1
    self.roomList = {}
    for _, player in pairs(playerList) do
        LOG_DEBUG(' >>>>>>>>allocRoom  uid = '..player.uid)
    end
    while #waitAllocPlayers ~= 0 or curIdx < #playerList do
        local roomInfo = skynet.call(raceMgr, "lua", "allocateValidRoom", self.groupId, self.roundid)
        roomInfo.roundCount = 1
        -- dump(roomInfo, 'roomInfo = ')
        print('#waitAlloc Players '..#waitAllocPlayers..' roomid = '..roomInfo.roomid)
        table.insert(self.roomList, roomInfo)
        for i = 1, roomInfo.maxplayernum do
            local item = playerList[curIdx]
			LOG_DEBUG("roomId:"..roomInfo.roomid.." player.Uid:"..item.uid.." roundCount:"..roomInfo.roundCount)
            -- dump(item, ' item = ')
            item.room = roomInfo  --将玩家与此房间关联
            --self:updatePlayerScore(roomInfo.roomid, item.uid, item.score)
            table.remove(waitAllocPlayers, 1)
            curIdx = curIdx + 1
            skynet.call(item.agent, "lua", "changePlayingStatus", 
            false, roomInfo.roomid, self.groupId)
            table.insert(self.playingPlayers, table.copy(item))
        end
    end

    -- 让玩家进房间
    for _, roomInfo in pairs(self.roomList) do
        for __, item in pairs(self.playingPlayers) do
            if item.room.roomid == roomInfo.roomid then
                local ret = skynet.call(item.agent, "lua", "enterAllocatedRoom", 
                roomInfo.roomid, item.score)
            end
        end
        --不用准备, 直接开始游戏
        skynet.call(raceMgr, "lua", "startGame", roomInfo.roomid, self.groupId)
    end

end

function RoundMgr:hasRoom(roomId)
    for _, roomInfo in pairs(self.roomList) do
        if roomInfo.roomid == roomId then
            return true
        end
    end
    return false
end

-- 玩家是否在本场比赛中
function RoundMgr:hasPlayer(uid)
    for idx, item in pairs(self.playerList) do
        if item.uid == uid and item.isHold == false then
            return true
        end
    end
    return false
end

function RoundMgr:isHoldPlayer(uid)
    for idx, item in pairs(self.playerList) do
        if item.uid == uid and item.isHold == true then
            return true
        end
    end
    return false
end

-- 玩家取消报名
function RoundMgr:cancelSignup(uid)
    if self.playing then
        return false
    end
    if self:hasPlayer(uid) then
        return self:deletePlayer(uid)
    end
end

function RoundMgr:getRoom(roomid)
    for idx, roomInfo in pairs(self.roomList) do
        if roomInfo.roomid == roomid then
            return roomInfo
        end
    end
    return nil
end

--
function RoundMgr:removeRoom(roomid)
    local raceMgr = skynet.uniqueservice("gameracemgr")
    for idx, roomInfo in pairs(self.roomList) do
        if roomInfo.roomid == roomid then
            --让里面的玩家全部退出
            for _, item in pairs(self.playingPlayers) do
                if item.room.roomid == roomid then
                    skynet.call(raceMgr, "lua", "leaveRoom", item.uid)
                    if nil == table.keyof(self.reservePlayer, item) then
                        self:updateOutPlayerStatus(item)
                    else
                        skynet.call(item.agent, 'lua', 'sendMsg', 'sngKnockOut', {knockout = 0})
                        skynet.call(raceMgr, "lua", "changePlayerState", item.uid, Enums.PlayerState.SNGSIGNUP)
                    end
                end
            end
            table.remove(self.roomList, idx)
            return
        end
    end
end

-- 中间更新分数 {uid=score, uid=score},返回是否要结束游戏
function RoundMgr:updateScore(scoreMap, roomid)
    --dump(scoreMap, ' RoundMgr scoreMap = ')
    LOG_DEBUG('-- RoundMgr.updateScore --')
    local willGameEnd = false
    local roomInfo = self:getRoom(roomid)
    if not roomInfo then
        return willGameEnd
    end
    
    if not scoreMap then
        scoreMap = {}
    end

    -- 打满指定有盘数以后通知游戏结束
    if roomInfo.roundCount >= self.roundConfig.endCount then
        willGameEnd = true
    end
    roomInfo.roundCount = roomInfo.roundCount + 1
    -- 有人被淘汰以后游戏结束
    for _, item in pairs(self.playingPlayers) do
        if scoreMap[item.uid] ~= nil then
            item.score = item.score + scoreMap[item.uid]
            self:updatePlayerScore(roomid, item.uid, item.score)
            self:refreshRankList(item)
            if item.score < self.cutScore then
                willGameEnd = true
                break
            end
        end
    end
    -- 把保留玩家弄出来
    if willGameEnd then
        local redisMgr = skynet.uniqueservice('redismgr')
        for _, item in pairs(self.playingPlayers) do
            if scoreMap[item.uid] ~= nil then
                if item.score >= self.cutScore then
                    table.insert(self.reservePlayer, item)
                else
                    -- 玩家被淘汰，从玩家库中删除之
                    if skynet.call(redisMgr, "lua", "get_value", item.uid) then
                        skynet.call(redisMgr, "lua", "del_key", item.uid)
                    end
                    
                end
            end
        end
    end

    -- 排序
    table.sort(self.playerList, function(l, r)
        return l.score > r.score
    end)

    -- 排行
    table.sort(self.playingPlayers, function(l, r)
        return l.score > r.score
    end)

    for idx, item in pairs(self.playingPlayers) do
        self:refreshRankList(item)
    end

    table.sort(self.reservePlayer, function(l, r)
        return l.score > r.score
    end)

    self:broadCastRankList()
    
    return willGameEnd
end

function RoundMgr:broadCastRankList()
    --填充排行榜消息
    local pkg = {}
    pkg.rankList = {}
    for _, item in pairs(self.playingPlayers) do
        local tmp = {}
        tmp.score = item.score
        tmp.name = item.nickName
        tmp.uid = item.uid
        table.insert(pkg.rankList, tmp)
    end
    -- dump(pkg, ' rankList = ')

    -- 发送排行信息
    for _, item in pairs(self.playingPlayers) do
        skynet.call(item.agent, 'lua', 'sendMsg', 'sngRankList', pkg)
    end
end

-- 游戏开始前需要做的事情
function RoundMgr:beforGameBegin(roomid)
    -- dump(self.playingPlayers, ' beforGameBegin players = ')
    for _, item in pairs(self.playingPlayers) do
        local room = self:getRoom(roomid)
        if not item.room then  
            LOG_DEBUG('-- before no item.room--'..roomid)
        end
        local playerNum = self.sngConfig.roundConfig[self.sngConfig.totalRound].openCount
        local final = 0
        if #self.playingPlayers < playerNum + 1 then
            final = 1
        end
        if room and item.room and item.room.roomid == roomid then
            skynet.call(item.agent, "lua", 'sendMsg', 'sngRound', {
                curTurn = self.roundCount,
                curRound = room.roundCount,
                final = final,
            })
        end
    end
    return true
end

-- 游戏结束，需要通知此管理器，用来执行下一轮的开始
-- 这里一定要先调用race的gameEnd，不然状态无法改变
function RoundMgr:onGameEnd(roomid)
    self:removeRoom(roomid)
    -- dump(self.reservePlayer, ' onGameEnd = ')
    LOG_DEBUG('roomListLen = '..#self.roomList..' reservePlayer = '..#self.reservePlayer)
    if #self.roomList == 0 then
        -- 结束了
        if self.roundCount == self.sngConfig.totalRound then
            self:overRound()
            return 
        end
        -- 进入下轮
        self.roundCount = self.roundCount + 1
		LOG_DEBUG("sng game go to next round:"..self.roundCount)
        self.roundLevel = 0
        self.roundConfig = self.sngConfig.roundConfig[self.roundCount]
        if #self.reservePlayer < self.roundConfig.openCount then
            --todo通知发奖
            local bOver = false
            if self.roundCount < self.sngConfig.totalRound then
                while self.roundCount < self.sngConfig.totalRound do
                    self.roundCount = self.roundCount + 1
                    self.roundConfig = self.sngConfig.roundConfig[self.roundCount]
                    if #self.reservePlayer > self.roundConfig.openCount then
                        while #self.reservePlayer > self.roundConfig.openCount do
                            LOG_DEBUG("less than need, next remove out players. ")
                            self:updateOutPlayerStatus(self.reservePlayer[#self.reservePlayer])
                            table.remove(self.reservePlayer, #self.reservePlayer )
                        end
                        break      
                    else
                        if self.roundCount == self.sngConfig.totalRound then
                            self:overRound()
                            return
                        end
                    end
                end
            else
               self:overRound()
               return
            end
        elseif #self.reservePlayer > self.roundConfig.openCount then
            --只保留分数最高的几个人
            while #self.reservePlayer > self.roundConfig.openCount do
                LOG_DEBUG("remove out players. ")
                dump(self.reservePlayer[#self.reservePlayer], "self.reservePlayer["..#self.reservePlayer.."]")
                self:updateOutPlayerStatus(self.reservePlayer[#self.reservePlayer])
                table.remove( self.reservePlayer, #self.reservePlayer )
            end
            -- update in  player status.
            -- self:updateInPlayerStatus()
        end
        --2秒以后进入下一轮
        self.timeMgr:setTimeOut(dealyBeginTime, function()
            self:beginRound(self.reservePlayer)
        end)
    end
end

function RoundMgr:setTimeOut(delayMS, callbackFunc, param)
    return self.timeMgr:setTimeOut(delayMS, callbackFunc, param)
end

function RoundMgr:deleteTimeOut(handle)
	self.timeMgr:deleteTimeOut(handle)
end
--
function RoundMgr:updateOutPlayerStatus(player)
    if nil == player then
        return 
    end
    local raceMgr = skynet.uniqueservice("gameracemgr")
    skynet.call(player.agent, 'lua', 'sendMsg', 'sngKnockOut', {knockout = 1})
    skynet.call(raceMgr, "lua", 'leaveGame', player.uid)  -- 非保留的玩家离开游戏
    self:deletePlayer(player.uid)

end

-- function RoundMgr:updateInPlayerStatus()
--     local raceMgr = skynet.uniqueservice("gameracemgr")
--     for _, item in pairs(self.reservePlayer) do 
--         skynet.call(item.agent, 'lua', 'sendMsg', 'sngKnockOut', {knockout = 0})
--         skynet.call(raceMgr, "lua", "changePlayerState", item.uid, Enums.PlayerState.SNGSIGNUP)
--     end
-- end

function RoundMgr:sendMsgToPlayer(agent, protoName, pkg)
    if nil == agent or nil == protoName or nil == pkg then
        return false
    end

    skynet.call(agent, 'lua', 'sendMsg', protoName, pkg)
    
    return true
end

function RoundMgr:sendNotifyGameLoadingBegin(agent, waitPlayerNum, needPlayerNum)
    if false == self:isPlaying() then
        if nil ~= agent then
            self:sendMsgToPlayer(agent, 'notifyGameLoadingBegin', {})
            self:sendNotifyGameLoading(waitPlayerNum, needPlayerNum)
        end
    end
end

function RoundMgr:sendNotifyGameLoadingEnd()
    if true == self:isPlaying() then
        for _, item in pairs(self.playerList) do 
            self:sendMsgToPlayer(item.agent, 'notifyGameLoadingEnd', {})
        end
    end
end

function RoundMgr:sendNotifyGameLoading(waitPlayerNum, needPlayerNum)
    if nil == waitPlayerNum or nil == needPlayerNum then
        LOG_DEBUG("RoundMgr:sendnotifyGameLoading input args error.")
        return
    end
    for _, item in pairs(self.playerList) do 
        self:sendMsgToPlayer(item.agent, 'notifyGameLoading', {waitPlayerNum = waitPlayerNum,
                                                       needPlayerNum = needPlayerNum})
    end 
end

function RoundMgr:sendMsgIsFinals()
    if #self.playingPlayers < 3 then

    else
        
    end
end

function RoundMgr:awardPlayers()
    ---local num = 
    ---self.rankList
end

function RoundMgr:refreshRankList(_item)
    for idx, item in pairs(self.rankList) do 
        if item.uid == _item.uid then
            item.score = _item.score
            item.agent = _item.agent
            break
        end
    end
end

function RoundMgr:updatePlayerScore(roomId, uid, score)
    local raceMgr = skynet.uniqueservice("gameracemgr")
    skynet.call(raceMgr, "lua", "updatePlayerScore", roomId, uid, score)
end

return RoundMgr