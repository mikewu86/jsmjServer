-- 2016.9.21 ptrjeffrey
-- 麻将基础定义

local MJConst = {}

MJConst.kMJAnyCard  = -1        -- 百搭
MJConst.kCardNull   = 0         -- 无效牌
MJConst.kMaxMJCount = 53       -- 最大麻将子数


--操作定义
MJConst.kOperNull      = 0
MJConst.kOperHu        = 1
MJConst.kOperPeng      = 2
MJConst.kOperMG        = 3   -- 明杠
MJConst.kOperAG        = 4   -- 暗杠
MJConst.kOperMXG       = 5   -- 面下杠
MJConst.kOperLChi      = 6
MJConst.kOperMChi      = 7
MJConst.kOperRChi      = 8
MJConst.kOperBuHua     = 9
MJConst.kOperPlay      = 10   --- 出牌
MJConst.kOperCancel    = 11
MJConst.kOperTing      = 12
MJConst.kOperNewCard   = 13
MJConst.kOperSyncData  = 14
MJConst.kOperTuoGuan   = 15
MJConst.kOperTestNeedCard = 16  --- 测试时玩家要牌， 不从牌值池中取牌
MJConst.kOperHG        = 17   -- 花杠
MJConst.kOperAITip     = 18     -- 智能提示听什么牌
MJConst.kOperAbandonSuit = 19


MJConst.kMJSuitWan     = 0
MJConst.kMJSuitTiao    = 1
MJConst.kMJSuitTong    = 2
MJConst.kMJSuitZi      = 3     -- 东南西北中发白
MJConst.kMJSuitHua     = 4     -- 花牌
MJConst.kMJSuitCai     = 5     -- 财宝猫鼠
MJConst.kMJSuitBlank   = 6     -- 大白板
MJConst.kMJSuitNull    = 7

MJConst.kMJPoint1      = 1
MJConst.kMJPoint2      = 2
MJConst.kMJPoint3      = 3
MJConst.kMJPoint4      = 4
MJConst.kMJPoint5      = 5
MJConst.kMJPoint6      = 6
MJConst.kMJPoint7      = 7
MJConst.kMJPoint8      = 8
MJConst.kMJPoint9      = 9
MJConst.kMJPointNull   = 10

MJConst.Wan1           = MJConst.kMJSuitWan * MJConst.kMJPointNull + MJConst.kMJPoint1 
MJConst.Wan2           = MJConst.kMJSuitWan * MJConst.kMJPointNull + MJConst.kMJPoint2
MJConst.Wan3           = MJConst.kMJSuitWan * MJConst.kMJPointNull + MJConst.kMJPoint3
MJConst.Wan4           = MJConst.kMJSuitWan * MJConst.kMJPointNull + MJConst.kMJPoint4
MJConst.Wan5           = MJConst.kMJSuitWan * MJConst.kMJPointNull + MJConst.kMJPoint5
MJConst.Wan6           = MJConst.kMJSuitWan * MJConst.kMJPointNull + MJConst.kMJPoint6
MJConst.Wan7           = MJConst.kMJSuitWan * MJConst.kMJPointNull + MJConst.kMJPoint7
MJConst.Wan8           = MJConst.kMJSuitWan * MJConst.kMJPointNull + MJConst.kMJPoint8
MJConst.Wan9           = MJConst.kMJSuitWan * MJConst.kMJPointNull + MJConst.kMJPoint9

