

/* ---- 2. Depreciation rates ----------------------------------------------- */

//  a. outliers to exclude from construction of depreciation rates
flagout d2 [pw = hhweight], item(d0) z(2.5)
rename _flag flag1
drop _min _max _median
gen logd3 = log(d3)
flagout logd3 [pw = hhweight], item(d0) z(2.5)
rename _flag flag2
drop _min _max _median
gen include = flag1 == 0 & flag2 == 0

//  b. regressions
gen lnval = ln(d3)
gen beta = .
gen signif = .
qui levelsof d0, local(items)
foreach i of local items {
	di _n _n "`: label durables `i''"
	reg lnval d2 [pw = hhweight] if d0 == `i' & include
	qui replace beta = e(b)[1,1] if d0 == `i'
	qui replace signif = abs(beta/sqrt(e(V)[1,1])) > 1.645 if d0 == `i'
}
table d0, stat(mean signif)

//  c. define depreciation rates
gen delta_regress = 1 - exp(beta)
tabstat delta_regress, by(d0) 

//  d. adjust any negative or nonsignificant rates
sum delta_regress if signif & delta_regress > 0 [aw = hhweight]
replace delta_regress = r(mean) if !signif
replace delta_regress = r(mean) if delta_regress < 0

//  3. check delta is in possible range
assert delta_regress > 0 & delta_regress < 1


/* ---- 3. Construct use value ---------------------------------------------- */

gen consexp = d1 * d3 * (`r' + delta_regress) 
