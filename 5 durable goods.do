local r 0.03  // real interest rate at time of survey
local pi 0.02 // typical inflation in years preceeding survey


/* ---- 1. Load and check data ---------------------------------------------- */

//  a. load data
use "${datain}\Section_D_durables.dta", clear
merge m:1 hhid using "${temp}\hh_char.dta", keepusing(hhweight)
keep if _m == 3
drop _merge

//  b. check data shape
tab d0
tab d1

//  c. missing observations
bys hhid: gen nitems = _N
bys hhid: gen hhtag = _n == 1
tab nitems if hhtag

//  d. check missing and 0 values
count if d0 == . // no missing item code
count if d1 == .
foreach var of varlist d2 d3 d4 d5 {
    di "`var'"
    count if `var' == . & d1 >= 1
    count if `var' == 0 & d1 >= 1
    count if `var' > 0 & `var' < . & d1 == 0 
    count if `var' < 0
}
// issues: a couple of negatives and 0 values in current value

//  e. keep only obs where the hh owns at least one item
keep if d1 > 0


/* ---- 2/3. Depreciation rates and use value ------------------------------- */

include "${frags}\durables_maxlife.do"


/* ---- 4. Check for outliers and 0 values ---------------------------------- */ 

//  a. identify outliers
gen logconsexp = log(consexp/d1)
flagout logconsexp [pw = hhweight], item(d0) z(3.5)

//  b. winsorize lower and upper outliers
replace consexp = d1 * exp(_min) if _flag == -1 
replace consexp = d1 * exp(_max) if _flag == 1 

//  c. 0 values
// assume these are very low value items and replace with lowest nonoutlier value
replace consexp = d1 * exp(_min) if consexp == 0

//  d. negative values
// treat as missing and winsorize
replace consexp = d1 * exp(_med) if consexp < 0

//  e. check
assert consexp > 0 & consexp < .
sum consexp, d


/* ---- 5. Form data and save ----------------------------------------------- */ 

// no need to annualize

//  b. define universal item code
gen item = 1200 + d0

//  c. deal with labels
forval i = 1/10 {
    lab def items1200 `=1200+`i'' "`: label (d0) `i''", add
}
lab val item items1200

//  d. save
keep hhid item consexp
gen source = 3 
save "${temp}\durables.dta", replace orphans
