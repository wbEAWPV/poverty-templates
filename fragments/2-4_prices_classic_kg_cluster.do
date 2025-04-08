// assume we have c1-c5 (classic form of data, quantity consumed from purchases and cost of purchases over recall period)
// use conversion factors and do prices per kg only
// constructs prices down to the level of the cluster=PSU if possible

//  a. keep observations from which we will construct prices
keep if (c2a > 0 & c2a < .) & inlist(c2b, 1, 2, 3) & (c3 > 0 & c3 < .) // keep only obs with all the information needed
drop if miss_inv_c2 | miss_inv_c3 // in addition, drop anything flagged as invalid in c2 or c3
gen lnexp = ln(c3)
flagout c3 [pw = hhweight], item(c0) z($lowz) // flag and don't use outliers in cost of purchases
keep if _flag == 0

//  b. merge in conversion factors
gen unit = c2b
merge m:1 c0 unit using "${datain}\conversion_factors.dta", keep(master match)
assert _merge == 3 if inlist(unit, 2, 3) // have all the factors we need

//  c. construct price per kg for each record of consumption from purchases
gen     qkg = c2a * kg_per_unit if inlist(unit, 2, 3)
replace qkg = c2a               if unit == 1
replace qkg = c2a/1000          if unit == 4
gen p = c3 / qkg
// could check for outliers in qkg and/or p and drop
assert p > 0 & p < .

//  d. define levels for aggregation and minimum number of observations needed
gen national = 1
local l0 national
local l1 urbrur quarter
local l2 admin1 quarter
local l3 admin1 urbrur quarter
local l4 admin1 admin2 urbrur quarter
local l5 psu

//  e. construct median price at each level of aggregation
gen x = 1  // to use with rawsum in collapse to count observations
forval i = 0/5 {
    preserve
    collapse (p50) p`i' = p (rawsum) N`i' = x [pw = hhweight], by(c0 `l`i'')
    assert p`i' != .
    tempfile f`i'
    save `f`i''
    restore
}

//  f. construct framework dataset of each psu-item
use `maindata', clear
keep c0 psu admin1 admin2 quarter urbrur
duplicates drop
fillin c0 psu // rectangularize the data set
sort psu _fillin
foreach var of varlist admin1-urbrur {
    by psu: replace `var' = `var'[1] if _fillin
}
tab c0

//  g. merge in prices at all levels
gen national = 1
forval i = 0/5 {
    merge m:1 c0 `l`i'' using `f`i'', nogen
}

//  h. take as the local price the price at the lowest level with the minimum # of obs
table c0, stat(mean N0) // number of obs at national level
assert p0 < .
gen ph = p0
forval i = 1/5 {
    replace ph = p`i' if p`i' < . & N`i' >= $minN_prices
}

//  i. tidy up and save
drop N0-N5 national _fillin
isid psu c0
assert ph > 0 & ph < .
drop p0
lab var ph "local (to PSU) price per kg"
des
save "${temp}\ph_classic_kg_cluster.dta", replace

//  j. check distribution of prices
if $draw graph box ph, over(c0, label(angle(90))) name(g1a, replace)
// with real data would have to concentrate on most important food items, and separate by order of magnitude of food prices

//  k. construct p0 as weighted mean of ph
use "${temp}\hh_char.dta", clear
collapse (sum) psuweight = hhweight, by(psu)
merge 1:m psu using "${temp}\ph_classic_kg_cluster.dta", assert(match)
collapse (mean) p0 = ph [pw = psuweight], by(c0)
lab var p0 "national price per kg"
save "${temp}\p0_classic_kg_cluster.dta", replace