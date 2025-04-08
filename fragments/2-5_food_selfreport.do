// assume we have c1-c5
// use respondent reports on cost of consumption from purchases and value of consumption from own production

gen consexp1 = c3 if !miss_inv_c3
gen consexp2 = c5 if !miss_inv_c5

gen miss_inv_consexp1 = miss_inv_c3  // in real life, you don't need to define new variables here for use in the "main" program
gen miss_inv_consexp2 = miss_inv_c5 