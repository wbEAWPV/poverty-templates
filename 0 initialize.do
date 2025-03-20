global codelib "C:\Users\WB431651\OneDrive - WBG\GSG1\Poverty Class\code library"
global datain  "${codelib}\datain"
global temp    "${codelib}\temp"
global frags   "${codelib}\fragments"
global dataout "${codelib}\dataout"

discard
adopath ++ 	"${codelib}\ado"


global draw 0

// reference population for basket for food poverty line
global min_decile 2
global max_decile 6

// minimum share of total food exp for basket
global minshare 0.8

// target calories
global calories 2300

// interval for Ravallion (population within what % of food poverty line)
global intrav = 10

// Ravallion method
// 1 = lower, 2 = mid, 3 = upper
global ravallion 1