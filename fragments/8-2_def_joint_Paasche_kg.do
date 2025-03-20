// joint spatial-temporal Paasche deflator at the admin1-urbrur-quarter level
// comment out / delete either c1 or c2 depending on how you want to construct the weights

if !regexm("$prices", "kg") {
   di as err "need per kg prices for def_joint_Paasche_kg deflator"
   di as err "using $prices prices"
   exit
}

tempfile ph

if regexm("$prices", "cluster") {
   //  a. collapse prices to domain-quarter level
   use "${temp}\hh_char.dta", clear
   collapse (sum) hhweight, by(psu)
   merge 1:m psu using "${temp}\ph_$prices.dta", assert(match) nogen
   collapse (mean) ph [aw = hhweight], by(c0 admin1 urbrur quarter)
   save `ph'
}
else if regexm("$prices", "domain_quarter") {
   //  a. nothing extra needed
   use "${temp}\ph_$prices.dta"
   save `ph'
}
else {
   di as err "need cluster or domain_quarter level prices for def_joint_Paasche_kg"
   di as err "using $prices prices"
}

//  c1. share of domain (admin1-strata) & quarter value of consumption of each item - plutocratic shares
use "${dataout}\hh_item_data.dta", clear
merge m:1 item using `itemlist', keep(match) nogen
collapse (sum) consexp [pw = hhweight], by(item admin1 urbrur quarter) // sum over purchases and own consumption for each item-hh
bys admin1 urbrur quarter: egen domain_total = total(consexp)
gen wh = consexp/domain_total

//  c2. share of domain (admin1-strata) value of consumption of each item - democratic
use "${dataout}\hh_item_data.dta", clear
collapse (sum) consexp, by(hhid item admin1 urbrur hhweight quarter) // add together consumption from purchases and own production
merge m:1 item using `itemlist', keep(match) nogen
fillin item hhid
sort hhid _fillin
foreach var of varlist admin1 urbrur quarter hhweight {
   bys hhid: replace `var' = `var'[1] if _fillin
}
replace consexp = 0 if _fillin
bys hhid: egen hh_total = total(consexp)
gen wh = consexp / hh_total
collapse (mean) wh [pw = hhweight], by(item admin1 urbrur quarter) 

//  d. final check
table item (admin1 urbrur quarter), stat(sum wh) total(admin1#urbrur#quarter) nformat(%5.3fc)
// all columns should have 1 in the total row

//  e. merge in prices
gen c0 = item
merge m:1 c0 admin1 urbrur quarter using `ph',                     assert(match using) keep(match) nogen
merge m:1 c0                       using "${temp}\p0_$prices.dta", assert(match using) keep(match) nogen

//  f. relative prices
gen p0_ph = p0/ph
sum p0_ph, d
assert p0_ph > 0.33 & p0_ph < 3 // check relative prices within a reasonable range, not a difference of more than a factor of 2 or 3 depending on context

//  g. sum and take inverse
collapse (sum) sum_terms = p0_ph [pw = wh], by(admin1 urbrur quarter)
gen deflator_joint = 1/sum_terms
lab var deflator_joint "joint Paasche index, admin1-urbrur-quarter level, food prices from hh survey"
table quarter (admin1 urbrur), stat(mean deflator_joint) nototal
mean deflator_joint // should be close to 1.  weighted average should be closer
drop sum_terms

//  h. save
save "${temp}\deflators_joint_Paasche_kg.dta", replace

//  i. merge into hh data on correct variables before returning
use "${temp}\hh_char.dta", clear
merge m:1 admin1 urbrur quarter using "${temp}\deflators_joint_Paasche_kg.dta", assert(match) nogen