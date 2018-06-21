--
-- Author: Liuq
-- Date: 2016-04-20 14:17:35
--
Enums = {}

Enums.RoomState = {}
Enums.RoomState.IDLE = 1
Enums.RoomState.WAIT = 2
Enums.RoomState.PLAYING = 3

Enums.PlayerState = {}
Enums.PlayerState.IDLE = 1
Enums.PlayerState.SEAT = 2
Enums.PlayerState.WATCH = 3
Enums.PlayerState.READY = 4
Enums.PlayerState.PLAYING = 5
Enums.PlayerState.WATING = 6
Enums.PlayerState.SNGSIGNUP = 7
Enums.PlayerState.MTTSIGNUP = 8

Enums.GameBeginType = {}
Enums.GameBeginType.ALLREADY_EQUAL_MAXPLAYER = 1 			--房间人数等于最大人数并且所有人都准备好了
Enums.GameBeginType.ALLREADY_MORETHAN_MINPLAYER = 2			--房间人数大于最小人数并且所有人都准备好了


GAME_RESULT_TYPE_LOSE   = 0
GAME_RESULT_TYPE_WIN    = 1
GAME_RESULT_TYPE_DRAW   = 2
GAME_RESULT_TYPE_RACING = 5

SERVERPORT_LOGIN        = 8002
SERVERPORT_GATE         = 8003


RoomConstant = {}
RoomConstant.RoomType = {}
RoomConstant.RoomType.Common				= 1			--常规
RoomConstant.RoomType.VIP 					= 2			--VIP开房间
RoomConstant.RoomType.SNG					= 3			--德州SNG比赛房间
RoomConstant.RoomType.MTT					= 4			--德州MTT比赛房间

-- notifyTip gamecommon协议中使用
kAction = {
    null = 0,
    returnHall = 1, -- 返回大厅
    userDefine = 200,
}

kErrorCode = {
    allocSeatFail = 1,
    readyFail = 2,        -- 准备错误
    userDefine = 200,
}

-- 包房状态
kVipRoomState = {
    wait        = 0,   -- 等待开始    
    playing     = 1,   -- 正在游戏
    gameover    = 2,   -- 游戏结束
    disband     = 3,    -- 房间已解散
}