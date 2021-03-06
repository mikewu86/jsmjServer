-- 游戏自定义消息（5xx-6xx)
local gametexas = {}

gametexas.types = [[
.handcards {
        Pos 0 : integer
        Cards 1 : *integer
}

.posData {
        Pos 0 : integer
        data 1 : integer
        
}

.posInfo {
        Pos 0 : integer         #位置
        Chips 1 : integer       #身上筹码
        Bets 2 : integer        #已下注
        IsFold 3 : boolean      #是否已盖牌
        IsAllIn 4 : boolean     #是否ALLIN
}

.bestCard {
        type 0 : integer
        Cards 1 : *integer
}
.resltDetail {
        ChipsDelta 0 : integer    #赢或输的总金额
        Pos 1 : integer           #座位号
        Uid 2 : integer           #用户id
        CardGroupType 3 : integer #牌型
}

.potResult {
        WinnerPos 0 : *integer    #赢家的座位号数组
        WinChips 1 : integer     #赢家赢取的筹码数量
}

.quickBetBtn {
        BtnId 0 : integer  # 1:3x大盲注  2:4x大盲注 3:1倍底池  4:1/2底池  5:2/3底池
        Enabled 1 : boolean #是否可用
        ChipsAmount 2 : integer #对应筹码数量
}

]]

gametexas.c2s = [[
#玩家操作    
playerOperationRes 501 {
	request {
                Operation 0 : integer
                OperationSeq 1 : integer #操作序号
                RaiseAmount 2 : integer #加注数量
        }
}
#补充筹码
exchangeChipsReq 502 {
        request {
                amount 0 : integer   #需要补充的最大金额
        }
}
]]

gametexas.s2c = [[
#给玩家发牌    
addHandCardNotify 601 {
        request {
		Pos 0 : integer
                Cards 1 : *integer
                GroupType 2 : integer    #自己当前牌型  给自己发的时候有值 非自己为0
        }
}
#请求玩家操作
playerOperationReq 602 {
        request {
              Pos 0 : integer
              Operation 1 : *integer #可操作类型
              OperationSeq 2 : integer #操作序号
              MinRaiseAmount 3 : integer #如果有加注操作此参数为最小加注金额
              MaxRaiseAmount 4 : integer #最大下注筹码数量
              CallAmount 5 : integer #如果有跟注操作的话此参数为跟注筹码数量
              QuickBetBtn 6 : *quickBetBtn  #快捷加注按钮
              Timeout 7 : integer  #超时秒数，用于客户端下定时器
        }
}
#玩家操作结果通知
playerOperationNotify 603 {
        request {
              Pos 0 : integer
              Operation 1 : integer
              BetAmount 2 : integer
              TotalPotAmount 3 : integer      #累计底池金额
              IsAllIn 4 : boolean             #当前操作是否allin
        }
}
#发桌面牌
addDeskCardNotify 604 {
        request {
                Cards 0 : *integer
                GroupType 1 : integer    #自己当前牌型  给自己发的时候有值 非自己为0
        }
}

#用户手中筹码同步
playerChipsCountNotify 605 {
        request {
                Counts 0 : *posData  #当前所有玩家的筹码
        }
}
#用户下注金额同步
playerBetCountNotify 606 {
        request {
                Counts 0 : *posData  #当前所有玩家的下注
        }
}
#结算的时候发送手中牌
setHandCardNotify 607 {
        request {
                HandCards 0 : *handcards
        }
}
#结算消息
roundResultNotify 608 {
        request {
                BestCardsPos 0 : integer
                BestCards 1 : *integer
                Details 2 : *resltDetail
                PotDetails 3 : *potResult
        }
}
#游戏基本信息，开局的时候下发，包含大小盲注金额，庄家位置等
gameinfoNotify 609 {
        request {
                DealerPos 0 : integer   #本局庄家的座位号
                SBPos 1 : integer #小盲注位置
                BBPos 2 : integer #大盲注位置
                SBChips 3 : integer #小盲注筹码
                BBChips 4 : integer #大盲注筹码
                
        }
}

#每轮彩池的信息
roundPotinfoNotify 610 {
        request {
                BetAmount 0 : *integer  #各彩池的信息，key为序号 最前面的为mainpot 后面为sidepot
        }
}

#场景初始化数据，可用于掉线重入以及旁观
gameSceneDataRes 611 {
        request {
                DealerPos 0 : integer #本局庄家的座位号
                SBPos 1 : integer #小盲注位置
                BBPos 2 : integer #大盲注位置
                SBChips 3 : integer #小盲注筹码
                BBChips 4 : integer #大盲注筹码
                Pos 5 : integer    #掉线者（自己）的座位号
                HandCards 6 : *integer   #手中牌，只有为自己的时候才有值
                DeskCards 7 : *integer   #桌面牌
                GroupType 8 : integer    #自己当前牌型  给自己发的时候有值 非自己为0
                BetAmount 9 : *integer  #各彩池的信息，key为序号 最前面的为mainpot 后面为sidepot
                PosInfo 10 : *posInfo  #当前所有玩家的信息，不包含开始后进入的
                OperationPos 11 : integer  #当前操作者的座位号
                Operation 12 : *integer #可操作类型
                OperationSeq 13 : integer #操作序号
                MinRaiseAmount 14 : integer #如果有加注操作此参数为最小加注金额
                MaxRaiseAmount 15 : integer #最大下注筹码数量
                CallAmount 16 : integer #如果有跟注操作的话此参数为跟注筹码数量
                QuickBetBtn 17 : *quickBetBtn  #快捷加注按钮
                Timeout 18 : integer  #超时秒数，用于客户端下定时器
        }
}

#兑换筹码后的通知
exchangeChipsRes 612 {
        request {
                chipsAmount 0 : integer #兑换的筹码数量
                moneyAmount 1 : integer #剩余金币的数量
        }
}

#盲注升级提醒  用于sng以及mtt比赛
blindUpgradeNotify 613 {
        request {
                SBBets 0 : integer #小盲注筹码
                BBBets 1 : integer #大盲注筹码
        }
}

]]

return gametexas