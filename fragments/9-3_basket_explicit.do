//  a. get food consumption data and select relevant hhs and items
use "${temp}\food.dta", clear
des
merge m:1 hhid using `refpop', keep(match) nogen // keep only obs for hh in reference population
merge m:1 item using `itemlist', assert(master match) keep(match) nogen // keep only items in the basket

//  b. check have data required
cap des qkg
if _rc {
    di as err "quantities in kg have not been constructed, cannot do explicit basket construction"
    di as err "using $prices prices"
    exit
}

//  c. total quantity in kg, per capita per day
collapse (sum) qkg [pw = hhweight], by(c0)
gen pc_daily_qkg = qkg / `Nrefpop' / 7 // 7 is number of days in recall period
list

//  d. merge in calories and construct calories per capita per day initially
merge 1:1 c0 using "${datain}\calories.dta", assert(match using) keep(match) nogen
gen cal = pc_daily_qkg * kcal_per_100g * 10
list
total cal

//  e. scale up for target number of calories
local factor = $calories / r(table)[1,1] // factor by which we need to scale up
replace pc_daily_qkg = pc_daily_qkg * `factor'
replace cal = cal * `factor'
total cal // double check

//  f. merge in prices to cost
merge 1:1 c0 using "${temp}\p0_$prices.dta", assert(match using) keep(match) nogen
gen cost = pc_daily_qkg * p0
gen per_cal = cost/cal
list c0 pc_daily_qkg cal p0 cost per_cal
total cost
local plf = 365 * r(table)[1,1]