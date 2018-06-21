--region MJUtils.lua
--Author : yuanxj
--Date   : 2014/9/12
--此文件由[BabeLua]插件自动生成
local MJConst = require "MJCommon.MJConstant"
local Bits = require("MJCommon.Bits")
local MJConstant = MJConst.new()
--  global function
function getOneUnsortedCardInNodes(_nodes, _card)
    local array = _nodes:getChildren()

    if not array then
        return nil
    end

    for i = 0, #array - 1 do
        local node = array[i+1]

        if node
        and node.__cname == "MJWidgetCard"
        and not node:isSorted()
        and node:getCardData().suit == _card.suit
        and node:getCardData().value == _card.value then
            return node, i - 1
        end
    end

    return nil
end

function getOneUnsortedCardInArray(_array, _card, _reverse)
    local array = _array

    if not array then
        return nil
    end

    if nil == _reverse then
        _reverse = false
    end

    local fwdIdx = 0
    local bwdIdx = #array - 1

    for i = fwdIdx, bwdIdx do
        local index = i

        if _reverse then
            index = #array - 1 - index
        end

        local node = array[index + 1]

        if node
        and node.__cname == "MJWidgetCard"
        and not node:isSorted()
        and node:getCardData().suit == _card.suit
        and node:getCardData().value == _card.value then
            return node
        end
    end

    return nil
end

local MJUtils = {}

function MJUtils.getChiCardGroup(_handCards, _chiCard)
    local function findCardData(_cards, _card)
        for i, v in ipairs(_cards) do
        if v.suit == _card.suit and
        v.value == _card.value then
            return true, i
            end
        end
        return false, -1
    end

    local chiCard = _chiCard
    local handCards = _handCards
    if #handCards < 2 then
        Log.Debug("[MJUtils.getChiCardGroup] handcards less than 2")
        return nil
    end

    local chiCardGroup = {}

    --  移除非同suit牌型
    for i, v in ipairs(handCards) do
        if v.suit ~= chiCard.suit then
            table.remove(handCards, i)
        end
    end

    --  进行排序
    table.sort(handCards, MJUtils.sort_CardLess)

    --  前向查找
    if chiCard.value >= MJConstant.VALUE_TYPE.VALUE_3 then
        Log.Debug("[MJUtils.getChiCardGroup] forward search")
        local findCard1 = {suit = chiCard.suit, value = chiCard.value - 2}
        local findCard2 = {suit = chiCard.suit, value = chiCard.value - 1}
        local found1 = findCardData(handCards, findCard1)
        local found2 = findCardData(handCards, findCard2)
        if found1 and found2 then
            table.insert(chiCardGroup, findCard1)
            table.insert(chiCardGroup, findCard2)
            table.insert(chiCardGroup, chiCard)
        end
    end
    --  中间查找
    if chiCard.value >= MJConstant.VALUE_TYPE.VALUE_2 and
        chiCard.value <= MJConstant.VALUE_TYPE.VALUE_8 then
        Log.Debug("[MJUtils.getChiCardGroup] middle search")
        local findCard1 = {suit = chiCard.suit, value = chiCard.value - 1}
        local findCard2 = {suit = chiCard.suit, value = chiCard.value + 1}
        local found1 = findCardData(handCards, findCard1)
        local found2 = findCardData(handCards, findCard2)
        if found1 and found2 then
            table.insert(chiCardGroup, findCard1)
            table.insert(chiCardGroup, chiCard)
            table.insert(chiCardGroup, findCard2)
        end
    end
    --  后向查找
    if chiCard.value <= MJConstant.VALUE_TYPE.VALUE_7 then
        Log.Debug("[MJUtils.getChiCardGroup] backward search")
        local findCard1 = {suit = chiCard.suit, value = chiCard.value + 1}
        local findCard2 = {suit = chiCard.suit, value = chiCard.value + 2}
        local found1 = findCardData(handCards, findCard1)
        local found2 = findCardData(handCards, findCard2)
        if found1 and found2 then
            table.insert(chiCardGroup, chiCard)
            table.insert(chiCardGroup, findCard1)
            table.insert(chiCardGroup, findCard2)
        end
    end

    if #chiCardGroup == 0 then
        Log.Debug("[MJUtils.getChiCardGroup] empty chi card group")
        return nil
    else
        return chiCardGroup
    end
