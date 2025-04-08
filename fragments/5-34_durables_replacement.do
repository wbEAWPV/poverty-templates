// M&V formula if you have replacement cost (current cost of new item)
drop d4 // assume we don't have purchase price

/* ---- 2. Depreciation rates ----------------------------------------------- */

//  a. outliers to exclude from construction of depreciation rates
gen logd3 = log(d3) if !miss_inv_d3
flagout logd3 [pw = hhweight], item(d0) z($lowz)
rename _flag flag3

gen logd5 = log(d5) if !miss_inv_d5
flagout logd5 [pw = hhweight], item(d0) z($lowz)
rename _flag flag5

gen include = (!miss_inv_d2) & flag3 == 0 & flag5 == 0

//  b. depreciation for each item
gen age = d2
replace age = 0.5 if d2 == 0 // for items with age given as 0 years, assume age is 6 months
gen delta = 1 - (d3/d5)^(1/age) if include

//  c. median depreciation by item type
bys d0: egen delta_med = pctile(delta), p(50)
table d0, stat(mean delta_med)

//  d. check delta is in possible range
assert delta_med > 0 & delta_med < 1
count if delta_med < 0.05 | delta_med > 0.5
if r(N) > 0 di as error "highly unlikely depreciation rates generated (less than 5% or more than 50%)"


/* ---- 3. Construct use value ---------------------------------------------- */

gen useval = d3 * (`r' + delta_med) if !miss_inv_d3  // only for most recent item
