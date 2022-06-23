library(here)
library(dplyr)
library(haven)
library(HonestDiD)
library(fixest)
library(did)
library(bacondecomp)

df <- read_dta(here("Exercises/Data/ehec_data.dta"))

#Impose data restrictions:
  # Restrict to 2015 or earlier
  # Remove states treated in 2015
df_restricted <- 
df %>% 
  filter(year <= 2015) %>%
  filter(is.na(yexp2) | yexp2 != 2015) %>%
  mutate(D = ifelse(is.na(yexp2) | yexp2 > 2015, 0, 1 ))

#Event study using restricted data set
event_study_reg <- fixest::feols(dins ~ i(year, D, 2013) | stfips + year, df_restricted  )
event_study_reg_summary <- summary(event_study_reg, cluster = ~stfips)

#Extract the coefficients and variance-covariance matrix
beta <- event_study_reg_summary$coefficients
sigma <- event_study_reg_summary$cov.scaled

delta_rm_results <- 
HonestDiD::createSensitivityResults_relativeMagnitudes(betahat = beta,
                                    sigma = sigma,
                                    numPrePeriods = 5,
                                    numPostPeriods = 2,
                                    l_vec = basisVector(index = 1, size =2))

originalResults <- HonestDiD::constructOriginalCS(betahat = beta,
                                                  sigma = sigma,
                                                  numPrePeriods = 5,
                                                  numPostPeriods = 2,
                                                  l_vec = basisVector(index = 1, size =2))

createSensitivityPlot_relativeMagnitudes(delta_rm_results, originalResults)


delta_sd_results <- 
  HonestDiD::createSensitivityResults(betahat = beta,
                                      sigma = sigma,
                                      numPrePeriods = 5,
                                      numPostPeriods = 2,
                                      l_vec = basisVector(index = 1, size =2))


createSensitivityPlot(delta_sd_results, originalResults)



## Callaway and Sant'Anna

cs_results <- att_gt(yname = "dins",tname = "year",idname = "stfips", gname = "yexp2", 
                     data = df %>% mutate(yexp2 = ifelse(is.na(yexp2),Inf,yexp2 )),
                     control_group = "notyettreated")

summary(cs_results)

##Compute the ATT(2014,2014) by hand
ytable <-
df %>%
  filter(year %in% c(2013,2014)) %>%
  mutate(treated = case_when(yexp2 == 2014 ~ 1,
                             is.na(yexp2) | yexp2 > 2014 ~ 0) ) %>%
  group_by(treated, year) %>%
  summarise(dins = mean(dins))

ATT_2014_2014_by_hand <- (mean_dins_by_year_group[ytable$year ==2014 & ytable$treated == 1, "dins"]-
                            mean_dins_by_year_group[ytable$year ==2013 & ytable$treated == 1, "dins"]) -
                        (mean_dins_by_year_group[ytable$year ==2014 & ytable$treated == 0, "dins"]-
                          mean_dins_by_year_group[ytable$year ==2013 & ytable$treated == 0, "dins"])


##Compute CS event-study
es <- aggte(cs_results, type = "dynamic")

ggdid(es)


cs_results <- att_gt(yname = "dins",tname = "year",idname = "stfips", gname = "yexp2", 
                     data = df %>% mutate(yexp2 = ifelse(is.na(yexp2),Inf,yexp2 )),
                     control_group = "notyettreated",
                     base_period = "universal")

es <- aggte(cs_results, type = "dynamic", 
            min_e = -5, max_e = 5)

ggdid(es)


## -----------------------------------------------------------------------------

#' @title honest_did
#'
#' @description a function to compute a sensitivity analysis
#'  using the approach of Rambachan and Roth (2021)
#' @param es an event study
honest_did <- function(es, ...) {
  UseMethod("honest_did", es)
}


