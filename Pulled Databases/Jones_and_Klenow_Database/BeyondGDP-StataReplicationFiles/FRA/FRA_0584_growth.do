*log using "C:\Users\klenow\Documents\Rawls\FRA\FRA_05_growth.smcl", replace
*log using "C:\Users\klenow.ECON\Documents\Rawls\FRA\FRA_05_growth.smcl", replace


*****************************************************************************
*		 FIND THE GROWTH LAMBDA IN France BETWEEN 1984 - 2005				*
* This program computes the % reduction in consumption that individuals are *
* willing to undertake in 2005 and still be as well of as they were in 1984 *
*****************************************************************************

*** The program proceeds in 2 steps

*** STEP I: Calculate base (2005) values for CbarFRA, LbarFRA, CineqFRA, 
* LineqFRA etc using 2005 data and 2005 survival rates

*** STEP II, use 1984 data with 2005 survival rates and combine with Part I 
* to get growth lambda's. NOTE: Because 1984 data for consumption and 
* leisure have different weights in IND, this 2nd step is itself done in 2 sub-steps


**********************************************************
*********				STEP I  			 *************
********* 2005 data with 2005 survival rates *************
**********************************************************

drop _all
scalar drop _all
set varabbrev off
set more off
**Set parameter values for the utility function
/*
scalar ubar = 4.1466
scalar theta= 14.883
scalar epsilon= 1
*/
**Set type of allocation rule:
//* 1=Equal Allocation Rule
//* 2=Square Root Rule
//* 3=OECD Modified Equivalence Scale
scalar rule=1


* Discard all observations with age > 100 and normalize weights
quietly {
*use "C:\Users\klenow\Documents\Rawls\FRA\FRA_05.dta", clear
use "FRA_05.dta", clear

*destring pcode, replace

drop if age > 100
drop if age==.

ren weight weight_temp
egen weight_total=total(weight_temp)
gen weight = weight_temp/weight_total
drop weight_temp weight_total
}


* Apply country year identifying variables to each observation 
* to facilitate merge with survival data

gen country="France"
gen country_code="FRA" 
gen int year=2005
order country country_code year 


/*Create an OECD Modified Equivalence Scale variable 
quietly{
gen OECD1=1 if pcode==1
gen OECD2=0.5 if pcode~=1 & age>=14
gen OECD3=0.3 if pcode~=1 & age<14
egen OECDw= rsum(OECD1 OECD2 OECD3)
by hhid: egen OECDscale= total(OECDw)
drop OECD1 OECD2 OECD3 OECDw
lab var OECDscale "OECD Modified Equivalent Scale for household allocation"
}
*/
*apply allocation rule 
foreach var in hhexp {
if rule==1 {
replace `var'=`var'/hhsize
}
else if rule==2 {
replace `var'=`var'/sqrt(hhsize)
}
else if rule==3 {
replace `var'=`var'/OECDscale
}
}


*	Now that we have allocated expenditures to individuals, convert individual consumption from 
* 	2005 FRA to constant international prices, incorporate govt consumption
* 	using Penn World Tables 6.3, and scale to year $baseyear US $
 
gen wc=weight*hhexp
lab var wc "weight*hhexp"
quietly {
su wc
}
return list
scalar sum_wc=r(sum) 

*Bring in cpop and gpop by merging with PWT_cpop_gpop.dta
sort country_code year
*merge m:m country_code year using "C:\Users\klenow\Documents\Rawls\PWT 6.3\PWT_cpop_gpop.dta"
merge m:m country_code year using "$pwt_file"
keep if country_code=="FRA"
keep if year==2005 
gen c_hat_jit=(cpop/sum_wc)*hhexp + gpop 
gen chat= c_hat_jit / cgpop_US_$baseyear
lab var chat "per capita consumption scaled by $baseyear U.S. $"
drop c_hat_jit wc cpop gpop cgpop cgpop_US_$baseyear _merge 


