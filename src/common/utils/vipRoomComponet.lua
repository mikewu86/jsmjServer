
-- 2017.3.23
-- zhangxiao
--基础包间功能，包间可以选择此组件

local VIPComponet = class("VIPComponet")
local skynet = require "skynet"
local kPersecent 			= 100

function VIPComponet:ctor(room, autoDisbandTimeOut)
    self.room = room
    if autoDisbandTimeOut then
        self.autoDisbandTimeOut = autoDisbandTimeOut
    else
        self.autoDisbandTimeOut = 900 * kPersecent -- 自动解散的时间
    end
end

-- 开房以后规定时间内不开始，关闭该房间
function VIPComponet:startAutoDisband()
	if not self.autoDisband then
		-- dump(self.autoDisbandTimeOut, '-- VIPComponet:startAutoDisband -- ')
		self.autoDisband = self.room:setTimeOut(self.autoDisbandTimeOut, function()
			self.autoDisband = nil
			if not self.room.isVIPLock then
				if not self.room.voteMgr:isDisband() then
					self.room.voteMgr:onDisband()
					self.room.voteMgr:sendVIPErrorMsg(nil, '此房间已解散\n(游戏未开始不扣钻石)', 1)
				end
			end
		end)
	end
end

function VIPComponet:stopAutoDisband()
	if self.autoDisband then
		self.room:deleteTimeOut(self.autoDisband)
		self.autoDisband = nil
	end
end

function VIPComponet:deleteAutoDisband()
	if self.autoDisband then
		self.room:deleteTimeOut(self.autoDisband)
		self.autoDisband = nil
	end
end

--在room初始化的时候调用，主要用于派生的room中实现
function VIPComponet:onInit(room)
    self.room = room
    local fangInfo = room.fangInfo
	if fangInfo and fangInfo.RoomStatus == kVipRoomState.playing then
		-- 房间重启以后若是游戏状态，则解散并退款
		self.room:onDisband()
        return
	end
    self:startAutoDisband()
end

function VIPComponet:onEnterRoom(_player)
	--可在此处理额外的进入房间后的动作
	if self.room:isVIPRoom() then
		if self.room.voteMgr.isdisband then
			self.room.voteMgr:sendVIPErrorMsg(nil, '此房间已解散\n', 1)
			return
		end
        -- self.room:broadcastMsg('notifyUserCut', {})
		if self.room.isVIPLock then -- 发送掉线玩家的消息
			local pkg = {}
			pkg.cutUserList = self:findAllVirtualCutPlayer()
			if not self.room.watchers[_player:getUid()] then
				local idx = table.keyof(pkg.cutUserList, _player:getDeskPos())
				if idx ~= nil then
					table.remove( pkg.cutUserList, idx)
				end
			end
			-- 同步玩家数据
			--- todo  更完善的方案
			self.room.GameProgress:broadCastMsgUpdatePlayerData(_player.uid)
			-- dump(self.room.GameProgress.playerList, ' VIPComponet:onEnterRoom 1')
			-- dump(self.room.players, ' VIPComponet:onEnterRoom 2')
			self.room:broadcastMsg('notifyUserCut', pkg)
		else -- 游戏未开始也要发
			local pkg = {}
			pkg.cutUserList = self:findAllHoldCutPlayer()
			if not self.room.watchers[_player:getUid()] then
				local idx = table.keyof(pkg.cutUserList, _player:getDeskPos())
				if idx ~= nil then
					table.remove( pkg.cutUserList, idx)
				end
			end
			self.room:broadcastMsgToAll('notifyUserCut', pkg)
		end
		if self.room:isWatcher(_player:getUid()) == 0 then
			self.room.voteMgr:handleCutPlayerVote(_player.uid)
		end
	end
end

function VIPComponet:onWatcherEnterRoom(_player)
	LOG_DEBUG('VIPComponet:onWatcherEnterRoom uid = '.._player:getUid())
end

--掉线重入了，恢复游戏场景
function VIPComponet:onUserCutBack(_player, cutList)
	if self.room:isVIPRoom() then
		self.room.voteMgr:handleCutPlayerVote(_player.uid)
	end
end

function VIPComponet:isVirtualCutPlayer(player)
	for _, _player in pairs(self.room.players) do
		if _player then
			if _player:getUid() == player:getUid() then
				return false
			end
		end
	end
	return true
end

-- 拿逻辑数据与坐位上的人比对。有就在线，没有就不在线。
function VIPComponet:findAllVirtualCutPlayer()
	local cutplayers = {}
	for _, _player in pairs(self.room.GameProgress.playerList) do
		if self:isVirtualCutPlayer(_player) then
			if table.keyof(cutplayers, _player:getDeskPos()) == nil then
				table.insert(cutplayers, _player:getDeskPos())
			end
		end
	end
	return cutplayers
end

-- 找出所有占位玩家掉线的,拿占位玩家与坐位上的玩家比对。有就在线，没有就不在线
function VIPComponet:findAllHoldCutPlayer()
	local cutplayers = {}
	for _, _player in pairs(self.room.holdPlayers) do
		if self:isVirtualCutPlayer(_player) then
			if table.keyof(cutplayers, _player:getDeskPos()) == nil then
				table.insert(cutplayers, _player:getDeskPos())
			end
		end
	end
	return cutplayers
end

function VIPComponet:LeaveRoom(uid)
	if self.room:isVIPRoom() then
		if self.room.isVIPLock then
			-- 找出所有掉线的玩家，这个玩家也即将掉线
			local pkg = {}
			pkg.cutUserList = self:findAllVirtualCutPlayer()
			if not self.room.watchers[uid] then
				for _, _player in pairs(self.room.GameProgress.playerList) do
					if _player:getUid() == uid then
						if table.keyof(pkg.cutUserList, _player:getDeskPos()) == nil then
							table.insert(pkg.cutUserList, _player:getDeskPos())
						end
						break
					end
				end
			end
			self.room:broadcastMsg('notifyUserCut', pkg)
		else -- 游戏未开始，有人离开，也需要发消息
			local pkg = {}
			pkg.cutUserList = self:findAllHoldCutPlayer()
			if not self.room.watchers[uid] then
				for _, _player in pairs(self.room.holdPlayers) do
					if _player:getUid() == uid then
						if table.keyof(pkg.cutUserList, _player:getDeskPos()) == nil then
							table.insert(pkg.cutUserList, _player:getDeskPos())
						end
						break
					end
				end
			end
			self.room:broadcastMsgToAll('notifyUserCut', pkg)
		end
	end
end

return VIPComponet