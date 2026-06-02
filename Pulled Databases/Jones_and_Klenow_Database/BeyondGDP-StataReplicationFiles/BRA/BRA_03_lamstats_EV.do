**********************Program****************************************
* Computes lambda decomposition EV
*********************************************************************

* BRA 2003

drop _all
scalar drop _all
set more off 
*cd "C:\Zach\Projects_Pete\Brazil\Calculation"
*log using ITA_06_lamstats_EV.log, replace
set varabbrev off

**Set type of allocation rule:
//* 1=Equal Allocation Rule
//* 2=Square Root Rule
//* 3=OECD Modified Equivalence Scale

scalar rule=1

**Set parameter and U.S. values

*scalar ubar = 4.1466
*scalar theta= 14.883
*scalar epsilon= 1

* U.S. 2003 C relative to U.S. $baseyear C
*  Bring in cpop and gpop from PWT_cpop_gpop.dta.
*use "C:\Users\klenow\Documents\Rawls\PWT 6.3\PWT_cpop_gpop.dta"
use "$pwt_file",clear
sort country_code year
keep if country_code=="USA"
keep if year==2003
scalar CbarUS = cgpop_ratio
di CbarUS
duplicates list country_code year
clear
******************************************************
* U.S. 2003 average consumption (demographic adjustment)
use $working_dir/baseline_results/USA_lamstats_results.dta, clear
keep if year == 2003
scalar lnCbarUSdemo = log_lambda_C_avg

* U.S. 2003 leisure  
scalar LbarUS = lbar

* U.S. 2003 inequality
scalar CineqUS =  log_lambda_C_ineq

scalar LineqUS = log_lambda_L_ineq /$theta
**********************************************************


***************************************************************
********** NOW DOING LAMBDA FOR CONSUMPTION TERMS *************
***************************************************************


**open 2008 consumption data file. Discard age > 100 and renormalize weights
quietly {
*use "C:\Users\Siddharth\Documents\phd\pete\Rawls\stata_copy\stata\38\Rawls\final\ind_83_exp.dta", clear
*use "C:\Documents and Settings\Sid\My Documents\phd\pete\Rawls\stata_copy\stata\38\Rawls\final\ind_83_exp.dta", clear
*use "C:\Users\klenow\Documents\Rawls\BRA\ind_83_exp.dta", clear
use "BRA_03_exp.dta", clear
rename hhexp exp
}

*Apply country year identifying variables to each observation 
*	to facilitate merge with survival data

gen country="Brazil"
gen country_code="BRA" 
* PWT data only has number up to 2007
gen int year=2003 
order country country_code year 

