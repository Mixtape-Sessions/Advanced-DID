Exercise 2: Violations of Parallel Trends
================
2022-06-24

## Introduction

This exercise will walk you through using the HonestDiD R or Stata
package to conduct sensitivity analysis for possible violations of
parallel trends, using the methods proposed in [Rambachan and Roth
(2022)](https://jonathandroth.github.io/assets/files/HonestParallelTrends_Main.pdf).
Here are links to the [Stata
package](https://github.com/mcaceresb/stata-honestdid) and [R
package](https://github.com/asheshrambachan/HonestDiD).

## 0. Install packages if needed

*R Instructions:*

We will use several R packages in our analysis, which you can install as
follows if needed.

``` r
# Install here, dplyr, did, haven, ggplot2, remotes packages from CRAN
install.packages(c("here", "dplyr", "did", "haven", "ggplot2", "remotes", "fixest"))

# Turn off warning-error-conversion, because the tiniest warning stops installation
Sys.setenv("R_REMOTES_NO_ERRORS_FROM_WARNINGS" = "true")
# Install HonestDiD from github
remotes::install_github("asheshrambachan/HonestDiD")
```

*Stata Instructions:*

We will use several Stata packages in our analysis, which you can
install as follows if needed.

``` stata
* reghdfe
ssc install reghdfe

* honestdid
net install honestdid, from("https://raw.githubusercontent.com/mcaceresb/stata-honestdid/main") replace
honestdid _plugin_check

* csdid 
net install csdid, from ("https://raw.githubusercontent.com/friosavila/csdid_drdid/main/code/") replace
```

## 1. Run the baseline DiD

For simplicity, we will first focus on assessing sensitivity to
violations of parallel trends in a non-staggered DiD. Load the same
[dataset](https://github.com/Mixtape-Sessions/Advanced-DID/tree/main/Exercises/Exercise-1#data)
on Medicaid as in the previous exercise. For simplicity, restrict the
sample to the years 2015 and earlier, drop the the three states who
expand Medicaid in 2015 (this ensures states are either first-treated in
2014 or never-treated over our sample). We are now left with a panel
dataset where some units are first treated in 2014 and the remaining
units are not treated during the sample period.

Start by running the simple TWFE regression
*Y*<sub>*i**t*</sub> = *α*<sub>*i*</sub> + *λ*<sub>*t*</sub> + ∑<sub>*s* ≠ 2013</sub>1\[*s*=*t*\] × *D*<sub>*i*</sub> × *β*<sub>*s*</sub> + *u*<sub>*i**t*</sub>,
where *D*<sub>*i*</sub> = 1 if a unit is first treated in 2014 and 0
otherwise. Note that since we do not have staggered treatment, the
coefficients *β̂*<sub>*s*</sub> are equivalent to DiD estimates between
the treated and non-treated units between period *s* and 2013. I
recommend using the `feols` command from the `fixest` package in R and
`reghdfe` command in Stata; although feel free to use your favorite
regression command. Don’t forget to cluster your SEs at the state level.

## 2. Extract the coefficients and standard error from the baseline spec

*NOTE: R only*

To conduct sensitivity analysis using the `HonestDiD` package, we need
to extract the event-study coefficients and their variance-covariance
matrix. (Note: the event-study coefficients are assumed to be in order
from earliest to latest.) If you estimated the coefficients using
`feols` from the `fixest` package, it is easy to extract these objects
from the summary command. In particular, if your `feols` results are
stored in `twfe_results`, you can use the commands:

``` r
betahat <- summary(twfe_results)$coefficients
sigma <- summary(twfe_results)$cov.scaled
```

## 3. Sensitivity analysis using relative magnitudes restrictions

We are now ready to apply the HonestDiD package to do sensitivity
analysis. Suppose we’re interested in assessing the sensitivity of the
estimate for 2014 (the first year of treatment). We will use the
“relative magnitudes” restriction that allows the violation of parallel
trends between 2013 and 2014 to be no more than *M̄* times larger than
the worst pre-treatment violation of parallel trends.

*R instructions:*

To create a sensitivity analysis, load the `HonestDiD` package, and call
the `createSensitivityResults_relativeMagnitudes` function. You will
need to input the parameters `betahat` and `sigma` calculated above,
`numPrePeriods` (in this case, 5), and `numPostPeriods` (in this case,
2). I suggest that you also give the optional parameter
`Mbarvec = seq(0,2,by=0.5)` to specify the values of *M̄* you wish to
use. (Note: it may take a couple of minutes to calculate the sensitivity
results.)

Look at the results of the sensitivity analysis you created. For each
value of *M̄*, it gives a robust confidence interval that allows for
violations of parallel trends between 2013 and 2014 to be no more than
*M̄* times the max pre-treatment violation of parallel trends. What is
the “breakdown” value of *M̄* at which we can no longer reject a null
effect? Interpret this parameter.

*Stata instructions:*

To create a sensitivity analysis, use the `honest_did` function. You
will need to pass the options `pre` and `post` to specify the pre and
post treatment estimates. I suggest that you also give the optional
parameter `mvec` a value of `0.5(0.5)2` to specify the values of *M̄* you
wish to use. (Note: it may take a couple of minutes to calculate the
sensitivity results.)

Look at the results of the sensitivity analysis you created. For each
value of *M̄*, it gives a robust confidence interval that allows for
violations of parallel trends between 2013 and 2014 to be no more than
*M̄* times the max pre-treatment violation of parallel trends. What is
the “breakdown” value of *M̄* at which we can no longer reject a null
effect? Interpret this parameter.

## 4. Create a sensitivity analysis plot

*R Instructions:*

We can also visualize the sensitivity analysis using the
`createSensitivityPlot_relativeMagnitudes`. To do this, we first have to
calculate the CI for the original OLS estimates using the
`constructOriginalCS` command. We then pass our sensitivity analysis and
the original results to the `createSensitivityPlot_relativeMagnitudes`
command.

*Stata Instructions:*

We can also visualize the sensitivity analysis using the `honestdid`
command by adding the `coefplot` option. You can use the `cached` option
to use the results from the previous `honestdid` call (for speed’s
sake).

## 5. Sensitivity Analysis Using Smoothness Bounds

We can also do a sensitivity analysis based on different restrictions on
what violations of parallel trends might look like. The starting point
for this analysis is that often if we’re worried about violations of
parallel trends, we let treated units be on a different time-trend
relative to untreated units. Rambachan and Roth consider a sensitivity
analysis based on this idea – how much would the difference in trends
need to differ from linearity to violate a particular result?
Specifically, they introduce a parameter *M* that says that the change
in the slope of the trend can be no more than *M* between consecutive
periods.

*R Instructions:*

Use the function `createSensitivityPlot` to run a sensitivity analysis
using this smoothness bound. The inputs are similar to those for the
previous analysis, except instead of inputting `Mbarvec`, set the
parameter `Mvec = seq(from = 0, to = 0.05, by =0.01)`. (Note: as before
it may take a couple of minutes for the sensitivity code to run.) What
is the breakdown value of *M* – that is, how non-linear would the
difference in trends have to be for us not to reject a significant
effect?

*Stata Instructions:*

To create a sensitivity analysis using smoothness bounds, add the
`delta(sd)` option to your `honestdid` function call. (Note: as before
it may take a couple of minutes for the sensitivity code to run.) What
is the breakdown value of *M* – that is, how non-linear would the
difference in trends have to be for us not to reject a significant
effect?

## 6. Bonus: Sensitivity Analysis for Average Effects

*R Instructions:*

Re-run the sensitivity analyses above using the option
`l_vec = c(0.5,0.5)` to do sensitivity on the `average` effect between
2014 and 2015 rather than the effect for 2014 (`l_vec = c(0,1)` would
give inference on the 2015 effect). How do the breakdown values of *M̄*
and *M* compare to those for the effect in 2014? \[Hint: breakdown
values for longer-run effects often tend to be smaller, since this
leaves more time for the groups’ trends to diverge from each other.\]

*Stata Instructions:*

Re-run the sensitivity analyses above using the option `l_vec` to do
sensitivity on the `average` effect between 2014 and 2015 rather than
the effect for 2014. To do so, run the following
`matrix l_vec = 0.5 \ 0.5` and then add `l_vec(l_vec)` to the
`honestdid` call (`matrix l_vec = 0 \ 1` would give inference on the
2015 effect). How do the breakdown values of *M̄* and *M* compare to
those for the effect in 2014? \[Hint: breakdown values for longer-run
effects often tend to be smaller, since this leaves more time for the
groups’ trends to diverge from each other.\]

## 7. Bonus 2: HonestDiD + Callaway & Sant’Anna

*R Instructions:*

Look at the instructions
[here](https://github.com/asheshrambachan/HonestDiD#staggered-timing)
for running an event-study using Callaway and Sant’Anna and passing the
results to the HonestDiD package for sensitivity analysis. Create a
Callaway and Sant’Anna event-study using the full Medicaid data, and
then apply the HonestDiD sensitivity. \[Hint: I recommend using
`min_e = -5` and `max_e = 5` in the `aggte` command, since the earlier
pre-trends coefficients are very noisy.\]

*Stata Instructions:*

Look at the instructions
[here](https://github.com/mcaceresb/stata-honestdid#staggered-timing)
for running an event-study using Callaway and Sant’Anna and passing the
results to the HonestDiD package for sensitivity analysis. Create a
Callaway and Sant’Anna event-study using the full Medicaid data, and
then apply the HonestDiD sensitivity. \[Hint: I recommend using
`window(-4 5)` in the `csdid_estat` command, since the earlier
pre-trends coefficients are very noisy.\]

## Solutions

You can view an HTML file with worked out solutions [for
R](https://raw.githack.com/Mixtape-Sessions/Advanced-DID/main/Exercises/Exercise-2/Solutions/medicaid-analysis-pt-violations-solutions-R.html)
or [for
Stata](https://raw.githack.com/Mixtape-Sessions/Advanced-DID/main/Exercises/Exercise-2/Solutions/medicaid-analysis-pt-violations-solutions-stata.html).
