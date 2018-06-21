local skynet = require "skynet"
local snax = require "snax"
local RobotAI = require "RobotAI"
local MJUtils = require "MJCommon.MJUtils"
local MJOperations = MJUtils.MJOperations
local MJConst = require "mj_core.MJConst"

local CMD = {}
local REQUEST = {}

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

local robotAI = RobotAI.new(6)

local currentStep

local maxPlayCount = 1          --这个机器人最多玩多少局就会退出
local currentPlayCount = 0

local isWaittingLeave = false   --等待离开

local roomid = 0
local groupId = 0

math.randomseed(os.time()) 

local notifyTypes = {}
--  player notify type
notifyTypes.DICE_NUMBER    =  0
notifyTypes.ZHUANG         =  1
notifyTypes.PLAYER_CHU     =  2
notifyTypes.PLAYER_PENG    =  3
notifyTypes.PLAYER_GANG    =  4
notifyTypes.PLAYER_HU      =  5

local ops = MJOperations.new()

local opTypes = {}
opTypes.REMOVE = 0
opTypes.ADD = 1
opTypes.OPCARDS_MAX = 2
--- info
local flowerCount = 0

local pengCards = nil
local gangData = nil
local huCards = nil
function sendToServer(name, data)
    local str = "sendToServer"
    print(str)
    skynet.call(RACEMGR, "lua", "RequestGame", userid, name, data)
end

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
    print("robotagent enterGame call")
    --此时处理为异步执行
    skynet.timeout(1, function()
        skynet.call(RACEMGR, "lua", "enterGame", userid, skynet.self(), 0, groupId)
        if roomid then
            local ret = skynet.call(RACEMGR, "lua", "enterRoom", userid, nil, roomid, true)
            if ret.ret == true then
                myRoomPos = ret.pos
            end
        else
            print("can't find availiable room for robot")
        end
    end)
end

function CMD.sendThreeCard(source, cards)
    robotAI:addDeskCards(cards)
    robotAI:calcCardsRate()
    
    print("robot pre process finish")
end

function CMD.dispatch(source, name, data)
    local f = assert(REQUEST[name], "game pkg: "..name.." not found")
    pcall(f, data)
end

function CMD.init(source, _roomid, _uid, _maxPlay, _groupId)
    roomid = _roomid
    userid = _uid
    maxPlay = _maxPlay
    groupId = _groupId
    print("init robot agent for uid:".._uid)
end

function CMD.changePlayingStatus()

end

function CMD.isRobot()
    return true
end

