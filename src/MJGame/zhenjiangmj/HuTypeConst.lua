local HuTypeConst = {}

-- 胡牌类型枚举
HuTypeConst.kHuType = {
        kHu         = 1,
        kTianHu     = 2,
        kPaoDa      = 3, -- 跑搭，抓任何一张牌都可以胡牌
        kPaoDaTuoDa = 4, -- 跑搭脱搭，跑搭时再抓一张搭
        kQiangGang  = 5, -- 抢杠
}

-- 大胡类型
HuTypeConst.kDaHuTypeList = {
    
}
-- 胡牌类型描述
HuTypeConst.huTypeMap = {
    [HuTypeConst.kHuType.kHu]       = {name = '胡', fan = 1, descrip = '1子'},
    [HuTypeConst.kHuType.kPaoDa]     = {name = '跑搭', fan = 5, descrip = '5子'},
    [HuTypeConst.kHuType.kPaoDaTuoDa] = {name = '跑搭脱搭', fan = 10, descrip = '10子'},
}

return HuTypeConst