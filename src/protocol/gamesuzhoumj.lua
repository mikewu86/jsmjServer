-- 游戏自定义消息（5xx-6xx)
local gamemajiang = {}

gamemajiang.types = [[
#data types
.detailsElem {
    pos  0 : integer
    describe  1 : string
    caption 2 : string
}

.pengGang {
    pengType 0 : integer
    from 1 : integer
    card 2 : integer
}

.tipCardData {
    op 0 : integer
    cards 1: *integer 
}

.tingInfo {
    huCard 0 : integer
    fan 1 : integer
    left 2 : integer
}

.tingCardNode {
    playCard 0 : integer
    huInfo 1 : *tingInfo
}

.posMoney {
    pos 0 : integer
    money 1 : integer
}

.pengGangWH {
    pengType 0 : integer
    from 1 : integer
    cards 2 : *integer
}

.knockOutItem {
    uid 0 : integer
    knockout 1 : integer
}

.rankItem {
    score 0 : integer
    name 1 : string
    uid 2 : integer
}
.statisticsData {
    ziMo 0 : integer
    jiePao 1 : integer
    fangPao 2 : integer
    anGang 3 : integer
    mingGang 4 : integer
}

]]

gamemajiang.c2s = [[
#玩家操作
onPlayerOperation 501 {
    request {
        OperationSeq 0 : integer #操作序号
        operation 1 : integer   # chu gang peng pass hu 
        card_bytes 2 : integer #加注数量
    }    
} 

# card is data
testMJCardTypeCS 502 {
    request {
        Cards 0 : *integer 
    }
}

#请求解散包房
requestVIPDisband 503 {
    request {
        isRequest 0 : integer      # 是请求还是同意
        willDisband 1 : integer
    }
}

]]

