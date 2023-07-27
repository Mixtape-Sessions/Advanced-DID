
## Introduction

This exercise will help you learn about the recent DiD literature on settings with multiple periods and staggered treatment timing. We will examine the effects of Medicaid expansions on insurance coverage using publicly-available data from the ACS. This analysis is similar in spirit to that in [Carey, Miller, and Wherry (2020)](https://www.dropbox.com/s/mgunjcebpgnb939/Carey-et-al.pdf?dl=0), although they use confidential data.

## Package Setup 

For R, you will need the following packages: `did`, `dplyr`, `fixest`, `bacondecomp`, `here`, and `haven`. For Stata, you will need `csdid`, `drdid`, `reghdfe`, and `ddtiming`. Note that `ddtiming` is not on SSC, but can installed with `net install ddtiming, from(https://tgoldring.com/code)`. 


## Data

The provided dataset `ehec_data.dta` contains a state-level panel dataset on health insurance coverage and Medicaid expansion. The variable `dins` shows the share of low-income childless adults with health insurance in the state. The variable `yexp2` gives the year that a state expanded Medicaid coverage under the Affordable Care Act, and is missing if the state never expanded. The variable `year` gives the year of the observation and the variable `stfips` is a state identifier. (The variable `W` is the sum of person-weights for the state in the ACS; for simplicity, we will treat all states equally and ignore the weights, although if you'd like an additional challenge feel free to re-do everything incorporating the population weights!)

## Questions

1.  **Load the data**

The easiest way to load the data is to run
```
df <- haven::read_dta("https://raw.githubusercontent.com/Mixtape-Sessions/Advanced-DID/main/Exercises/Data/ehec_data.dta")
```
in R, or 
```
use "https://raw.githubusercontent.com/Mixtape-Sessions/Advanced-DID/main/Exercises/Data/ehec_data.dta"
```
in Stata.

If you'd like to have a local copy of the data, you can also download it [here](https://raw.githubusercontent.com/Mixtape-Sessions/Advanced-DID/main/Exercises/Data/ehec_data.dta).


2.  **Estimate the ATT(g,t) using Callaway and Sant'Anna's estimator**

Use the `attgt` function in the did package (R) or the `csdid` function in the csdid package (Stata) to estimate the group-time specific ATTs for the outcome `dins`. In R, I recommend using the control group option "notyettreated", which uses as a comparison group all units who are not-yet-treated at a given period (including never-treated units). In Stata, use the option `, notyet`. (For fun, you're welcome to also try out using "nevertreated" units as the control). Hint: replace missing values of `yexp2` to some large number (say, 3000) for the the did package to incorporate the never-treated units as controls.


For R users, apply the `summary` command to the results from the `att_gt` command. For Stata users, this should already be reported as a result of `csdid` command. After applying the correct command, you should have a table with estimates of the ATT(g,t) -- that is, average treatment effects for a given "cohort" first-treated in period g at each time t. For example, ATT(2014,2015) gives the treatment effect in 2015 for the cohort first treated in 2014.


3.  **Compare to DiD estimates calculated by hand**

To understand how these ATT(g,t) estimates are constructed, we will manually compute one of them by hand. For simplicity, let's focus on ATT(2014, 2014), the treatment effect for the first treated cohort (2014) in the year that they're treated (2014). Create an indicator variable D for whether a unit is first-treated in 2014. Calculate the conditional mean of `dins` for the years 2013 and 2014 for units with D=1 and units with D=0 (i.e. calculate 4 means, for each combination of year and D). Manually compute the 2x2 DiD between D=1 and D=0 and 2013 and 2014. If you did it right, this should line up exactly with the ATT(g,t) estimate you got from the CS package! (Bonus: If you're feeling ambitious, you can verify by hand that the other ATT(g,t) estimates from the CS package also correspond with simple 2x2 DiDs that you can compute by hand)

4.  **Aggregate the ATT(g,t)**

We are often interested in a summary of the ATT(g,t)'s. 

In R, use the `aggte` command with option `type = "dynamic"` to compute "event-study" parameters. These are averages of the ATT(g,t) for cohorts at a given lag from treatment --- for example, the estimate for event-time 3 gives an average of parameters of the form ATT(g,g+3), i.e. treatment effects 3 periods after units were first treated. You can use the `ggdid` command to plot the relevant event-study. 

In Stata, use the commands `qui: estat event` followed by `csdid_plot`. 

You can also calculate overall summary parameters. E.g, in R, using `aggte` with the option `type = "simple"` takes a simple weighted average of the ATT(g,t), weighting proportional to cohort sizes. In Stata, you can use `estat simple`.

5.  **Compare to TWFE estimates (part 1)**

Estimate the OLS regression specification 

$$
Y_{it} = \alpha_i + \lambda_t + D_{it} \beta +\epsilon_{it},
$$

where  $D_{it}$  is an indicator for whether unit $i$ was treated in period $t$. How does the estimate for
$\hat{\beta}$ compare to the simple weighted average you got from Callaway and Sant'Anna? (Don't forget to cluster your SEs at the state level!)

6.  **Explain this result using the Bacon decomposition**

You probably noticed that the static TWFE estimate and the simple-weighted average from C&S were fairly similar. The reason for that is that in this example, there are a fairly large number of never-treated units, and so TWFE mainly puts weight on "clean comparisons". We can see this by using the `Bacon decomposition`, which shows how much weight static TWFE is putting on clean versus forbidden comparisons. In R, use the `bacon()` command to estimate the weights that TWFE puts on each of the types of comparisons. The first data-frame returned by the command shows how much weight OLS put on the three types of comparisons. How much weight is put on forbidden comparisons here (i.e. comparisons of 'Later vs Earlier')? In Stata, use the command `ddtiming`.




7.  **Compare to TWFE estimates (part 2)**

To see a situation where negative weights can matter (somewhat) more, drop from your dataset all the observations that are never-treated. Re-run the Callaway and Sant'Anna and TWFE estimates like you did before on this modified data-set. How does the TWFE estimate compare to the simple weighted average (or the average of the event-study coefficients) now?



8.  **Run the Bacon decomposition (part 2)**

Re-run the Bacon decomposition on the modified dataset. How much weight is put on "forbidden comparisons" now?




9.  **Even bigger TWFE problems**

In the last question, you saw an example where TWFE put a lot of weight on "forbidden comparisons". However, the estimates from the forbidden comparisons were not so bad because the treatment effects were relatively stable over time (the post-treatment event-study coefficients are fairly flat). To see how dynamic treatment effects can make the problem worse, create a variable `relativeTime` that gives the number of periods since a unit has been treated. Create a new outcome variable `dins2` that adds 0.01 times `relativeTime` to `dins` for observations that have already been treated (i.e., we add in some dynamic treatment effects that increase by 0.01 in each period after a unit is treated). Re-run the Callaway & Sant'Anna and TWFE estimates and the Bacon decomp using the dataset from the previous question and the `dins2` variable. How do the differences between C&S and TWFE compare to before?



## Solution

You can view solutions in multiple forms. You can view it as an HTML file with worked out solutions [for Stata](https://raw.githack.com/Mixtape-Sessions/Advanced-DID/main/Exercises/Exercise-1/Solutions/medicaid-analysis-solutions-stata.html) and [for R](https://raw.githack.com/Mixtape-Sessions/Advanced-DID/main/Exercises/Exercise-1/Solutions/medicaid-analysis-solutions-R.html). You can also view it directly in github [for Stata](https://github.com/Mixtape-Sessions/Advanced-DID/blob/main/Exercises/Exercise-1/Solutions/medicaid-analysis-solutions-stata.md) and [for R](https://github.com/Mixtape-Sessions/Advanced-DID/blob/main/Exercises/Exercise-1/Solutions/medicaid-analysis-solutions-R.md). 

If you want to download a RMarkdown notebook with solutions that you can run in RStudio, [click here](https://raw.githubusercontent.com/Mixtape-Sessions/Advanced-DID/main/Exercises/Exercise-1/Solutions/medicaid-analysis-solutions-R.Rmd), then right-click and choose 'Save as', then save the file