*Check that the weighted average of chat is ?
gen wchat=weight*chat
su wchat
return list


foreach var in chat leisure {
qui {
gen ln`var'=ln(`var')
}
}


****************************************
gen eps_leisure=((1-leisure)^((1+$epsilon)/$epsilon))/((1+$epsilon)/$epsilon)
su eps_leisure
scalar sd_eps_leisure_unwt=r(sd)
****************************************

*sum weights within age groups, create wbar:
*(individual sampling weight)/(sum of all individual sampling weights in age group) 
sort age 
by age: egen total_age_weight=total(weight)
gen wbar=weight/total_age_weight 
drop weight total_age_weight
order age

*Check that wbar sums to 1 within each age group
*by age: egen total_wbar_a=total(wbar)
*list age total_wbar_a


*Merge with country-age level survival rates
sort country_code year age 
*merge m:1 country_code year age using "C:\Users\klenow\Documents\Rawls\Survival Rates\survivalFRA05.dta"
merge m:1 country_code year age using "$survival_ind/survivalFRA05.dta"
keep if year==2005
keep if country_code=="FRA"
drop _merge

*create logca and logla, averages over people of the same age. 
* first create lnchat*wbar for each observation, then sum over age groups
sort age 
gen logcja=lnchat*wbar
by age: egen logca=total(logcja)
gen loglja=lnleisure*wbar 
by age: egen logla=total(loglja) 

*********************************
gen eps_lja=eps_leisure*wbar 
by age: egen eps_la=total(eps_lja) 
*********************************

*create ca and la, which are sums of chat*wbar and leisure*wbar within age groups.
* Will be used to calculate cbar and lbar
gen cja=chat*wbar
by age: egen ca=total(cja)
gen lja=leisure*wbar
by age: egen la=total(lja)

order country country_code year age logca logla eps_la ca la wbar 


*collapse dataset to have one observation(row) per age group.
 
collapse (mean) logca=logca logla=logla eps_la=eps_la ca=ca la=la s_FRAa=s_FRAa  delta_s_FRAa= delta_s_FRAa, by(country_code year age)

*If ca=0 then age must be missing.
gen missing_age=0
replace missing_age=1 if ca==0
*list