MJConst.Tiao1           = MJConst.kMJSuitTiao * MJConst.kMJPointNull + MJConst.kMJPoint1 
MJConst.Tiao2           = MJConst.kMJSuitTiao * MJConst.kMJPointNull + MJConst.kMJPoint2
MJConst.Tiao3           = MJConst.kMJSuitTiao * MJConst.kMJPointNull + MJConst.kMJPoint3
MJConst.Tiao4           = MJConst.kMJSuitTiao * MJConst.kMJPointNull + MJConst.kMJPoint4
MJConst.Tiao5           = MJConst.kMJSuitTiao * MJConst.kMJPointNull + MJConst.kMJPoint5
MJConst.Tiao6           = MJConst.kMJSuitTiao * MJConst.kMJPointNull + MJConst.kMJPoint6
MJConst.Tiao7           = MJConst.kMJSuitTiao * MJConst.kMJPointNull + MJConst.kMJPoint7
MJConst.Tiao8           = MJConst.kMJSuitTiao * MJConst.kMJPointNull + MJConst.kMJPoint8
MJConst.Tiao9           = MJConst.kMJSuitTiao * MJConst.kMJPointNull + MJConst.kMJPoint9

MJConst.Tong1           = MJConst.kMJSuitTong * MJConst.kMJPointNull + MJConst.kMJPoint1 
MJConst.Tong2           = MJConst.kMJSuitTong * MJConst.kMJPointNull + MJConst.kMJPoint2
MJConst.Tong3           = MJConst.kMJSuitTong * MJConst.kMJPointNull + MJConst.kMJPoint3
MJConst.Tong4           = MJConst.kMJSuitTong * MJConst.kMJPointNull + MJConst.kMJPoint4
MJConst.Tong5           = MJConst.kMJSuitTong * MJConst.kMJPointNull + MJConst.kMJPoint5
MJConst.Tong6           = MJConst.kMJSuitTong * MJConst.kMJPointNull + MJConst.kMJPoint6
MJConst.Tong7           = MJConst.kMJSuitTong * MJConst.kMJPointNull + MJConst.kMJPoint7
MJConst.Tong8           = MJConst.kMJSuitTong * MJConst.kMJPointNull + MJConst.kMJPoint8
MJConst.Tong9           = MJConst.kMJSuitTong * MJConst.kMJPointNull + MJConst.kMJPoint9

MJConst.Zi1           = MJConst.kMJSuitZi * MJConst.kMJPointNull + MJConst.kMJPoint1
MJConst.Zi2           = MJConst.kMJSuitZi * MJConst.kMJPointNull + MJConst.kMJPoint2
MJConst.Zi3           = MJConst.kMJSuitZi * MJConst.kMJPointNull + MJConst.kMJPoint3
MJConst.Zi4           = MJConst.kMJSuitZi * MJConst.kMJPointNull + MJConst.kMJPoint4
MJConst.Zi5           = MJConst.kMJSuitZi * MJConst.kMJPointNull + MJConst.kMJPoint5
MJConst.Zi6           = MJConst.kMJSuitZi * MJConst.kMJPointNull + MJConst.kMJPoint6
MJConst.Zi7           = MJConst.kMJSuitZi * MJConst.kMJPointNull + MJConst.kMJPoint7

MJConst.Hua1           = MJConst.kMJSuitHua * MJConst.kMJPointNull + MJConst.kMJPoint1 
MJConst.Hua2           = MJConst.kMJSuitHua * MJConst.kMJPointNull + MJConst.kMJPoint2
MJConst.Hua3           = MJConst.kMJSuitHua * MJConst.kMJPointNull + MJConst.kMJPoint3
MJConst.Hua4           = MJConst.kMJSuitHua * MJConst.kMJPointNull + MJConst.kMJPoint4
MJConst.Hua5           = MJConst.kMJSuitHua * MJConst.kMJPointNull + MJConst.kMJPoint5
MJConst.Hua6           = MJConst.kMJSuitHua * MJConst.kMJPointNull + MJConst.kMJPoint6
MJConst.Hua7           = MJConst.kMJSuitHua * MJConst.kMJPointNull + MJConst.kMJPoint7
MJConst.Hua8           = MJConst.kMJSuitHua * MJConst.kMJPointNull + MJConst.kMJPoint8

