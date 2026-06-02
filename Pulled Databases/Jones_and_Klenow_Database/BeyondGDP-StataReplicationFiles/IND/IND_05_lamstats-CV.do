* IND 2004-05 (2005 figures from PWT are being used)

set more off
set varabbrev off
drop _all
scalar drop _all

*log using IND_05_lamstats.log, replace

**Set type of allocation rule:
//* 1=Equal Allocation Rule
//* 2=Square Root Rule
//* 3=OECD Modified Equivalence Scale

scalar rule=1

**Set parameter and U.S. values

*scalar ubar = 4.1466
*scalar theta= 14.883
*scalar epsilon= 1

* U.S. 2005 C relative to U.S. 2000 C
*  Bring in cpop and gpop from PWT_cpop_gpop.dta.
*use "C:\Users\Siddharth\Documents\phd\pete\Rawls\stata_copy\stata\lambda\PWT_cpop_gpop.dta"
*use "C:\Documents and Settings\Sid\My Documents\phd\pete\Rawls\stata_copy\stata\lambda\PWT_cpop_gpop.dta"
use "$pwt_file"
*use "C:\Documents and Settings\Pete Klenow\My Documents\My Documents\Rawls\PWT 6.3\PWT_cpop_gpop.dta"
sort country_code year
keep if country_code=="USA"
keep if year==2005
scalar CbarUS = cgpop_ratio
duplicates list country_code year
clear

* U.S. 2005 average consumption (demographic adjustment)
use $working_dir/baseline_results/USA_lamstats_results.dta, clear
keep if year == 2005
scalar lnCbarUSdemo = log_lambda_C_avg

* U.S. 2005 leisure  
scalar LbarUS =  lbar

scalar CineqUS =  log_lambda_C_ineq
* U.S. 2005 inequality
scalar LineqUS = log_lambda_L_ineq /$theta
*scalar list

**open COUNTRY_YR.dta output file from Program 1; apply allocation rule
quietly {
*use "C:\Users\Siddharth\Documents\phd\pete\Rawls\stata_copy\stata\61\Rawls\final\ind_05.dta"
*use "C:\Documents and Settings\Sid\My Documents\phd\pete\Rawls\stata_copy\stata\61\Rawls\final\ind_05.dta"
*use "C:\Documents and Settings\Pete Klenow\My Documents\My Documents\Rawls\IND\ind_05.dta", clear


use "CFE Labor/2005/ind_05.dta", clear
*replace age=age+1
drop if age > 100
drop if age==.
ren weight weight_temp
egen weight_total=total(weight_temp)
gen weight = weight_temp/weight_total
drop weight_temp weight_total

}

*Apply country year identifying variables to each observation 
*	to facilitate merge with survival data

gen country="India"
gen country_code="IND" 
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

*gen hrs_week=hrs_month*12/52
*replace hrs_week=8*5 if hrs_week>8*5
*replace hrs_month=hrs_week*52/12
*replace leisure=(5840/12-hrs_month)/(5840/12)
*apply allocation rule 
foreach var in exp {
if rule==1 {
replace `var'=`var'/hhsize
}
else if rule==2 {
replace `var'=`var'/sqrt(hhsize)
}
/*
else if rule==3 {
replace `var'=`var'/OECDscale
}
*/
}

*Now that we have allocated expenditures to individuals, convert individual consumption from 
* 	2005 Indian Rupee to constant international prices, incorporate govt consumption
* 	using Penn World Tables 6.3, and scale to year 2000 US $
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
merge m:m country_code year using "$pwt_file"
*merge m:m country_code year using "C:\Documents and Settings\Pete Klenow\My Documents\My Documents\Rawls\PWT 6.3\PWT_cpop_gpop.dta"
keep if country_code=="IND"
keep if year==2005
gen c_hat_jit=(cpop/sum_wc)*exp+gpop 
gen chat= c_hat_jit / cgpop_US_$baseyear
lab var chat "per capita consumption scaled by 2005 U.S. $"
drop c_hat_jit wc cpop gpop cgpop cgpop_US_$baseyear _merge 


*Check that the weighted average of chat is ?
gen wchat=weight*chat
su wchat
return list

**Compute unweighted stdev of ln(leisure),ln(chat) with local demographic composition.
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


**Compute weighted stdev of ln(leisure), ln(chat) with local demographic composition.
foreach var in chat leisure{
qui {
su ln`var' [weight=weight]
*return list
scalar sd_ln`var'_wt=r(sd)
}
}
di sd_lnchat_wt
di sd_lnleisure_wt

*****************************
su eps_leisure [weight=weight]
scalar sd_eps_leisure_wt=r(sd)
*****************************


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

*Merge with country-year-age level surivival rate variables
sort country country_code year age 
*merge m:1 country_code year age using "C:\Users\Siddharth\Documents\phd\pete\Rawls\stata_copy\stata\lambda\survival.dta"
*merge m:1 country_code year age using "C:\Documents and Settings\Sid\My Documents\phd\pete\Rawls\stata_copy\stata\lambda\survival.dta"
merge m:1 country_code year age using "$survival_file" 
*merge m:1 country_code year age using "C:\Documents and Settings\Pete Klenow\My Documents\My Documents\Rawls\Survival Rates\survival.dta" 
keep if year==2005
keep if country_code=="IND"
gen s_ia=S_ia/Stotal_i
replace delta_s_ia=(S_ia - S_USa)/Stotal_i
drop _merge

