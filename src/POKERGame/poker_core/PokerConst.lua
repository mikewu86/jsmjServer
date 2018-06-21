local PokerCard = require("poker_core.PokerCard")

--扑克牌基础定义
local PokerConst = {}

PokerConst.kPokerAnyCard    = -1
PokerConst.kPokerNull       = 0

--操作定义
PokerConst.kOperNull        = 0
PokerConst.kOperCallPoint   = 1
PokerConst.kOperGrabLL      = 2
PokerConst.kOperDoubleScore = 3      --加倍
PokerConst.kOperShowCards   = 4      --明牌
PokerConst.kOperPlay        = 5
PokerConst.kOperPass        = 6
PokerConst.kOperTipCard     = 7      --提示牌
PokerConst.kOperSyncData    = 8

PokerConst.kPokerSuitNull       = 0
PokerConst.kPokerSuitSpade      = 1  --黑桃
PokerConst.kPokerSuitHeart      = 2  --红桃
PokerConst.kPokerSuitClub       = 3  --梅花
PokerConst.kPokerSuitDiamond    = 4  --方块
PokerConst.kPokerSuitJoker      = 5  --王

PokerConst.kPokerPointNull  = 0
PokerConst.kPokerPoint1     = 1
PokerConst.kPokerPoint2     = 2
PokerConst.kPokerPoint3     = 3
PokerConst.kPokerPoint4     = 4
PokerConst.kPokerPoint5     = 5
PokerConst.kPokerPoint6     = 6
PokerConst.kPokerPoint7     = 7
PokerConst.kPokerPoint8     = 8
PokerConst.kPokerPoint9     = 9
PokerConst.kPokerPoint10    = 10
PokerConst.kPokerPointJ     = 11
PokerConst.kPokerPointQ     = 12
PokerConst.kPokerPointK     = 13
PokerConst.kPokerPointBlack = 14
PokerConst.kPokerPointRed   = 15

--扑克牌掩码值
PokerConst.CardBitMask = math.pow(2, 4)

PokerConst.Spade1 = PokerConst.kPokerSuitSpade * PokerConst.CardBitMask + PokerConst.kPokerPoint1
PokerConst.Spade2 = PokerConst.kPokerSuitSpade * PokerConst.CardBitMask + PokerConst.kPokerPoint2
PokerConst.Spade3 = PokerConst.kPokerSuitSpade * PokerConst.CardBitMask + PokerConst.kPokerPoint3
PokerConst.Spade4 = PokerConst.kPokerSuitSpade * PokerConst.CardBitMask + PokerConst.kPokerPoint4
PokerConst.Spade5 = PokerConst.kPokerSuitSpade * PokerConst.CardBitMask + PokerConst.kPokerPoint5
PokerConst.Spade6 = PokerConst.kPokerSuitSpade * PokerConst.CardBitMask + PokerConst.kPokerPoint6
PokerConst.Spade7 = PokerConst.kPokerSuitSpade * PokerConst.CardBitMask + PokerConst.kPokerPoint7
PokerConst.Spade8 = PokerConst.kPokerSuitSpade * PokerConst.CardBitMask + PokerConst.kPokerPoint8
PokerConst.Spade9 = PokerConst.kPokerSuitSpade * PokerConst.CardBitMask + PokerConst.kPokerPoint9
PokerConst.Spade10 = PokerConst.kPokerSuitSpade * PokerConst.CardBitMask + PokerConst.kPokerPoint10
PokerConst.SpadeJ = PokerConst.kPokerSuitSpade * PokerConst.CardBitMask + PokerConst.kPokerPointJ
PokerConst.SpadeQ = PokerConst.kPokerSuitSpade * PokerConst.CardBitMask + PokerConst.kPokerPointQ
PokerConst.SpadeK = PokerConst.kPokerSuitSpade * PokerConst.CardBitMask + PokerConst.kPokerPointK

PokerConst.Heart1 = PokerConst.kPokerSuitHeart * PokerConst.CardBitMask + PokerConst.kPokerPoint1
PokerConst.Heart2 = PokerConst.kPokerSuitHeart * PokerConst.CardBitMask + PokerConst.kPokerPoint2
PokerConst.Heart3 = PokerConst.kPokerSuitHeart * PokerConst.CardBitMask + PokerConst.kPokerPoint3
PokerConst.Heart4 = PokerConst.kPokerSuitHeart * PokerConst.CardBitMask + PokerConst.kPokerPoint4
PokerConst.Heart5 = PokerConst.kPokerSuitHeart * PokerConst.CardBitMask + PokerConst.kPokerPoint5
PokerConst.Heart6 = PokerConst.kPokerSuitHeart * PokerConst.CardBitMask + PokerConst.kPokerPoint6
PokerConst.Heart7 = PokerConst.kPokerSuitHeart * PokerConst.CardBitMask + PokerConst.kPokerPoint7
PokerConst.Heart8 = PokerConst.kPokerSuitHeart * PokerConst.CardBitMask + PokerConst.kPokerPoint8
PokerConst.Heart9 = PokerConst.kPokerSuitHeart * PokerConst.CardBitMask + PokerConst.kPokerPoint9
PokerConst.Heart10 = PokerConst.kPokerSuitHeart * PokerConst.CardBitMask + PokerConst.kPokerPoint10
PokerConst.HeartJ = PokerConst.kPokerSuitHeart * PokerConst.CardBitMask + PokerConst.kPokerPointJ
PokerConst.HeartQ = PokerConst.kPokerSuitHeart * PokerConst.CardBitMask + PokerConst.kPokerPointQ
PokerConst.HeartK = PokerConst.kPokerSuitHeart * PokerConst.CardBitMask + PokerConst.kPokerPointK

