/* ---- 1. File locations --------------------------------------------------- */

// set this to where you have cloned the GitHub repository
global github_rep   "C:\Users\WB431651\OneDrive - WBG\GSG1\Poverty Class\code library\poverty-templates"
global datain       "${github_rep}\datain"
global frags        "${github_rep}\fragments"

//  set these to local locations where you want to save temporary and output files
global local_dir    "C:\Users\WB431651\OneDrive - WBG\GSG1\Poverty Class\code library"
global temp         "${local_dir}\temp"
global dataout      "${local_dir}\dataout"


/* ---- 2. Add to ado path -------------------------------------------------- */

discard
adopath ++ 	"${github_rep}\ado"


/* ---- 3. Globals for parameters ------------------------------------------- */

global draw 1 // whether or not to draw diagnostic graphs

// prices to construct and use
global prices classic_kg_cluster
// classic_unit_cluster
// lsms_kg_cluster
// lsms_kg_domain_deflated
// lsms_kg_domain_none
// lsms_kg_domain_quarter
// lsms_unit_domain_quarter

global minN_prices 8 // minimum number of observations to construct median price

// reference population for basket for food poverty line
global min_decile 2
global max_decile 6

// minimum share of total food exp for basket and deflators (could define separately)
global minshare 0.8

// target calories
global calories 2300

// interval for Ravallion (population within what % of food poverty line)
global intrav = 10

// Ravallion method
// 1 = lower, 2 = mid, 3 = upper
global ravallion 1


/* ---- 4. Other useful things ---------------------------------------------- */

global specials 99, 999, 9999, 99999, 98, 998, 9998, 99998, 88, 888, 8888, 88888 
// not exhaustive!  check what is defined on qx or other values of this type interviewers made up

global z    4 // general threshold for identifying outliers
global lowz 3 // lower threshold to be extra careful for inputs

//exit


/* ---- 5. Remove all temporary and output files ---------------------------- */

local dirfiles: dir "$dataout" files "*.dta"
foreach file of local dirfiles {
	dis "${dataout}/`file'"
	erase "${dataout}/`file'"
}

local dirfiles: dir "$temp" files "*.dta"
foreach file of local dirfiles {
	dis "${temp}/`file'"
	erase "${temp}/`file'"
}


/* ---- 5. Run all programs ------------------------------------------------- */

do "${github_rep}\1 hh basics.do"
do "${github_rep}\2 food and prices.do"
do "${github_rep}\3 nonfood general.do"
do "${github_rep}\5 durable goods.do"
do "${github_rep}\7 compile.do"
do "${github_rep}\8 deflators.do"
do "${github_rep}\9 poverty.do"