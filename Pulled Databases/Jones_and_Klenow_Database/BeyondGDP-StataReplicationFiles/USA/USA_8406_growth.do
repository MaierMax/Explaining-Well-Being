*log using "C:\Users\klenow\Documents\Rawls\USA\growth_84_log.smcl", replace
*log using "C:\My Documents\Rawls\USA\growth_84_log.smcl", replace


*****************************************************************************
*		 FIND THE GROWTH LAMBDA IN THE USA BETWEEN 1984 - 2006				*
* This program computes the % increase in consumption that individuals 	    *
* need in 1984 to be as well of as they are in 2006 					*
*****************************************************************************

*** STEP I: Calculate base (1984) values for CbarUSA, LbarUSA, CineqUSA, 
* LineqUSA etc using 1984 data and 1990 survival rates. 

* NOTE: Because 1983 Indian data for consumption and leisure had different 
* weights, this 2nd step is itself done in 2 sub-steps

*** STEP II, use 2006 data with 1990 survival rates and combine with Part I 
* to get growth lambda's. 



**********************************************************
*********				STEP I  			 *************
********* 1984 data with 1990 survival rates *************
**********************************************************


* Done in 2 steps as consumption and leisure data were in different files in India in 1983

*********************************************************************
********** GENERATING BASE VALUES FOR CONSUMPTION TERMS *************
*********************************************************************


drop _all
scalar drop _all

**Set parameter values for the utility function

*scalar ubar = 4.1466
*scalar theta= 14.883
*scalar epsilon= 1

**Set type of allocation rule:
//* 1=Equal Allocation Rule
//* 2=Square Root Rule
//* 3=OECD Modified Equivalence Scale
scalar rule=1


* Discard all observations with age > 100 and normalize weights
quietly {
*use "C:\Users\klenow\Documents\Rawls\USA\USA_84.dta", clear
use "USA_84.dta", clear
drop if age <= 0
drop if age > 100
drop if age==.

ren weight weight_temp
egen weight_total=total(weight_temp)
gen weight = weight_temp/weight_total
drop weight_temp weight_total
}


* Apply country year identifying variables to each observation 
* to facilitate merge with survival data

gen country="United States"
gen country_code="USA" 
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


*	Now that we have allocated expenditures to individuals, convert individual consumption from 
* 	1984 U.S. dollars to constant international prices, incorporate govt consumption
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
*merge m:m country_code year using "C:\Documents and Settings\Sid\My Documents\phd\pete\Rawls\stata_copy\stata\lambda\PWT_cpop_gpop.dta"
*merge m:m country_code year using "C:\Users\klenow\Documents\Rawls\PWT 6.3\PWT_cpop_gpop.dta"
merge m:m country_code year using "$pwt_file"
keep if country_code=="USA"
keep if year==1984
gen c_hat_jit=(cpop/sum_wc)*hhexp + gpop 
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

*Merge with country-age level survival rate variables
sort country country_code year age 
*merge m:1 country_code year age using "C:\Users\klenow\Documents\Rawls\Survival Rates\survivalUSA90.dta"
merge m:1 country_code year age using "$survival_ind/survivalUSA90.dta"
keep if year==1990
keep if country_code=="USA"
drop _merge

replace year=1984

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
 
collapse (mean) logca=logca ca=ca s_USAa=s_USAa  delta_s_USAa= delta_s_USAa, by(country_code year age)

*If ca=0 then age must be missing.
gen missing_age=0
replace missing_age=1 if ca==0
*list

