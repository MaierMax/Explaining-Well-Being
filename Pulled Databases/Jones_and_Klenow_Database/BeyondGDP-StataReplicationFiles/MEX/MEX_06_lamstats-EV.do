**********************Program 2****************************************
* Computes ln(lambdas), lambdas, SD of ln(consumption), ln(leisure), 
* in cross-section*
***********************************************************************

* MEX yyyy
scalar drop _all
drop _all
*global pwt_root C:\Users\Rui\Dropbox\Beyond_GDP\PWT_7.1
*global survival_root C:\Users\Rui\Dropbox\Beyond_GDP\Survival_Rates
*cd "C:\Users\Rui\Dropbox\Beyond_GDP"

*set varabbrev off
*set mem 100m
*local yyyy 2002
*local yy 02
*local stat_file_pfix "`pfix' "
* log using MEX_`yy'_lamstats.log, replace

**Set type of allocation rule:
* 1=Equal Allocation Rule
* 2=Square Root Rule
* 3=OECD Modified Equivalence Scale

scalar rule=1

**Set parameter and U.S. values

*scalar ubar = 4.1466
*scalar theta= 14.883
*scalar epsilon= 1

/*
foreach year of num 1984 2006{
	scalar Cbar_`year'= log_lambda_C_avg if year == `year'
	scalar LbarUS_`year' = exp(log_lambda_L_avg) if year == `year'
	scalar Cineq_`year'=log_lambda_C_inq if year == `year'
	scalar Lineq_`year' = log_lambda_L_inq if year == `year'
}
*/

use "$pwt_file",clear
sort country_code year
keep if country_code=="USA"
keep if year==2006
scalar CbarUS = cgpop_ratio
duplicates list country_code year
clear

* U.S. 2006 average consumption (demographic adjustment)
use $working_dir/baseline_results/USA_lamstats_results.dta, clear
keep if year == 2006
scalar lnCbarUSdemo = log_lambda_C_avg

* U.S. 1993 leisure  
scalar LbarUS =  lbar

* U.S. 1993 inequality
scalar CineqUS =  log_lambda_C_ineq

scalar LineqUS = log_lambda_L_ineq /$theta

/*
mat US_demo = J(2,4,.)
use $working_dir/baseline_results/USA_lamstats_results.dta, clear
keep if year == 1984
scalar  log_lambda_C_avg= log_lambda_C_avg
scalar lbar=lbar
scalar log_lambda_C_ineq=log_lambda_C_ineq
scalar  log_lambda_L_ineq = log_lambda_L_ineq 
mat US_demo[1,1]= log_lambda_C_avg 
mat US_demo[1,2] = lbar
mat US_demo[1,3] =log_lambda_C_ineq 
mat US_demo[1,4] =  log_lambda_L_ineq 
use $working_dir/baseline_results/USA_lamstats_results.dta, clear
keep if year == 2006
scalar log_lambda_C_avg =log_lambda_C_avg 
scalar lbar=lbar
scalar log_lambda_C_ineq=log_lambda_C_ineq
scalar log_lambda_L_ineq=log_lambda_L_ineq
mat US_demo[2,1]=log_lambda_C_avg 
mat US_demo[2,2] = lbar
mat US_demo[2,3] =log_lambda_C_ineq
mat US_demo[2,4] =  log_lambda_L_ineq 


*matrix input US_demo = (0.01903426,0.85505188,-0.19963368,-0.24580644\0.02995170,0.84740752,-0.20233819,-0.25504291\0.03736497,0.84151393,-0.20481502,-0.25976896\0.06168039,0.84340519,-0.20013148,-0.24873100\0.03112390,0.84381056,-0.21163824,-0.25718377\0.02875819,0.84184635,-0.20738260,-0.26163880)
matrix rownames US_demo = 1984 2006
matrix colnames US_demo = Cbar Lbar Cineq Lineq


*  Bring in cpop and gpop from PWT_cpop_gpop.dta.
*******************************************************************CHANGE DIRECTORY HERE********************
*cd "C:/research/ra_pk/rawls"
*cd "E:/4th Year/KLENOW_RA"
*cd "C:/My Documents/Rawls/MEX"
************************************************************************************************************



* U.S. yyyy demographic adjustment to average C
mat aux = US_demo["`yyyy'","Cbar"]
scalar lnCbarUSdemo = aux[1,1]

* U.S. yyyy leisure
mat aux = US_demo["`yyyy'","Lbar"]
scalar LbarUS = aux[1,1]

* U.S. yyyy inequality
mat aux = US_demo["`yyyy'","Cineq"]
scalar CineqUS = aux[1,1]
mat aux = US_demo["`yyyy'","Lineq"]
scalar LineqUS = aux[1,1]/$theta
*/
*scalar list

**open COUNTRY_YR.dta output file from Program 1; apply allocation rule
quietly {
use "MEX_06.dta", clear
drop if hhsize == .
drop if hhexp < 0
**(NOTE) I will destring pcode since I kept it in string mode in Program1 (sumstats) for not confusing ids within the household/
*destring pcode, replace

ren hhexp exp

* A couple of 'sanity-check' counts:
count
scalar def id_N = r(N)
count if leisure==1
scalar def full_leisure = r(N)/id_N
}

*Apply country year identifying variables to each observation 
*	to facilitate merge with survival data

