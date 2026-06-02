*log using "C:\Users\Siddharth\Documents\phd\pete\Rawls\stata_copy\stata\CFE Labor\Growth\IND_83_growth_log.log",replace
*log using "C:\Documents and Settings\Sid\My Documents\phd\pete\Rawls\stata_copy\stata\growth\growth_log.smcl", replace
*log using "C:\Users\klenow\Documents\Rawls\IND\IND_83_growth_log.smcl", replace

*****************************************************************************
*		 FIND THE GROWTH LAMBDA IN INDIA BETWEEN 1983 - 2005				*
* This program computes the % increase in consumption that individuals 	    *
* want in 1983 and still be as well of as they are in 2005 					*
*****************************************************************************

*** The program proceeds in 2 steps

*** STEP I: Calculate base (1983) values for CbarIND, LbarIND, CineqIND, 
* LineqIND etc using 1983 data and 1983 (1990) survival rates. NOTE: Because 1983
* data for consumption and leisure have different weights, this 2nd step is
* itself done in 2 sub-steps

*** STEP II, use 2005 data with 1983 (1990) survival rates and combine with Part I 
* and II to get growth lambda's. 
drop _all
scalar drop _all
/*
scalar ubar = 4.1466
scalar theta= 14.883
scalar epsilon= 1
*/

**********************************************************
*********				STEP I  			 *************
********* 1983 data with 1990 survival rates *************
**********************************************************


* Done in 2 steps as consumption and leisure data are different in 1983

*********************************************************************
********** GENERATING BASE VALUES FOR CONSUMPTION TERMS *************
*********************************************************************



set varabbrev off
set more off
**Set type of allocation rule:
// 1=Equal Allocation Rule
// 2=Square Root Rule
// 3=OECD Modified Equivalence Scale
scalar rule=1


* Discard all observations with age > 100 and normalize weights
quietly {
*use "C:\Users\Siddharth\Documents\phd\pete\Rawls\stata_copy\stata\38\Rawls\final\ind_83_exp.dta"
*use "C:\Documents and Settings\Sid\My Documents\phd\pete\Rawls\stata_copy\stata\38\Rawls\final\ind_83_exp.dta"
*use "C:\Users\klenow\Documents\Rawls\IND\ind_83_exp.dta", clear
use "IND_83_exp.dta", clear
*replace age=age+1
*replace age=100 if age>=100
drop if age > 100
drop if age==.
/*
ren weight_c weight_temp
egen weight_total=total(weight_temp)
gen weight = weight_temp/weight_total
drop weight_temp weight_total
*/
}


* Apply country year identifying variables to each observation 
* to facilitate merge with survival data