*Convert variables for missing ages from zero to missing
foreach var in logca ca{
replace `var'=. if (missing_age==1) 
}

/*
*interpolate logca, logla, ca, la for missing ages
foreach var in logca logla eps_la ca la {
ipolate `var' age, gen(i`var')
replace `var'=i`var'
drop i`var'
}
*/
* replace missing values by neighboring non-missing values
sort age
foreach var in logca ca {
replace `var' = `var'[_n-1] if missing(`var')
}

*generate log_cbar, the log of average ca, with s_USAa as weights
* 

gen cbar_a = s_USAa*ca
egen cbar = total(cbar_a)
di cbar
gen log_cbar = ln(cbar)

*generate Elogc
gen logc_a = logca*s_USAa
egen Elogc = total(logc_a)

drop cbar_a

* Storing base year values in scalars for use in STEP I

scalar log_cbar_84=log_cbar
scalar Elogc_84=Elogc

scalar Cbar_USA_84=exp(log_cbar_84)
scalar Cineq_USA_84=Elogc_84-log_cbar_84




*********************************************************************
********** GENERATING BASE VALUES FOR LEISURE TERMS 	*************
*********************************************************************


* Discard all observations with age > 100 and normalize weights
quietly {
*use "C:\Users\klenow\Documents\Rawls\USA\USA_84.dta", clear
use "USA_84.dta", clear
drop if age <= 0
drop if age > 100
drop if age==.

ren weight weight_temp
egen weight_total=total(weight_temp)
gen weight = weight_temp/weight_total
drop weight_temp weight_total
}


* Apply country year identifying variables to each observation 
* to facilitate merge with survival data

gen country="United States"
gen country_code="USA" 
gen int year=1984
order country country_code year 


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

replace year=1990

*Merge with country-age level survival rates
sort country country_code year age 
*merge m:1 country_code year age using "C:\Users\klenow\Documents\Rawls\USA\survivalUSA90.dta"
merge m:1 country_code year age using "$survival_ind/survivalUSA90.dta"
keep if year==1990
keep if country_code=="USA"
drop _merge

replace year=1984

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

gen lja=leisure*wbar
by age: egen la=total(lja)

order country country_code year age logla eps_la wbar 

*collapse dataset to have one observation(row) per age group.
 
collapse (mean) logla=logla eps_la=eps_la la=la s_USAa=s_USAa  delta_s_USAa= delta_s_USAa, by(country_code year age)

*If la=0 then age must be missing.
gen missing_age=0
replace missing_age=1 if la==0
*list

*Convert variables for missing ages from zero to missing
foreach var in logla eps_la la {
replace `var'=. if (missing_age==1) 
}

/*
*interpolate logca, logla, ca, la for missing ages
foreach var in logca logla eps_la ca la {
ipolate `var' age, gen(i`var')
replace `var'=i`var'
drop i`var'
}
*/
* replace missing values by neighboring non-missing values
sort age
foreach var in logla eps_la la{
replace `var' = `var'[_n-1] if missing(`var')
}

*generate log_lbar, the log of average la, with s_USAa as weights
* 

gen lbar_a = s_USAa*la
egen lbar = total(lbar_a)
gen log_lbar = ln(lbar)

****************************************
scalar eps_lbar = ((1-lbar)^((1+$epsilon)/$epsilon))/((1+$epsilon)/$epsilon)
di eps_lbar
****************************************

*generate Elogl

gen logl_a = logla*s_USAa
egen Elogl = total(logl_a)

**************************
gen epsl_a = eps_la*s_USAa
egen Eeps_l = total(epsl_a)
drop lbar_a epsl_a
**************************

* Storing base year values in scalars for use in STEP I

scalar eps_lbar_84=eps_lbar
scalar Eeps_l_84=Eeps_l

scalar epsLbar_USA_84=eps_lbar_84 
scalar Lineq_USA_84=-$theta*(Eeps_l_84-eps_lbar)

di epsLbar_USA_84
di Lineq_USA_84


**********************************************************************************
*********						STEP II 					 		 *************
********* Finding growth lambda's (uses) output of STEP I            ************
**********************************************************************************


**Set type of allocation rule:
//* 1=Equal Allocation Rule
//* 2=Square Root Rule
//* 3=OECD Modified Equivalence Scale

scalar rule=1

**open 2006 consumption data file.
quietly {
*use "C:\Users\klenow\Documents\Rawls\USA\USA_06.dta", clear
use "USA_06.dta", clear
drop if age <= 0
drop if age > 100
drop if age==.

ren weight weight_temp
egen weight_total=total(weight_temp)
gen weight = weight_temp/weight_total
drop weight_total weight_temp
}

*Apply country year identifying variables to each observation 
*	to facilitate merge with survival data

gen country="United States"
gen country_code="USA" 
gen int year=2006
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
* 	2006 U.S. dollars to constant international prices, incorporate govt consumption
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
*merge m:m country_code year using "C:\Documents and Settings\Sid\My Documents\phd\pete\Rawls\stata_copy\stata\lambda\PWT_cpop_gpop.dta"
*merge m:m country_code year using "C:\Users\klenow\Documents\Rawls\PWT 6.3\PWT_cpop_gpop.dta"
merge m:m country_code year using "$pwt_file"
keep if country_code=="USA"
keep if year==2006
gen c_hat_jit=(cpop/sum_wc)*hhexp + gpop 
gen chat= c_hat_jit / cgpop_US_$baseyear
lab var chat "per capita consumption scaled by $baseyear U.S. $"
drop c_hat_jit wc cpop gpop cgpop cgpop_US_$baseyear _merge 

