// estimate alpha (share of food in total consumption) directly
qui mean alpha [aw = hhweight] if inrange(welfare, `=`plf'*(1-$intrav/100)', `=`plf'*(1+$intrav/100)')
local la = r(table)[1,1]
qui mean alpha [aw = hhweight] if inrange(foodwel, `=`plf'*(1-$intrav/100)', `=`plf'*(1+$intrav/100)')
local ua = r(table)[1,1]

local lr = (2 - `la') * `plf'
local ur = `plf' / `ua'