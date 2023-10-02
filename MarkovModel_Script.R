##### 0.  Libraries ###########################################################

# Documentation for the development of the following model can be found at the following links.
# Paper:
#   https://link.springer.com/content/pdf/10.2165/00019053-199712050-00007.pdf
# Manual: 
#   https://aphp.r-universe.dev/heemod/doc/manual.html
# Deterministic Sensitivity Analysis:
#   https://aphp.r-universe.dev/articles/heemod/f_sensitivity.html
# Probabilistic Uncertainty Analysis:
#   https://aphp.r-universe.dev/articles/heemod/e_probabilistic.html

if (!require(heemod)) {
  install.packages("heemod")
}

library(heemod)

##### 1.  Parameters ###########################################################

parameters <- define_parameters(
  p_NoReliefFromDrug = 0.442,
  p_Recurrence = 0.406,
  p_EmergencyDep = 0.08,
  p_Hospitalization = 0.002,
  rr_NoReliefFromDrug = 0.621,
  rr_Recurrence = 0.297,
  c_Sumatriptan = 16.1,
  c_EmergencyDep = 63.13,
  c_Hospitalization = 1093,
  c_CaffeineErgotamine = 1.32,
  u_NoRecurrence = 1,
  u_Recurrence = 0.9,
  u_EnduresAttack = -0.3,
  u_ReliefFromEmergency = 0.1,
  u_Hospitalization = -0.3
)

##### 2.1 Transition matrix: Sumatriptan #######################################

tm_Sumatriptan <- define_transition(
  state_names = 
    c('Attack',	'ReliefFromDrug',	'NoReliefFromDrug',	
      'NoRecurrence',	'Recurrence',	'EnduresAttack',
      'EmergencyDep',	'ReliefFromEmergency',	
      'Hospitalization'),
  0,	C,	p_NoReliefFromDrug,	0,	0,	0,	0,	0,	0,
  0,	0,	0,	C,	p_Recurrence,	0,	0,	0,	0,
  0,	0,	0,	0,	0,	C,	p_EmergencyDep,	0,	0,
  0,	0,	0,	1,	0,	0,	0,	0,	0,
  0,	0,	0,	0,	1,	0,	0,	0,	0,
  0,	0,	0,	0,	0,	1,	0,	0,	0,
  0,	0,	0,	0,	0,	0,	0,	C,	p_Hospitalization,
  0,	0,	0,	0,	0,	0,	0,	1,	0,
  0,	0,	0,	0,	0,	0,	0,	0,	1
)

plot(tm_Sumatriptan)

##### 2.2 Transition matrix: CaffeineErgotamine ################################

tm_CaffeineErgotamine <- define_transition(
  state_names =
    c('Attack',	'ReliefFromDrug',	'NoReliefFromDrug',
      'NoRecurrence',	'Recurrence',	'EnduresAttack',
      'EmergencyDep',	'ReliefFromEmergency',
      'Hospitalization'),
  0,	C,	rr_NoReliefFromDrug,	0,	0,	0,	0,	0,	0,
  0,	0,	0,	C,	rr_Recurrence,	0,	0,	0,	0,
  0,	0,	0,	0,	0,	C,	p_EmergencyDep,	0,	0,
  0,	0,	0,	1,	0,	0,	0,	0,	0,
  0,	0,	0,	0,	1,	0,	0,	0,	0,
  0,	0,	0,	0,	0,	1,	0,	0,	0,
  0,	0,	0,	0,	0,	0,	0,	C,	p_Hospitalization,
  0,	0,	0,	0,	0,	0,	0,	1,	0,
  0,	0,	0,	0,	0,	0,	0,	0,	1
)

##### 3.  States ###############################################################

## Attack
State_Attack <- define_state(
  utility = 1,
  cost = 0
)

## ReliefFromDrug
State_ReliefFromDrug <- define_state(
  utility = 0,
  cost = 0
)

## NoReliefFromDrug
State_NoReliefFromDrug <- define_state(
  utility = 0,
  cost = 0
)

## NoRecurrence
State_NoRecurrence <- define_state(
  utility = u_NoRecurrence,
  cost = dispatch_strategy(
    Sumatriptan        = c_Sumatriptan ,
    CaffeineErgotamine = c_CaffeineErgotamine
  )
)

## Recurrence
State_Recurrence <- define_state(
  utility = u_Recurrence,
  cost = dispatch_strategy(
    Sumatriptan        = c_Sumatriptan*2 ,
    CaffeineErgotamine = c_CaffeineErgotamine*2
  )
)