*Convert variables for missing ages from zero to missing
foreach var in logca logla eps_la ca la {
replace `var'=. if (missing_age==1) 
}


*interpolate logca, logla, ca, la for missing ages
foreach var in logca logla eps_la ca la {
ipolate `var' age, gen(i`var')
replace `var'=i`var'
drop i`var'
}

* replace missing values by neighboring non-missing values
sort age
foreach var in logca logla eps_la ca la{
replace `var' = `var'[_n-1] if missing(`var')
}
*generate log_cbar and log_lbar, the log of average ca and la, with s_FRAa as weights
* 

gen cbar_a = s_FRAa*ca
egen cbar = total(cbar_a)
di cbar
gen log_cbar = ln(cbar)

gen lbar_a = s_FRAa*la
egen lbar = total(lbar_a)
gen log_lbar = ln(lbar)

****************************************
scalar eps_lbar = ((1-lbar)^((1+$epsilon)/$epsilon))/((1+$epsilon)/$epsilon)
di eps_lbar
****************************************

*generate Elogc and Elogl
gen logc_a = logca*s_FRAa
egen Elogc = total(logc_a)

gen logl_a = logla*s_FRAa
egen Elogl = total(logl_a)

**************************
gen epsl_a = eps_la*s_FRAa
egen Eeps_l = total(epsl_a)
drop lbar_a cbar_a epsl_a
**************************

* Storing base year values in scalars for use in STEP III

scalar log_cbar_05=log_cbar
scalar eps_lbar_05=eps_lbar
scalar Elogc_05=Elogc
scalar Eeps_l_05=Eeps_l

scalar Cbar_FRA_05=exp(log_cbar_05) //This is 2005 micro data on consumption weighted by 2005 survival rates
scalar epsLbar_FRA_05=eps_lbar_05 //This is 2005 micro data on leisure weighted by 2005 survival rates
scalar Cineq_FRA_05=Elogc_05-log_cbar_05
scalar Lineq_FRA_05=-$theta*(Eeps_l_05-eps_lbar)


**********************************************************************************
*********						STEP II 					 		 *************
********* Finding growth lambda's( uses) output of STEP I            ************
**********************************************************************************


**Set type of allocation rule:
//* 1=Equal Allocation Rule
//* 2=Square Root Rule
//* 3=OECD Modified Equivalence Scale

scalar rule=1


****** Lambda's are found in 2 steps because 1984 consumption and expenditure data are different ******



***************************************************************
********** NOW DOING LAMBDA FOR CONSUMPTION TERMS *************
***************************************************************


**open 1984 consumption data file. Discard age > 100 and renormalize weights
quietly {
*use "C:\Users\klenow\Documents\Rawls\FRA\FRA_84.dta", clear
use "FRA_84.dta", clear

*destring pcode, replace

drop if age > 100
drop if age==.

ren weight weight_temp
egen weight_total=total(weight_temp)
gen weight = weight_temp/weight_total
drop weight_total weight_temp
}

*Apply country year identifying variables to each observation 
*	to facilitate merge with survival data

gen country="FRAia"
gen country_code="FRA" 
gen int year=1984
order country country_code year 

/*Create an OECD Modified Equivalence Scale variable 
quietly{
gen OECD1=1 if pcode==1
gen OECD2=0.5 if pcode~=1 & age>=14
gen OECD3=0.3 if pcode~=1 & age<14
egen OECDw= rsum(OECD1 OECD2 OECD3)
by hhid: egen OECDscale= total(OECDw)
drop OECD1 OECD2 OECD3 OECDw
lab var OECDscale "OECD Modified Equivalent Scale for household allocation"
}
*/
*apply allocation rule 
foreach var in hhexp {
if rule==1 {
replace `var'=`var'/hhsize
}
else if rule==2 {
replace `var'=`var'/sqrt(hhsize)
}
else if rule==3 {
replace `var'=`var'/OECDscale
}
}

*Now that we have allocated expenditures to individuals, convert individual consumption from 
* 	1984 FRA to constant international prices, incorporate govt consumption
* 	using Penn World Tables 6.3, and scale to year $baseyear US $
 
gen wc=weight*hhexp
lab var wc "weight*hhexp"
quietly {
su wc
}
return list
scalar sum_wc=r(sum) 

*Bring in cpop and gpop by merging with PWT_cpop_gpop.dta
sort country_code year
*merge m:m country_code year using "C:\Users\klenow\Documents\Rawls\PWT 6.3\PWT_cpop_gpop.dta"
merge m:m country_code year using "$pwt_file"
keep if country_code=="FRA"
keep if year==1984 
gen c_hat_jit=(cpop/sum_wc)*hhexp + gpop 
gen chat= c_hat_jit / cgpop_US_$baseyear
lab var chat "per capita consumption scaled by $baseyear U.S. $"
drop c_hat_jit wc cpop gpop cgpop cgpop_US_$baseyear _merge 

*Check that the weighted average of chat is ?
gen wchat=weight*chat
su wchat
return list

**Compute ln(chat)
foreach var in chat {
qui {
gen ln`var'=ln(`var')
}
}



*sum weights within age groups, create wbar:
*(Individual sampling weight)/(sum of all individual sampling weights in age group) 
sort age 
by age: egen total_age_weight=total(weight)
gen wbar=weight/total_age_weight 
drop weight total_age_weight
order age

*Check that wbar sums to 1 within each age group
*by age: egen total_wbar_a=total(wbar)
*list age total_wbar_a


