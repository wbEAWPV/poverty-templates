
/* ---- 1. Select items to include ---------------------------------------------------- */

//  this is simplest approach, could also use a reference population, or require a minimum share across different strata
use "${temp}\food.dta", clear
merge m:1 hhid using "${temp}\hh_char.dta", assert(match using) keep(match) keepusing(hhweight)
collapse (sum) consexp [pw = hhweight], by(item)
egen item_total = total(consexp)
gen share = consexp / item_total
gsort -share
gen cumul_share = sum(share)
gen prev_share = cumul_share[_n-1]
list
keep if prev_share < $minshare | _n == 1 // keep items so that cumulative share is at least minimum
total share
keep item
tempfile itemlist
save `itemlist'


/* ---- 2. Construct deflator ----------------------------------------------- */

include "${frags}\8-2_def_DZ.do"


/* ---- 3. Merge in and inspect --------------------------------------------- */

//  a. merge
use "${temp}\hh_char.dta", clear
// should drop hhs with no food consumption here, then can use assert(match) below
//merge 1:1 hhid using "${temp}\deflators_DZ.dta", assert(match master) keep(match) nogen
//merge m:1 admin1 urbrur quarter using "${temp}\deflators_joint_Laspeyres.dta", assert(match) nogen
merge m:1 admin1 urbrur quarter using "${temp}\deflators_joint_Paasche_modal.dta", assert(match) nogen

//  b. inspect
mean deflator [pw = hhweight] // should be close to 1
table (quarter) (admin1 urbrur) [pw = hhweight], stat(mean deflator) nototal
if $draw graph box deflator, over(urbrur) asyvar over(admin1) name(spatial, replace)
if $draw graph box deflator, over(quarter) name(temporal, replace)