MJConst.Cai             = MJConst.kMJSuitCai * MJConst.kMJPointNull + MJConst.kMJPoint1
MJConst.Bao             = MJConst.kMJSuitCai * MJConst.kMJPointNull + MJConst.kMJPoint2
MJConst.Mao             = MJConst.kMJSuitCai * MJConst.kMJPointNull + MJConst.kMJPoint3
MJConst.Shu             = MJConst.kMJSuitCai * MJConst.kMJPointNull + MJConst.kMJPoint4
MJConst.Blank           = MJConst.kMJSuitBlank * MJConst.kMJPointNull + MJConst.kMJPoint1
MJConst.Baida           = MJConst.kMJSuitBlank * MJConst.kMJPointNull + MJConst.kMJPoint2

-- 转化为原来的牌点数
MJConst.fromNow2OldCardByteMap = {
    [MJConst.Wan1] = 65, [MJConst.Wan2] = 66, [MJConst.Wan3] = 67,
    [MJConst.Wan4] = 68, [MJConst.Wan5] = 69, [MJConst.Wan6] = 70,
    [MJConst.Wan7] = 71, [MJConst.Wan8] = 72, [MJConst.Wan9] = 73,

    [MJConst.Tiao1] = 129, [MJConst.Tiao2] = 130, [MJConst.Tiao3] = 131,
    [MJConst.Tiao4] = 132, [MJConst.Tiao5] = 133, [MJConst.Tiao6] = 134,
    [MJConst.Tiao7] = 135, [MJConst.Tiao8] = 136, [MJConst.Tiao9] = 137,

    [MJConst.Tong1] = 97, [MJConst.Tong2] = 98, [MJConst.Tong3] = 99,
    [MJConst.Tong4] = 100, [MJConst.Tong5] = 101, [MJConst.Tong6] = 102,
    [MJConst.Tong7] = 103, [MJConst.Tong8] = 104, [MJConst.Tong9] = 105,

    [MJConst.Zi1] = 170, [MJConst.Zi2] = 171, [MJConst.Zi3] = 172,
    [MJConst.Zi4] = 173, [MJConst.Zi5] = 206, [MJConst.Zi6] = 207,
    [MJConst.Zi7] = 208,

    [MJConst.Hua1] = 241, [MJConst.Hua2] = 242, [MJConst.Hua3] = 243,
    [MJConst.Hua4] = 244, [MJConst.Hua5] = 245, [MJConst.Hua6] = 246,
    [MJConst.Hua7] = 247, [MJConst.Hua8] = 248,

    [MJConst.Cai] = 249, [MJConst.Bao] = 250, [MJConst.Mao] = 251,
    [MJConst.Shu] = 252, [MJConst.Blank] = 253,[MJConst.Baida] = 254
}

-- 原来的点数转成现在的点数
MJConst.fromOld2NowCardByteMap = {
     [65] = MJConst.Wan1,  [66] = MJConst.Wan2, [67] = MJConst.Wan3,
     [68] = MJConst.Wan4,  [69] = MJConst.Wan5, [70] = MJConst.Wan6,
     [71] = MJConst.Wan7,  [72] = MJConst.Wan8, [73] = MJConst.Wan9,

     [129] =  MJConst.Tiao1,  [130] = MJConst.Tiao2, [131] =   MJConst.Tiao3,
     [132] =  MJConst.Tiao4,  [133] = MJConst.Tiao5,  [134] =  MJConst.Tiao6,
     [135] =  MJConst.Tiao7,  [136] = MJConst.Tiao8, [137] =  MJConst.Tiao9 ,

     [97] = MJConst.Tong1 ,  [98] = MJConst.Tong2 , [99] = MJConst.Tong3 ,
     [100] = MJConst.Tong4,  [101] = MJConst.Tong5 ,  [102] = MJConst.Tong6 ,
     [103] = MJConst.Tong7 ,  [104] = MJConst.Tong8 ,  [105] = MJConst.Tong9 ,

     [170] = MJConst.Zi1 ,  [171] = MJConst.Zi2 ,  [172] = MJConst.Zi3 ,
     [173] = MJConst.Zi4 ,  [206] = MJConst.Zi5 ,  [207] = MJConst.Zi6 ,
     [208] = MJConst.Zi7 ,

     [241] = MJConst.Hua1 ,  [242] = MJConst.Hua2 ,  [243] = MJConst.Hua3 ,
     [244] = MJConst.Hua4 ,  [245] = MJConst.Hua5 ,  [246] = MJConst.Hua6 ,
     [247] = MJConst.Hua7 ,  [248] = MJConst.Hua8 ,
     
     [249] = MJConst.Cai, [250] = MJConst.Bao, [251] = MJConst.Mao,
     [252] = MJConst.Shu, [253] = MJConst.Blank, [254] = MJConst.Baida,
}

