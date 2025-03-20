//  a. get food consumption data and select relevant hhs and items
use "${temp}\food.dta", clear
merge m:1 hhid using `refpop', assert(master match) keep(match) nogen // keep only obs for hh in reference population
merge m:1 item using `itemlist', assert(master match) keep(match) nogen // keep only items in the basket -- this step is optional for cost-per-calorie

//  b. check we have data needed
cap des qkg 
if !_rc {
    di as err "quantities in kg have not been constructed, cannot do cost per calorie"
    di as err "using $prices prices"
    exit
}

//  c. merge in calories and construct cost per calorie
merge m:1 c0 using "${datain}\calories.dta", keep(match) nogen
gen calories = qkg * kcal_per_100g * 10
gen cost_per_cal = (consexp/365) / (calories/5) // consexp is annual.  qkg and calories are per 5 days
table item, stat(mean cost_per_cal)

//  d. plutocratic cost per calorie
mean cost_per_cal [aw = hhweight]

//  e. set food poverty based on target number of calories per day
local plf = 365 * $calories * r(table)[1,1]