PokerConst.Club1 = PokerConst.kPokerSuitClub * PokerConst.CardBitMask + PokerConst.kPokerPoint1
PokerConst.Club2 = PokerConst.kPokerSuitClub * PokerConst.CardBitMask + PokerConst.kPokerPoint2
PokerConst.Club3 = PokerConst.kPokerSuitClub * PokerConst.CardBitMask + PokerConst.kPokerPoint3
PokerConst.Club4 = PokerConst.kPokerSuitClub * PokerConst.CardBitMask + PokerConst.kPokerPoint4
PokerConst.Club5 = PokerConst.kPokerSuitClub * PokerConst.CardBitMask + PokerConst.kPokerPoint5
PokerConst.Club6 = PokerConst.kPokerSuitClub * PokerConst.CardBitMask + PokerConst.kPokerPoint6
PokerConst.Club7 = PokerConst.kPokerSuitClub * PokerConst.CardBitMask + PokerConst.kPokerPoint7
PokerConst.Club8 = PokerConst.kPokerSuitClub * PokerConst.CardBitMask + PokerConst.kPokerPoint8
PokerConst.Club9 = PokerConst.kPokerSuitClub * PokerConst.CardBitMask + PokerConst.kPokerPoint9
PokerConst.Club10 = PokerConst.kPokerSuitClub * PokerConst.CardBitMask + PokerConst.kPokerPoint10
PokerConst.ClubJ = PokerConst.kPokerSuitClub * PokerConst.CardBitMask + PokerConst.kPokerPointJ
PokerConst.ClubQ = PokerConst.kPokerSuitClub * PokerConst.CardBitMask + PokerConst.kPokerPointQ
PokerConst.ClubK = PokerConst.kPokerSuitClub * PokerConst.CardBitMask + PokerConst.kPokerPointK

PokerConst.Diamond1 = PokerConst.kPokerSuitDiamond * PokerConst.CardBitMask + PokerConst.kPokerPoint1
PokerConst.Diamond2 = PokerConst.kPokerSuitDiamond * PokerConst.CardBitMask + PokerConst.kPokerPoint2
PokerConst.Diamond3 = PokerConst.kPokerSuitDiamond * PokerConst.CardBitMask + PokerConst.kPokerPoint3
PokerConst.Diamond4 = PokerConst.kPokerSuitDiamond * PokerConst.CardBitMask + PokerConst.kPokerPoint4
PokerConst.Diamond5 = PokerConst.kPokerSuitDiamond * PokerConst.CardBitMask + PokerConst.kPokerPoint5
PokerConst.Diamond6 = PokerConst.kPokerSuitDiamond * PokerConst.CardBitMask + PokerConst.kPokerPoint6
PokerConst.Diamond7 = PokerConst.kPokerSuitDiamond * PokerConst.CardBitMask + PokerConst.kPokerPoint7
PokerConst.Diamond8 = PokerConst.kPokerSuitDiamond * PokerConst.CardBitMask + PokerConst.kPokerPoint8
PokerConst.Diamond9 = PokerConst.kPokerSuitDiamond * PokerConst.CardBitMask + PokerConst.kPokerPoint9
PokerConst.Diamond10 = PokerConst.kPokerSuitDiamond * PokerConst.CardBitMask + PokerConst.kPokerPoint10
PokerConst.DiamondJ = PokerConst.kPokerSuitDiamond * PokerConst.CardBitMask + PokerConst.kPokerPointJ
PokerConst.DiamondQ = PokerConst.kPokerSuitDiamond * PokerConst.CardBitMask + PokerConst.kPokerPointQ
PokerConst.DiamondK = PokerConst.kPokerSuitDiamond * PokerConst.CardBitMask + PokerConst.kPokerPointK

PokerConst.BlackJoker = PokerConst.kPokerSuitNull * PokerConst.CardBitMask + PokerConst.kPokerPointBlack
PokerConst.RedJoker   = PokerConst.kPokerSuitNull * PokerConst.CardBitMask + PokerConst.kPokerPointRed

PokerConst.fromByteToSuitAndPoint = function(_cardByte)
    local suit = math.floor(_cardByte / PokerConst.CardBitMask)
    local point = _cardByte % PokerConst.CardBitMask
    return {suit = suit, point = point}
end

PokerConst.getCardValue = function(_cardByte)
    local suit = math.floor(_cardByte / PokerConst.cardBitMask)
    local value = _cardByte - suit * PokerConst.cardBitMask
    return value
end

PokerConst.getCardSuit = function(_cardByte)
    local suit = math.floor(_card / PokerConst.cardBitMask)
    return suit
end

PokerConst.getOpsValue = function(opList)
    local sum = 0
    if "table" ~= type(opList) then
        return sum
    end
    for _, v in pairs(opList) do
        sum = sum + calcBinaryLeftBiteValue(v)
    end
    return sum
end

PokerConst.tanslateCardsToValues = function(_cardList)
    local valueList = {}
    if #_cardList == 0 or not _cardList then
        return nil
    end
    for _, cardByte in ipairs(_cardList) do
        local card = PokerCard.new(cardByte)
        if card:isValid() then
            table.insert(valueList, cardByte)
        end
    end
    return valueList
end

return PokerConst