*Merge with country-age level survival rate variables 
replace year = 1990
sort country_code year age 
*merge m:1 country_code year age using "C:\Users\klenow\Documents\Rawls\Survival Rates\survivalFRA05.dta"
merge m:1 country_code year age using "$survival_ind/survivalFRA05.dta"
keep if year==1990
keep if country_code=="FRA"
drop _merge
replace year=1984

**Compute stdev of ln(leisure) with FRA base period demographic weights
foreach var in lnchat {
qui {
su `var' [weight=s_FRAa*wbar]
return list
scalar sd_`var'_w=r(sd)
}
}
di sd_lnchat_w 


*create logca, averages over people of the same age. 
* first create lnchat*wbar for each observation, then sum over age groups
sort age 
gen logcja=lnchat*wbar
by age: egen logca=total(logcja)

*create ca, which are sums of chat*wbar within age groups.
* Will be used to calculate cbar
gen cja=chat*wbar
by age: egen ca=total(cja)


order country country_code year age logca ca wbar 

*collapse dataset to have one observation(row) per age group.

collapse (mean) logca=logca ca=ca s_FRAa=s_FRAa  delta_s_FRAa= delta_s_FRAa, by(country_code year age)

*If ca=0 then age must be missing.
gen missing_age=0
replace missing_age=1 if ca==0
*list

*Convert variables for missing ages from zero to missing 
foreach var in logca ca {
replace `var'=. if (missing_age==1) 
}


*interpolate logca, logla, ca, la for missing ages
foreach var in logca ca {
ipolate `var' age, gen(i`var')
replace `var'=i`var'
drop i`var'
}

* replace missing values by neighboring non-missing values
sort age
foreach var in logca ca{
replace `var' = `var'[_n-1] if missing(`var')
}
gen utila = 0.5*$ubar + logca
*list age s_USa logca logla ca utila

*generate log_cbar, the log of average ca, with s_FRAa as weights

gen cbar_a = s_FRAa*ca
egen cbar = total(cbar_a)
di cbar
scalar log_cbar = ln(cbar)
di log_cbar


*generate Elogc
gen logc_a = logca*s_FRAa
egen Elogc = total(logc_a)



* Calculate lambda components

** Calculate life expectancy term
gen ua = (0.5*$ubar + logca)
gen LE_a =  delta_s_FRAa*ua
*list age LE_a
egen LE = total(LE_a)
scalar log_lambda_LE_c = LE
drop logc_a

* Calculate average consumption term
scalar log_lambda_C_avg = log_cbar - ln(Cbar_FRA_05)


* Calculate consumption inequality term
scalar log_lambda_C_ineq = Elogc - log_cbar - Cineq_FRA_05




***************************************************************
********** NOW DOING LAMBDA FOR LEISURE TERMS *****************
***************************************************************


drop _all

**open 1984 leisure data file. Discard age > 100 and renormalize weights
quietly {
*use "C:\Users\klenow\Documents\Rawls\FRA\FRA_84.dta", clear
use "FRA_84.dta", clear
replace age=age+1
*replace age=100 if age>=100
drop if age > 100
drop if age==.

rename weight weight_l
egen weight_l_total=total(weight_l)
gen weight = weight_l/weight_l_total
drop weight_l weight_l_total
}

*Apply country year identifying variables to each observation 
*	to facilitate merge with survival data

gen country="France"
gen country_code="FRA" 
gen int year=1984
order country country_code year 



** Compute log of leisure
foreach var in leisure {
qui {
gen ln`var'=ln(`var')
}
}



****************************************
gen eps_leisure=((1-leisure)^((1+$epsilon)/$epsilon))/((1+$epsilon)/$epsilon)
su eps_leisure
scalar sd_eps_leisure_unwt=r(sd)
****************************************

*sum weights within age groups, create wbar:
*(individual sampling weight)/(sum of all individual sampling weights in age group) 
sort age 
by age: egen total_age_weight=total(weight)
gen wbar=weight/total_age_weight 
drop weight total_age_weight
order age