*Create an OECD Modified Equivalence Scale variable 
/*
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
foreach var in exp{
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
* 	2008 Brazilian rupee to constant international prices, incorporate govt consumption
* 	using Penn World Tables 6.3, and scale to year $baseyear US $
 egen weight_sum = sum(weight)
 replace weight = weight/weight_sum
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
keep if country_code=="BRA"
keep if year==2003
gen c_hat_jit=(cpop/sum_wc)*exp+gpop
gen chat= c_hat_jit / cgpop_US_$baseyear
lab var chat "per capita consumption scaled by $baseyear U.S. $"
drop c_hat_jit wc cpop gpop cgpop cgpop_US_$baseyear _merge 

*Check that the weighted average of chat is ?
gen wchat=weight*chat
su wchat
return list

**Compute ln(chat)
foreach var in chat{
qui {
gen ln`var'=ln(`var')
scalar sd_ln`var'_unwt=r(sd)
}
}

foreach var in chat {
qui{ 
su ln`var' [weight=weight]
*return list
scalar sd_ln`var'_wt=r(sd)
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


*Merge with country-age level survival rate variables 
sort country_code year age 
*merge m:1 country_code year age using "C:\Users\Siddharth\Documents\phd\pete\Rawls\stata_copy\stata\growth\survivalBRA05.dta"
*merge m:1 country_code year age using "C:\Documents and Settings\Sid\My Documents\phd\pete\Rawls\stata_copy\stata\growth\survivalBRA05.dta"
*merge m:1 country_code year age using "C:\Users\klenow\Documents\Rawls\Survival Rates\survivalBRA05.dta"
merge m:1 country_code year age using "$survival_file"
keep if year==2003
keep if country_code=="BRA"
drop _merge

**Compute stdev of ln(leisure) with BRA base period demographic weights
foreach var in lnchat {
qui {
su `var' [weight=s_USa*wbar]
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

collapse (mean) logca=logca ca=ca s_USa=s_USa  delta_s_ia= delta_s_ia, by(country_code year age)

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
foreach var in logca ca {
replace `var' = `var'[_n-1] if missing(`var')
}

save "test.dta",replace

*generate log_cbar, the log of average ca, with s_BRAa as weights

gen cbar_a = s_USa*ca
egen cbar = total(cbar_a)
di cbar
scalar log_cbar = ln(cbar)
di log_cbar


*generate Elogc
gen logc_a = logca*s_USa
egen Elogc = total(logc_a)



* Calculate lambda components

** Calculate life expectancy term
gen ua = (0.5*$ubar + logca)
gen LE_a =  delta_s_ia*ua
*list age LE_a
egen LE = total(LE_a)
scalar log_lambda_LE_c = LE
drop logc_a

* Calculate average consumption term
scalar log_lambda_C_avg = log_cbar - ln(CbarUS) - lnCbarUSdemo


* Calculate consumption inequality term
scalar log_lambda_C_ineq = Elogc - log_cbar - CineqUS




***************************************************************
********** NOW DOING LAMBDA FOR LEISURE TERMS *****************
***************************************************************


**open 2008 leisure data file. Discard age > 100 and renormalize weights
quietly {
*use "C:\Users\Siddharth\Documents\phd\pete\Rawls\stata_copy\stata\38\Rawls\final\ind_83_leisure.dta",clear
*use "C:\Documents and Settings\Sid\My Documents\phd\pete\Rawls\stata_copy\stata\38\Rawls\final\ind_83_leisure.dta",clear
*use "C:\Users\klenow\Documents\Rawls\BRA\ind_83_leisure.dta", clear
use "BRA_03_leisure.dta", clear
}

*Apply country year identifying variables to each observation 
*	to facilitate merge with survival data

gen country="Brazil"
gen country_code="BRA" 
gen int year=2003
order country country_code year 
egen weight_sum = sum(weight)
replace weight = weight/weight_sum
gen wleisure=weight*leisure
su wleisure
return list

** Compute log of leisure
foreach var in leisure {
qui {
gen ln`var'=ln(`var')
scalar sd_ln`var'_unwt=r(sd)
}
}

*************************************************************************
gen eps_leisure=((1-leisure)^((1+$epsilon)/$epsilon))/((1+$epsilon)/$epsilon)
scalar sd_eps_leisure_unwt=r(sd)
*************************************************************************

foreach var in leisure {
qui {
su ln`var' [weight=weight]
*return list
scalar sd_ln`var'_wt=r(sd)
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


*Merge with country-year-age level survival rate variables
sort country_code year age 
*merge m:1 country_code year age using "C:\Users\Siddharth\Documents\phd\pete\Rawls\stata_copy\stata\growth\survivalBRA05.dta"
*merge m:1 country_code year age using "C:\Documents and Settings\Sid\My Documents\phd\pete\Rawls\stata_copy\stata\growth\survivalBRA08.dta"
*merge m:1 country_code year age using "C:\Users\klenow\Documents\Rawls\Survival Rates\survivalBRA08.dta"
merge m:1 country_code year age using "$survival_file"
keep if year==2003
keep if country_code=="BRA"
drop _merge

**Compute stdev of ln(leisure) with BRA base period demographic weights
foreach var in lnleisure{
qui {
su `var' [weight=s_USa*wbar]
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

***********************************
gen eps_lja=eps_leisure*wbar 
by age: egen eps_la=total(eps_lja) 
***********************************

*create la, which are sums of leisure*wbar within age groups.
* Will be used to calculate cbar and lbar
gen lja=(leisure)*wbar
by age: egen la=total(lja)

order country country_code year age logla eps_la la wbar 

*collapse dataset to have one observation(row) per age group.
 
collapse (mean)logla=logla la=la eps_la=eps_la s_USa=s_USa delta_s_ia=delta_s_ia, by(country_code year age)

*If la=0 then age must be missing.
gen missing_age=0
replace missing_age=1 if la==0
*list

*Convert variables for missing ages from zero to missing 
foreach var in logla eps_la la {
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


***************************************
gen eps_utila = 0.5*$ubar - $theta*eps_la
***************************************

*list age s_USa logca logla ca la eps_utila

*generate log_lbar, the log of average la, with sa as weights

gen lbar_a = s_USa*la
egen lbar = total(lbar_a)
scalar log_lbar = ln(lbar)
di log_lbar

****************************************
scalar eps_lbar = ((1-lbar)^((1+$epsilon)/$epsilon))/((1+$epsilon)/$epsilon)
di eps_lbar
****************************************

*generate Elogl

gen logl_a = logla*s_USa
egen Elogl = total(logl_a)
drop lbar_a

**************************
gen epsl_a = eps_la*s_USa
egen Eeps_l = total(epsl_a)
drop epsl_a
**************************

* Calculate lambda components

** Calculate life expectancy term
gen ua = (0.5*$ubar - $theta*eps_la)
gen LE_a = delta_s_ia*ua
*list age LE_a
egen LE = total(LE_a)
scalar log_lambda_LE_l = LE
drop logl_a

scalar log_lambda_LE=log_lambda_LE_l +log_lambda_LE_c

* Calculate average leisure term
scalar log_lambda_L_avg = -$theta*(eps_lbar - ((1-LbarUS)^((1+$epsilon)/$epsilon))/((1+$epsilon)/$epsilon))

* Calculate leisure inequality term
scalar log_lambda_L_ineq = $theta*(-(Eeps_l-eps_lbar)-LineqUS)

* Calculate lambda, i.e., the sum of the terms

scalar log_lambda = log_lambda_LE + log_lambda_C_avg + log_lambda_L_avg + log_lambda_C_ineq + log_lambda_L_ineq

* Lambda Decomposition for BRA 2003

{
di log_lambda_LE
di log_lambda_C_avg
di log_lambda_L_avg
di log_lambda_C_ineq
di log_lambda_L_ineq
di log_lambda
}
