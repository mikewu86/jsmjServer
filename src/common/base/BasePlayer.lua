--房间中的用户对象基类
--管理玩家的一些基础的属性，如是否在游戏 座位号 FD  UID等
local skynet = require "skynet"
local BasePlayer = class("BasePlayer")
local snax = require "snax"

local WIN_SI_COUNT = 1
local LOSE_SI_COUNT = 2
local DRAW_SI_COUNT = 3

local WIN_STR_COUNT = "WinCount"
local LOSE_STR_COUNT = "LoseCount"
local DRAW_STR_COUNT = "DrawCount"

function BasePlayer:ctor()
	--	playing state
	self.playing = false
    --	uid
	self.uid = 0
    --	money
	self.money = 0
	--	deskid
	self.deskid = 0
	--	desk pos
	self.deskpos = 0
	--	offline?
	self.offline = false
	self.client_fd = nil
	self.agent = nil
	-- 当前所在玩的场次的unitcoin	
	self.unitcoin = 0
	self.isRobotUser = false
	
	self.sendRequest = nil
	
	self.currentGameUUID = ""
	--  player data
	self.nickname = ""
	--
	self.sngScore = 0
	self.ipaddr = ""
	self.isWatcher = 0
end

function BasePlayer:setWatcher(isWatcher)
	self.isWatcher = isWatcher
	skynet.call(self.agent, 'lua', 'setWatcher', isWatcher)
end

function BasePlayer:getWatcher(isWatcher)
	return self.isWatcher
end

function BasePlayer:setTmpMoney(money)
	self.sngScore = money
end

function BasePlayer:setUnitCoin(_unitcoin)
	self.unitcoin = _unitcoin
end

function BasePlayer:getUnitCoin()
	return _unitcoin
end

function BasePlayer:setNickname(_nickname)
	self.nickname = _nickname
end

function BasePlayer:getNickname()
	return self.nickname
end

function BasePlayer:setIPAddr(_ipaddr)
	self.ipaddr = _ipaddr
end

function BasePlayer:getIPAddr()
	return self.ipaddr
end

function BasePlayer:isRobot()
	return self.isRobotUser
end

function BasePlayer:setGameUUID(_uuid)
	self.currentGameUUID = _uuid
end

function BasePlayer:getGameUUID()
	return self.currentGameUUID
end

function BasePlayer:setRobot()
	self.isRobotUser = true
end

function BasePlayer:getUid()
	return self.uid
end

function BasePlayer:setUid(_uid)
	self.uid = _uid
end

function BasePlayer:getDeskID()
	return self.deskid
end

function BasePlayer:setDeskID(_id)
	self.deskid = _id
end

function BasePlayer:getDeskPos()
	return self.deskpos
end

function BasePlayer:setDeskPos(_pos)
	self.deskpos = _pos
end

function BasePlayer:getMoney()
	return self.money
end

function BasePlayer:getSngScore()
	return self.sngScore
end

function BasePlayer:setSngScore(_score)
	LOG_DEBUG("uid:"..self.uid.."BasePlayer:setSngScore _score:".._score)
	if _score < 0 then
		_score = 0
	end
	
	self.sngScore = _score
end

function BasePlayer:setMoney(_money)
	self.money = _money
end

function BasePlayer:isOffline()
	return self.offline
end

function BasePlayer:setOffline(_ol)
	self.offline = _ol
end

function BasePlayer:setClientFD(_fd)
	self.client_fd = _fd
end

function BasePlayer:getClientFD()
	return self.client_fd
end

function BasePlayer:setAgent(_agent)
	self.agent = _agent
end

function BasePlayer:getAgent()
	return self.agent
end

function BasePlayer:isPlaying()
	return self.playing
end

function BasePlayer:setPlaying(_playing)
	self.playing = _playing
end

function BasePlayer:setSendRequest(_sendRequest)
	self.sendRequest = _sendRequest
end

