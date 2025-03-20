
/* ---- 1. Load and check data ---------------------------------------------- */

//  a. load data
use "${datain}\Section_B_nonfood.dta", clear
merge m:1 hhid using "${temp}\hh_char.dta", keepusing(hhweight hhsize admin1 urbrur)
keep if _m == 3
drop _m
isid hhid b0

//  b. check data shape
tab b0
tab b1
// have observations where hh bought and where it didn't
// have some missing observations

//  c. missing observations
bys hhid: gen nitems = _N
bys hhid: gen hhtag = _n == 1
tab nitems if hhtag
// just a few, seem very random

//  d. check missing and 0 values
count if b0 == . // no missing item code
count if b1 == .
count if b2 == . & b1 == 1
count if b2 == 0 & b1 == 1
count if b2 > 0 & b2 < . & b1 == 2 // none -- highly unlikely with CAPI systems


/* ---- 2. Address missing observations and missing filter questions -------- */

//  a. rectangularize data
// may or may not want to do this.  here we seem to have all items for all hhs except a handful of cases, so we are assuming these were lost at random
fillin hhid b0
tab _fillin
gsort hhid _fillin
foreach var of varlist admin1 urbrur hhweight hhsize {
    by hhid: replace `var' = `var'[1] if `var' == .
}

//  a. whether or not hhs in each admin1-urbrur bought each item on average
bys b0 admin1 urbrur: egen med_b1 = wpctile(b1), p(50) w(hhweight)
count if b1 == .

//  b. missing values of the filter question (including for filled in observations)
gen bought = b1
replace bought = med_b1 if bought == .


/* ---- 3. Consumption ------------------------------------------------------ */

keep if bought == 1
gen consexp = b2


/* ---- 4. Lower outliers --------------------------------------------------- */

table b0, stat(min consexp)
// decide less than 1 LCU is not plausible, will treat 0 as mising
replace consexp = 1 if consexp < 1 & consexp > 0 


/* ---- 5. Upper outliers --------------------------------------------------- */

gen lpccons = log(consexp/hhsize) 
flagout lpccons [pw = hhweight], item(b0) z(3.5) over(admin1 urbrur)
replace consexp = hhsize * exp(_max) if _flag == 1


/* ---- 6. Missing values --------------------------------------------------- */

replace consexp = hhsize * exp(_med) if consexp == .
replace consexp = hhsize * exp(_med) if consexp == 0


/* ---- 7. Form data -------------------------------------------------------- */

//  a. annualize
replace consexp = consexp * 12 // assume 1 month recall period

//  b. define universal item code
gen item = 1000 + b0

//  c. deal with labels on new item code
forval i = 1/10 {
    lab def items1000 `=1000+`i'' "`: label (b0) `i''", add
}
lab val item items1000

//  d. save
keep hhid item consexp
gen source = 1
save "${temp}\nonfood_basic.dta", replace 
