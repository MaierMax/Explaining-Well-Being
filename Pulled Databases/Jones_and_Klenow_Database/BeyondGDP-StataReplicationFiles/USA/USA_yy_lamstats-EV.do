**********************Program 2****************************************
* Computes ln(lambdas), lambdas, SD of ln(consumption), ln(leisure), 
* ln(income) in cross-section
***********************************************************************

* USA `yyyy'
*local yy = substr(`yyyy',3,2)
scalar drop _all
drop _all
set varabbrev off


**Set type of allocation rule:
// 1=Equal Allocation Rule
// 2=Square Root Rule
// 3=OECD Modified Equivalence Scale

scalar rule=1

**Set parameter and U.S. values

*scalar ubar = 4.1466
*scalar theta= 14.883
*scalar epsilon= 1

* U.S. `yyyy' C relative to U.S. `yyyy' C
*  Bring in cpop and gpop from PWT_cpop_gpop.dta.
use "$pwt_file"
*use "C:\Documents and Settings\Pete Klenow\My Documents\My Documents\Rawls\PWT 6.3\PWT_cpop_gpop.dta"
sort country_code year
keep if country_code=="USA"
keep if year==`yyyy'
scalar CbarUS = cgpop_ratio
di CbarUS
duplicates list country_code year
clear

* U.S. $baseyear leisure
scalar LbarUS = 1.00

* U.S. `yyyy' average consumption (demographic adjustment)
scalar lnCbarUSdemo = 0.0

* U.S. `yyyy' inequality
scalar CineqUS = 0.0
scalar LineqUS = 0.0/$theta

*scalar list

**open COUNTRY_YR.dta output file from Program 1; apply allocation rule
quietly {
use "USA_`yy'.dta", clear
*use "C:\Documents and Settings\Pete Klenow\My Documents\My Documents\Rawls\USA\USA_05.dta", clear
ren hhexp exp
}

*Apply country year identifying variables to each observation 
*	to facilitate merge with survival data

gen country="United States"
gen country_code="USA" 
gen int year=`yyyy'
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
* 	2006 U.S. dollars to constant international prices, incorporate govt consumption
* 	using Penn World Tables 6.3, and scale to year $baseyear US $
 
 
* check if the weight adds up to be 1
egen weight_sum = sum(weight)
replace weight=weight/weight_sum
gen wc=weight*exp
lab var wc "weight*exp"
quietly {
su wc
}
return list
scalar sum_wc=r(sum) 

*Bring in cpop and gpop by merging USA_06.dta with PWT_cpop_gpop.dta
sort country_code year
merge m:m country_code year using "$pwt_file"
*merge m:m country_code year using "C:\Documents and Settings\Pete Klenow\My Documents\My Documents\Rawls\PWT 6.3\PWT_cpop_gpop.dta"
keep if country_code=="USA"
keep if year==`yyyy'
gen c_hat_jit=(cpop/sum_wc)*exp+gpop 
gen chat= c_hat_jit / cgpop_US_$baseyear
lab var chat "per capita consumption scaled by $baseyear U.S. $"
drop c_hat_jit wc cpop gpop cgpop cgpop_US_$baseyear _merge 


*Check that the weighted average of chat is ?
gen wchat=weight*chat
su wchat
return list

*Check unweighted average of leisure
su leisure

*Check weighted average of leisure
gen wleisure=weight*leisure
su wleisure
return list

**Compute unweighted stdev of ln(leisure), ln(income), ln(chat) with local demographic composition.
foreach var in chat leisure {
qui {
gen ln`var'=ln(`var')
su ln`var'
*return list
scalar sd_ln`var'_unwt=r(sd)
}
}
di sd_lnchat_unwt 
di sd_lnleisure_unwt

****************************************
gen eps_leisure=((1-leisure)^((1+$epsilon)/$epsilon))/((1+$epsilon)/$epsilon)
su eps_leisure
scalar sd_eps_leisure_unwt=r(sd)
****************************************

**Compute weighted stdev of ln(leisure), ln(income), ln(chat) with local demographic composition.
foreach var in chat leisure{
qui {
su ln`var' [weight=weight]
*return list
scalar sd_ln`var'_wt=r(sd)
}
}
di sd_lnchat_wt
di sd_lnleisure_wt

*sum weights within age groups, create wbar:
*(individual sampling weight)/(sum of all individual sampling weights in age group) 
sort age 
by age: egen total_age_weight=total(weight)
gen wbar=weight/total_age_weight 
drop total_age_weight
order age

*Check that wbar sums to 1 within each age group
*by age: egen total_wbar_a=total(wbar)
*list age total_wbar_a

