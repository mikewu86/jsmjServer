local skynet = require "skynet"
local snax = require "snax"
local CardConstant = require "CardConstant"
local RobotAI = require "RobotAI"

local CMD = {}
local REQUEST = {}
local roomid = 0
local groupid = 0

function REQUEST:addHandCardNotify()
    print("robot receive addHandCardNotify")
end

local RACEMGR
local raceMgrName

local ROBOTMGR

local ipaddr = "8.8.8.8"
local isPlaying = false

local userid = 2924
local myRoomPos = 0
local myChips = 0
local maxPlay = 1
local bbBet = 0             --大盲注注额

local robotAI = RobotAI.new(6)

local currentStep

local maxPlayCount = 1          --这个机器人最多玩多少局就会退出
local currentPlayCount = 0

local isWaittingLeave = false   --等待离开

function CMD.updateMoney(source, wantedamount, modifyamount, ModuleName, Remark)

	if not user_dc then
		user_dc = snax.uniqueservice("userdc")
	end
	local record = {}
	record.userid = userid
	record.wantedamount = wantedamount
	record.modifyamount = modifyamount
	record.ModuleName = ModuleName
	record.Remark = Remark
	record.ipaddr = ipaddr
	return user_dc.req.updateMoney(record)
end

function CMD.updateChips(chipsAmount, Remark)
    local doc = skynet.call("dbmgr", "lua", "update_gameuser_chips",
        userid,
        chipsAmount,
        tonumber(skynet.getenv "gameid" or 0),
		tonumber(skynet.getenv "nodeid" or 0),
        Remark,
        ipaddr)
end

function CMD.changePlayingStatus(source, userIsPlaying, groupid, roomid)
	isPlaying = userIsPlaying

end


function CMD.enterGame(source)
    LOG_DEBUG("robotagent enterGame call")
    --此时处理为异步执行
    skynet.timeout(1, function()
        skynet.call(RACEMGR, "lua", "enterGame", userid, skynet.self(), 0, groupid)
        local ret = skynet.call(RACEMGR, "lua", "enterRoom", userid, nil, roomid, true)
        dump(ret)
        if ret.ret == true then
            myRoomPos = ret.pos
        end
    end)
end

function CMD.sendThreeCard(source, cards)
    robotAI:addDeskCards(cards)
    robotAI:calcCardsRate()
    
    LOG_DEBUG("robot pre process finish")
end

function CMD.dispatch(source, name, data)
    local f = assert(REQUEST[name], "game pkg: "..name.." not found")
    pcall(f, data)
end

function CMD.init(source, _roomid, _uid, _maxPlay, _groupid)
    roomid = _roomid
    userid = _uid
    maxPlay = _maxPlay
    groupid = _groupid
    LOG_DEBUG("init robot agent for uid:".._uid)
end

--房间状态改变
function REQUEST.roomstatuNotify(data)
    LOG_DEBUG("REQUEST.roomstatuNotify robot reset, room status:%d", data.status)
    
    --myRoomPos = 0
    --myChips = 0
    --结束了
    if data.status == Enums.RoomState.WAIT then
        if currentPlayCount > maxPlayCount then
            LOG_DEBUG("robot max play, must leave")
            skynet.call(ROBOTMGR, "lua", "resetRobot", userid)
            return
        else
            if bbBet > 0 then
                math.randomseed(os.time())
                local bbCounts = math.random(200, 400)
            
                if myChips > bbCounts * bbBet then
                    LOG_DEBUG("robot rich, must leave")
                    skynet.call(ROBOTMGR, "lua", "resetRobot", userid)
                    return
                end
            end
        end
        
        --等待10秒，如果游戏还没有开始就退出
        isWaittingLeave = true
        skynet.timeout(100 * 10, function()
            if isWaittingLeave == true then
                LOG_DEBUG("robot idle timeout, must leave")
                skynet.call(ROBOTMGR, "lua", "resetRobot", userid)
            end
        end)
    elseif data.status == Enums.RoomState.PLAYING then
        --游戏开始 初始化一下ai
        robotAI:reset()
        currentStep = 0
        bbBet = 0
        
        isWaittingLeave = false
        
        currentPlayCount = currentPlayCount + 1
    end
end

--游戏开始后的信息
function REQUEST.gameinfoNotify(data)
    bbBet = data.BBChips
end

function CMD.changePlayingStatus()

end

function REQUEST.leaveroomNotify()

