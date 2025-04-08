/* -------------------------------------------------------------------------- */
/*          A. General Food                                                   */
/* -------------------------------------------------------------------------- */

/* ---- 1. Load and check data ---------------------------------------------- */

//  a. load data
use "${datain}\section_C_food.dta", clear
merge m:1 hhid using "${temp}\hh_char.dta", keepusing(quarter hhsize hhweight urbrur admin1 admin2 psu) 
// note: not all hhs in food data in this version
keep if _m == 3
drop _m
isid hhid c0

//  b. check data shape
tab c0
tab c1, m

//  c. check of quantities and units
sum c2a, d
sum c4a, d
sum c7a, d
tab c0 c2b 
tab c0 c4b
tab c0 c7b
tabstat c2a, by(c2b) s(min p10 p25 p50 p75 p90 max)
tabstat c4a, by(c4b) s(min p10 p25 p50 p75 p90 max)
tabstat c7a, by(c7b) s(min p10 p25 p50 p75 p90 max)

//  d. expenditure amounts
sum c3, d
sum c5, d
sum c8, d

//  e. second filter question
tab c6, m
egen nvars = rownonmiss(c7a c7b c8)
tab nvars c6 // based on this, check the specific case below:
list c7a-c8 if c6 == 2 & nvars == 1 
replace c8 = .a if c8 == 9999 & c6 == 2 // a rare case where it is totally fine to replace the original variable -- still prefer to use extended missing values


/* ---- 2. Identify missing and invalid values in quantities/units ---------- */

// doing this with real data, you could use asserts to verify that certain issues don't occur in your data, and 
// then just focus on flagging those that do. 
// most real datasets would not have all these variables as well

// in this dataset, there are no filter questions "did the hh consume from purchases" or "did the hh consume from own production"
count if c2a == 0 & c4a == 0 // these are errors, but can't know for sure if from consumption or purchase or both
gen miss_inv_c24 = (c2a == 0 & c4a == 0)

//  a. identify missing values and invalid 0s in c2a/b and c4a/b
gen miss_inv_c2 = 0
replace miss_inv_c2 = 1 if c2a >= . // quantity should never be missing
replace miss_inv_c2 = 1 if c2b >= . & c2a != 0 // unit should not be missing if quantity is nonzero
replace miss_inv_c2 = 3 if c2a == 0 & c2b > .  // 0 quantity but nonmissing unit
gen miss_inv_c4 = 0
replace miss_inv_c4 = 1 if c4a >= . // quantity should never be missing
replace miss_inv_c4 = 1 if c4b >= . & c4a != 0 // unit should not be missing if quantity is nonzero
replace miss_inv_c4 = 3 if c4a == 0 & c4b > .   // 0 quantity by nonmissing unit

//  b. identify missing values and invalid 0s in c7a/b
gen miss_inv_c7 = 0
replace miss_inv_c7 = 1 if (c7a >= . | c7b >= .) & c6 == 1
replace miss_inv_c7 = 3 if c7a == 0 & c6 == 1

//  c. identify truly invalid values, improbably low or high quantities, invalid item-unit combos
foreach i of numlist 2 4 7 {
    di "---"
    replace miss_inv_c`i' = 2 if c`i'a < 0                                      // negative quantities
    replace miss_inv_c`i' = 2 if !inlist(c`i'b, 1, 2, 3, 4) & c`i'b < .         // invalid unit codes
    replace miss_inv_c`i' = 5 if inlist(c`i'b, 2, 3) & floor(c`i'a) != c`i'a    // fractional heaps/cups

    // ad hoc bounds, could do more robustly via flagout
    replace miss_inv_c`i' = 8 if inlist(c`i'b, 1, 2, 3) & c`i'a > 50 & c`i'a < .    // max of 50 for cups, heaps or kg
    replace miss_inv_c`i' = 8 if c`i'b == 4 & c`i'a > 5000 & c`i'a < .              // max of 5000 for mg = 5 kg
    replace miss_inv_c`i' = 4 if c`i'b == 1 & c`i'a < 0.1 & c`i'a > 0               // min of 0.1 for kg
    replace miss_inv_c`i' = 4 if inlist(c`i'b, 2, 3) == 1 & c`i'a < 1 & c`i'a > 0   // min of 1 for cup or heap
    replace miss_inv_c`i' = 4 if c`i'b == 4 & c`i'a < 5 & c`i'a > 0                 // min of 5 for mg

    replace miss_inv_c`i' = 6 if inlist(c`i'a, $specials)

    replace miss_inv_c`i' = 7 if inlist(c0, 10, 11) & c`i'b == 2 // say these two items can't be measured in heaps
}