*Merge with country-year-age level survival rate variables
* [Rui: exception: no survival rate data before 1990. Use survival rates from 1990 for earlier years]
if `yyyy' < 1990 {
	replace year = 1990
	sort country country_code year age 
	merge m:1 country_code year age using "$survival_file" 
	*merge m:1 country_code year age using "C:\Documents and Settings\Pete Klenow\My Documents\My Documents\Rawls\Survival Rates\survival.dta" 
	keep if year==1990
	keep if country_code=="USA"
	replace year = `yyyy'
	drop _merge
}
else {
	sort country country_code year age 
	merge m:1 country_code year age using "$survival_file" 
	*merge m:1 country_code year age using "C:\Documents and Settings\Pete Klenow\My Documents\My Documents\Rawls\Survival Rates\survival.dta" 
	keep if year==`yyyy'
	keep if country_code=="USA"
	drop _merge
}
**Compute stdev of ln(chat) with U.S. demographic weights
foreach var in lnchat lnleisure {
qui {
su `var' [weight=s_USa*wbar]
return list
scalar sd_`var'_w=r(sd)
}
}
di sd_lnchat_w 
di sd_lnleisure_w


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
by age: egen totweight = sum(weight)
order country country_code year age logca logla eps_la ca la wbar 

*collapse dataset to have one observation(row) per age group.
*  Columns: age, U.S. survival rate, U.S. survival rate, log consumption, 
*   log leisure, chat*wbar, leisure*wbar, mean(chat), mean(leisure), mean(income), 
*   sd(chat) sd(leisure) sd(income) 
 
collapse (mean) logca=logca logla=logla eps_la=eps_la ca=ca la=la s_USa=s_USa delta_s_ia=delta_s_ia totweight=totweight, by(country_code year age)
*save "US_test1.dta",replace
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

save "US_test2.dta",replace

gen utila = $ubar + logca + $theta*logla
list age ca la utila totweight

*****************************************
gen eps_utila = $ubar +logca - $theta*eps_la
*****************************************

*generate log_cbar and log_lbar, the log of average ca and la, with sa as weights

gen cbar_a = s_USa*ca
egen cbar = total(cbar_a)
di cbar
scalar log_cbar = ln(cbar)
di log_cbar

gen lbar_a = s_USa*la
egen lbar = total(lbar_a)
di lbar
scalar log_lbar = ln(lbar)
*scalar LbarUS = lbar
di log_lbar

****************************************
scalar eps_lbar = ((1-lbar)^((1+$epsilon)/$epsilon))/((1+$epsilon)/$epsilon)
di eps_lbar
****************************************

*generate Elogc and Elogl
gen logc_a = logca*s_USa
egen Elogc = total(logc_a)

gen logl_a = logla*s_USa
egen Elogl = total(logl_a)

**************************
gen epsl_a = eps_la*s_USa
egen Eeps_l = total(epsl_a)
drop lbar_a cbar_a epsl_a
**************************

* Calculate lambda components

** Calculate life expectancy term
gen ua = ($ubar + logca - $theta*eps_la)
gen LE_a = (delta_s_ia)*ua
*list age LE_a
egen LE = total(LE_a)
scalar log_lambda_LE = LE
drop logl_a logc_a


* Calculate average consumption term
scalar log_lambda_C_avg = log_cbar - ln(CbarUS) - lnCbarUSdemo
*scalar log_lambda_C_avg = log_cbar

** Calculate average leisure term
scalar log_lambda_L_avg = -$theta*(eps_lbar - ((1-LbarUS)^((1+$epsilon)/$epsilon))/((1+$epsilon)/$epsilon))
scalar lbar = lbar
* Calculate consumption inequality term
scalar log_lambda_C_ineq = Elogc - log_cbar - CineqUS

* Calculate leisure inequality term
scalar log_lambda_L_ineq = $theta*(-(Eeps_l-eps_lbar)-LineqUS)

* Calculate lambda, i.e., the sum of the terms

scalar log_lambda = log_lambda_LE + log_lambda_C_avg + log_lambda_L_avg + log_lambda_C_ineq + log_lambda_L_ineq

ren logca logca_US
ren eps_la epsla_US
ren ca ca_US
ren la la_US
keep year age logca_US epsla_US ca_US la_US
save "USA_`yy'_byage.dta", replace
*save "C:\Documents and Settings\Pete Klenow\My Documents\My Documents\Rawls\USA\USA_05_byage.dta", replace

* Lambda Decomposition for USA `yyyy'

{
di log_lambda_LE
di log_lambda_C_avg
di lbar
di log_lambda_C_ineq
di log_lambda_L_ineq
di log_lambda
}

*exit