**Compute stdev of ln(chat) with local demographic weights
foreach var in lnchat lnleisure {
qui {
su `var' [weight=s_ia*wbar]
return list
scalar sd_`var'_w=r(sd)
}
}
di sd_lnchat_w 
di sd_lnleisure_w

*********************************
su eps_leisure [weight=s_ia*wbar]
return list
scalar sd_rholeisure_w=r(sd)
*********************************


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

gen lja=(leisure)*wbar
by age: egen la=total(lja)
** No need to bring in $epsilon here **

order country country_code year age logca logla eps_la ca la wbar 

*collapse dataset to have one observation(row) per age group.
*  Columns: age, survival rate, log consumption, 
*   log leisure, chat*wbar, leisure*wbar, mean(chat), mean(leisure), mean(income), 
*   sd(chat) sd(leisure) sd(income) 
 
collapse (mean) logca=logca logla=logla eps_la=eps_la ca=ca la=la s_ia=s_ia delta_s_ia=delta_s_ia, by(country_code year age)

*If ca=0 then age must be missing. this problem doesn't arise with Indian data
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

gen utila = $ubar + logca + $theta*logla

*****************************************
gen eps_utila = $ubar +logca - $theta*eps_la
*****************************************

*list age s_ia logca logla ca la utila

*generate log_cbar and log_lbar, the log of average ca and la, with s_ia as weights

gen cbar_a = s_ia*ca
egen cbar = total(cbar_a)
di cbar
scalar log_cbar = ln(cbar)
di log_cbar

gen lbar_a = s_ia*la
egen lbar = total(lbar_a)
scalar log_lbar = ln(lbar)
di log_lbar

****************************************
scalar eps_lbar = ((1-lbar)^((1+$epsilon)/$epsilon))/((1+$epsilon)/$epsilon)
di eps_lbar
****************************************


*generate Elogc and Elogl Erhol
gen logc_a = logca*s_ia
egen Elogc = total(logc_a)

gen logl_a = logla*s_ia
egen Elogl = total(logl_a)

**************************
gen epsl_a = eps_la*s_ia
egen Eeps_l = total(epsl_a)
**************************

drop lbar_a cbar_a epsl_a

* Merge in U.S. ua components
sort year age 
merge m:1 year age using "$working_dir/USA/USA_05_byage.dta" 
*merge m:1 year age using "C:\Documents and Settings\Pete Klenow\My Documents\My Documents\Rawls\USA\USA_05_byage.dta"
drop _merge


* Calculate lambda components

** Calculate life expectancy term
gen ua_US = ($ubar + logca_US - $theta*epsla_US)
gen LE_a = (delta_s_ia)*ua_US
*list age LE_a
egen LE = total(LE_a)
scalar log_lambda_LE = LE
drop logl_a logc_a

* Calculate average consumption term
gen Cbara_US = s_ia*ca_US
egen CbarUS = total(Cbara_US)
scalar log_lambda_C_avg = log_cbar - ln(CbarUS)

* Calculate average leisure term
gen Lbara_US = s_ia*la_US
egen LbarUS = total(Lbara_US)
scalar log_lambda_L_avg = -$theta*(eps_lbar - ((1-LbarUS)^((1+$epsilon)/$epsilon))/((1+$epsilon)/$epsilon))

* Calculate consumption inequality term
gen logca_USa = s_ia*logca_US
egen Elogc_US = total(logca_USa)
scalar log_lambda_C_ineq = Elogc - log_cbar - (Elogc_US - ln(CbarUS))

* Calculate leisure inequality term
gen epsla_USa = s_ia*epsla_US
egen Eepsl_US = total(epsla_USa)
scalar log_lambda_L_ineq = $theta*(-(Eeps_l-eps_lbar)+(Eepsl_US-((1-LbarUS)^((1+$epsilon)/$epsilon))/((1+$epsilon)/$epsilon)))

* Calculate lambda, i.e., the sum of the terms

scalar log_lambda = log_lambda_LE + log_lambda_C_avg + log_lambda_L_avg + log_lambda_C_ineq + log_lambda_L_ineq

* Lambda Decomposition for IND 2005

{
di log_lambda_LE
di log_lambda_C_avg
di log_lambda_L_avg
di log_lambda_C_ineq
di log_lambda_L_ineq
di log_lambda
}


*log close

*drop _all

*mat result =[sd_lnchat_unwt, sd_rholeisure_unwt,sd_lnchat_wt,sd_rholeisure_wt,sd_lnchat_w,sd_rholeisure_w,log_cbar,rho_lbar,log_lambda_LE,log_lambda_C_avg,log_lambda_L_avg,log_lambda_C_ineq,log_lambda_L_ineq,log_lambda]

*svmat result
*outsheet using "C:\Users\Siddharth\Documents\phd\pete\Rawls\stata_copy\stata\pete_lambda_3-16-2010\2004\result.csv", comma replace