end

function MJUtils.makeMJCard(_suit, _value)
    return {suit=_suit,value=_value}
end

function MJUtils.makeMJCardByte(_suit, _value)
    return MJUtils.CardDataToByte({suit=_suit,value=_value})
end

function MJUtils.makeWord(_byteLow, _byteHigh)
    local byteLow = Bits:_and(0xff, _byteLow)
    local byteHigh = Bits:_lshift(Bits:_and(_byteHigh, 0xff), 8)

    return Bits:_or(byteLow, byteHigh)
end

function MJUtils.makeLong(_wordLow, _wordHigh)
    local wordLow = Bits:_and(0xffff, _wordLow)
    local wordHigh = Bits:_lshift(Bits:_and(_wordHigh, 0xffff), 16)

    return Bits:_or(wordLow, wordHigh)
end

function MJUtils.lowByte(_word)
    return Bits:_and(0xff, _word)
end

function MJUtils.highByte(_word)
    return Bits:_rshift(Bits:_and(_word, 0xff00), 8)
end

function MJUtils.lowWord(_long)
    return Bits:_and(0xffff, _long)
end

function MJUtils.highWord(_long)
    return Bits:_rshift(Bits:_and(_long, 0xffff0000), 16)
end

function MJUtils.isSuitHua(_cardData)
    return (_cardData.suit == MJConstant.SUIT_TYPE.SUIT_HUA)
end

function MJUtils.isSuitJian(_cardData)
    return (_cardData.suit == MJConstant.SUIT_TYPE.SUIT_JIAN)
end

function MJUtils.CardDataToInt(_cardData)
    local value = -1

    if type(_cardData) ~= "table"
    or nil == _cardData.suit
    or nil == _cardData.value then
        return value
    end

    if _cardData.suit == MJConstant.SUIT_TYPE.SUIT_NONE then
        value = 0
    elseif _cardData.suit == MJConstant.SUIT_TYPE.SUIT_WAN then
        value = MJConstant.VALUE_OFFSET.WAN + _cardData.value
    elseif _cardData.suit == MJConstant.SUIT_TYPE.SUIT_TONG then
        value = MJConstant.VALUE_OFFSET.TONG + _cardData.value
    elseif _cardData.suit == MJConstant.SUIT_TYPE.SUIT_TIAO
    or _cardData.suit == MJConstant.SUIT_TYPE.SUIT_FENG
    or _cardData.suit == MJConstant.SUIT_TYPE.SUIT_JIAN
    or _cardData.suit == MJConstant.SUIT_TYPE.SUIT_HUA then
        value = MJConstant.VALUE_OFFSET.TIAO + _cardData.value
    end

    return value
end

function MJUtils.CardIntToData(_value)
    local data = {suit=MJConstant.SUIT_TYPE.SUIT_NONE, value=MJConstant.VALUE_TYPE.VALUE_NONE}

    if type(_value) ~= "number" then
        return data
    end

    if 0 == _value then
        data.suit = MJConstant.SUIT_TYPE.SUIT_UNKNOWN
        return data
    end

    local mapTable = {
        {MJConstant.VALUE_OFFSET.TIAO + MJConstant.VALUE_TYPE.VALUE_HUA_CHUN, MJConstant.SUIT_TYPE.SUIT_HUA, MJConstant.VALUE_OFFSET.TIAO},
        {MJConstant.VALUE_OFFSET.TIAO + MJConstant.VALUE_TYPE.VALUE_JIAN_ZHONG, MJConstant.SUIT_TYPE.SUIT_JIAN, MJConstant.VALUE_OFFSET.TIAO},
        {MJConstant.VALUE_OFFSET.TIAO + MJConstant.VALUE_TYPE.VALUE_FENG_DONG, MJConstant.SUIT_TYPE.SUIT_FENG, MJConstant.VALUE_OFFSET.TIAO},
        {MJConstant.VALUE_OFFSET.TIAO + MJConstant.VALUE_TYPE.VALUE_1, MJConstant.SUIT_TYPE.SUIT_TIAO, MJConstant.VALUE_OFFSET.TIAO},
        {MJConstant.VALUE_OFFSET.TONG + MJConstant.VALUE_TYPE.VALUE_1, MJConstant.SUIT_TYPE.SUIT_TONG, MJConstant.VALUE_OFFSET.TONG},
        {MJConstant.VALUE_OFFSET.WAN + MJConstant.VALUE_TYPE.VALUE_1, MJConstant.SUIT_TYPE.SUIT_WAN, MJConstant.VALUE_OFFSET.WAN}
    }

    for i, v in ipairs(mapTable) do
        if _value >= v[1] then
            data.suit = v[2]
            data.value = _value - v[3]
            break
        end
    end

    Log.Debug("value ".._value.." data suit:"..data.suit.." value:"..data.value)

    return data
