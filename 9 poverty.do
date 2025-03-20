/* ---- 1. Construct welfare measure ---------------------------------------- */

//  a. use nominal consumption aggregate data and other hh chars
use "${temp}\nca.dta", clear
merge 1:1 hhid using "${temp}\hh_char_def.dta", assert(match) nogen

//  b. construct welfare and food welfare
gen welfare = consexp/deflator_joint/hhsize 
gen foodwel = foodcons/deflator_joint/hhsize
tabstat welfare foodwel [aw = hhweight], stat(min p10 p25 med p75 p90 max)

//  c. construct deciles based on welfare
xtile decile = welfare [aw = hhweight * hhsize], n(10)

//  d. check Engels
gen alpha = foodcons/consexp
table decile urbrur [aw = hhweight], stat(mean alpha)


tempfile allhhs
save `allhhs'


/* ---- 2. Preliminary to food poverty line definition ---------------------- */

//  a. define reference population
keep if inrange(decile, $min_decile, $max_decile)
total hhsize
local Nrefpop = r(table)[1,1]
tempfile refpop
save `refpop'

//  b. select items for basket
// if using cost per calorie, could skip this step, as long as you are properly accounting for items without calorie values
use "${temp}\food.dta", clear 
drop if class != 1 // drop nonfood items and FAFH
merge m:1 hhid using `refpop', keep(match) nogen // keep only obs for hh in reference population
// drop FAFH unless we have it with enough granularity to have calorie values
collapse (sum) consexp [pw = hhweight], by(item)
egen item_total = total(consexp)
gen share = consexp / item_total
replace share = 0 if inlist(item, 13) // items without calorie values or can't be in basket for other reasons
gsort -share
gen cumul_share = sum(share)
gen prev_share = cumul_share[_n-1]
list
keep if prev_share < $minshare | _n == 1 // keep items so that cumulative share is at least target
total share
keep item
tempfile itemlist
save `itemlist'


/* ---- 3. Food poverty line ------------------------------------------------ */
// basket explicit and cost-of-calories require you to have constructed quantities

include "${frags}\9-3_basket_explicit.do"
di `plf'


/* ---- 4. Nonfood component ------------------------------------------------ */

// Ravallion for nonfood component
use `allhhs', clear
gen foodpovline = `plf'
lab var foodpovline "food povery line"
sum foodpovline

include "${frags}\9-4_ravallion_alpha.do"

if $ravallion == 1  gen povline_total = `lr'
if $ravallion == 2  gen povline_total = (`lr' + `ur')/2
if $ravallion == 3  gen povline_total = `ur'

sum povline_total


/* ---- 5. Basic summary stats ---------------------------------------------- */

gen poor = welfare < povline
table admin1 urbrur [aw = hhweight*hhsize], stat(mean poor)