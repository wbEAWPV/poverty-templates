// one possibility when you only have age and current value
drop d4 d5 // assume we don't have these

/* ---- 2. Maximum life span ------------------------------------------------ */

//  a. flag outliers in age to exclude from construction of maximum life
// doing additional checks assuming age is log-normally distributed because max age in years in so important here
gen age = d2 if !miss_inv_d2
replace age = 0.5 if age == 0
gen logage = log(age) // do additional checks because upper tail of age distribution is key here
flagout logage [pw = hhweight], item(d0) z($lowz)

//  b. max life by item type, defined as 99th pctile
replace age = . if _flag != 0 // need to do this in a separate step rather than add if clause to egen
bys d0: egen max_life = pctile(age), p(99)
table d0, stat(mean max_life) nototal


/* ---- 3. Construct use value ---------------------------------------------- */

//  a. years of life left
gen years_remaining = max_life - age if !miss_inv_d2
sum years_remaining, d
replace years_remaining = 2 if years_remaining < 2 // some negative values are expected, this will also take care of them as well

//  b. use value
gen useval = d3/years_remaining if !miss_inv_d3 // just for most recently acquired item!