--房间状态改变
function REQUEST.roomstatuNotify(data)
    print("REQUEST.roomstatuNotify robot reset, room status: "..data.status)
    
    --myRoomPos = 0
    --myChips = 0
    --结束了
    if data.status == Enums.RoomState.WAIT then
        if currentPlayCount > maxPlayCount then
            print("robot max play, must leave")
            skynet.call(ROBOTMGR, "lua", "resetRobot", userid)
            return
        end
        
        --等待10秒，如果游戏还没有开始就退出
        isWaittingLeave = true
        skynet.timeout(100 * 10, function()
            if isWaittingLeave == true then
                print("robot idle timeout, must leave")
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

function REQUEST.enterroomNotify(data)
end

function REQUEST.leaveroomNotify(data)

end


function REQUEST.userStandupNotify(data)

end

function REQUEST.userStandupRes(data)

end

function REQUEST.playerClientNotify(data)
    local debugStr = "playerClientNotify "
    if data.NotifyType == notifyTypes.DICE_NUMBER then
      debugStr = debugStr.."骰子值:"..data.Params.."\n"
    elseif data.NotifyType == notifyTypes.ZHUANG then
      debugStr = debugStr.."庄家位置:"..data.Params.."\n"
    end
    print(debugStr)
end

function REQUEST.FlowerCardCountNotify(data)
    if myRoomPos == data.Pos then
        local str = "RobotAI:"..myRoomPos.." flowerCounts change from "..flowerCount.." to "..data.Count
        print(str)
        flowerCount = data.Count
    end
end

function REQUEST.opHandCardNotify(data)
    if myRoomPos == data.Pos then
        for _, v in pairs(data.Cards) do 
            if opTypes.REMOVE == data.Op then
                robotAI:removeHandCards(v)
            else
                robotAI:addHandCards(v)
            end
        end
    end
end

function REQUEST.opBuHuaHandCardNotify(data)
    if myRoomPos == data.Pos then
        for _, v in pairs(data.Cards) do 
            if opTypes.REMOVE == data.Op then
                robotAI:removeHandCards(v)
            else
                robotAI:addHandCards(v)
            end
        end
    end
end
 

function REQUEST.gameResultNotify(data)

end

function REQUEST.opOnDeskOutCard(data)
    if myRoomPos == data.Pos then 
        if opTypes.REMOVE == data.Op then
            robotAI:removeDeskCards(data.Card)
        else
            robotAI:addDeskCards(data.Card)
        end  
            --- print player cards---
        local deskCards = robotAI:getDeskCards()
        local debugStr = "pos: "..myRoomPos.."outcards: "
        for index,v in pairs(deskCards) do 
            debugStr = debugStr..index..","..MJUtils.FormatDataToString(v).." "
        end
        print(debugStr)    
    end

end
function REQUEST.addPengCards(data)
    if myRoomPos == data.SelfPos then
        robotAI:addPengCards(data.Card)
    elseif myRoomPos == data.ChuPos then
        robotAI:removeDeskCards(data.Card)
    end
end
function REQUEST.gameResult(data)

end
function REQUEST.setOperationTipCardsNotify(data)
    local opData = table.copy(data.Data)
    resetTipData()
    dump(opData, "opData")
    for _, v in pairs(opData) do  
        LOG_DEBUG("op:"..v.op)
        dump(v.cards, "cards.")
        if MJConst.kOperPeng == v.op then
            if nil == pengCards then
                pengCards = {}
            end
            LOG_DEBUG("set peng cards...")
            for _, cardbyte in pairs(v.cards) do 
                table.insert(pengCards, cardbyte)
            end
            dump(pengCards, "pengcards")
        elseif true == isGangOp(v.op) then
            if nil == gangData then
                gangData = {}
            end
            for _, cardByte in pairs(v.cards) do 
                table.insert(gangData,{card = cardByte, op = v.op})
            end
            dump(gangData, "gangData set Tip.")
        elseif MJConst.kOperHu  == v.op then
            if nil == huCards then
                huCards = {}
            end 
            for _, cardbyte in pairs(v.cards) do 
                table.insert(huCards, cardbyte)
            end
            dump(huCards, "huCards set tip.")
        elseif MJConst.kOperPlay == v.op then
        else
            LOG_DEBUG("unkown op:"..v.op)
        end
    end
end
function REQUEST.addGangCards(data)

end
function REQUEST.notifyEachPlayerCards(data)

end




function REQUEST.playerOperationReq(data)
    local opSeq = data.OPerationSeq
    local onPlayerOperation = {}
    onPlayerOperation.OperationSeq = opSeq

    if myRoomPos == data.Pos then
        robotAI:resetOperations()
        robotAI:setOperations(data.Op)
        LOG_DEBUG("RobotAI:Op number is ".. data.Op .. ",my pos is ".. myRoomPos)
        local ops = robotAI:getOperations()
        LOG_DEBUG("RobotAI:I can do "..ops)
        if true == robotAI:checkOperation(MJConst.kOperHu) then
            if nil == huCards then
                LOG_DEBUG("no set hu tip cards.")
                return 
            end
            LOG_DEBUG("RobotAI:I can hu poS:"..myRoomPos)
            onPlayerOperation.operation = MJConst.kOperHu
            dump(huCards, "ROBOT HU CARDS")
            onPlayerOperation.card_bytes = huCards[1]
            sendToServer("onPlayerOperation", onPlayerOperation)

        elseif true == robotAI:checkOperation(MJConst.kOperPeng) then
    	    if nil == pengCards then
                LOG_DEBUG("not setpengtipcards")
    	    	return
    	    end   
            LOG_DEBUG("RobotAI:I can peng")
            onPlayerOperation.operation = MJConst.kOperPeng
            onPlayerOperation.card_bytes = pengCards[1]
            sendToServer("onPlayerOperation", onPlayerOperation)
        elseif true == robotAI:hasGangOps() then
            if nil == gangData then
                LOG_DEBUG("not settipcards")
                return
            end
            LOG_DEBUG("RobotAI:I can gang pos:"..myRoomPos)
            onPlayerOperation.operation = gangData[1].op
            onPlayerOperation.card_bytes = gangData[1].card
            dump(gangData, "gangData op gang.")
            sendToServer("onPlayerOperation", onPlayerOperation)
        elseif true == robotAI:checkOperation(MJConst.kOperPlay) then
            LOG_DEBUG("robot play card.")
            onPlayerOperation.operation = MJConst.kOperPlay
            sendToServer("onPlayerOperation", onPlayerOperation)
        elseif true == robotAI:checkOperation(MJConst.kOperCancel) then
            LOG_DEBUG("robot cancel op.")
            onPlayerOperation.operation = MJConst.kOperCancel
            sendToServer("onPlayerOperation", onPlayerOperation)
        else
            LOG_WARNING("RobotAI:invalid op")
            return 
        end
        resetTipData()
    else
        LOG_DEBUG("RobotAI:It's not my turn ".."destPos:"..data.Pos.." myPos:"..myRoomPos)
    end
end

function REQUEST.userreadyNotify(data)

end

function REQUEST.updatePlayerData(data)

end
function REQUEST.wallDataCountNotify(data)
end


function REQUEST.testMJCardTypeSC(data)
end

function REQUEST.fideGangMoney(data)
end

function REQUEST.moneyNotEnoughNotify(data)
end

function REQUEST.huaGangNumNotify(data)
end

function REQUEST.fideOutCardMoney(data)
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


function isGangOp(_op)
    local bRet = false
    if type(1) ~= type(_op) then
        return bRet
    end

    if MJConst.kOperMG == _op or 
        MJConst.kOperAG == _op or 
        MJConst.kOperMXG == _op then
        bRet = true
    end
    return bRet
end

function resetTipData()
    huCards = nil
    pengCards = nil
    gangData = nil
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