tab1 miss_inv*
// with real data, the highish number of obs with more than 50 cups or 50 heaps for own production could be cause for concern


/* ---- 3. Identify missing and invalid expenditures/values of consumption -- */

//  a. truly missing values
gen miss_inv_c3 = 0
replace miss_inv_c3 = 1 if c3 >= . & c2a > 0 & c2b < .

gen miss_inv_c5 = 0
replace miss_inv_c5 = 1 if c5 >= . & c4a > 0 & c4b < .

gen miss_inv_c8 = 0
replace miss_inv_c8 = 1 if c8 >= . & c6 == 1

foreach i of numlist 3 5 8 {
    di "---"
    replace miss_inv_c`i' = 2 if c`i' == 0 // should never be 0
    replace miss_inv_c`i' = 3 if c`i' < 0  // should never be negative
    replace miss_inv_c`i' = 4 if c`i' > 0 & c`i' < 50 // set 50 as smallest transaction
    replace miss_inv_c`i' = 5 if mod(c`i', 5) != 0 & c`i' < .
    replace miss_inv_c`i' = 6 if inlist(c`i', $specials)
}

tab1 miss_inv_c3 miss_inv_c5 miss_inv_c8


/* ---- 4. Prices ----------------------------------------------------------- */
//  almost certainly need to do something for prices (for deflators, basket) even if using self-reports in 4

tempfile maindata
save `maindata'
include "${frags}\2-4_prices_$prices.do"



/* ---- 5. Consumption ------------------------------------------------------ */

use `maindata', clear
include "${frags}\2-5_food_valuation_$prices.do"
//include "${frags}\2-5_food_selfreport.do"


/* ---- 6. Indentification and treatment of outliers and missing/invalid ---- */

gen adm1ur = admin1*10 + urbrur // extra variable for outlier detection / winsorization / imputation

//  a. a few additional missing where hh said consumed but both quants 0
// consumption for each item more likely from purchases or own production?
gen more_purch = c2a > 0 & c2a < . if !(c2a > 0 & c4a > 0)
bys c0: egen item_more_purch = wpctile(more_purch), w(hhweight)
replace miss_inv_consexp1 = 9 if miss_inv_c24 & item_more_purch // flag to impute value of consumption from purchases
replace miss_inv_consexp2 = 9 if miss_inv_c24 & !item_more_purch // flag to impute value of consumption from own product

//  b. missing and upper outliers
forval i = 1/2 {
    di _n _n "****"
    gen lpccons`i' = log(consexp`i'/hhsize) 
    flagout lpccons`i' [pw = hhweight], item(c0) z($z) over(admin1 urbrur adm1ur)
    table c0 _flag, stat(min consexp`i') stat(max consexp`i') nototal nformat(%12.0fc)
    replace consexp`i' = hhsize * exp(_max) if _flag == 1            // winsorize upper outliers
    replace consexp`i' = hhsize * exp(_med) if miss_inv_consexp`i'   // imput missing or invalid values
}


/* ---- 7. Form data -------------------------------------------------------- */

//  aa. reshape
keep consexp* hhid c0 q*
reshape long consexp qkg, i(hhid c0) j(source)
lab def sources 1 "purchases" 2 "own production" 3 "constructed use value" 4 "imputed rent"
lab val source sources
drop if consexp == .

//  a. annualize
replace consexp = consexp * 365/7 // assume 1 week recall period

//  b. define universal item code
gen item = c0

//  c. deal with labels on new item code
label copy foods items
lab val item items

//  d. distinguish between food and not actually food
// alcohol, tobacco, traditional narcotics that can be home produced are often on food section
// occaisonally other home produced goods like firewood
recode c0 (1/17 = 1 "food general") (18/20 = 3 "nonfood") (99 = 2 "FAFH"), gen(class)

//  d. save
des
save "${temp}\food.dta", replace 


/* ---- 8. Quick check ------------------------------------------------------ */

table item source, stat(p50 consexp)

collapse (sum) consexp, by(hhid)
sum consexp, d
gen logcons = log(consexp)
if $draw histogram logcons, normal // less normal than you would expect with real data



/* -------------------------------------------------------------------------- */
/*          B. Food Away from Home                                            */
/* -------------------------------------------------------------------------- */

// to be written
