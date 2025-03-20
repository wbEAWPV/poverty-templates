clear
use "${temp}\food.dta"
append using "${temp}\nonfood_basic.dta"
append using "${temp}\durables.dta"

merge m:1 hhid using "${temp}\hh_char.dta", assert(match) nogen

forval i = 1001/1010 {
    lab def items `i' "`: label items1000 `i''", add
}
forval i = 1201/1210 {
    lab def items `i' "`: label items1200 `i''", add
}
lab val item items

tab item [aw = hhweight * consexp]

recode item (1/17            = 1 "food and nonalcoholic beverages") ///
            (18/20           = 2 "alcoholic beverages, tobacco and narctics") ///
            (1001/1002       = 3 "clothing and footwear") ///
            (1003 1300       = 4 "housing, water, electricity, gas and other fuels") ///
            (1004 1201/1205  = 5 "furnishings, hh equipment and routine hh maintenance") ///
            (1101/1110       = 6 "health") ///
            (1005 1206/1207  = 7 "transport") ///
            (1006 1208/1210  = 8 "information and communication") ///
            (1007            = 9 "recreation, sports and culture") ///
            (1111/1120       = 10 "education services") ///
            (21/25           = 11 "restaurant and accomodation services") ///
            (1008            = 12 "insurance and financial services") ///
            (1009/1010       = 13 "personal care, social protection and misc goods and services") ///
            (nonm = .)    ///
    , gen(coicop) test
lab var coicop "COICOP 2018 top-level coding"
assert coicop < .

tab coicop
tab coicop source

lab var hhweight "hh sampling weight"

tab coicop [aw = hhweight * consexp]

save "${dataout}\hh_item_data.dta", replace

gen foodcons = consexp if coicop == 1 // add FAFH here when we have
gen nonfcons = consexp if coicop != 1 

collapse (sum) consexp foodcons nonfcons, by(hhid)
isid hhid
lab var consexp "total nominal value of consumption"
lab var foodcons "total nominal vlaue of food consumption"
lab var nonfcons "total nominal vlaue of nonfood consumption"

save "${temp}\nca.dta", replace