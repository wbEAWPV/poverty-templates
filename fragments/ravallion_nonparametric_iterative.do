// this is the nonparametric method originally suggested by Ravallion in his 1998 paper, with intrav = 10

local lr_nf = 0
local ur_nf = 0
forval i = 1/$intrav {
    qui mean nonfcons [aw = hhweight] if inrange(foodwel, `=`plf'*(1-`i'/100)', `=`plf'*(1+`i'/100)')
    local lr_nf = `lr_nf' + r(table)[1,1]
    qui mean nonfcons [aw = hhweight] if inrange(welfare, `=`plf'*(1-`i'/100)', `=`plf'*(1+`i'/100)')
    local ur_nf = `ur_nf' + r(table)[1,1]
}
local lr_nf = `lr_nf'/$intrav
local ur_nf = `ur_nf'/$intrav

local lr = `plf' + `lr_nf'
local ur = `plf' + `ur_nf'