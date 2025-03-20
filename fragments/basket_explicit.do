use "${temp}\food.dta", clear
merge m:1 hhid using `refpop', assert(master match) keep(match) nogen // keep only obs for hh in reference population
merge m:1 item using `itemlist', assert(master match) keep(match) nogen // keep only items in the basket

// total quantity when have qkg
collapse (sum) qkg [aw = hhweight], by(c0)
gen pc_daily_qkg = qkg / `Nrefpop' / 7 // 7 is number of days in recall period
list
merge 1:1 c0 using "${datain}\calories.dta", assert(match using) keep(match) nogen
gen cal = pc_daily_qkg * kcal_per_100g * 10
total cal
local factor = $calories / r(table)[1,1] // factor by which we need to scale up
replace pc_daily_qkg = pc_daily_qkg * `factor'
replace cal = cal * `factor'
total cal // double check

// merge in prices
merge 1:1 c0 using "${temp}\p0_classic_kg_cluster.dta", assert(match using) keep(match) nogen
gen cost = pc_daily_qkg * p0
gen per_cal = cost/cal
list c0 pc_daily_qkg cal p0 cost per_cal
total cost
local plf = 365 * r(table)[1,1]