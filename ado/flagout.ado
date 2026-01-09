program flagout_asymmetric
    version 13
    syntax varname [pweight] [if], item(varlist max=1) [over(varlist) z(real 3.5) minn(integer 30) VERbose ASYMmetric]

    tempfile stats
    tempvar p10 p25 center p75 p90 n scale i
    tempvar min max

    gen `i' = 1 if `varlist' < .

    preserve
        collapse (p10) `p10' = `varlist' (p25) `p25' = `varlist' (p50) `center' = `varlist' (p75) `p75' = `varlist' (p90) `p90' = `varlist' (rawsum) `n' = `i' [`weight'`exp'], by(`item')
        qui generat `scale' = (`p75' - `p25')/1.35
        qui replace `scale' = (`p90' - `p10')/2.56 if `scale' == 0
        if "`asymmetric'" != "" {
            qui generat `min' = `p25' - `z'/2 * (`p75'-`p25')/1.35
            qui generat `max' = `p75' + `z'/2 * (`p75'-`p25')/1.35
            qui replace `min' = `p10' - `z'/2 * (`p90'-`p10')/2.56 if `p75' == `p25'
            qui replace `max' = `p90' + `z'/2 * (`p90'-`p10')/2.56 if `p75' == `p25'
        }
        else {
            qui generat `min' = `center' - `z' * (`p75'-`p25')/1.35
            qui generat `max' = `center' + `z' * (`p75'-`p25')/1.35
            qui replace `min' = `center' - `z' * (`p90'-`p10')/2.56 if `p75' == `p25'
            qui replace `max' = `center' + `z' * (`p90'-`p10')/2.56 if `p75' == `p25'
        }
        keep `item' `center' `min' `max' `n' `scale'
        qui save `stats'
    restore

    qui merge m:1 `item' using `stats', assert(match) nogen

    if "`over'" != "" {
        foreach var of varlist `over' {
            tempfile stats_`var'
            preserve
                collapse (p10) `p10' = `varlist' (p25) `p25' = `varlist' (p50) `center' = `varlist' (p75) `p75' = `varlist' (p90) `p90' = `varlist' (rawsum) `n' = `i' [`weight'`exp'], by(`item' `var')
                qui drop if `n' < `minn'
                qui generat `scale' = `p75' - `p25'
                qui replace `scale' = `p90' - `p10' if `scale' == 0
                if "`asymmetric'" != "" {
                    qui generat `min' = `p25' - `z'/2 * (`p75'-`p25')/1.35
                    qui generat `max' = `p75' + `z'/2 * (`p75'-`p25')/1.35
                    qui replace `min' = `p10' - `z'/2 * (`p90'-`p10')/2.56 if `p75' == `p25'
                    qui replace `max' = `p90' + `z'/2 * (`p90'-`p10')/2.56 if `p75' == `p25'
                }
                else {
                    qui generat `min' = `center' - `z' * (`p75'-`p25')/1.35
                    qui generat `max' = `center' + `z' * (`p75'-`p25')/1.35
                    qui replace `min' = `center' - `z' * (`p90'-`p10')/2.56 if `p75' == `p25'
                    qui replace `max' = `center' + `z' * (`p90'-`p10')/2.56 if `p75' == `p25'
                }
                keep `var' `item' `center' `min' `max' `n' `scale'
                qui save `stats_`var''
            restore

            qui merge m:1 `item' `var' using `stats_`var'',  update replace nogen
        }
    }

    qui count if `scale' == 0
    if r(N) > 0 {
        di as err _n "warning: items with 0 scale (p10 = p90)."
        di as err "Any value not equal to p10 = p90 will be flagged as outlier"
        tab `item' if `scale' == 0 & `varlist' < .
    }
    qui count if `n' < `minn' 
    if r(N) > 0 {
        di as err _n "warning: items with less than `minn' observations globally"
        di as err "No values flagged as outlier for this items."
        tab `item' if `n' < `minn' & `varlist' < .
    }

    foreach nvar in _min _max _median _flag {
        qui cap confirm new variable `nvar'
        if _rc == 110 {
            di "`nvar' already exists, dropping"
            drop `nvar'
        }
    }
    qui gen _median = `center' // can use this to impute
    qui gen _min  = `min'
    qui gen _max  = `max'

    qui gen _flag = 0 if `varlist' < . & `n' > `minn'
    qui replace _flag = -1 if `varlist' < _min & `varlist' < . & `n' > `minn'
    qui replace _flag = 1  if `varlist' > _max & `varlist' < . & `n' > `minn'

    if "`verbose'" == "verbose" {
        table `item', c(mean _min mean _median mean _max freq)
        tab `item' _flag, nofreq row
    }

    tempname xx
    lab def `xx' -1 "lower" 0 "nonoutlier" 1 "upper"
    lab val _flag `xx'

    tab _flag if `varlist' < ., m

end