MJConst.chiList = { 
    MJConst.kOperLChi,
    MJConst.kOperMChi,
    MJConst.kOperRChi 
}

MJConst.gangList = {
    MJConst.kOperMG,
    MJConst.kOperAG,
    MJConst.kOperMXG
}

MJConst.pgList = {
    MJConst.kOperPeng,
    MJConst.kOperMG,
    MJConst.kOperAG,
    MJConst.kOperMXG
}

MJConst.fengList = {MJConst.Zi1, MJConst.Zi2, MJConst.Zi3, MJConst.Zi4}
MJConst.jianList = {MJConst.Zi5, MJConst.Zi6, MJConst.Zi7}
MJConst.ziList = {
    MJConst.Zi1, MJConst.Zi2, MJConst.Zi3, MJConst.Zi4,
    MJConst.Zi5, MJConst.Zi6, MJConst.Zi7
}

MJConst.createOperMap = function ()
    local operMap = {}
    for i = MJConst.kOperNull, MJConst.kOperNewCard do
        operMap[i] = 0
    end
    return operMap
end

MJConst.transferNew2OldCardList = function (t)
    local tempTb = {}
    if "table" ~= type(t) then 
        LOG_DEBUG("transferNew2OldCardList invalid arg.")
        return nil 
    end
    for i, v in pairs(t) do 
        table.insert(tempTb, MJConst.fromNow2OldCardByteMap[v]) 
    end
    return tempTb
end

MJConst.tranferOld2NewCardList = function (t)
    local tempTb = {}
    if "table" ~= type(t) then 
        LOG_DEBUG("tranferOld2NewCardList invalid arg.")
        return  nil
    end
    for i, v in pairs(t) do 
        table.insert(tempTb, MJConst.fromOld2NowCardByteMap[v]) 
    end
    return tempTb
end

MJConst.getOpsValue = function(opList)
    local sum = 0
    if "table" ~= type(opList) then 
        return sum 
    end
    for _, v in pairs(opList) do
        sum = sum + calcBinaryLeftBiteValue(v)
    end
    return sum
end

MJConst.fromNow2Old = function(byteCard)
    return MJConst.fromNow2OldCardByteMap[byteCard]
end

MJConst.fromOld2Now = function(byteCard)
    return MJConst.fromOld2NowCardByteMap[byteCard]
end

MJConst.fromSuitAndPointToByte = function(_suit, _point)
    local cardByte = _suit * MJConst.kMJPointNull + _point
    return cardByte
end

MJConst.fromByteToSuitAndPoint = function(_cardByte)
    local suit = math.floor(_cardByte / MJConst.kMJPointNull)
    local value = _cardByte % MJConst.kMJPointNull
    return {suit = suit, value = value}
end

MJConst.isFengCard = function(_byteCard)
    local bRet = false 
    if _byteCard >= MJConst.Zi1 and _byteCard <= MJConst.Zi4 then
        bRet = true
    end
    return bRet
end

MJConst.isGang = function(_op)
    local bRet = false
    if MJConst.kOperMG == _op or 
        MJConst.kOperAG == _op or 
        MJConst.kOperMXG == _op then
        bRet = true
    end
    return bRet
end

return MJConst