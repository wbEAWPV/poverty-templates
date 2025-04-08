// assume we have c1-c5 (classic form of data, quantity consumed from purchases and cost of purchases over recall period)
// use respondent reports on cost of purchases and price * quantity (in kg) for own production

//  a. consumption from purchases
gen consexp1 = c3 if !miss_inv_c3
gen miss_inv_consexp1 = miss_inv_c3 // in real life, you don't need to define new variables here for use in the "main" program

//  b. merge in conversion factors to get consumption from own production in kg
gen unit = c4b
merge m:1 c0 unit using "${datain}\conversion_factors.dta", keep(master match) nogen
gen qkg2 = c4a if unit == 1
replace qkg2 = c4a * kg_per_unit if inlist(unit, 2, 3)
replace qkg2 = c4a / 1000 if unit == 4
replace qkg2 = . if miss_inv_c4

//  c. value this using local prices
merge m:1 psu c0 using "${temp}\ph_classic_kg_cluster.dta", keep(master match)
gen consexp2 = qkg2 * ph 
gen miss_inv_consexp2 = miss_inv_c4 | ph >= .

//  d. construct quanitity in kg for consumption from purchases as well
drop kg_per_unit
replace unit = c2b
merge m:1 c0 unit using "${datain}\conversion_factors.dta", keep(master match) nogen
gen qkg1 = c2a if unit == 1
replace qkg1 = c2a * kg_per_unit if inlist(unit, 2, 3)
replace qkg1 = c2a / 1000 if unit == 4
replace qkg1 = . if miss_inv_c2