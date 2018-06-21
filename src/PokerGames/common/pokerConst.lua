--- poker const 
--- only for poker data
--- author: zhangyl
--- date:2016/12/29 11:12

local PokerConst = {}

-- poker color
PokerConst.kDiamond = 0
PokerConst.kClub    = 1
PokerConst.kHeart   = 2
PokerConst.kSpade   = 3
PokerConst.kJoker   = 4

-- poker color string
PokerConst.strColor = {
    [PokerConst.kDiamond]   = "方块",
    [PokerConst.kClub]      = "梅花",
    [PokerConst.kHeart]     = "红桃",
    [PokerConst.kSpade]     = "黑桃",
    [PokerConst.kJoker]     = "王",
}
-- poker point
PokerConst.kA     = 1
PokerConst.k2     = 2
PokerConst.k3     = 3
PokerConst.k4     = 4
PokerConst.k5     = 5
PokerConst.k6     = 6
PokerConst.k7     = 7
PokerConst.k8     = 8
PokerConst.k9     = 9
PokerConst.k10    = 10
PokerConst.kJ     = 11
PokerConst.kQ     = 12
PokerConst.kK     = 13
--- poker point string
PokerConst.strPoint = {
    [PokerConst.kA] = "A",
    [PokerConst.k1] = "1",
    [PokerConst.k2] = "2",
    [PokerConst.k3] = "3",
    [PokerConst.k4] = "4",
    [PokerConst.k5] = "5",
    [PokerConst.k6] = "6",
    [PokerConst.k7] = "7",
    [PokerConst.k8] = "8",
    [PokerConst.k9] = "9",
    [PokerConst.k10]= "10",
    [PokerConst.kJ] = "J",
    [PokerConst.kQ] = "Q",
    [PokerConst.kK] = "K",
}

PokerConst.cardType = {
    Single      = 1,
    Couple      = 2,
    Three       = 3,
    ThreeTwo    = 4,
    SisterCouple= 5,
    Junko       = 6,    
    Bump        = 7,
}

-- poker color weight
PokerConst.weight = PokerConst.kK

PokerConst.SA = PokerConst.kSpade * PokerConst.weight + PokerConst.kA
PokerConst.S2 = PokerConst.kSpade * PokerConst.weight + PokerConst.k2
PokerConst.S3 = PokerConst.kSpade * PokerConst.weight + PokerConst.k3
PokerConst.S4 = PokerConst.kSpade * PokerConst.weight + PokerConst.k4
PokerConst.S5 = PokerConst.kSpade * PokerConst.weight + PokerConst.k5
PokerConst.S6 = PokerConst.kSpade * PokerConst.weight + PokerConst.k6
PokerConst.S7 = PokerConst.kSpade * PokerConst.weight + PokerConst.k7
PokerConst.S8 = PokerConst.kSpade * PokerConst.weight + PokerConst.k8
PokerConst.S9 = PokerConst.kSpade * PokerConst.weight + PokerConst.k9
PokerConst.S10 = PokerConst.kSpade * PokerConst.weight + PokerConst.k10
PokerConst.SJ = PokerConst.kSpade * PokerConst.weight + PokerConst.kJ
PokerConst.SQ = PokerConst.kSpade * PokerConst.weight + PokerConst.kQ
PokerConst.SK = PokerConst.kSpade * PokerConst.weight + PokerConst.kK

PokerConst.HA =  PokerConst.kHeart * PokerConst.weight + PokerConst.kA
PokerConst.H2 = PokerConst.kHeart * PokerConst.weight + PokerConst.k2
PokerConst.H3 = PokerConst.kHeart * PokerConst.weight + PokerConst.k3
PokerConst.H4 = PokerConst.kHeart * PokerConst.weight + PokerConst.k4
PokerConst.H5 = PokerConst.kHeart * PokerConst.weight + PokerConst.k5
PokerConst.H6 = PokerConst.kHeart * PokerConst.weight + PokerConst.k6
PokerConst.H7 = PokerConst.kHeart * PokerConst.weight + PokerConst.k7
PokerConst.H8 = PokerConst.kHeart * PokerConst.weight + PokerConst.k8
PokerConst.H9 = PokerConst.kHeart * PokerConst.weight + PokerConst.k9
PokerConst.H10 = PokerConst.kHeart * PokerConst.weight + PokerConst.k10
PokerConst.HJ = PokerConst.kHeart * PokerConst.weight + PokerConst.kJ
PokerConst.HQ = PokerConst.kHeart * PokerConst.weight + PokerConst.kQ
PokerConst.HK = PokerConst.kHeart * PokerConst.weight + PokerConst.kK

PokerConst.CA = PokerConst.kClub * PokerConst.weight + PokerConst.kA
PokerConst.C2 = PokerConst.kClub * PokerConst.weight + PokerConst.k2
PokerConst.C3 = PokerConst.kClub * PokerConst.weight + PokerConst.k3
PokerConst.C4 = PokerConst.kClub * PokerConst.weight + PokerConst.k4
PokerConst.C5 = PokerConst.kClub * PokerConst.weight + PokerConst.k5
PokerConst.C6 = PokerConst.kClub * PokerConst.weight + PokerConst.k6
PokerConst.C7 = PokerConst.kClub * PokerConst.weight + PokerConst.k7
PokerConst.C8 = PokerConst.kClub * PokerConst.weight + PokerConst.k8
PokerConst.C9 = PokerConst.kClub * PokerConst.weight + PokerConst.k9
PokerConst.C10 = PokerConst.kClub * PokerConst.weight + PokerConst.k10
PokerConst.CJ = PokerConst.kClub * PokerConst.weight + PokerConst.kJ
PokerConst.CQ = PokerConst.kClub * PokerConst.weight + PokerConst.kQ
PokerConst.CK = PokerConst.kClub * PokerConst.weight + PokerConst.kK

PokerConst.DA = PokerConst.kDiamond * PokerConst.weight + PokerConst.kA
PokerConst.D2 = PokerConst.kDiamond * PokerConst.weight + PokerConst.k2
PokerConst.D3 = PokerConst.kDiamond * PokerConst.weight + PokerConst.k3
PokerConst.D4 = PokerConst.kDiamond * PokerConst.weight + PokerConst.k4
PokerConst.D5 = PokerConst.kDiamond * PokerConst.weight + PokerConst.k5
PokerConst.D6 = PokerConst.kDiamond * PokerConst.weight + PokerConst.k6
PokerConst.D7 = PokerConst.kDiamond * PokerConst.weight + PokerConst.k7
PokerConst.D8 = PokerConst.kDiamond * PokerConst.weight + PokerConst.k8
PokerConst.D9 = PokerConst.kDiamond * PokerConst.weight + PokerConst.k9
PokerConst.D10 = PokerConst.kDiamond * PokerConst.weight + PokerConst.k10
PokerConst.DJ = PokerConst.kDiamond * PokerConst.weight + PokerConst.kJ
PokerConst.DQ = PokerConst.kDiamond * PokerConst.weight + PokerConst.kQ
PokerConst.DK = PokerConst.kDiamond * PokerConst.weight + PokerConst.kK

PokerConst.JA = PokerConst.kJoker * PokerConst.weight + PokerConst.kA
PokerConst.J2 = PokerConst.kJoker * PokerConst.weight + PokerConst.k2

return PokerConst