gen country="India"
gen country_code="IND" 
gen int year=1983
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
rename hhexp exp
*apply allocation rule 
foreach var in exp {
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
* 	1983 Indian Rupee to constant international prices, incorporate govt consumption
* 	using Penn World Tables 6.3, and scale to year $baseyear US $
 
gen wc=weight*exp
lab var wc "weight*exp"
quietly {
su wc
}
return list
scalar sum_wc=r(sum) 

*Bring in cpop and gpop by merging with PWT_cpop_gpop.dta
sort country_code year
*merge m:m country_code year using "C:\Users\Siddharth\Documents\phd\pete\Rawls\stata_copy\stata\lambda\PWT_cpop_gpop.dta"
*merge m:m country_code year using "C:\Documents and Settings\Sid\My Documents\phd\pete\Rawls\stata_copy\stata\lambda\PWT_cpop_gpop.dta"
*merge m:m country_code year using "C:\Users\klenow\Documents\Rawls\PWT 6.3\PWT_cpop_gpop.dta"
merge m:m country_code year using "$pwt_file"
keep if country_code=="IND"
keep if year==1983
gen c_hat_jit=(cpop/sum_wc)*exp+gpop
gen chat= c_hat_jit / cgpop_US_$baseyear
lab var chat "per capita consumption scaled by $baseyear U.S. $"
drop c_hat_jit wc cpop gpop cgpop cgpop_US_$baseyear _merge 


*Check that the weighted average of chat is ?
gen wchat=weight*chat
su wchat
return list


foreach var in chat {
qui {
gen ln`var'=ln(`var')
}
}


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

replace year=1990

*Merge with country-age level survival rates
sort country_code year age 
*merge m:1 country_code year age using "C:\Users\Siddharth\Documents\phd\pete\Rawls\stata_copy\stata\growth\survivalIND90.dta"
*merge m:1 country_code year age using "C:\Documents and Settings\Sid\My Documents\phd\pete\Rawls\stata_copy\stata\growth\survivalIND90.dta"
*merge m:1 country_code year age using "C:\Users\klenow\Documents\Rawls\Survival Rates\survivalIND90.dta"
merge m:1 country_code year age using "$survival_ind/survivalIND90.dta"
keep if year==1990
keep if country_code=="IND"
drop _merge

replace year=1983

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
 
collapse (mean) logca=logca ca=ca s_INDa=s_INDa  delta_s_INDa= delta_s_INDa, by(country_code year age)

*If ca=0 then age must be missing. this problem doesn't arise with Indian data
gen missing_age=0
replace missing_age=1 if ca==0
*list

*Convert variables for missing ages from zero to missing
foreach var in logca ca{
replace `var'=. if (missing_age==1) 
}

*interpolate logca, ca for missing ages
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
*generate log_cbar, the log of average ca, with s_INDa as weights
* 

gen cbar_a = s_INDa*ca
egen cbar = total(cbar_a)
di cbar
gen log_cbar = ln(cbar)

*generate Elogc
gen logc_a = logca*s_INDa
egen Elogc = total(logc_a)

drop cbar_a

* Storing base year values in scalars for use in STEP II

scalar log_cbar_83=log_cbar
scalar Elogc_83=Elogc

scalar Cbar_IND_83=exp(log_cbar_83)
scalar Cineq_IND_83=(Elogc_83-log_cbar_83)




*********************************************************************
********** GENERATING BASE VALUES FOR LEISURE TERMS 	*************
*********************************************************************


* Discard all observations with age > 100 and normalize weights
quietly {
*use "C:\Users\Siddharth\Documents\phd\pete\Rawls\stata_copy\stata\38\Rawls\final\ind_83_leisure.dta", clear
*use "C:\Documents and Settings\Sid\My Documents\phd\pete\Rawls\stata_copy\stata\38\Rawls\final\ind_83_leisure.dta", clear
*use "C:\Users\klenow\Documents\Rawls\IND\ind_83_leisure.dta", clear
use "IND_83_leisure.dta", clear
*replace age=age+1
*replace age=100 if age>=100
drop if age > 100
drop if age==.

ren weight weight_temp
egen weight_total=total(weight_temp)
gen weight = weight_temp/weight_total
drop weight_temp weight_total

}


* Apply country year identifying variables to each observation 
* to facilitate merge with survival data

gen country="India"
gen country_code="IND" 
gen int year=1983
order country country_code year 


foreach var in leisure {
qui {
gen ln`var'=ln(`var')
}
}

*************************************************************************
gen eps_leisure=((1-leisure)^((1+$epsilon)/$epsilon))/((1+$epsilon)/$epsilon)
*************************************************************************


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


*Merge with country-age level survival rate variables
replace year=1990
sort country_code year age 
*merge m:1 country_code year age using "C:\Users\Siddharth\Documents\phd\pete\Rawls\stata_copy\stata\growth\survivalIND90.dta"
*merge m:1 country_code year age using "C:\Documents and Settings\Sid\My Documents\phd\pete\Rawls\stata_copy\stata\growth\survivalIND90.dta"
*merge m:1 country_code year age using "C:\Users\klenow\Documents\Rawls\Survival Rates\survivalIND90.dta"
merge m:1 country_code year age using "$survival_ind/survivalIND90.dta"
keep if year==1990
keep if country_code=="IND"
drop _merge
replace year=1983

*create logla, averages over people of the same age. 
* first create logla*wbar for each observation, then sum over age groups
sort age 
gen loglja=lnleisure*wbar 
by age: egen logla=total(loglja) 

*********************************
gen eps_lja=eps_leisure*wbar 
by age: egen eps_la=total(eps_lja) 
*********************************


*create la, which are sums of leisure*wbar within age groups.
* Will be used to calculate cbar and lbar

gen lja=(leisure)*wbar
by age: egen la=total(lja)

order country country_code year age logla wbar 


*collapse dataset to have one observation(row) per age group.
 
collapse (mean) logla=logla la=la eps_la=eps_la s_INDa=s_INDa  delta_s_INDa= delta_s_INDa, by(country_code year age)

*If la=0 then age must be missing. this problem doesn't arise with Indian data
gen missing_age=0
replace missing_age=1 if la==0
*list