gamemajiang.s2c = [[
#给玩家发送通知   
playerClientNotify 601 {
    request {
        OperationSeq 0 : integer
        NotifyType 1 : integer
        Params 2 : *integer
    }
}

opHandCardNotify 602 {
    request {
        OperationSeq 0 : integer
        Pos 1 : integer
        Op 2 : integer
        Cards 3 : *integer
    }
}

FlowerCardCountNotify 603 {
    request {
        OperationSeq 0 : integer
        Pos 1 : integer
        Count 2 : integer
    }
}

playerOperationReq 605 {
    request {
        OperationSeq 0 : integer
        Pos 1 : integer
        Op 2 : integer
    }
}

gameResultNotify 607 {
    request {
        OperationSeq 0 : integer
        Caption 1 : integer
        hand_cards1 2 : *integer
        hand_cards2 3 : *integer
        hand_cards3 4 : *integer
        hand_cards4 5 : *integer
        timeValue 6 : integer
    }
}


opOnDeskOutCard 608 {
    request {
        OperationSeq 0 : integer #操作序号
        Op 1 : integer
        Pos 2 : integer 
        Card 3 : integer   
    }
}



addPengCards 610 {
    request {
        OperationSeq 0 : integer #操作序号
        SelfPos 1 : integer #curplayer pos  
        ChuPos 2 : integer  #chuPlayer pos
        Card 3 : integer       
    }
}

#fangpaoPos为0是自摸
gameResult 611 {
    request {
        OperationSeq 0 : integer #操作序号
        flags 1 : integer 
        times 2 : *integer # 保存结算倍数
        money 3 : *integer # 结算后每个玩家的钱数
        score 4 : *integer # 当前尚未使用
        details 5 : *detailsElem # 记录每个玩家hu类型的倍数
        table_titile 6 : string # 尚未使用
        last_out_card 7 : integer 
        winner_times 8 : integer # 尚未使用
        flee_user_name 9 : string # 尚未使用
        game_status_message 10 : string # 尚未使用
        hand_cards1 11 : *integer 
        hand_cards2 12 : *integer
        hand_cards3 13 : *integer 
        hand_cards4 14 : *integer
        isGangkai 15 : integer
        timeValue 16 : integer
    }
}
setOperationTipCardsNotify 612 {
    request {
        OperationSeq 0 : integer #操作序号
        Data 1 : *tipCardData
        tingNodes 2 : *tingCardNode
    }
}

addGangCards 614 {
	request {
	    OperationSeq 0 : integer #操作序号
        SelfPos 1 : integer #curplayer pos  
        ChuPos 2 : integer  #chuPlayer pos
        Card 3 : integer
        Coin 4 : integer
	}
}

#onUserCutBack message
notifyEachPlayerCards 615 {
    request {
        OperationSeq 0 : integer #操作序号
        Player1 1 : playerData
        Player2 2 : playerData
        Player3 3 : playerData
        Player4 4 : playerData
        handCards1 5 : *integer
        handCards2 6 : *integer
        handCards3 7 : *integer
        handCards4 8 : *integer
        outCards1 9 : *integer
        outCards2 10 : *integer
        outCards3 11 : *integer
        outCards4 12 : *integer
        pengGang1 13 : *pengGang
        pengGang2 14 : *pengGang
        pengGang3 15 : *pengGang
        pengGang4 16 : *pengGang
        flowerCardsCount1 17 : integer
        flowerCardsCount2 18 : integer
        flowerCardsCount3 19 : integer
        flowerCardsCount4 20 : integer
        zhuangPos 21 : integer
        gameStatus 22 : integer
        myPos 23 : integer
        roundTime 24 : integer
        grabTime 25 : integer
        isWatcher 26 : integer
        newCard 27 : integer  # 此玩家的新牌
    }
}

opBuHuaHandCardNotify 616 {
    request {
        OperationSeq 0 : integer
        Pos 1 : integer
        Op 2 : integer
        Cards 3 : *integer
    }
}

updatePlayerData 617 {
    request {
        Players 0 : *playerData
    }
}

wallDataCountNotify 618 {
    request {
        OperationSeq 0 : integer
        Num 1 : integer
    }
}

#Res 0 false 1 ok
testMJCardTypeSC 619 {
    request {
        Res 0 : integer
        Cards 1 : *integer
    }
}

fideGangMoney 620 {
    request {
        GangSelfPos 0 : integer 
        GangChuPos 1 : integer 
        Money 2 : integer
    }
}

fideOutCardMoney 621 {
    request {     
        Data 0 : *posMoney
    }
}

huaGangNumNotify 622 {
    request {
        Pos 0 : integer 
        OperationSeq 1 : integer 
        Num 2 : integer
        Money 3 : integer
    }
}

#onUserCutBack message
notifyEachPlayerCardsWH 626 {
    request {
        OperationSeq 0 : integer #操作序号
        Player1 1 : playerData
        Player2 2 : playerData
        Player3 3 : playerData
        Player4 4 : playerData
        handCards1 5 : *integer
        handCards2 6 : *integer
        handCards3 7 : *integer
        handCards4 8 : *integer
        outCards1 9 : *integer
        outCards2 10 : *integer
        outCards3 11 : *integer
        outCards4 12 : *integer
        pengGang1 13 : *pengGangWH
        pengGang2 14 : *pengGangWH
        pengGang3 15 : *pengGangWH
        pengGang4 16 : *pengGangWH
        flowerCardsCount1 17 : integer
        flowerCardsCount2 18 : integer
        flowerCardsCount3 19 : integer
        flowerCardsCount4 20 : integer
        zhuangPos 21 : integer
        gameStatus 22 : integer
        myPos 23 : integer
        roundTime 24 : integer
        grabTime 25 : integer
        isWatcher 26 : integer
    }
}

addchicards 627 {
    request {
        OperationSeq 0 : integer #操作序号
        SelfPos 1 : integer #curplayer pos  
        ChuPos 2 : integer  #chuPlayer pos
        Card 3 : *integer       
    }
}

ting 628 {
    request {
        OperationSeq 0 : integer #操作序号
        pos 1 : integer #curplayer pos  
        isPrevTing 2 : integer  # 1 ting else prevting
    }
}

tingPos 629 {
    request {
        OperationSeq 0 : integer #操作序号
        posList 1 : *integer #ting  pos
    }
}

#SNG的当前轮次
# final:0 is false 1 is true
sngRound 630 {
    request {
        curTurn 0 : integer
        curRound 1 : integer
        final 2 : integer
    }
}

#SNG是否淘汰
sngKnockOut 631 {
    request {
        knockout 0 : integer
    }
}

#SNG排行
sngRankList 632 {
    request {
        rankList 0 : *rankItem
    }
}

#SNG结束
sngOver 633 {
    request {
    }
}

#包房结束
vipOver 634 {
    request {
        Score 0 : *integer
		Data 1 : *statisticsData
        Owner 2 : integer
        timeValue 3 : integer
    }
}

#包房错误提示
vipErrorMsg 635 {
    request {
        Content 0 : string
        needExit 1 : integer
    }
}

#包房解散结果
vipDisbandResult 636 {
    request {
        result 0 : integer
        uid 1 : integer
        msg 2 : string
    }
}

#包房解散投票
vipDisbandVote 637 {
    request {
        userName 0 : string
        uid 1: integer
        willDisband 2 : integer
        isRequest 3 : integer
        pos 4 : integer
        totalTime 5 : integer
    }
}

#包房信息
# gameState
# 0:等待开始
# :正在游戏
# 2:游戏结束
# 3:房间已解散

vipRoomInfo 638 {
    request {
        owner 0 : integer
        totalRound 1 : integer
        curRound 2 : integer
        ruleDesc 3 : string
        roomId 4 : string
        baseScore 5 : integer
        gameState 6 : integer
        realRoomId 7 : integer
    }
}

# 包房的分数消息
vipTotalScore 639 {
    request {
        userScore 0 : *integer
    }
}

# 包房的投票状态
vipDisbandStatus 640 {
    request {
        owner 0 : integer
        leftTime 1 : integer
        agreedList 2 : *integer
    }
}

# 游戏开始的拿牌消息
dealHandCards 641 {
    request {
        myHandCards 0 : *integer
        followers 1 : *integer
        banker 2 : integer
    }
}

voteBeforeGameInfo 642 {
    request {
        OperationSeq 0 : integer
        hand_cards1 1 : *integer
        hand_cards2 2 : *integer
        hand_cards3 3 : *integer
        hand_cards4 4 : *integer
        Score 5 : *integer
		Data 6 : *statisticsData
        Owner 7 : integer
        timeValue 8 : integer
    }
}

checkHandData 644 {
    request {
        hand_cards 0 : *integer
    }
}

]]

return gamemajiang