gen country="Mexico"
gen country_code="MEX" 
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
* 	2002 Mexican pesos to constant international prices, incorporate govt consumption
* 	using Penn World Tables 6.3, and scale to year 2002 US $
  egen weight_sum = sum(weight)
 replace weight = weight/weight_sum
gen wc=weight*exp
lab var wc "weight*exp"
quietly {
su wc
}
return list
scalar sum_wc=r(sum) 

*Bring in cpop and gpop by merging MEX_02.dta with PWT_cpop_gpop.dta
sort country_code year
*merge m:m country_code year using PWT_cpop_gpop.dta
merge m:m country_code year using "$pwt_file"
keep if country_code=="MEX"
keep if year==2006

***************main doubt is line 115*;
gen c_hat_jit=(cpop/sum_wc)*exp+gpop

sum c_hat_jit
gen chat= c_hat_jit / cgpop_US_$baseyear
lab var chat "per capita consumption scaled by $baseyear U.S. $"
drop c_hat_jit wc cpop gpop cgpop cgpop_US_$baseyear _merge 


*Check that the weighted average of chat is ?
gen wchat=weight*chat
su wchat
return list

**Compute unweighted stdev of ln(leisure), ln(chat) with local demographic composition.
foreach var in chat leisure {
qui {
*gen ln`var'=ln(`var')
gen ln`var' = log(`var')
su ln`var'
*return list
scalar sd_ln`var'_unwt=r(sd)
}
}
di sd_lnchat_unwt 
di sd_lnleisure_unwt

**Compute weighted stdev of ln(leisure), ln(chat) with local demographic composition.
foreach var in chat leisure {
qui {
su ln`var' [weight=weight]
*return list
scalar sd_ln`var'_wt=r(sd)
}
}
di sd_lnchat_wt
di sd_lnleisure_wt

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


*(NOTE-CHANGE1)
*Merge with country-year-age level surivival rate variables
* [aim: Exception: Mexico missing survival rate data before 1990. Use survival rates from 1990 for earlier years]

	sort country_code year age 
	merge m:1 country_code year age using "$survival_file"
	keep if year==2006

keep if country_code=="MEX"

* [aim] Count ages that were not present in master data, i.e. had nothing to merge to
levelsof age if _merge==2, local(missing_ages)

drop _merge

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
by age: egen logca=sum(logcja)
gen loglja=lnleisure*wbar 
by age: egen logla=sum(loglja) 

*********************************
gen eps_lja=eps_leisure*wbar 
by age: egen eps_la=total(eps_lja) 
*********************************
save "test1.dta",replace
*create ca and la, which are sums of chat*wbar and leisure*wbar within age groups.
* Will be used to calculate cbar and lbar
gen cja=chat*wbar
by age: egen ca=total(cja)
gen lja=leisure*wbar
by age: egen la=total(lja)

order country country_code year age logca logla eps_la ca la wbar 

*collapse dataset to have one observation(row) per age group.
*  Columns: age, U.S. survival rate, log consumption, 
*   log leisure, chat*wbar, leisure*wbar, mean(chat), mean(leisure), 
*   sd(chat) sd(leisure) 
 
collapse (mean) logca=logca logla=logla eps_la=eps_la ca=ca la=la s_USa=s_USa delta_s_ia=delta_s_ia, by(country_code year age)
*collapse (min) logca=logca logla=logla eps_la=eps_la ca=ca la=la s_USa=s_USa delta_s_ia=delta_s_ia, by(age)

*If ca=0 then age must be missing.
gen missing_age=0
replace missing_age=1 if ca==0
*list

*Convert variables for missing ages from zero to missing (Note: 97 and 98 for ZAF) 
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
*save "test.dta",replace
gen utila = $ubar + logca + $theta*logla
*list age s_USa logca logla ca la utila

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
di log_lbar

****************************************
scalar eps_lbar = ((1-lbar)^((1+$epsilon)/$epsilon))/((1+$epsilon)/$epsilon)
di eps_lbar
****************************************

*generate Elogc and Elogl
gen logc_a = logca*s_USa
egen Elogc = total(logc_a)
*gen cineqi = Elogc-log_cbar-CineqUS

gen logl_a = logla*s_USa
egen Elogl = total(logl_a)

**************************
gen epsl_a = eps_la*s_USa
egen Eeps_l = total(epsl_a)
drop lbar_a cbar_a epsl_a
**************************

save "test2_.dta",replace

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

* Calculate average leisure term
scalar log_lambda_L_avg = -$theta*(eps_lbar - ((1-LbarUS)^((1+$epsilon)/$epsilon))/((1+$epsilon)/$epsilon))

* Calculate consumption inequality term
scalar log_lambda_C_ineq = Elogc - log_cbar - CineqUS

* Calculate leisure inequality term
scalar log_lambda_L_ineq = $theta*(-(Eeps_l-eps_lbar)-LineqUS)

* Calculate lambda, i.e., the sum of the terms

scalar log_lambda = log_lambda_LE + log_lambda_C_avg + log_lambda_L_avg + log_lambda_C_ineq + log_lambda_L_ineq

* Lambda Decomposition for MEX yyyy

{
di log_lambda_LE
di log_lambda_C_avg
di log_lambda_L_avg
di log_lambda_C_ineq
di log_lambda_L_ineq
di log_lambda
}

tab age if logca==.
*log close
*exit