function BasePlayer:sendMsg(packageName, data)
	if self:isRobot() then
		--异步发送rpc请求
		skynet.fork(function()
			skynet.call(self:getAgent(), "lua", "dispatch", packageName, data)
		end)
	else
		send_client(self:getClientFD(), self.sendRequest(packageName, data))
	end
end

function BasePlayer:updatePlayerInfo()
	local uid = self:getUid()
	if 0 == uid then 		
		LOG_ERROR("updatePlayerInfo: get invalid player's data") 
		return
	end
	
	LOG_DEBUG("BasePlayer:updatePlayerInfo call")
	if not self.user_dc then
		self.user_dc = snax.uniqueservice("userdc")
	end
	if not self.useTmpMoney then
		local money = self.user_dc.req.getvalue(self:getUid(), "CoinAmount")
		if nil ~= money then
			self:setMoney(money)
		end
	else
		
	end
end

-- 更新玩家钱数， 传入的参数分别是变更的钱数 和 结算说明
function BasePlayer:updateMoney(_siMoney, _strJieSuan)
	if type(1) ~= type(_siMoney) or type("hello") ~= type(_strJieSuan) then
		LOG_ERROR("BasePlayer:updateMoney invalid args.")
		return 
	end
	LOG_DEBUG("BasePlayer:updateMoney")
	local siTemp = _siMoney
	local siPreMoney = self:getMoney()
	if _siMoney < 0 and
		_siMoney + siPreMoney < 0 then
		self:setMoney(0)
		siTemp = 0 - siPreMoney
	else
		self:setMoney(siPreMoney + _siMoney)
	end
	skynet.call(self.agent, "lua", "updateMoney",
				siTemp,
				siTemp,
				_strJieSuan,
				_strJieSuan)
end

-- 接受 参数 _strKey 整型 值是 1         2         3; _siNum  整型
---                        WinCount LostCount DrawCount 
function BasePlayer:updateWinLostDraw(_siKey, _siNum)
	if type(1) ~= type(_siKey) or type(_siNum) ~= type(1) then
		LOG_ERROR("BasePlayer:updateWinLostDraw invalid args.")		
		return 
	end

	if nil == self.user_dc then
		self.user_dc = snax.uniqueservice("userdc")
	end
	local tbScoreStr ={WIN_STR_COUNT, LOSE_STR_COUNT, DRAW_STR_COUNT}
	if _siKey >= WIN_SI_COUNT and _siKey <= DRAW_SI_COUNT then
		self.user_dc.req.updateWinInfo({uid = self.uid, key = tbScoreStr[_siKey], value = _siNum})
	else
		LOG_ERROR("BasePlayer:updateWinLostDraw _siKey error")
	end
end

function BasePlayer:getPlayerInfo()
	-- LOG_DEBUG("BasePlayer:getPlayerInfo")
	if nil == self.user_dc then
		self.user_dc = snax.uniqueservice("userdc")
	end

	local pkg = {}
	if self.uid == 0 then
		return pkg
	end
	pkg.uid = self.uid
	pkg.nickname = self.user_dc.req.getvalue(self.uid, "NickName")
	pkg.sex = self.user_dc.req.getvalue(self.uid, "Sex")
	pkg.money = self.user_dc.req.getvalue(self.uid, "CoinAmount")
	pkg.sngScore = self:getSngScore()
	pkg.face = 0
	pkg.wincount = self.user_dc.req.getvalue(self.uid, "WinCount")
	pkg.losecount = self.user_dc.req.getvalue(self.uid, "LoseCount")
	pkg.drawcount = self.user_dc.req.getvalue(self.uid, "DrawCount")
	pkg.pic_url = self.user_dc.req.getvalue(self.uid, "SmallLogoUrl")
	pkg.user_ipaddr = self.ipaddr
	pkg.Pos = self:getDeskPos()
	pkg.isWatcher = self.isWatcher
	return pkg
end

return BasePlayer