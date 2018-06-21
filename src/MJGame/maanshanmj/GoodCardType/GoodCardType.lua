---Author: zhangyl
---Date:   2016/11/24 11:16
--- 牌型中不放入对子，仅放入顺子、刻子、杠
--- 同时，有些麻将要求胡牌要求胡8只，需考虑花色问题
local GoodCardType = {}

--- 组合类型
GoodCardType.combinationType = {
	Junko = 1,   --- 日语
	Three = 2, 
	Four = 3,
}

--- 以下牌型仅为测试使用
GoodCardType.typeList = {
						 {bSameSuit = false, SameNum = 0, cardTypes = {GoodCardType.combinationType.Junko, 
							GoodCardType.combinationType.Three, GoodCardType.combinationType.Three, GoodCardType.combinationType.Four,}},
                        {bSameSuit = true, SameNum = 8, cardTypes = {GoodCardType.combinationType.Junko, 
                            GoodCardType.combinationType.Three, GoodCardType.combinationType.Three, GoodCardType.combinationType.Four,}},
                           {bSameSuit = false, SameNum = 0, cardTypes = {GoodCardType.combinationType.Junko, GoodCardType.combinationType.Junko, GoodCardType.combinationType.Junko,
                                                    GoodCardType.combinationType.Junko,GoodCardType.combinationType.Junko, GoodCardType.combinationType.Junko}},
                        {bSameSuit = false, SameNum = 0, cardTypes = {GoodCardType.combinationType.Three}}, 
                        {bSameSuit = false, SameNum = 0, cardTypes = {GoodCardType.combinationType.Four}},                       
}

return GoodCardType