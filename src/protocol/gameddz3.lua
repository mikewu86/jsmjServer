-- 游戏自定义消息（5xx-6xx)
local gameddz3 = {}

gameddz3.types = [[
.RemainHandCardsElem {
    Pos 0 : integer
    Cards 1 : *integer
}
]]

gameddz3.c2s = [[
#玩家操作    
handleOnPlayerOperation 501 {
    request {
        Operation 0 : integer   # callpoint landlord addscord outcard pass 
        OperationSeq 1 : integer #操作序号
        Param 2 : integer   # point   
        Cards 3 : *integer #加注数量
    }
}
    
]]

gameddz3.s2c = [[
#给玩家发牌    
addHandCardNotifyReq 601 {
        request {
			OperationSeq 0 : integer #操作序号
			Pos 1 : integer
		    Cards 2 : *integer
        }
}
baseCardNotify 602 {
        request {
            OperationSeq 0 : integer #操作序号	
            Cards 1 :  *integer
        }
}



playerCallPointReq 603 {
        request {
	        OperationSeq 0 : integer
            Pos 1 : integer
        }
}

playerGrabLandLordReq 604 {
        request {
            OperationSeq 0 : integer
            Pos 1 : integer
        }
}

playerDoubleScoreReq 605 {
        request {
            OperationSeq 0 : integer
            Pos 1 : integer
        }
}

playerPlayCardReq 606 {  #call point end , start play card
        request {
	        OperationSeq 0 : integer
            Pos 1 : integer
            Op 2 : integer
        }
}

playerOutCardsRes_All 607 {
        request {
	        OperationSeq 0 : integer #操作序号	
            Operation 1 : integer 
            Pos 2 : integer
            Cards 3 : *integer
        }
}

playerPassCardRes_All 608 {
        request {
            Operation 0 : integer 
            Pos 1 : integer
	        OperationSeq 2 : integer #操作序号
        }
}

gameResult_All 609 {
        request {
            OperationSeq 0 : integer
            times 1 : *integer # 保存结算倍数
            money 2 : *integer # 每个玩家的加减钱
            RemainHandCards 3 : *RemainHandCardsElem # 每个玩家剩余牌
        }
}

playerClientNotify 610 {
        request {
            OperationSeq 0 : integer
            NotifyType 1 : integer
            Params 2 : *integer
    }
}

]]

return gameddz3