*Check that the weighted average of chat is ?
gen wchat=weight*chat
su wchat
return list

**Compute ln(chat) ln(leisure)
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

*Merge with country-age level survival rate variables 
sort country country_code year age 
*merge m:1 country_code year age using "C:\Users\klenow\Documents\Rawls\Survival Rates\survivalUSA90.dta"
merge m:1 country_code year age using "$survival_ind/survivalUSA90.dta"
keep if year==2006
keep if country_code=="USA"
drop _merge

**Compute stdev of ln(leisure) with USA base period demographic weights
foreach var in lnchat lnleisure {
qui {
su `var' [weight=s_USAa*wbar]
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

*********************************
gen eps_lja=eps_leisure*wbar 
by age: egen eps_la=total(eps_lja) 
*********************************

*create ca, which are sums of chat*wbar within age groups.
* Will be used to calculate cbar
gen cja=chat*wbar
by age: egen ca=total(cja)
gen lja=leisure*wbar
by age: egen la=total(lja)

order country country_code year age logca ca logla eps_la la wbar 

*collapse dataset to have one observation(row) per age group.

collapse (mean) logca=logca logla=logla eps_la=eps_la la=la ca=ca s_USAa=s_USAa  delta_s_USAa= delta_s_USAa, by(country_code year age)

*If ca=0 then age must be missing.
gen missing_age=0
replace missing_age=1 if ca==0
*list

*Convert variables for missing ages from zero to missing 
foreach var in logca ca logla eps_la la{
replace `var'=. if (missing_age==1) 
}

/*
*interpolate logca, logla, ca, la for missing ages
foreach var in logca logla eps_la ca la {
ipolate `var' age, gen(i`var')
replace `var'=i`var'
drop i`var'
}
*/
* replace missing values by neighboring non-missing values
sort age
foreach var in logca logla eps_la ca la{
replace `var' = `var'[_n-1] if missing(`var')
}


*generate log_cbar, the log of average ca, with s_USAa as weights

gen cbar_a = s_USAa*ca
egen cbar = total(cbar_a)
di cbar
scalar log_cbar = ln(cbar)
di log_cbar

*generate log_lbar, the log of average la, with sa as weights

gen lbar_a = s_USAa*la
egen lbar = total(lbar_a)
scalar log_lbar = ln(lbar)
di lbar
di log_lbar

****************************************
scalar eps_lbar = ((1-lbar)^((1+$epsilon)/$epsilon))/((1+$epsilon)/$epsilon)
di eps_lbar
****************************************


*generate Elogc
gen logc_a = logca*s_USAa
egen Elogc = total(logc_a)

*generate Elogl

gen logl_a = logla*s_USAa
egen Elogl = total(logl_a)

**************************
gen epsl_a = eps_la*s_USAa
egen Eeps_l = total(epsl_a)
drop lbar_a cbar_a epsl_a
**************************


* Calculate lambda components

** Calculate life expectancy term
gen ua = ($ubar + logca - $theta*eps_la)
gen LE_a =  delta_s_USAa*ua
*list age LE_a
egen LE = total(LE_a)
scalar log_lambda_LE= LE

* Calculate average consumption term
scalar log_lambda_C_avg = log_cbar - ln(Cbar_USA_84)

* Calculate average leisure term
scalar log_lambda_L_avg = -$theta*(eps_lbar - epsLbar_USA_84)

* Calculate consumption inequality term
scalar log_lambda_C_ineq = Elogc - log_cbar - Cineq_USA_84

* Calculate leisure inequality term
scalar log_lambda_L_ineq = -$theta*(Eeps_l-eps_lbar) - Lineq_USA_84

* Calculate lambda, i.e., the sum of the terms

scalar log_lambda = log_lambda_LE + log_lambda_C_avg + log_lambda_L_avg + log_lambda_C_ineq + log_lambda_L_ineq


* Lambda Decomposition for USA 1984-2006

{
di log_lambda_LE
di log_lambda_C_avg
di log_lambda_L_avg
di log_lambda_C_ineq
di log_lambda_L_ineq
di log_lambda
}

*log close