#' @title honest_did.AGGTEobj
#'
#' @description a function to compute a sensitivity analysis
#'  using the approach of Rambachan and Roth (2021) when
#'  the event study is estimating using the `did` package
#'
#' @param e event time to compute the sensitivity analysis for.
#'  The default value is `e=0` corresponding to the "on impact"
#'  effect of participating in the treatment.
#' @param type Options are "smoothness" (which conducts a
#'  sensitivity analysis allowing for violations of linear trends
#'  in pre-treatment periods) or "relative_magnitude" (which
#'  conducts a sensitivity analysis based on the relative magnitudes
#'  of deviations from parallel trends in pre-treatment periods).
#' @inheritParams HonestDiD::createSensitivityResults
#' @inheritParams HonestDid::createSensitivityResults_relativeMagnitudes
honest_did.AGGTEobj <- function(es,
                                e=0,
                                type=c("smoothness", "relative_magnitude"),
                                method=NULL,
                                bound="deviation from parallel trends",
                                Mvec=NULL,
                                Mbarvec=NULL,
                                monotonicityDirection=NULL,
                                biasDirection=NULL,
                                alpha=0.05,
                                parallel=FALSE,
                                gridPoints=10^3,
                                grid.ub=NA,
                                grid.lb=NA,
                                ...) {
  
  
  type <- type[1]
  
  # make sure that user is passing in an event study
  if (es$type != "dynamic") {
    stop("need to pass in an event study")
  }
  
  # check if used universal base period and warn otherwise
  if (es$DIDparams$base_period != "universal") {
    warning("it is recommended to use a universal base period for honest_did")
  }
  
  # recover influence function for event study estimates
  es_inf_func <- es$inf.function$dynamic.inf.func.e
  
  # recover variance-covariance matrix
  n <- nrow(es_inf_func)
  V <- t(es_inf_func) %*% es_inf_func / (n*n) 
  
  
  nperiods <- nrow(V)
  npre <- sum(1*(es$egt < 0))
  npost <- nperiods - npre
  
  baseVec1 <- basisVector(index=(e+1),size=npost)
  
  orig_ci <- constructOriginalCS(betahat = es$att.egt,
                                 sigma = V, numPrePeriods = npre,
                                 numPostPeriods = npost,
                                 l_vec = baseVec1)
  
  if (type=="relative_magnitude") {
    if (is.null(method)) method <- "C-LF"
    robust_ci <- createSensitivityResults_relativeMagnitudes(betahat = es$att.egt, sigma = V, 
                                                             numPrePeriods = npre, 
                                                             numPostPeriods = npost,
                                                             bound=bound,
                                                             method=method,
                                                             l_vec = baseVec1,
                                                             Mbarvec = Mbarvec,
                                                             monotonicityDirection=monotonicityDirection,
                                                             biasDirection=biasDirection,
                                                             alpha=alpha,
                                                             gridPoints=100,
                                                             grid.lb=-1,
                                                             grid.ub=1,
                                                             parallel=parallel)
    
  } else if (type=="smoothness") {
    robust_ci <- createSensitivityResults(betahat = es$att.egt,
                                          sigma = V, 
                                          numPrePeriods = npre, 
                                          numPostPeriods = npost,
                                          method=method,
                                          l_vec = baseVec1,
                                          monotonicityDirection=monotonicityDirection,
                                          biasDirection=biasDirection,
                                          alpha=alpha,
                                          parallel=parallel)
  }
  
  list(robust_ci=robust_ci, orig_ci=orig_ci, type=type)
}


honest_did.AGGTEobj(es)


## Run TWFE event-study
df <- df %>% mutate(relativeTime = ifelse(is.na(yexp2), 0, year - yexp2) )
twfe_es <- feols(dins ~ i(relativeTime, ref = -1) | stfips + year, data =df, cluster = "stfips" )
summary(twfe_es)
iplot(twfe_es)

## Run static TWFE
df <- df %>% mutate(postTreated = relativeTime > 0 )
twfe_static <- feols(dins ~ postTreated | stfips + year, data =df, cluster = "stfips" )
summary(twfe_static)


## Run static TWFE using eventually-treated only
df <- df %>% mutate(postTreated = relativeTime >= 0 )
twfe_static <- feols(dins ~ postTreated | stfips + year, data =df %>% filter(!is.na(yexp2)), cluster = "stfips" )
summary(twfe_static)

## Run CS using eventually-treated only 

cs_results <- att_gt(yname = "dins",tname = "year",idname = "stfips", gname = "yexp2", 
                     data = df %>% filter(!is.na(yexp2)),
                     control_group = "notyettreated")

es <- aggte(cs_results, type = "dynamic", 
            min_e = -5, max_e = 5)

ggdid(es)


## Run TWFE event-study using eventually treated only
twfe_es <- feols(dins ~ i(relativeTime, ref = c(-1,-10)) | stfips + year, data =df %>% filter(!is.na(yexp2)), cluster = "stfips" )
summary(twfe_es)
iplot(twfe_es)

##Bacon decomp using everyone
bacon(dins ~ postTreated,
      data = df,
      id_var = "stfips",
      time_var = "year")

##Bacon decomp using eventually treated only
bacon(dins ~ postTreated,
      data = df %>% filter(!is.na(yexp2)),
      id_var = "stfips",
      time_var = "year")

