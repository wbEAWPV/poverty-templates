// assume we have c1-c5 (classic form of data, quantity consumed from purchases and cost of purchases over recall period)
// use respondent reports on cost of purchases and price * quantity (in different units) for own production

//  a. consumption from purchases
gen consexp1 = c3 if !miss_inv_c3
gen miss_inv_consexp1 = miss_inv_c3 // in real life, you don't need to define new variables here for use in the "main" program

//  b. value quantity from own production using local prices
gen unit = c4b
merge m:1 psu c0 unit using "${temp}\ph_classic_unit_cluster.dta", keep(master match)
gen consexp2 = c4a * ph
gen miss_inv_consexp2 = miss_inv_c4 | (c4a > 0 & c4a < . & ph >= .)