end

function MJUtils.CardEqual(_left, _right)
    if nil == _left or nil == _right then return false end
    return _left.value == _right.value and _left.suit == _right.suit
end

function MJUtils.ValueEqual(_left, _right)
    return _left.value == _right.value
end

function MJUtils.SuitEqual(_left, _right)
    return _left.suit == _right.suit
end

function MJUtils.CardDataToByte(_data)
    -- ptrjeffrey 2014.12.8 优化转换运算
    local l = _data.suit * 32
    local r = _data.value

    return l + r
end

function MJUtils.CardByteToData(_value)
    local data = {suit=MJConstant.SUIT_TYPE.SUIT_NONE, value=MJConstant.VALUE_TYPE.VALUE_NONE}

    --data.suit = Bits:_rshift(_value, 5)
    --data.value = Bits:_and(_value, 0x1f)

    -- ptrjeffrey 2014.12.8 优化转换运算
    data.suit = math.floor(_value / 32)
    data.value = _value % 32

    return data
end
--- data = {}
function MJUtils.FormatDataToString(_card)
    local suitStr = MJConstant:GetStringBySuit(_card.suit)
    local valueStr = MJConstant:GetStringByValue(_card.value)
    local retStr = valueStr..suitStr
    return retStr
end

function MJUtils.FormatCardToString(_value)
    if nil == _value then
        return " "
    end
    
    local data = MJUtils.CardByteToData(_value)
    return MJUtils.FormatDataToString(data)
end

function MJUtils.sort_CardLess(lcard, rcard)
    if lcard.suit == rcard.suit then
        return lcard.value < rcard.value
    end

    return lcard.suit < rcard.suit
end

function MJUtils.sort_CardGreater(lcard, rcard)
    if lcard.suit == rcard.suit then
        return lcard.value > rcard.value
    end

    return lcard.suit > rcard.suit
end

function MJUtils.sort_ByteCardLess(_lcard, _rcard)
    local ldata = MJUtils.CardByteToData(_lcard)
    local rdata = MJUtils.CardByteToData(_rcard)

    return MJUtils.sort_CardLess(ldata, rdata)
end

function MJUtils.sort_ByteCardGreater(_lcard, _rcard)
    local ldata = MJUtils.CardByteToData(_lcard)
    local rdata = MJUtils.CardByteToData(_rcard)

    return MJUtils.sort_CardGreater(ldata, rdata)
end

--MJUtils.MJCard_None = {suit=MJConstant.SUIT_TYPE.SUIT_NONE, value=MJConstant.VALUE_TYPE.VALUE_NONE}
MJUtils.MJCard_None = {suit=0, value=MJConstant.VALUE_TYPE.VALUE_NONE}
function MJUtils.getNoneCard()
    return clone(MJUtils.MJCard_None)
end

function MJUtils.getNoneCardByte()
    return MJUtils.CardDataToByte(MJUtils.MJCard_None)
end

function MJUtils.isNoneCard(_card)
    if _card.suit == MJUtils.MJCard_None.suit and
    _card.value == MJUtils.MJCard_None.value then
        return true
    end

    return false
end

MJUtils.MJCard_Unknown = {suit = MJConstant.SUIT_TYPE.SUIT_UNKNOWN, value = MJConstant.VALUE_TYPE.VALUE_NONE}

