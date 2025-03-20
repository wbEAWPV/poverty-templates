/* -------------------------------------------------------------------------- */
/*          A. General Food                                                   */
/* -------------------------------------------------------------------------- */

/* ---- 1. Load and check data ---------------------------------------------- */

//  a. load data
use "${datain}\section_C_food.dta", clear
merge m:1 hhid using "${temp}\hh_char.dta", keepusing(quarter hhsize hhweight urbrur admin1 admin2 psu) 
// note: all hhs in food data in this version
keep if _m == 3
drop _m
isid hhid c0

//  b. check data shape
tab c0
tab c1, m
tab c6 if c1 == 1, m
// no issues

//  d. check missing values in filter
count if c0 == . // no missing item code
count if c1 == .
count if c6 == . & c1 == 1
// no missing in filter questions

//  e. check of nonmissing behind filter
egen x1 = rownonmiss(c2a-c8)
count if x1 > 0 & c1 == 2
egen x2 = rownonmiss(c7a-c8)
count if x2 > 0 & c6 == 2
// no issues

//  f. check of key variables
assert c3 >= 0
assert c5 >= 0


/* ---- 2. Address missing observations and missing filter questions -------- */

//  nothing to do for this dataset

bys hhid: egen items_consumed = total(c1 == 1)
bys hhid: gen hhtag = _n == 1
tab items_consumed if hhtag
// 68 hhs with no food consumption

keep if c1 == 1


/* ---- 3. Prices ----------------------------------------------------------- */

tempfile maindata
save `maindata'
include "${frags}\prices_classic_kg_cluster.do"


/* ---- 4. Consumption ------------------------------------------------------ */

use `maindata', clear
include "${frags}\food_valuation_classic_kg_cluster.do"



/* ---- 5. Lower outliers --------------------------------------------------- */

//  a. look at lowest values
table c0, stat(min consexp1 consexp2)
// winsorize these 

//  b. flag outliers in consexp1
gen lpccons1 = log(consexp1/hhsize) 
flagout lpccons1 [pw = hhweight], item(c0) z(3.5) over(admin1 urbrur)
rename (_flag _max _min _median) =1

//  c. flag outliers in consexp2
gen lpccons2 = log(consexp2/hhsize) 
flagout lpccons2 [pw = hhweight], item(c0) z(3.5) over(admin1 urbrur)
rename (_flag _max _min _median) =2

//  d. winsorize lower outliers and negative values in both
replace consexp1 = hhsize * exp(_min1) if _flag1 == -1 
replace consexp1 = hhsize * exp(_min1) if consexp1 < 0
replace consexp2 = hhsize * exp(_min2) if _flag2 == -1 
replace consexp2 = hhsize * exp(_min2) if consexp2 < 0


/* ---- 6. Upper outliers --------------------------------------------------- */

replace consexp1 = hhsize * exp(_max1) if _flag1 == 1
replace consexp2 = hhsize * exp(_max2) if _flag2 == 1


/* ---- 7. Missing and zeros ------------------------------------------------ */

replace consexp1 = hhsize * exp(_median1) if consexp1 == 0
replace consexp2 = hhsize * exp(_median2) if consexp2 == 0

egen count1 = rownonmiss(c2a c2b c3) // any variables relating to consumption from purchases
egen count2 = rownonmiss(c4a c4b c5) // any variables relating to consumption from own production
assert count1 == 0 if consexp1 == .
assert count2 == 0 if consexp2 == .
// no missing values of consexp.  If there were, we could impute them as below
//replace consexp1 = hhsize * exp(_median1) if count1 > 0 & consexp1 == .
//replace consexp2 = hhsize * exp(_median2) if coutn2 > 0 & consexp2 == .


/* ---- 8. Form data -------------------------------------------------------- */

//  aa. reshape
keep consexp* hhid c0 q*
reshape long consexp qkg, i(hhid c0) j(source)
lab def sources 1 "purchases" 2 "own production" 3 "constructed use value" 4 "imputed rent"
lab val source sources
drop if consexp == .

//  a. annualize
replace consexp = consexp * 52 // assume 1 week recall period

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
save "${temp}\food.dta", replace 


/* ---- 9. Quick check ------------------------------------------------------ */

table item source, stat(p50 consexp)

collapse (sum) consexp, by(hhid)
sum consexp, d
gen logcons = log(consexp)
if $draw histogram logcons, normal // less normal than you would expect with real data



/* -------------------------------------------------------------------------- */
/*          B. Food Away from Home                                            */
/* -------------------------------------------------------------------------- */