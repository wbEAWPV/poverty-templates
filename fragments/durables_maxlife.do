
/* ---- 2. Maximum life span ------------------------------------------------ */

//  a. flag outliers in age to exclude from construction of maximum life
// setting higher limit because the maximum or high percentile is the statistic of interest
gen logage = log(d2)
replace logage = log(0.5) if d2 == 0
flagout logage [pw = hhweight], item(d0) z(3.5)
gen nonout_d2 = d2 if _flag == 0
drop _flag _min _max _med

//  b. max life by item type, defined as 99th pctile
bys d0: egen max_life = pctile(nonout_d2), p(99)


/* ---- 3. Construct use value ---------------------------------------------- */

//  a. years of life left
gen years_remaining = max_life - d2
sum years_remaining, d
replace years_remaining = 2 if years_remaining < 2

//  b. use value
gen consexp = d1 * d3/years_remaining