function MJUtils.getUnknownCard()
    return clone(MJUtils.MJCard_Unknown)
end

function MJUtils.getUnknownCardByte()
    return MJUtils.CardDataToByte(MJUtils.MJCard_Unknown)
end

function MJUtils.makeUnknownCard(_card)
    _card.suit = MJUtils.MJCard_Unknown.suit
    _card.value = MJUtils.MJCard_Unknown.value
end

function MJUtils.isUnknownCard(_card)
    if _card.suit == MJUtils.MJCard_Unknown.suit and
    _card.value == MJUtils.MJCard_Unknown.value then
        return true
    end

    if _card.suit == MJConstant.SUIT_TYPE.SUIT_NONE and
    _card.value == MJUtils.MJCard_Unknown.value then
        return true
    end

    return false
end

function MJUtils.isCardValid(_card)
    local card = MJUtils.CardByteToData(_card)
    if card.suit < MJConstant.SUIT_TYPE.SUIT_WAN or card.suit > MJConstant.SUIT_TYPE.SUIT_TYPE_SUM or card.value < MJConstant.VALUE_TYPE.VALUE_1 or card.value > MJConstant.VALUE_TYPE.VALUE_TYPE_SUM then
        return false
    end
    return true
end

local MJOperations = class("MJOperations")

MJOperations.kOperNull      = 0
MJOperations.kOperHu        = 1
MJOperations.kOperPeng      = 2
MJOperations.kOperMG        = 3   -- 明杠
MJOperations.kOperAG        = 4   -- 暗杠
MJOperations.kOperMXG       = 5   -- 面下杠
MJOperations.kOperLChi      = 6
MJOperations.kOperMChi      = 7
MJOperations.kOperRChi      = 8
MJOperations.kOperBuHua     = 9
MJOperations.kOperPlay      = 10   --- 出牌
MJOperations.kOperCancel    = 11
MJOperations.kOperTing      = 12
MJOperations.kOperNewCard   = 13
MJOperations.kOperSyncData  = 14
MJOperations.kOperTuoGuan   = 15

function MJOperations:ctor()
    self.operations = 0
    self.currentOperation = 0
    self.operationSerial = 0
end

function MJOperations:setOperations(_op)
    self.operations = _op
end

function MJOperations:setOperationsWithBytes(_byte0, _byte1, _byte2, _byte3)
    self.operations = MJUtils.makeLong(MJUtils.makeWord(_byte3, _byte2), MJUtils.makeWord(_byte1, _byte0))
end

function MJOperations:setCurrentOperation(_op)
    self.currentOperation = _op
end

function MJOperations:getOperations()
    return self.operations
end

function MJOperations:getCurrentOperation()
    return self.currentOperation
end

function MJOperations:addOperations(_op)
    self.operations = Bits:_or(self.operations, Bits:_lshift(1, _op))
end

function MJOperations:addOperation(_op)
    self:addOperations(_op)
end

function MJOperations:setOperationSerial(_serial)
    self.operationSerial = _serial
end

function MJOperations:getOperationSerial()
    return self.operationSerial
end

function MJOperations:checkOperation(_op)
    local checked = calcBinaryLeftBiteValue(_op)
    local has = Bits:_and(self.operations, checked)
    if 0 ~= has then
        return true
    end

    return false
end

function MJOperations:onlyChuOperationExist()
    local checked = Bits:_lshift(1, MJOperations.kOperPlay)
    if self.operations == checked then
        return true
    end

    return false
end

function MJOperations:reset()
    self:resetOperations()
    self.operationSerial = 0
end

function MJOperations:resetOperations()
    self.operations = 0
    self.currentOperation = 0
end

MJUtils.MJOperations = MJOperations


local MJWallData = class("MJWallData")

function MJWallData:ctor()
    self:_initFields()
end

function MJWallData:_initFields()
    self.cardNumberTable = {}
    self.playerNumber = 0
end

function MJWallData:initWithPlayerNumber(_number)
    self.playerNumber = _number
    
    for i = 1, _number do
        self.cardNumberTable[i] = 0
    end
end

function MJWallData:reset()
    self.cardNumberTable = {}
    self:initWithPlayerNumber(self.playerNumber)
