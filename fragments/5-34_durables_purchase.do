// M&V formula if you have purchase price (more common than replacement value)
drop d5 // assume we don't have replacement value in our dataset

/* ---- 2. Depreciation rates ----------------------------------------------- */

//  a. outliers to exclude from construction of depreciation rates
// median construction is quite robust, not a big concern
gen logd3 = log(d3) if !miss_inv_d3
flagout logd3 [pw = hhweight], item(d0) z($lowz)
rename _flag flag3

gen logd4 = log(d4) if !miss_inv_d4
flagout logd4 [pw = hhweight], item(d0) z($lowz) 
rename _flag flag4

gen include = (!miss_inv_d2) & flag3 == 0 & flag4 == 0

//  b. depreciation for each item
gen age = d2 
replace age = 0.5 if d2 == 0 // for items with age given as 0 years, assume age is 6 months
gen replacement_cost = d4 * (1 + `pi')^age         // construct replacement cost from purchase price and inflation since
gen delta = 1 - (d3/replacement_cost)^(1/age) if include
// can also implemented as 
// gen delta = 1 - (d3/d4)^(1/age) + `pi' if include // linearizes impact of inflation, very similar except in very high inflation contexts

//  c. median depreciation by item type
bys d0: egen delta_med = pctile(delta), p(50)
table d0, stat(mean delta_med)

//  d. check delta is in possible range
assert delta_med > 0 & delta_med < 1
count if delta_med < 0.05 | delta_med > 0.5
if r(N) > 0 di as error "highly unlikely depreciation rates generated (less than 5% or more than 50%)"


/* ---- 3. Construct use value ---------------------------------------------- */

gen useval = d3 * (`r' + delta_med) if !miss_inv_d3  // just for most recently acquired item