end

function REQUEST.playerOperationNotify()

end

function REQUEST.userStandupNotify()

end

function REQUEST.userStandupRes()

end

function REQUEST.exchangeChipsRes(data)
    myChips = data.chipsAmount
end

--盲注升级
function REQUEST.blindUpgradeNotify()

end

function sendToServer(name, data)
    --等待3秒，后期变为动态等待时间
    skynet.timeout(100, function()
        skynet.call(RACEMGR, "lua", "RequestGame", userid, name, data)
    end)
end


function REQUEST.playerOperationReq(data)
    -- body
    LOG_DEBUG("robot:%d recv playerOperationReq for pos:%d myPos:%d  step:%d mychips:%d", userid, data.Pos, myRoomPos, currentStep, myChips)
    dump(data)
    
    --是请求自己
    if data.Pos == myRoomPos then
        LOG_DEBUG("it is my turn, robot:%d", userid)
        local currentOperationSeq = data.OperationSeq
        local minRaiseAmount = nil
        local action, minRaise, maxRaise = robotAI:getAction(currentStep)
        LOG_DEBUG("getAction is return:%d", action)
        local nMinRaise = tonumber(minRaise or 0)
        local nMaxRaise = tonumber(maxRaise or 0)
        LOG_DEBUG("robot:%d getAction, action:%d, minRaise:%f, maxRaise:%f", userid, action, nMinRaise, nMaxRaise)
        local myOperation
        if action ~= nil then
            if table.arrayContain(data.Operation, action) then
                --加注需要计算筹码
                if action == CardConstant.OPERATION_RAISE then
                    if nMinRaise > 0 and nMaxRaise > 0 then
                        
                        minRaiseAmount = nMinRaise * myChips
                        --最小下注必须大于请求的最小下注数量
                        if minRaiseAmount < data.MinRaiseAmount then
                            minRaiseAmount = data.MinRaiseAmount
                        else
                            --取大于minRaiseAmount的bbBet的整数倍
                            if minRaiseAmount % bbBet ~= 0 then
                                minRaiseAmount = (getIntPart(minRaiseAmount / bbBet) + 1) * bbBet
                            end
                        end
                        
                        local maxRaiseAmount = nMaxRaise * myChips
                        if maxRaiseAmount < data.MinRaiseAmount then
                            maxRaiseAmount = data.MinRaiseAmount
                        else
                            if maxRaiseAmount % bbBet ~= 0 then
                                maxRaiseAmount = (getIntPart(maxRaiseAmount / bbBet) + 1) * bbBet
                            end
                        end
                        
                        
                        if maxRaiseAmount > myChips then
                            maxRaiseAmount = myChips
                        end
                        
                        minRaiseAmount = maxRaiseAmount
                        
                        LOG_DEBUG("minRaiseAmount:%d", minRaiseAmount)
                    else
                        if nMaxRaise > 0 then
                            minRaiseAmount = nMaxRaise * myChips
                            if minRaiseAmount < data.MinRaiseAmount then
                                minRaiseAmount = data.MinRaiseAmount
                            else
                                --取大于minRaiseAmount的bbBet的整数倍
                                if minRaiseAmount % bbBet ~= 0 then
                                    minRaiseAmount = (getIntPart(minRaiseAmount / bbBet) + 1) * bbBet
                                end
                            end
                        else
                            minRaiseAmount = nMinRaise * myChips
                            if minRaiseAmount < data.MinRaiseAmount then
                                minRaiseAmount = data.MinRaiseAmount
                            else
                                --取大于minRaiseAmount的bbBet的整数倍
                                if minRaiseAmount % bbBet ~= 0 then
                                    minRaiseAmount = (getIntPart(minRaiseAmount / bbBet) + 1) * bbBet
                                end
                            end
                        end
                        
                        
                            
                        
                        if minRaiseAmount > myChips then
                            minRaiseAmount = myChips
                        end
                        
                        --如果之前有跟注的话，需要判断跟注的金额+加注的金额是否大于剩余筹码
                        if table.arrayContain(data.Operation, CardConstant.OPERATION_CALL) then
                            if data.CallAmount > 0 then
                                if data.CallAmount + minRaiseAmount >= myChips then
                                    action = CardConstant.OPERATION_ALLIN
                                end
                            end
                        end
                        
                        LOG_DEBUG("minRaiseAmount:%d", minRaiseAmount)
                    end
                    
                    myOperation = action
                    
                    if minRaiseAmount == nil then
                        --没有匹配到结果
                        if table.arrayContain(data.Operation, CardConstant.OPERATION_CALL) then
                            myOperation = CardConstant.OPERATION_CALL
                        elseif table.arrayContain(data.Operation, CardConstant.OPERATION_CHECK) then
                            myOperation = CardConstant.OPERATION_CHECK
                        else
                            --不知道该怎么操作就弃牌吧
                            myOperation = CardConstant.OPERATION_FOLD
                        end
                    end
                --如果是盖牌的话看看能否过
                elseif action == CardConstant.OPERATION_FOLD then
                    if table.arrayContain(data.Operation, CardConstant.OPERATION_CHECK) then
                        myOperation = CardConstant.OPERATION_CHECK
                    else
                        myOperation = CardConstant.OPERATION_FOLD
                    end
                else
                    myOperation = action
                end
            else
                LOG_DEBUG("action:%d not in op list", action)
                dump(data.Operation)
                if action == CardConstant.OPERATION_CALL then
                    if table.arrayContain(data.Operation, CardConstant.OPERATION_CHECK) then
                        myOperation = CardConstant.OPERATION_CHECK
                    else
                        myOperation = CardConstant.OPERATION_FOLD
                    end
                end
                
                if action == CardConstant.OPERATION_RAISE then
                    if table.arrayContain(data.Operation, CardConstant.OPERATION_ALLIN) then
                        myOperation = CardConstant.OPERATION_ALLIN
                    end
                    
                    if table.arrayContain(data.Operation, CardConstant.OPERATION_CALL) then
                        myOperation = CardConstant.OPERATION_CALL
                    end
                end
                
                
                if not myOperation then
                    myOperation = CardConstant.OPERATION_FOLD
                end
            end
        else
            --没有匹配到结果
            if table.arrayContain(data.Operation, CardConstant.OPERATION_CALL) then
                myOperation = CardConstant.OPERATION_CALL
            elseif table.arrayContain(data.Operation, CardConstant.OPERATION_CHECK) then
                myOperation = CardConstant.OPERATION_CHECK
            else
                --不知道该怎么操作就弃牌吧
                myOperation = CardConstant.OPERATION_FOLD
            end
        end
        
        
        local playerOperationRes = {}
        playerOperationRes.Operation = myOperation
        playerOperationRes.OperationSeq = currentOperationSeq
        if minRaiseAmount then
            playerOperationRes.RaiseAmount = minRaiseAmount
        end
        
        sendToServer("playerOperationRes", playerOperationRes)
        
        dump(playerOperationRes)
    end
