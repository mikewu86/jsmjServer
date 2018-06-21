-- 2016.10.11
-- ptrjeffrey
-- 南京麻将的胡牌类型定义,每个游戏一份单独文件
local index = 0
local HuTypeConst = {}
local function  accumulatedIndex()
    index = index + 1
    return index
end
-- 胡牌类型枚举
HuTypeConst.kHuType = {
    kHu             = accumulatedIndex(),      
    kHuOtherZi      = accumulatedIndex(),
    kGanQian        = accumulatedIndex(),  
    kMenFeng        = accumulatedIndex(), 
    kJianPai        = accumulatedIndex(),   
    KMG             = accumulatedIndex(),
    KAG             = accumulatedIndex(),    
    kSANCAISHEN     = accumulatedIndex(),
    kDuiDuiHu       = accumulatedIndex(),
    kQingYiSe       = accumulatedIndex(),
    kHunYiSe        = accumulatedIndex(),
    kDaDiaoChe      = accumulatedIndex(),
    kHaiDi          = accumulatedIndex(),
    kGangKai        = accumulatedIndex(),
    kQiangGang      = accumulatedIndex(),
    kRaoDa          = accumulatedIndex(),
    kDiuDa          = accumulatedIndex(),
    kDiHu           = accumulatedIndex(),
    kTianHu         = accumulatedIndex(),
}

-- 大胡类型
HuTypeConst.kDaHuTypeList = {

}

HuTypeConst.kZiMoHuTypeList = {
   HuTypeConst.kHuType.kRaoDa,
   HuTypeConst.kHuType.kDiuDa
}

-- 胡牌类型描述
HuTypeConst.huTypeMap = {
    [HuTypeConst.kHuType.kHu]        = {name = '胡牌', fan = 1, descrip = '1台'},
    [HuTypeConst.kHuType.kHuOtherZi] = {name = '胡牌', fan = 2, descrip = '2台'},
    [HuTypeConst.kHuType.kGanQian]   = {name = '干嵌', fan = 1, descrip = '1台'},
    [HuTypeConst.kHuType.kMenFeng]   = {name = '门风', fan = 1, descrip = '1台'},
    [HuTypeConst.kHuType.kJianPai]   = {name = '箭牌', fan = 1, descrip = '1台'},
    [HuTypeConst.kHuType.KMG]        = {name = '明杠', fan = 1, descrip = '1台'},
    [HuTypeConst.kHuType.KAG]        = {name = '暗杠', fan = 3, descrip = '3台'},
    [HuTypeConst.kHuType.kSANCAISHEN]= {name = '三财神', fan = 8, descrip = '8台'},
    [HuTypeConst.kHuType.kDuiDuiHu]  = {name = '碰碰胡', fan = 3, descrip = '3台'},
    [HuTypeConst.kHuType.kQingYiSe]  = {name = '清一色', fan = 8, descrip = '8台'},
    [HuTypeConst.kHuType.kHunYiSe]   = {name = '混一色', fan = 3, descrip = '3台'},
    [HuTypeConst.kHuType.kDaDiaoChe] = {name = '大吊车', fan = 3, descrip = '3台'},
    [HuTypeConst.kHuType.kHaiDi]     = {name = '海底捞月', fan = 1, descrip = '1台'},
    [HuTypeConst.kHuType.kGangKai]   = {name = '杠开', fan = 1, descrip = '1台'},
    [HuTypeConst.kHuType.kQiangGang] = {name = '抢杠', fan = 2, descrip = '2台'},
    [HuTypeConst.kHuType.kRaoDa]     = {name = '绕搭', fan = 1, descrip = '1台'},
    [HuTypeConst.kHuType.kDiuDa]     = {name = '丢搭', fan = 1, descrip = '1台'},
    [HuTypeConst.kHuType.kDiHu]      = {name = '地胡', fan = 10, descrip = '10台'},
    [HuTypeConst.kHuType.kTianHu]    = {name = '天胡', fan = 10, descrip = '10台'},
}

return HuTypeConst