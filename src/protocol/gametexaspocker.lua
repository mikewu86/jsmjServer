--  servicer handler (5xx-6xx)
local prototexaspocker = {}

prototexaspocker.types = [[
.roundResultItem {
        chipsDelta 0 : integer
        pos 1 : integer
        uid 2 : integer
        cardGroupType 3 : integer
}

]]



prototexaspocker.c2s = [[
    
playcard 501 {
		request {
                card 0 : *integer
        }
}
    
]]

prototexaspocker.s2c = [[
    
playcardNotify 601 {
		request {
				uid 0 : integer
                card 1 : *integer
        }
}

addHandCards_Not  602{
		request {
				uid 0 : integer
				card 1 : *integer
		}
}

addHandCards_Broadcast 603 {
		request {
				uid 0 : integer
				card 1 : *integer
		}
}

addDeskCards_Not 604{
		request {
			card 0 : *integer
		}
}

playerOperation_Not 605 {
		request {
			uid 0 : integer
			operation 1 :  integer
			betSum 2  :  integer
		}
}

minBetCount_Not     606 {
		request {
			MinBet 0 : integer 		  
		}
}

enableOperation_Not 607{
		request {
			operation 0 :  integer
			operationSeq 1 :  integer
		}
}

showTimer_Not 608{
		request {
			uid 0 : integer
			seconds 1 : integer
		}
}

roundResult_Not 609{
		request {
		    details 0 : *roundResultItem
		    bestCards 1 : *integer
			bestCardsPos 2 : integer
		}
}

]]

return prototexaspocker