*Convert variables for missing ages from zero to missing
foreach var in logla la eps_la{
replace `var'=. if (missing_age==1) 
}

*interpolate logla,la for missing ages
foreach var in logla la eps_la{
ipolate `var' age, gen(i`var')
replace `var'=i`var'
drop i`var'
}
* replace missing values by neighboring non-missing values
sort age
foreach var in logla eps_la la{
replace `var' = `var'[_n-1] if missing(`var')
}
*generate log_lbar, the log of average la, with s_INDa as weights
* 

gen lbar_a = s_INDa*la
egen lbar = total(lbar_a)
gen log_lbar = ln(lbar)

******************************************************************
scalar eps_lbar = ((1-lbar)^((1+$epsilon)/$epsilon))/((1+$epsilon)/$epsilon)
******************************************************************


*generate Elogl

gen logl_a = logla*s_INDa
egen Elogl = total(logl_a)


**************************
gen epsl_a = eps_la*s_INDa
egen Eeps_l = total(epsl_a)
***************************


drop lbar_a

* Storing base year values in scalars for use in STEP II

scalar log_lbar_83=log_lbar
scalar Elogl_83=Elogl

*scalar Lbar_IND_83=exp(log_lbar_83)
*scalar Lineq_IND_83=Elogl_83-log_lbar_83

scalar Lbar_IND_83 = lbar
scalar Lineq_IND_83 = -(Eeps_l-eps_lbar)





**********************************************************************************
*********						STEP II 					 		 *************
********* Finding growth lambda's (uses) output of STEP I            ************
**********************************************************************************


**Set type of allocation rule:
//* 1=Equal Allocation Rule
//* 2=Square Root Rule
//* 3=OECD Modified Equivalence Scale

scalar rule=1



**open 2005 consumption data file. Discard age > 100 and renormalize weights
quietly {
*use "C:\Users\Siddharth\Documents\phd\pete\Rawls\stata_copy\stata\61\Rawls\final\ind_05.dta", clear
*use "C:\Documents and Settings\Sid\My Documents\phd\pete\Rawls\stata_copy\stata\61\Rawls\final\ind_05.dta", clear
*use "C:\Users\klenow\Documents\Rawls\IND\ind_05.dta", clear
use "IND_05.dta", clear

*replace age=age+1
*replace age=100 if age>=100
drop if age > 100
drop if age==.

ren weight weight_temp
egen weight_total=total(weight_temp)
gen weight = weight_temp/weight_total
drop weight_total weight_temp

}

*Apply country year identifying variables to each observation 
*	to facilitate merge with survival data

gen country="India"
gen country_code="IND" 
gen int year=2005
order country country_code year 
rename hhexp exp
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
foreach var in exp {
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
* 	2005 Indian rupee to constant international prices, incorporate govt consumption
* 	using Penn World Tables 6.3, and scale to year $baseyear US $
 
gen wc=weight*exp
lab var wc "weight*exp"
quietly {
su wc
}
return list
scalar sum_wc=r(sum) 

*Bring in cpop and gpop by merging with PWT_cpop_gpop.dta
sort country_code year
*merge m:m country_code year using "C:\Users\Siddharth\Documents\phd\pete\Rawls\stata_copy\stata\lambda\PWT_cpop_gpop.dta"
*merge m:m country_code year using "C:\Documents and Settings\Sid\My Documents\phd\pete\Rawls\stata_copy\stata\lambda\PWT_cpop_gpop.dta"
*merge m:m country_code year using "C:\Users\klenow\Documents\Rawls\PWT 6.3\PWT_cpop_gpop.dta"
merge m:m country_code year using "$pwt_file"
keep if country_code=="IND"
keep if year==2005
gen c_hat_jit=(cpop/sum_wc)*exp+gpop
gen chat= c_hat_jit / cgpop_US_$baseyear
lab var chat "per capita consumption scaled by $baseyear U.S. $"
drop c_hat_jit wc cpop gpop cgpop cgpop_US_$baseyear _merge 

*Check that the weighted average of chat is 0.08
gen wchat=weight*chat
su wchat
return list

**Compute ln(chat) ln(leisure)
foreach var in chat leisure {
qui {
gen ln`var'=ln(`var')
}
}

*************************************************************************
gen eps_leisure=((1-leisure)^((1+$epsilon)/$epsilon))/((1+$epsilon)/$epsilon)
*************************************************************************


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


