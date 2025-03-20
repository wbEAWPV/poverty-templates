
/* ---- 2. Depreciation rates ----------------------------------------------- */

//  a. outliers to exclude from construction of depreciation rates
// median construction is quite robust, not a big concern
flagout d2 [pw = hhweight], item(d0) z(2.5)  // assumes age is normally distributed, might want to assume it has some other distribution
rename _flag flag1
drop _min _max _median
gen logd3 = log(d3)
flagout logd3 [pw = hhweight], item(d0) z(2.5)
rename _flag flag2
drop _min _max _median
gen logd4 = log(d4)
flagout logd4 [pw = hhweight], item(d0) z(2.5)    // need to flag outliers in purchase price
rename _flag flag3
drop _min _max _median
gen include = flag1 == 0 & flag2 == 0 & flag3 == 0

//  b. depreciation for each item
gen age = d2
replace age = 0.5 if d2 == 0 // for items with age given as 0 years, assume age is 6 months
gen replacement_cost = d4 * (1 + `pi')^age         // construct replacement cost from purchase price and inflation since
gen delta = 1 - (d3/replacement_cost)^(1/age) if include

//  c. median depreciation by item type
bys d0: egen delta_med = pctile(delta), p(50)
table d0, stat(mean delta_med)

//  d. check delta is in possible range
assert delta_med > 0 & delta_med < 1


/* ---- 3. Construct use value ---------------------------------------------- */

gen consexp = d1 * d3 * (`r' + delta_med) 
