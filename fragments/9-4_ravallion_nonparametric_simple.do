// simplification of Ravallions 1998 method

qui mean nonfcons [aw = hhweight] if inrange(welfare, `=`plf'*(1-$intrav/100)', `=`plf'*(1+$intrav/100)')
local lr_nf = r(table)[1,1]
qui mean nonfcons [aw = hhweight] if inrange(foodwel, `=`plf'*(1-$intrav/100)', `=`plf'*(1+$intrav/100)')
local ur_nf = r(table)[1,1]

local lr = `plf' + `lr_nf'
local ur = `plf' + `ur_nf'