*Merge with country-age level survival rate variables 
sort country_code year age 
*merge m:1 country_code year age using "C:\Users\Siddharth\Documents\phd\pete\Rawls\stata_copy\stata\growth\survivalIND90.dta"
*merge m:1 country_code year age using "C:\Documents and Settings\Sid\My Documents\phd\pete\Rawls\stata_copy\stata\growth\survivalIND90.dta"
*merge m:1 country_code year age using "C:\Users\klenow\Documents\Rawls\Survival Rates\survivalIND90.dta"
merge m:1 country_code year age using "$survival_ind/survivalIND90.dta"
keep if year==2005
keep if country_code=="IND"
drop _merge

**Compute stdev of ln(leisure) with IND base period demographic weights
foreach var in lnchat lnleisure {
qui {
su `var' [weight=s_INDa*wbar]
return list
scalar sd_`var'_w=r(sd)
}
}
di sd_lnchat_w 
di sd_lnleisure_w


*create logca, averages over people of the same age. 
* first create lnchat*wbar for each observation, then sum over age groups
sort age 
gen logcja=lnchat*wbar
by age: egen logca=total(logcja)
gen loglja=lnleisure*wbar 
by age: egen logla=total(loglja) 

***********************************
gen eps_lja=eps_leisure*wbar 
by age: egen eps_la=total(eps_lja) 
***********************************



*create ca, which are sums of chat*wbar within age groups.
* Will be used to calculate cbar
gen cja=chat*wbar
by age: egen ca=total(cja)
gen lja=(leisure)*wbar
by age: egen la=total(lja)

order country country_code year age logca ca logla la wbar 

*collapse dataset to have one observation(row) per age group.

collapse (mean) logca=logca logla=logla la=la eps_la=eps_la ca=ca s_INDa=s_INDa  delta_s_INDa= delta_s_INDa, by(country_code year age)

*If ca=0 then age must be missing.
gen missing_age=0
replace missing_age=1 if ca==0
*list

*Convert variables for missing ages from zero to missing 
foreach var in logca ca logla la eps_la{
replace `var'=. if (missing_age==1) 
}

*interpolate logca, logla, ca, la for missing ages 
foreach var in logca ca logla la eps_la{
ipolate `var' age, gen(i`var')
replace `var'=i`var'
drop i`var'
}
* replace missing values by neighboring non-missing values
sort age
foreach var in logca logla eps_la ca la{
replace `var' = `var'[_n-1] if missing(`var')
}
gen utila = $ubar + logca + logla

***************************************
gen eps_utila = $ubar + logca- $theta*eps_la
***************************************


*generate log_cbar, the log of average ca, with s_INDa as weights

gen cbar_a = s_INDa*ca
egen cbar = total(cbar_a)
di cbar
scalar log_cbar = ln(cbar)
di log_cbar

*generate log_lbar, the log of average la, with sa as weights

gen lbar_a = s_INDa*la
egen lbar = total(lbar_a)
scalar log_lbar = ln(lbar)
di log_lbar

****************************************
scalar eps_lbar = ((1-lbar)^((1+$epsilon)/$epsilon))/((1+$epsilon)/$epsilon)
di eps_lbar
****************************************

*generate Elogc
gen logc_a = logca*s_INDa
egen Elogc = total(logc_a)

*generate Elogl

gen logl_a = logla*s_INDa
egen Elogl = total(logl_a)
drop lbar_a

**************************
gen epsl_a = eps_la*s_INDa
egen Eeps_l = total(epsl_a)
**************************


* Calculate lambda components

** Calculate life expectancy term
gen ua = ($ubar + logca - $theta*eps_la)
gen LE_a =  delta_s_INDa*ua
*list age LE_a
egen LE = total(LE_a)
scalar log_lambda_LE= LE

* Calculate average consumption term
scalar log_lambda_C_avg = log_cbar - ln(Cbar_IND_83)

* Calculate average leisure term
scalar log_lambda_L_avg = -$theta*(eps_lbar - ((1-Lbar_IND_83)^((1+$epsilon)/$epsilon))/((1+$epsilon)/$epsilon))

* Calculate consumption inequality term
scalar log_lambda_C_ineq = Elogc - log_cbar - Cineq_IND_83

* Calculate leisure inequality term
scalar log_lambda_L_ineq = $theta*(-(Eeps_l-eps_lbar)-Lineq_IND_83)

* Calculate lambda, i.e., the sum of the terms

scalar log_lambda = log_lambda_LE + log_lambda_C_avg + log_lambda_L_avg + log_lambda_C_ineq + log_lambda_L_ineq


* Lambda Decomposition for IND 1983-2005

{
di log_lambda_LE
di log_lambda_C_avg
di log_lambda_L_avg
di log_lambda_C_ineq
di log_lambda_L_ineq
di log_lambda
}

*log close