end

function MJWallData:setCardNumberR(_pos, _number)
    if _pos == -1 then
        for i = 1, self.playerNumber do
            self.cardNumberTable[i] = _number
        end
        return
    end

    local relativePos = _pos + 1
    if relativePos <= 0 or
    relativePos > self.playerNumber then
        return
    end

    self.cardNumberTable[relativePos] = _number
end

function MJWallData:getCardNumberR(_pos)
    local relativePos = _pos + 1
    if relativePos <= 0 or
    relativePos > self.playerNumber then
        return 0 
    end

    return self.cardNumberTable[relativePos]
end

function MJWallData:incCardNumberR(_inc)
    local relativePos = _pos + 1
    if relativePos <= 0 or
    relativePos > self.playerNumber then
        return
    end

    local oft = _inc
    if oft == nil then
        oft = 1
    end

    self.cardNumberTable[relativePos] = self.cardNumberTable[relativePos] + oft
end

function MJWallData:decCardNumberR(_dec)
    local relativePos = _pos + 1
    if relativePos <= 0 or
    relativePos > self.playerNumber then
        return
    end

    local oft = _inc

    if oft == nil then
        oft = 1
    end

    oft = math.abs(oft)

    if self.cardNumber < oft then
        self.cardNumberTable[relativePos] = 0
    else
        self.cardNumberTable[relativePos] = self.cardNumberTable[relativePos] - oft
    end
end

function MJWallData:moPai(_sum)
    if nil == _sum then
        _sum = 1
    end
    --  就减去一张牌
    for i = 1, self.playerNumber do
        local sum = self.cardNumberTable[i]

        if sum >= _sum then
            self.cardNumberTable[i] = sum - _sum
            _sum = 0
        else
            self.cardNumberTable[i] = 0
            _sum = _sum - sum
        end

        if _sum <= 0 then
            break
        end
    end
end

function MJWallData:buPai(_sum)
    self:moPai(_sum)
end

function MJWallData:getCount()
    local count = 0
    for i = 1, self.playerNumber do
        count = count + self.cardNumberTable[i]
    end

    return count
end

MJUtils.MJWallData = MJWallData


--------------------------------
--  enum utils
local FlagOperator = class("BitOperator")

function FlagOperator:ctor()
    self:reset()
end

function FlagOperator:reset()
    self.flag = 0
end

function FlagOperator:setFlag(_flag)
    self.flag = _flag
end

function FlagOperator:getFlag()
    return self.flag
end

function FlagOperator:_getRawFlag(_flag)
    return Bits:_lshift(1, _flag)
end

function FlagOperator:addFlag(_flag)
    local flag = self:getFlag()
    local rawFlag = self:_getRawFlag(_flag)

    flag = Bits:_or(flag, rawFlag)
    self:setFlag(flag)
end

function FlagOperator:testFlag(_flag)
    local rawFlag = self:_getRawFlag(_flag)
    return (Bits:_and(self:getFlag(), rawFlag) ~= 0)
end

function FlagOperator:removeFlag(_flag)
    local rawFlag = self:_getRawFlag(_flag)
    local eraseFlag = Bits:_not(rawFlag)
    local flag = Bits:_and(self:getFlag(), eraseFlag)
    self:setFlag(flag)
end

function FlagOperator:_test()
    local flagOp = FlagOperator.new()
    local flagBits = {1, 3, 5 ,7, 10}

    for i, v in ipairs(flagBits) do
        flagOp:addFlag(v)
    end

    for i = 1, 10 do
        local exist = flagOp:testFlag(i)
        local output
        if exist then
            output = " ok"
        else
            output = " fail"
        end
        Log.Info("test flag bit "..i..output)
    end

    for i, v in ipairs(flagBits) do
        flagOp:removeFlag(v)
        if not flagOp:testFlag(v) then
            Log.Info("erase flag "..v.." ok")
        else
            Log.Info("erase flag "..v.." fail")
        end
    end

    if 0 == flagOp:getFlag() then
        Log.Info("zero ok")
    else
        Log.Info("zero fail")
    end
end

MJUtils.FlagOperator = FlagOperator

return MJUtils

--endregion
