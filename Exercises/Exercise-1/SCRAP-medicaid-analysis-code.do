********************************************************************************
* SCRAP-medicaid-analysis-code.do
*
* Translated by Kyle Butts, CU Boulder Economics
* 2022-06-23
********************************************************************************

* ssc install csdid
* ssc install drdid
* ssc install reghdfe
* ssc install bacondecomp

*-> 1. **Load the data**
  use "https://github.com/Mixtape-Sessions/Advanced-DID/raw/main/Exercises/Data/ehec_data.dta", clear

*-> 2. **Estimate the $ATT(g,t)$ using Callaway and Sant'Anna's estimator**
  * I've been to the year 3000...
  replace yexp2 = 3000 if yexp2 == .

  csdid dins, ivar(stfips) time(year) gvar(yexp2) notyet


*-> 3. **Compare to DiD estimates calculated by hand**
  preserve

  keep if year == 2013 | year == 2014
  gen treated = (yexp2 == 2014)

  * calculate means
  sum dins if year == 2013 & treated == 0
  loc dins_00 = r(mean)
  sum dins if year == 2014 & treated == 0
  loc dins_01 = r(mean)
  sum dins if year == 2013 & treated == 1
  loc dins_10 = r(mean)
  sum dins if year == 2014 & treated == 1
  loc dins_11 = r(mean)
  loc att_2014_2014 = (`dins_11' - `dins_10') - (`dins_01' - `dins_00')
  disp "ATT(2014, 2014): `att_2014_2014'"

  restore


*-> 4. **Aggregate the $ATT(g,t)$**
  csdid dins, ivar(stfips) time(year) gvar(yexp2) notyet
  
  qui: estat event
  csdid_plot
  graph export "es_plot.png", replace

  estat simple

*-> 5. **Compare to TWFE estimates (part 1)**
  gen postTreated = year >= yexp2 & (yexp2 != 3000)

  reghdfe dins i.postTreated, absorb(stfips year) vce(cluster stfips)

*-> 6. **Explain this result using the Bacon decomposition**

  xtset stfips year
  * bacondecomp is weird
  bacondecomp dins postTreated, ddetail stub(Bacon_)
  graph export "bacon_decomp.png", replace
  bys Bacon_cgroup: sum Bacon_B
  drop Bacon_*

*-> 7. **Compare to TWFE estimates (part 2)**
  
  preserve
  drop if yexp2 == 3000

  qui: csdid dins, ivar(stfips) time(year) gvar(yexp2) notyet
  
  estat simple

  qui: estat event
  csdid_plot
  graph export "es_plot_no_nevertreated.png", replace


  reghdfe dins i.postTreated, absorb(stfips year) vce(cluster stfips)

*-> 8. **Run the Bacon decomposition (part 2)**

  bacondecomp dins postTreated
  graph export "bacon_decomp_no_nevertreated.png", replace


*-> 9. **Even bigger TWFE problems**
  gen relativeTime = year - yexp2
  replace relativeTime = . if yexp2 == 3000
  gen dins2 = dins + (relativeTime>0) * relativeTime * 0.01

  qui: csdid dins2, ivar(stfips) time(year) gvar(yexp2) notyet

  estat simple

  qui: estat event
  csdid_plot
  graph export "es_plot_dynamic.png", replace

  reghdfe dins i.postTreated, absorb(stfips year) vce(cluster stfips)
  bacondecomp dins postTreated
  graph export "bacon_decomposition_dynamic.png", replace
