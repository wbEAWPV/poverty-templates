local r 0.03  // real interest rate at time of survey
local pi 0.02 // typical inflation in years preceeding survey


/* ---- 1. Load and check data ---------------------------------------------- */

//  a. load data
use "${datain}\Section_D_durables.dta", clear
merge m:1 hhid using "${temp}\hh_char.dta", keepusing(hhweight)
keep if _m == 3
drop _merge
isid hhid d0

//  b. check data shape
tab d0

//  c. check key varaibles
tab d1, m
tab d2, m

count if d3 >= . // note: no dataset would have all of d3, d4 and d5 -- check the variables you have
count if d3 <= 0
sum d3, d

count if d4 >= .
count if d4 <= 0
sum d4, d

count if d5 >= .
count if d5 <= 0
sum d5, d


/* ---- 2. Flag missing and invalid values of key variables ----------------- */

//  a. number of durable goods owned
gen miss_inv_d1 = 0
replace miss_inv_d1 = 1 if d1 >= .
replace miss_inv_d1 = 2 if d1 < 0
replace miss_inv_d1 = 3 if d1 == 0
// no case 4 or 5 -- no minimum value, no need to be multiple of 5
replace miss_inv_d1 = 6 if inlist(d1, $specials)
tab miss_inv_d1
tab d1 if miss_inv_d1

//  b. "age" (length of time hh has owned)
gen miss_inv_d2 = 0
replace miss_inv_d2 = 1 if d2 >= .
replace miss_inv_d2 = 2 if d2 < 0
// no case 3, 4 or 5
replace miss_inv_d2 = 6 if inlist(d2, $specials)
replace miss_inv_d2 = 7 if d2 > 50 & !miss_inv_d2 // extra condition: assume no hh has been in existence for more than 50 years
tab miss_inv_d2
tab d2 if miss_inv_d2

//  c. current value, purchase price, replacement cost
foreach var of varlist d3 d4 d5 {
    sum `var', d
    gen miss_inv_`var' = 0
    replace miss_inv_`var' = 1 if `var' >= .
    replace miss_inv_`var' = 2 if `var' < 0 
    replace miss_inv_`var' = 3 if `var' == 0
    replace miss_inv_`var' = 4 if `var' > 0 & `var' < 50 // some threshold for smallest plausible transaction, can be item-dependent
    replace miss_inv_`var' = 5 if mod(`var', 5) != 0
    replace miss_inv_`var' = 6 if inlist(`var', $specials)
    tab miss_inv_`var'
    tab `var' if miss_inv_`var'
}

pause

/* ---- 3/4. Depreciation rates and use value (of single item) -------------- */

include "${frags}\5-34_durables_regression.do"


/* ---- 5. Winsorize outliers and impute median in single item use value ---- */ 

//  a. identify outliers
gen loguseval = log(useval)
flagout loguseval [pw = hhweight], item(d0) z($z)

//  b. winsorize lower and upper outliers
replace useval = exp(_min) if _flag == -1 
replace useval = exp(_max) if _flag == 1 

//  c. impute missing values 
replace useval = exp(_med) if useval >= .


/* ---- 6. Winsorize outliers and impute median in number of items owned ---- */ 

//  a. identify outliers
gen nitems = d1 if !miss_inv_d1
gen lognitem = log(nitems) 
flagout lognitem [pw = hhweight], item(d0) z($z)
tab nitems d0 if inlist(d0, 7, 10) // check those where p10=p90 -- ideally flagout would do this

//  b. winsorize upper outliers and impute missing
replace nitems = exp(_max) if _flag == 1 & !(inlist(d0, 7, 10) & d1 <= 3) // add extra clause for cases where p10=p90
replace nitems = exp(_med) if miss_inv_d1


/* ---- 7. Form data and save ----------------------------------------------- */ 

// no need to annualize

//  a. number of items owned * use value of single item
gen consexp = nitems * useval
assert consexp > 0 & consexp < .
gen logcons = log(consexp)
flagout logcons [pw = hhweight], item(d0) z($z) // should have very few or no outliers now

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