end

function REQUEST.userreadyNotify()

end

function REQUEST.playerChipsCountNotify(data)
    for _, value in pairs(data.Counts) do
        if value.Pos == myRoomPos then
            myChips = value.data
            break
        end
    end
end

function REQUEST.playerBetCountNotify()

end

--发手中牌
function REQUEST.addHandCardNotify(data)
    if data.Pos == myRoomPos then
        --传递给ai
        robotAI:addHandCards(data.Cards)
        currentStep = CardConstant.TURN_PREFLOP
    end
end

function REQUEST.roundPotinfoNotify()

end

function REQUEST.addDeskCardNotify(data)
    currentStep = currentStep + 1
    --robotAI:addDeskCards(data.Cards)
end

function REQUEST.setHandCardNotify()

end

--游戏结算消息
function REQUEST.roundResultNotify()
    
end

function REQUEST.enterroomNotify(data)
    if data.uid == userid then
        myRoomPos = data.pos
    end
end

function printXXX(...)
    if arg then
        local printResult = ""
        for i,v in ipairs(arg) do
            printResult = printResult .. tostring(v) .. "\t"
        end
        printResult = printResult .. "\n"
        print(printResult)
    end

end

skynet.start(function()
	-- If you want to fork a work thread , you MUST do it in CMD.login
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command], "CMD:  "..command.."  not found")
        local r = f(source, ...)
        skynet.ret(skynet.pack(r))
		
	end)
    
    math.randomseed(os.time())
    maxPlayCount = math.random(4, 20)           --机器人随机玩4-20局
    
    raceMgrName = skynet.getenv("racemgrname") or "gameracemgr"
    RACEMGR = skynet.uniqueservice(raceMgrName)
    
    ROBOTMGR = skynet.uniqueservice("RobotMgr")

end)