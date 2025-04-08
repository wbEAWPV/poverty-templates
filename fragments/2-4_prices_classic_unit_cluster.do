// assume we have c1-c5 (classic form of data, quantity consumed from purchases and cost of purchases over recall period)
// construct prices separately for each unit
// constructs prices down to the level of the cluster=PSU if possible

//  a. keep observations from which we will construct prices
drop if miss_inv_c2 | miss_inv_c3 // in addition, drop anything flagged as invalid in c2 or c3
gen lnexp = ln(c3)
flagout c3 [pw = hhweight], item(c0) z($lowz)
keep if _flag == 0

//  c. construct price per unit for each record of consumption from purchases
gen p = c3 / c2a
// could check for outliers in p and drop
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
gen x = 1 // to use with rawsum in collapse to count observations
forval i = 0/5 {
    preserve
    collapse (p50) p`i' = p (rawsum) N`i' = x [pw = hhweight], by(c0 c2b `l`i'')
    rename c2b unit
    assert p`i' != .
    tempfile f`i'
    save `f`i''
    restore
}

//  f. construct framework dataset of each psu-item-unit
use `maindata', clear
replace c2b = . if miss_inv_c2 == 7 // remove invalid item-unit combinations
replace c4b = . if miss_inv_c4 == 7
keep admin1 admin2 urbrur quarter psu hhid c0 c2b c4b 
rename (c2b c4b) (unit1 unit2)
reshape long unit, i(hhid c0) j(source)
drop hhid source
drop if unit == .
tab c0 unit
duplicates drop
tab c0 unit // up to 1000 obs each cell

gen item_unit = c0*10 + unit
fillin item_unit psu // rectangularize the data set 
replace c0 = floor(item_unit/10) if _fillin
replace unit = mod(item_unit, 10) if _fillin
drop item_unit
gsort psu _fillin
foreach var of varlist admin1-urbrur {
    by psu: replace `var' = `var'[1] if _fillin
}
tab c0 unit // 1000 obs (one per cluster) for each possible item-unit combination

//  g. merge in prices at all levels
gen national = 1
forval i = 0/5 {
    merge m:1 c0 unit `l`i'' using `f`i'', nogen
}

//  h. take as the local price the price at the lowest level with the minimum # of obs
table c0, stat(mean N0) // number of obs at national level
table c0 unit if p0 >= .
drop if p0 >= .
gen ph = p0
forval i = 1/5 {
    replace ph = p`i' if p`i' < . & N`i' >= $minN_prices
}

//  i. tidy up and save
drop N0-N5 national _fillin
isid psu c0 unit
assert ph > 0 & ph < .
lab var p0 "national median price per unit"
lab var ph "local (to PSU) price per unit"
des
save "${temp}\ph_classic_unit_cluster.dta", replace

if $draw {
    graph box ph if unit == 1, over(c0, label(angle(90))) name(g2a, replace)
    // with real data would have to concentrate on most important food items, and separate by order of magnitude of food prices
    graph box ph if unit == 2, over(c0, label(angle(90))) name(g2b, replace)
    graph box ph if unit == 3, over(c0, label(angle(90))) name(g2c, replace)
}