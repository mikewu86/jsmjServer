local HuTypeConst = {}

-- 搭牌：2张一样的牌，如（2张8筒，等）
-- 刻牌：3张一样的牌，如（3张3条或者，等）
-- 顺牌：3张顺序相连的条，万，筒牌，如（3万4万5万，6条7条8条等）

-- 胡牌类型枚举
HuTypeConst.kHuType = {
        -- 可以直接结算嘴数类型
        kHu          = 1,
        kTianHu      = 2,
        kDiHu        = 3,
        kQingYiSe    = 4,
        kQiDui       = 5,
        kHQiDui      = 6,
        kCHQiDui     = 7,
        k4He         = 8,  -- 某种牌有四张且没有开杠，只要有四张的就算活（豪华七对也算活），+4嘴
        kMShuangPuZi = 9,  -- 两个一样的顺，如345万 345万，若胡牌是胡其中的一张算明双铺，+2嘴
        kAShuangPuZi = 10,  -- 若不是胡其中的牌则为 暗双铺+4嘴
        k3LianKan    = 11,  -- 同花色连在一起的3个坎 +100嘴
        kHaiDi       = 12,
        k4AnKe       = 13,  -- 4坎加一个搭牌，坎牌必须是自己摸的才算，点炮不算 +100嘴
        kQueMeng     = 14,
        k10Tong      = 15,  -- 同超过10张 +100嘴
        k2An2Shuang  = 16,  -- 有2个暗双铺子，双暗双铺子必须是两个暗双铺，自摸算，点炮不算。 +100嘴
        kKa          = 17,  -- 只胡一张牌的牌型所胡的牌称为卡。+1嘴 23胡4 78胡6也算卡

        -- 不能直接结算嘴数的类型
        kTong        = 18,   -- 所有牌中数字一样的牌从 4 张起数， 每多一张多+1嘴
        kZhi         = 19,   -- 某一门有 8 张是胡牌的的基本要求，如有 9 张则加 1 支， 10 张加 2 支，以此类推，多支多分 ( 一支+1嘴)
        kKan         = 20,  -- 三张一样的牌在手，且符合基本胡牌牌型中的刻 ，即三张牌未分开叫做一坎，每一坎+1嘴
        kGangKai     = 21,  -- 由开杠后，补上来的牌构成和牌。总嘴数*2
        kLianZhuang  = 22,  -- 连庄：庄家自摸多加连庄数*4嘴，胡牌多加连庄数*2嘴，闲家自摸庄家多付连庄数*4嘴，庄家放冲庄家多付2*连庄数，连庄基数为1
}

-- 大胡类型
HuTypeConst.kDaHuTypeList = {
    HuTypeConst.kHuType.kTianHu,
    HuTypeConst.kHuType.kDiHu,
    HuTypeConst.kHuType.kQingYiSe,
    HuTypeConst.kHuType.kGangKai,
    HuTypeConst.kHuType.kQiDui,
    HuTypeConst.kHuType.kHQiDui,
    HuTypeConst.kHuType.kCHQiDui,
    HuTypeConst.kHuType.kHaiDi,
    HuTypeConst.kHuType.k4AnKe,
    HuTypeConst.kHuType.k3LianKan,
    HuTypeConst.kHuType.k10Tong,
    HuTypeConst.kHuType.k2An2Shuang,
}
-- 胡牌类型描述
HuTypeConst.huTypeMap = {
    [HuTypeConst.kHuType.kHu]          = {name = '胡', fan = 15, descrip = '15嘴'},
    [HuTypeConst.kHuType.kTianHu]      = {name = '天胡', fan = 200, descrip = '200嘴'},
    [HuTypeConst.kHuType.kDiHu]        = {name = '地胡', fan = 150, descrip = '150嘴'},
    [HuTypeConst.kHuType.kQingYiSe]    = {name = '清一色', fan = 100, descrip = '100嘴'},
    [HuTypeConst.kHuType.kQiDui]       = {name = '七对', fan = 10, descrip = '10嘴'},
    [HuTypeConst.kHuType.kHQiDui]      = {name = '豪华七对', fan = 50, descrip = '50嘴'},
    [HuTypeConst.kHuType.kCHQiDui]     = {name = '超豪华七对', fan = 100, descrip = '100嘴'},
    [HuTypeConst.kHuType.k4He]         = {name = '四核', fan = 4, descrip = '4嘴'},
    [HuTypeConst.kHuType.kMShuangPuZi] = {name = '双铺子', fan = 2, descrip = '2嘴'},
    [HuTypeConst.kHuType.kAShuangPuZi] = {name = '暗双铺子', fan = 4, descrip = '4嘴'},
    [HuTypeConst.kHuType.k3LianKan]    = {name = '3连坎', fan = 100, descrip = '100嘴'},
    [HuTypeConst.kHuType.kHaiDi]       = {name = '海底捞月', fan = 15, descrip = '15嘴'},
    [HuTypeConst.kHuType.k4AnKe]       = {name = '4暗刻', fan = 100, descrip = '100嘴'},
    [HuTypeConst.kHuType.kQueMeng]     = {name = '缺门', fan = 2, descrip = '2嘴'},
    [HuTypeConst.kHuType.k10Tong]      = {name = '10同', fan = 100, descrip = '100嘴'},
    [HuTypeConst.kHuType.k2An2Shuang]  = {name = '双暗双铺子', fan = 100, descrip = '100嘴'},
    [HuTypeConst.kHuType.kKa]          = {name = '卡', fan = 1, descrip = '1嘴'},
}

return HuTypeConst