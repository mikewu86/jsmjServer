--- base poker type
--- if other type, sub class added.
--- if details is diff, sub class is called.
--- here by guan poker
--- input: cardByte
--- output: card type or compare result.
--- function: judge card type, and return compare result.
--- author: zhangyl
--- date: 2016/12/29 16:35
local cardType = require("common.pokerConst").cardType
local baseType = class("baseType")

function baseType:ctor(_pokerCard)
    self.pokerCard = _pokerCard
    self.tbJudgeFuncMap = {}
    self:init()
end

function baseType:init()
    self.tbJudgeFuncMap[cardType.Single] = self.judgeSingle
    self.tbJudgeFuncMap[cardType.Couple] = self.judgeCouple
    self.tbJudgeFuncMap[cardType.Three]  = self.judgeThree
    self.tbJudgeFuncMap[cardType.ThreeTwo] = self.judgeThreeTwo
    self.tbJudgeFuncMap[cardType.SisterCouple] = self.judgeSisterCouple
    self.tbJudgeFuncMap[cardType.Junko]  = self.judgeJunko
    self.tbJudgeFuncMap[cardType.Bump]  = self.judgeBump
end

function baseType:judgeSingle(cards)

end

function baseType:judgeCouple(cards)

end

function baseType:judgeThree(cards)

end

function baseType:judgeThreeTwo(cards)

end

function baseType:judgeSisterCouple(cards)

end

function baseType:judgeJunko(cards)

end

function baseType:judgeBump(cards)

end
return baseType 
