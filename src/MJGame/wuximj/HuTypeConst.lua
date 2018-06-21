-- 2016.10.11
-- ptrjeffrey
-- 南京麻将的胡牌类型定义,每个游戏一份单独文件

local HuTypeConst = {}

-- 胡牌类型枚举
HuTypeConst.kHuType = {
    kHu            = 1,
    kDiaoChe       = 2, -- crane
    kPengPengHu    = 3, -- right hu
    kGangKai       = 4, -- Bar open
    kZiMo          = 5, -- self get hu card
    kFlowerCard    = 6, -- flower card
    kWindBumb      = 7, -- wind bumb
    kWindBumbHand  = 8, -- wind black bumb
    kWindBar       = 9, -- wind Bar
    kWindBlackBar  = 10, -- wind black Bar
    kNormalBar     = 11, -- wind Bar
    kNormalBlackBar= 12, -- wind black bar 

    kZiMoSlam      = 13, -- zimoSlam

    kQYSPPHSlam     = 14, -- qingyise pengpeng hu
    kQYSQDSlam      = 15, -- qingyise qidui hu

    kZYSPPHSlam     = 16, -- ziyise pengpeng hu
    kZYSQDSlam      = 17, -- ziyise qidui hu

    kQueMen         = 18, -- que men

    
    kXGK            = 19, -- xiaogangkai
    kHYS            = 20, -- hunyise
    kDoubleOp       = 21, -- dobule op
    kLeopard        = 22, -- leopard
    kZQDSlam        = 23, 
}

HuTypeConst.kSlamTypeList = {
    -- slam thirty
    HuTypeConst.kHuType.kPengPengHu,
    HuTypeConst.kHuType.kGangKai,
    HuTypeConst.kHuType.kZiMoSlam,
    -- double slam sixTy
    HuTypeConst.kHuType.kQYSPPHSlam,
    HuTypeConst.kHuType.kQYSQDSlam,
    -- four slam one hundred twenty
    HuTypeConst.kHuType.kZYSPPHSlam,
    HuTypeConst.kHuType.kZQDSlam,
}

HuTypeConst.kMultipleHuList = {
    HuTypeConst.kHuType.kXGK,
    HuTypeConst.kHuType.kHYS,
    HuTypeConst.kHuType.kZiMo,
    HuTypeConst.kHuType.kDoubleOp,
    --- pph special handle
}
-- 胡牌类型描述
HuTypeConst.huTypeMap = {
    [HuTypeConst.kHuType.kFlowerCard]       = {name = '花牌', fan = 0, descrip = '花'},
    [HuTypeConst.kHuType.kWindBumb]         = {name = '风碰', fan = 0, descrip = '花'},
    [HuTypeConst.kHuType.kWindBumbHand]     = {name = '风暗刻', fan = 0, descrip = '*2花'},
    [HuTypeConst.kHuType.kWindBar]          = {name = '风明杠', fan = 0, descrip = '*3花'},
    [HuTypeConst.kHuType.kWindBlackBar]     = {name = '风暗杠', fan = 0, descrip = '*4花'},
    [HuTypeConst.kHuType.kNormalBar]    = {name = '明杠', fan = 0, descrip = '花'},
    [HuTypeConst.kHuType.kNormalBlackBar]   = {name = '暗杠', fan = 0, descrip = '*2花'},

    [HuTypeConst.kHuType.kPengPengHu]       = {name = '碰碰胡', fan = 30, descrip = '30花'},
    [HuTypeConst.kHuType.kGangKai]          = {name = '大扛开', fan = 30, descrip = '30花'},
    [HuTypeConst.kHuType.kZiMoSlam]         = {name = '自摸满贯', fan = 30, descrip = '30花'},
    [HuTypeConst.kHuType.kQYSPPHSlam]       = {name = '清一色碰碰胡', fan = 60, descrip = '60花'},
    [HuTypeConst.kHuType.kQYSQDSlam]        = {name = '清一色七对', fan = 60, descrip = '60花'},
    [HuTypeConst.kHuType.kZYSPPHSlam]       = {name = '字一色碰碰胡', fan = 120, descrip = '120花'},
    [HuTypeConst.kHuType.kZQDSlam]          = {name = '字一色七对', fan = 120, descrip = '120花'},

    [HuTypeConst.kHuType.kXGK]              = {name = '小杠开', fan = 2, descrip = 'X 2'},
    [HuTypeConst.kHuType.kHYS]              = {name = '混一色', fan = 2, descrip = 'X 2'},
    [HuTypeConst.kHuType.kZiMo]             = {name = '自摸', fan = 2, descrip = 'X 2'},
    [HuTypeConst.kHuType.kDoubleOp]         = {name = '双算', fan = 2, descrip = 'X 2'},
    [HuTypeConst.kHuType.kLeopard]          = {name = '豹子', fan = 2, descrip = 'X 2'}
}

return HuTypeConst