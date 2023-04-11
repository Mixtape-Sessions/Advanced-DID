use "https://raw.githubusercontent.com/Mixtape-Sessions/Advanced-DID/main/Exercises/Data/ehec_data.dta", clear

* Keep years before 2016. Drop the 2016 cohort
keep if (year < 2016) & (missing(yexp2) | (yexp2 != 2015))

* Create a treatment dummy
gen D = (yexp2 == 2014)
gen Dyear = cond(D, year, 2013)

* Run the TWFE spec
reghdfe dins b2013.Dyear, absorb(stfips year) cluster(stfips) noconstant

coefplot, vertical yline(0) ciopts(recast(rcap)) xlabel(,angle(45)) ytitle("Estimate and 95% Conf. Int.") title("Effect on dins")
quietly graph export twfe.svg, replace