## EnduresAttack
State_EnduresAttack <- define_state(
  utility = u_Recurrence,
  cost = dispatch_strategy(
    Sumatriptan        = c_Sumatriptan ,
    CaffeineErgotamine = c_CaffeineErgotamine
  )
)

## ReliefFromEmergency
State_EmergencyDep <- define_state(
  utility = 0,
  cost = 0
)

## ReliefFromEmergency
State_ReliefFromEmergency <- define_state(
  utility = u_ReliefFromEmergency,
  cost = dispatch_strategy(
    Sumatriptan        = c_Sumatriptan        + c_EmergencyDep,
    CaffeineErgotamine = c_CaffeineErgotamine + c_EmergencyDep
  )
)

## Hospitalization
State_Hospitalization <- define_state(
  utility = u_Hospitalization,
  cost = dispatch_strategy(
    Sumatriptan        = c_Sumatriptan        + c_EmergencyDep + c_Hospitalization,
    CaffeineErgotamine = c_CaffeineErgotamine + c_EmergencyDep + c_Hospitalization
  )
)

##### 4.1 Strategy: Sumatriptan ################################################

Strategy_Sumatriptan <-  define_strategy(
  transition = tm_Sumatriptan,
  Attack	            =	State_Attack,
  ReliefFromDrug	    =	State_ReliefFromDrug,
  NoReliefFromDrug	  =	State_NoReliefFromDrug,
  NoRecurrence	      =	State_NoRecurrence,
  Recurrence	        =	State_Recurrence,
  EnduresAttack	      =	State_EnduresAttack,
  EmergencyDep	      =	State_EmergencyDep,
  ReliefFromEmergency	=	State_ReliefFromEmergency,
  Hospitalization     =	State_Hospitalization
)

##### 4.2 Strategy: CaffeineErgotamine #########################################

Strategy_CaffeineErgotamine <-  define_strategy(
  transition = tm_CaffeineErgotamine,
  Attack	            =	State_Attack,
  ReliefFromDrug	    =	State_ReliefFromDrug,
  NoReliefFromDrug	  =	State_NoReliefFromDrug,
  NoRecurrence	      =	State_NoRecurrence,
  Recurrence	        =	State_Recurrence,
  EnduresAttack	      =	State_EnduresAttack,
  EmergencyDep	      =	State_EmergencyDep,
  ReliefFromEmergency	=	State_ReliefFromEmergency,
  Hospitalization     =	State_Hospitalization
)

##### 5.  Run model ############################################################

markov_model <- run_model(
  Sumatriptan        = Strategy_Sumatriptan,
  CaffeineErgotamine = Strategy_CaffeineErgotamine,
  parameters = parameters,
  init = c(1000, rep(0,sqrt(length(tm_CaffeineErgotamine))-1)), # number of elements match number of states
  cycles = 10,  
  method = "end",
  cost = cost,
  effect = utility
)

summary(markov_model)
plot(markov_model)

##### 4.  Deterministic Sensitivity Analysis ###################################

# if coefficient of variation is 1,
# then standard deviation (σ) is equal to the mean (μ).
# CV = σ / μ
# if CV = 1 then σ = μ
# low  = μ - σ = 0.442 - 0.442 = 0
# high = μ + σ = 0.442 + 0.442 = 0.884

ds <- define_dsa(
  p_NoReliefFromDrug,
  Low  = 0,
  High = 0.884
)
print(ds)

DSA <- run_dsa(markov_model, ds)
summary(DSA)

plot(DSA, value = "cost")

##### 5.  Probabilistic Uncertainty Analysis ###################################

rsp <- define_psa(
  # Usually costs are resampled on a gamma distribution,
  # which has the property of being always positive.
  c_Sumatriptan        ~ gamma(mean = 16.1, sd = sqrt(16.1)),
  c_CaffeineErgotamine ~ gamma(mean = 1.32, sd = sqrt(1.32))
)

pm <- run_psa(
  model = markov_model,
  psa = rsp,
  N = 100
)

summary(
  pm,
  threshold = c(1000, 5000, 6000, 1e4))

# uncertainty cloud
plot(pm, type = "ce")

# cost-effectiveness acceptability curves or EVPI
plot(pm, type = "ac", max_wtp = 5000, log_scale = FALSE)
plot(pm, type = "evpi", max_wtp = 5000, log_scale = FALSE)

# covariance analysis
plot(pm, type = "cov")

# difference between strategies
plot(pm, type = "cov", diff = TRUE, threshold = 5000)


##### Appendix: additional xlsx file ##########################################

# The project folder contains an Excel file called Appendix. This file contains some text formulas
# that helped me build the code blocks used in this script.