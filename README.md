<img src="https://raw.githubusercontent.com/Mixtape-Sessions/Advanced-DID/main/img/banner.png" alt="Mixtape Sessions Banner" width="100%"> 


## About

This one-day workshop will cover advanced topics from the recent difference-in-differences (DiD) literature. The structure of the course is loosely based on my review paper, [What's Trending in Differences-in-Differences? A Synthesis of the Recent Econometrics Literature](https://jonathandroth.github.io/assets/files/DiD_Review_Paper.pdf) (forthcoming at Journal of Econometrics), particularly Sections 3 and 4. (I will not assume any knowledge of the paper, but if you'd like to do some optional course prep, you might start by reading the paper!) We will start by briefly reviewing the canonical DiD model. We will then cover two strands of the literature that have deviated from this basic model in different ways. The first strand considers settings with multiple periods and staggered treatment timing. The second strand considers the fact that the parallel trends assumption may not hold exactly. The workshop will focus not just on the theory, but also on practical implementation in statistical software such as R and Stata.

You can join the class Discord [here](https://discord.gg/euSHza8w)





## Schedule

All times Eastern Time.

- 10-11 **Preliminaries & The Canonical DiD Model**
- 11-11:15 **Break**
- 11:15-12:30 **Staggered treatment timing and heterogeneous treatment effects**
- 12:30-1 **Lunch break**
- 1-2 **Coding Exercise**
- 2-3:15 **Violations of Parallel Trends**
- 3:15-4:15 **Coding Exercise**
- 4:15-5 **Open "Office Hour" for your DiD questions**

### Preliminaries & The Canonical DiD Model

#### About

I'll start by telling you a little about myself and the logistics of the course. We'll then cover the key assumptions in the "canonical" two-period DiD model, where the econometrics are well-understood. This will give us a common baseline to understand how the various ways that recent innovations in the DiD literature have deviated from the baseline model. The discussion of the basic model will be based on Section 2 of [my review paper](https://jonathandroth.github.io/assets/files/DiD_Review_Paper.pdf) 


#### Slides

[Introduction.pdf](Slides/01-introduction.pdf)






### Staggered treatment timing

#### About

We'll next discuss a very active recent literature on DiD settings with multiple periods and staggered treatment timing. We'll first discuss issues with two-way fixed effects estimators in these settings. We'll then discuss recently-introduced estimators that have been developed to fix these problems. The discussion will be based on Section 3 of [my review paper](https://jonathandroth.github.io/assets/files/DiD_Review_Paper.pdf) 


#### Slides

[Staggered.pdf](Slides/02-staggered.pdf)

#### Coding Exercise

[Instructions](https://github.com/Mixtape-Sessions/Advanced-DID/blob/main/Exercises/Exercise-1/README.md#introduction)




### Violations of parallel trends

#### About

We'll next discuss the strand of the literature that has considered the possibility that the parallel trends assumption may not hold exactly. We'll discuss the intuitive practice of testing for "pre-trends," as well as its limitations. We'll also discuss solutions to these issues, including power analyses and the sensitivity analysis proposed by [Rambachan and Roth (2022)](https://jonathandroth.github.io/assets/files/HonestParallelTrends_Main.pdf). The discussion will be based on Section 4 of [my review paper](https://jonathandroth.github.io/assets/files/DiD_Review_Paper.pdf) 


#### Slides

[Violations.pdf](Slides/03-violations.pdf)


#### Coding Exercise

[Instructions](https://github.com/Mixtape-Sessions/Advanced-DID/blob/main/Exercises/Exercise-2/README.md#introduction)





