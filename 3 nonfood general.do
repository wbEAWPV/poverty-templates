
/* ---- 1. Load and check data ---------------------------------------------- */

//  a. load data
use "${datain}\Section_B_nonfood.dta", clear
merge m:1 hhid using "${temp}\hh_char.dta", keepusing(hhweight hhsize admin1 urbrur)
keep if _m == 3
drop _m
isid hhid b0

//  b. check data shape
tab b0
tab b1, m // only have observations where hh purchased

//  c. inspect key variables
count if b2 >= . 
count if b2 <= 0 
sum b2, d

//  d. discard observations that don't count as household consumption
// do based on actual item list, what is too lumpy, what is included elsewhere, what isn't consumption etc
drop if inlist(b0, 5, 7)


/* ---- 2. Flag missing and invalid values of b2 ---------------------------- */

sum b2, d
gen miss_inv = 0
replace miss_inv = 1 if b2 >= .
replace miss_inv = 2 if b2 < 0 
replace miss_inv = 3 if b2 == 0
replace miss_inv = 4 if b2 > 0 & b2 < 50 // some threshold for smallest plausible transaction, can be item-dependent
replace miss_inv = 5 if mod(b2, 5) != 0
replace miss_inv = 6 if inlist(b2, $specials)
tab miss_inv
tab b2 if miss_inv


/* ---- 3. Consumption ------------------------------------------------------ */

gen consexp = b2 if !miss_inv


/* ---- 4. Indentification and treatment of outliers and missing/invalid ---- */

gen lpccons = log(consexp/hhsize) 
gen adm1ur = admin1*10 + urbrur
flagout lpccons [pw = hhweight], item(b0) z($z) over(admin1 urbrur adm1ur)
table b0 _flag, stat(min b2) stat(max b2) nototal nformat(%12.0fc)
replace consexp = hhsize * exp(_max) if _flag == 1
replace consexp = hhsize * exp(_med) if miss_inv


/* ---- 5. Form data -------------------------------------------------------- */

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