*Check that wbar sums to 1 within each age group
*by age: egen total_wbar_a=total(wbar)
*list age total_wbar_a


*Merge with country-year-age level survival rate variables
replace year=1990
sort country_code year age 
*merge m:1 country_code year age using "C:\Users\klenow\Documents\Rawls\Survival Rates\survivalFRA05.dta"
merge m:1 country_code year age using "$survival_ind/survivalFRA05.dta"
keep if year==1990
keep if country_code=="FRA"
drop _merge
replace year=1984

**Compute stdev of ln(leisure) with FRA base period demographic weights
foreach var in lnleisure {
qui {
su `var' [weight=s_FRAa*wbar]
return list
scalar sd_`var'_w=r(sd)
}
}
di sd_lnleisure_w



*create logla, averages over people of the same age. 
* first create lnleisure*wbar for each observation, then sum over age groups
sort age 
gen loglja=lnleisure*wbar 
by age: egen logla=total(loglja) 

*********************************
gen eps_lja=eps_leisure*wbar 
by age: egen eps_la=total(eps_lja) 
*********************************

*create la, which are sums of leisure*wbar within age groups.
* Will be used to calculate cbar and lbar
gen lja=leisure*wbar
by age: egen la=total(lja)

order country country_code year age logla eps_la la wbar 

*collapse dataset to have one observation(row) per age group.
 
collapse (mean)logla=logla eps_la la=la s_FRAa=s_FRAa delta_s_FRAa=delta_s_FRAa, by(country_code year age)

*If la=0 then age must be missing.
gen missing_age=0
replace missing_age=1 if la==0
*list

*Convert variables for missing ages from zero to missing 
foreach var in  logla eps_la la {
replace `var'=. if (missing_age==1) 
}


*interpolate logca, logla, ca, la for missing ages
foreach var in logla eps_la la {
ipolate `var' age, gen(i`var')
replace `var'=i`var'
drop i`var'
}

* replace missing values by neighboring non-missing values
sort age
foreach var in logla eps_la la{
replace `var' = `var'[_n-1] if missing(`var')
}

gen utila = 0.5*$ubar + $theta*logla
*list age s_USa logca logla ca la utila

*generate log_lbar, the log of average la, with sa as weights

gen lbar_a = s_FRAa*la
egen lbar = total(lbar_a)
scalar log_lbar = ln(lbar)
di log_lbar

****************************************
scalar eps_lbar = ((1-lbar)^((1+$epsilon)/$epsilon))/((1+$epsilon)/$epsilon)
di eps_lbar
****************************************

*generate Elogl

gen logl_a = logla*s_FRAa
egen Elogl = total(logl_a)

**************************
gen epsl_a = eps_la*s_FRAa
egen Eeps_l = total(epsl_a)
drop lbar_a epsl_a
**************************

* Calculate lambda components

** Calculate life expectancy term
gen ua = (0.5*$ubar - $theta*eps_la)
gen LE_a = delta_s_FRAa*ua
*list age LE_a
egen LE = total(LE_a)
scalar log_lambda_LE_l = LE
drop logl_a

scalar log_lambda_LE=log_lambda_LE_l +log_lambda_LE_c

* Calculate average leisure term
scalar log_lambda_L_avg = -$theta*(eps_lbar - epsLbar_FRA_05)

* Calculate leisure inequality term
scalar log_lambda_L_ineq = -$theta*(Eeps_l-eps_lbar) - Lineq_FRA_05

* Calculate lambda, i.e., the sum of the terms

scalar log_lambda = log_lambda_LE + log_lambda_C_avg + log_lambda_L_avg + log_lambda_C_ineq + log_lambda_L_ineq

* Lambda Decomposition for FRA 1984-2005

{
di log_lambda_LE
di log_lambda_C_avg
di log_lambda_L_avg
di log_lambda_C_ineq
di log_lambda_L_ineq
di log_lambda
}

*log close
