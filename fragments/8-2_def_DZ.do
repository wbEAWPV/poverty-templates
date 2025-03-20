// Deaton-Zaidi Paasche deflator
// this is DZ's original theoretical best deflator
// inherently a joint deflator as each cluster is only interviewed at one point in time
// hhs in a cluster are assumed to face the same market prices, use cluster-level prices for ph
// use hh-level budget shares as weights, so each hh will have a unique value of the deflator

//  b. weights: share of hh value of consumption of each item
use "${temp}\food.dta", clear
merge m:1 hhid using "${temp}\hh_char.dta", assert(using match) keep(match) nogen
merge m:1 item using `itemlist', keep(match) nogen
collapse (sum) consexp, by(item hhid psu hhweight) // sum over purchases and own consumption for each item-hh
isid item hhid
bys hhid: egen hh_total = total(consexp)
gen wh = consexp/hh_total

//  c. merge in prices
gen c0 = item
merge m:1 psu c0 using "${temp}\ph_$prices.dta", assert(match using) keep(match) nogen
merge m:1 c0     using "${temp}\p0_$prices.dta", assert(match using) keep(match) nogen 

//  d. relative prices
gen p0_ph = p0/ph 
sum p0_ph, d
assert p0_ph > 0.33 & p0_ph < 3 // check relative prices within a reasonable range, not a difference of more than a factor of 2 or 3 depending on context

//  e. sum and take inverse
collapse (sum) sum_terms = p0_ph [pw = wh], by(hhid admin1 urbrur hhweight)
isid hhid
gen deflator_joint = 1/sum_terms
sum deflator_joint, d 
lab var deflator_joint "joint Paasche index, hh-level, food prices from survey"

//  f. winsorize outliers (optional, but a good idea with hh-level deflators)
merge 1:1 hhid using "${temp}\hh_char.dta", assert(using match) keepusing(hhid admin1 urbrur) // merge in all hhs so we can impute missing due to no food cons
gen domain = admin1 * 10 + urbrur // look at distribution of deflators in each domain
flagout deflator_joint [pw = hhweight], item(domain) z(3)
replace deflator_joint = _min if _flag == -1
replace deflator_joint = _max if _flag == 1
sum deflator_joint, d 

//  g. impute for hhs with no food consumption
replace deflator_joint = _med if _merge == 2
assert def < .
drop _merge _min _max _flag _med

//  h. save
save "${temp}\deflators_DZ.dta", replace

//  i. graphs
if $draw graph box deflator_joint, over(urbrur) asyvar over(admin1) 