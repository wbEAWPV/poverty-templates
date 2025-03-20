use "${datain}\section_A_hhroster.dta", clear


/* ---- 1. Household characteristics ---------------------------------------- */

//  a. for hh size
gen member = 1 // with real data would probably need to actually determine if a person on the roster counted as a hh member

//  b. for hh adult equivalency

//  c. other things

//  d. 


//  e. collapse to hh level
collapse (sum) hhsize = member, by(hhid admin1 admin2 urbrur hhweight psu month)
isid hhid

//  f. quarter of interview
bys psu: assert month == month[1]
gen quarter = floor((month-1)/3) + 1
tab month quarter 
tab admin1 quarter
table quarter (admin1 urbrur), nototal

//  g. save
save "${temp}\hh_char.dta", replace


/* ---- 2. Cluster level variables ------------------------------------------ */
// not sure we will actually use

collapse (mean) hhweight, by(psu admin1 admin2 urbrur quarter)
isid psu

save "${temp}\weight.dta", replace



/* ---- 3. Convert CPI data into deflators ---------------------------------- */

use "${datain}\CPI.dta", clear
egen mean_cpi = mean(cpi_headline)
gen deflator_cpi = cpi_headline/mean_cpi
save "${temp}\CPI_deflators.dta", replace