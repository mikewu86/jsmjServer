-- 游戏基础消息 (3xx-4xx)
local gamecommon = {}

gamecommon.types = [[
.playerData {
        uid 0 : integer
        nickname 1 : string
        sex 2 : integer
        money 3 : integer
        face 4 : integer
        wincount 5 : integer
        losecount 6 : integer
        drawcount 7 : integer
        Pos 8 : integer
	sngScore 9 : integer
        pic_url 10 : string
        user_ipaddr 11 : string
        isWatcher 12 : integer
}
]]

gamecommon.c2s = [[

entergameReq 301 {
        request {
                groupid 0 : integer
        }
}

userreadyReq 302 {
        request {

        }
}

changeRoomReq 303 {
        request {
                
        }
}
#玩家请求站起
userStandupReq 304 {
        request {
                isstandup 0 : integer   #1:站起  0:坐下
        }
}
#玩家聊天请求
gamechatReq 305 {
        request {
                chattype 0 : integer   #聊天类型   0:表情   1:快捷语   2:语音   3:特效（暂未开放）   4:全服小喇叭（对所有房间广播，暂未开放)
                content 1: string    #聊天内容 比如 表情id 快捷语id  语音id 文字聊天的内容等
                touid 2: integer  #聊天接收人，一般为空，用于发特效
        }
}
#玩家离开房间请求

# 进入SNG游戏请求
enterSNGGameReq 306 {
        request {
                groupid 0 : integer
        }
}

# 进入开房模式的房间
enterFangGameReq 307 {
        request {
                groupid 0 : integer
                roompassword 1 : string  #房间密码
                roomid 2 : integer  # 掉线回来时明确自己的房间号
        }
}

# 选择座位
selectSeatReq  308 {
        request {
                seatID 0 : integer
        }
}

# 退出房间
quitRoomReq  309 {
        request {

        }
}

]] 


gamecommon.s2c = [[
    
entergameNotify 401 {
        request {
                ret 0 : boolean
                msg 1 : string
        }
}

enterroomRes 402 {
        request {
                ret 0 : boolean
                roomid 1 : integer
                players 2 : *playerData
                maxplayer 3 : integer   #桌子上最大游戏人数
                unitcoin 4 : integer  #桌子的基础分  德州一般为大盲注的金额
                readyplayers 5 : *integer # 已准备的玩家
        }
}

enterroomNotify 403 {
        request {
                uid 0 : integer
                status 1 : integer   # 参见 Enums.PlayerState
                pos 2 : integer   #用户的座位号
                data 3 : *playerData
        }
}

userreadyNotify 404 {
        request {
                uid 0 : integer
                pos 1 : integer
        }        
}

roomstatuNotify 405 {
        request {
                roomid 0 : integer
                status 1 : integer
        }
}

entergameRes 406 {
        request {
              roomid 0 : integer
        }
}

leaveroomNotify 407 {
        request {
              uid 0 : integer
        }
}
#玩家请求站起结果
userStandupRes 408 {
        request {
                ret 0 : boolean
                isstandup 1 : boolean   #请求的值 true:站起  false:坐下
                errormsg 2 : string  #如果ret=false 这里是出错原因
                pos 3 : integer         #如果是坐下操作，坐下成功后此处为座位号
        }
}
#玩家请求站起通知
userStandupNotify 409 {
        request {
                uid 0 : integer
                isstandup 1 : boolean   #true:站起  false:坐下
        }
}
#聊天广播
gamechatNotify 410 {
        request {
                chattype 0 : integer   #聊天类型   0:表情   1:快捷语   2:语音   3:特效（暂未开放）   4:全服小喇叭（对所有房间广播，暂未开放)
                content 1: string    #聊天内容 比如 表情id 快捷语id  语音id 文字聊天的内容等
                fromuid 2: integer    #聊天发起人
                touid 3: integer    #聊天接收人，一般为空，用于发特效
        }
}
#用户钱不够了的通知
moneyNotEnoughNotify 411 {
        request {
                moneyCurrency 0 : integer #货币单位  1为金币   2为银子
                showShop 1 : boolean  #是否显示商城
        }
}

#游戏开始通知
gameBeginNotify 412{
        request {
                content 0 : string
        }
}

#游戏开始通知
gameEndNotify 413{
        request {
                content 0 : string
        }
}


#notify player enter game loading
notifyGameLoadingBegin 414 {
    request {
    }
}

notifyGameLoading 415 {
    request {
        waitPlayerNum 0 : integer
        needPlayerNum 1 : integer
    }
}

notifyGameLoadingEnd 416 {
    request {
    }
}

notifyTip 417 {
    request {
        errorCode 1 : integer
        errorStr 0 : string
        suggestAcion 2 : integer
    }
}

notifyUserCut 418 {
    request {
        cutUserList 0 : *integer
    }
}

canSeatNotify 420 {
    request {
        canSeatPos 0 : *integer
    }
}

notifyCheat 421 {
    request {
        tip 0 : string
    }
}

]]

return gamecommon